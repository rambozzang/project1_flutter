import Foundation
import Flutter

/// iOS가 소유하는 background URLSession Direct Upload 전송기.
/// Dart가 멈춰도 URLSession이 파일을 계속 보내고, 결과는 UserDefaults에 남겨 다음
/// 앱 실행에서 PendingUploadStore와 연결한다.
final class BackgroundUpload: NSObject, URLSessionTaskDelegate, URLSessionDataDelegate,
                              URLSessionDownloadDelegate {
  static let shared = BackgroundUpload()

  static let channel = "com.skysnap/background_upload"
  private static let sessionIdentifier = "com.codelabtiger.skysnap.background-upload"
  private static let storageKey = "skysnap_background_upload_records_v1"
  private static let tusVersion = "1.0.0"
  private static let tusChunkBytes: Int64 = 10 * 1024 * 1024
  private let stateQueue = DispatchQueue(label: "com.skysnap.background-upload-state")
  // multipart 본문 생성은 파일을 끝까지 한 번 복사한다. Flutter MethodChannel의 기본
  // 핸들러는 메인 스레드에서 실행되므로, 이 작업만큼은 반드시 별도 직렬 큐에서 한다.
  private let preparationQueue = DispatchQueue(
    label: "com.skysnap.background-upload-preparation",
    qos: .userInitiated
  )
  // background URLSession이 한 조각의 완료 이벤트를 모두 전달했다고 판단하기 전에
  // 다음 tus 조각 등록이 끝나야 한다. 그렇지 않으면 AppDelegate completion handler가
  // 먼저 호출되어 iOS가 프로세스를 다시 정지시키는 경합이 생길 수 있다.
  private let pendingTusContinuations = DispatchGroup()
  private var completionHandler: (() -> Void)?
  private var methodChannel: FlutterMethodChannel?

  private struct Record: Codable {
    var status: String
    var error: String?
    var bodyPath: String?
    var taskIdentifier: Int?
    // 이전 앱에서 쓴 레코드도 읽어야 하므로 optional로 둔다. nil은 다음 상태 조회에서
    // 즉시 실제 URLSession과 대조해야 하는 오래된 레코드라는 뜻이다.
    var updatedAt: TimeInterval?
    var sourcePath: String? = nil
    var uploadURL: String? = nil
    var uploadProtocol: String? = nil
    var uploadLength: Int64? = nil
    var tusOffset: Int64? = nil
    var tusRetryCount: Int? = nil
  }

  private lazy var session: URLSession = {
    let config = URLSessionConfiguration.background(withIdentifier: Self.sessionIdentifier)
    config.sessionSendsLaunchEvents = true
    config.isDiscretionary = false
    config.waitsForConnectivity = true
    config.allowsCellularAccess = true
    // 사진 한 묶음이 회선을 모두 점유하지 않도록 같은 Cloudflare 호스트에는 한 전송만
    // 활성화한다. 나머지는 URLSession이 OS 수준에서 대기시킨다.
    config.httpMaximumConnectionsPerHost = 1
    return URLSession(configuration: config, delegate: self, delegateQueue: nil)
  }()

  private override init() {
    super.init()
    // 세션을 즉시 만들어야 OS가 백그라운드 완료를 위해 재기동했을 때 delegate가 붙는다.
    _ = session
  }

  func accepts(identifier: String) -> Bool { identifier == Self.sessionIdentifier }

  func setBackgroundCompletionHandler(_ handler: @escaping () -> Void) {
    completionHandler = handler
  }

  func install(messenger: FlutterBinaryMessenger) {
    guard methodChannel == nil else { return }
    let channel = FlutterMethodChannel(name: Self.channel, binaryMessenger: messenger)
    channel.setMethodCallHandler { [weak self] call, result in
      self?.handle(call: call, result: result)
    }
    methodChannel = channel
  }

  private func handle(call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "enqueue":
      guard let args = call.arguments as? [String: Any],
            let uploads = args["uploads"] as? [[String: Any]] else {
        result(FlutterError(code: "bad_args", message: "uploads가 없습니다.", details: nil))
        return
      }
      preparationQueue.async { [weak self] in
        guard let self else {
          Self.finishOnMain(
            result,
            value: FlutterError(code: "enqueue_failed", message: "업로드 전송기를 준비하지 못했습니다.", details: nil)
          )
          return
        }
        do {
          try self.enqueueBatch(uploads)
          Self.finishOnMain(result, value: nil)
        } catch {
          Self.finishOnMain(
            result,
            value: FlutterError(code: "enqueue_failed", message: error.localizedDescription, details: nil)
          )
        }
      }
    case "states":
      guard let args = call.arguments as? [String: Any],
            let ids = args["ids"] as? [String] else {
        result([])
        return
      }
      // UserDefaults만 읽으면 사용자가 앱을 강제 종료해 OS task가 사라진 경우에도
      // queued 상태가 영원히 남는다. 실제 URLSession task와 대조한 뒤 반환한다.
      stateRows(ids: ids) { rows in
        Self.finishOnMain(result, value: rows)
      }
    case "forget":
      guard let args = call.arguments as? [String: Any],
            let ids = args["ids"] as? [String] else {
        result(nil)
        return
      }
      removeRecords(ids: ids)
      result(nil)
    case "excludeFromBackup":
      guard let args = call.arguments as? [String: Any],
            let path = args["path"] as? String, !path.isEmpty else {
        result(FlutterError(code: "bad_args", message: "백업 제외 경로가 없습니다.", details: nil))
        return
      }
      do {
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        var directory = URL(fileURLWithPath: path)
        try directory.setResourceValues(values)
        result(nil)
      } catch {
        result(FlutterError(code: "backup_exclusion_failed", message: error.localizedDescription, details: nil))
      }
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private static func finishOnMain(_ result: @escaping FlutterResult, value: Any?) {
    DispatchQueue.main.async {
      result(value)
    }
  }

  private struct Upload {
    let id: String
    let source: URL
    let uploadURL: URL
    let uploadProtocol: String
    let uploadLength: Int64
  }

  private struct PreparedBody {
    let upload: Upload
    let body: URL
    let boundary: String
  }

  /// multipart는 전체 body 파일을, tus는 첫 조각 파일을 모두 준비한 뒤 task를 시작한다.
  private func enqueueBatch(_ rawUploads: [[String: Any]]) throws {
    let uploads = try rawUploads.map(parseUpload)
    try ensureAvailableSpace(for: uploads)
    var prepared = [PreparedBody]()
    do {
      for upload in uploads where upload.uploadProtocol != "tus" {
        let body = try makeMultipartBody(id: upload.id, source: upload.source)
        guard let boundary = takeBoundary(for: body) else {
          throw NSError(domain: "BackgroundUpload", code: 3,
                        userInfo: [NSLocalizedDescriptionKey: "업로드 본문을 준비하지 못했습니다."])
        }
        prepared.append(PreparedBody(upload: upload, body: body, boundary: boundary))
      }
    } catch {
      prepared.forEach { try? FileManager.default.removeItem(at: $0.body) }
      throw error
    }

    // 이 아래는 메모리상 URLSession task 생성·상태 기록뿐이다. 모든 본문을 이미 준비해
    // 두었으므로 항목 일부만 전송을 시작하는 반쪽 등록이 발생하지 않는다.
    var tasks = [(Upload, URLSessionUploadTask, URL?)]()
    do {
      for upload in uploads where upload.uploadProtocol == "tus" {
        let (task, body) = try makeTusChunkTask(upload: upload, offset: 0)
        tasks.append((upload, task, body))
      }
      for item in prepared {
        var request = URLRequest(url: item.upload.uploadURL)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(item.boundary)", forHTTPHeaderField: "Content-Type")
        let attributes = try FileManager.default.attributesOfItem(atPath: item.body.path)
        let length = (attributes[.size] as? NSNumber)?.intValue ?? 0
        request.setValue(String(length), forHTTPHeaderField: "Content-Length")
        let task = session.uploadTask(with: request, fromFile: item.body)
        task.taskDescription = item.upload.id
        tasks.append((item.upload, task, item.body))
      }
    } catch {
      tasks.forEach { $0.1.cancel() }
      tasks.compactMap { $0.2 }.forEach { try? FileManager.default.removeItem(at: $0) }
      prepared.forEach { try? FileManager.default.removeItem(at: $0.body) }
      throw error
    }
    for (upload, task, body) in tasks {
      updateRecord(id: upload.id, record: Record(
        status: "queued", error: nil, bodyPath: body?.path,
        taskIdentifier: task.taskIdentifier, updatedAt: Date().timeIntervalSince1970,
        sourcePath: upload.source.path, uploadURL: upload.uploadURL.absoluteString,
        uploadProtocol: upload.uploadProtocol, uploadLength: upload.uploadLength,
        tusOffset: upload.uploadProtocol == "tus" ? 0 : nil, tusRetryCount: 0
      ))
    }
    tasks.forEach { $0.1.resume() }
  }

  private func parseUpload(_ raw: [String: Any]) throws -> Upload {
    guard let id = raw["id"] as? String, !id.isEmpty,
          let filePath = raw["filePath"] as? String, !filePath.isEmpty,
          let urlString = raw["uploadUrl"] as? String, let url = URL(string: urlString) else {
      throw NSError(domain: "BackgroundUpload", code: 1,
                    userInfo: [NSLocalizedDescriptionKey: "업로드 요청이 올바르지 않습니다."])
    }
    let source = URL(fileURLWithPath: filePath)
    guard FileManager.default.fileExists(atPath: source.path) else {
      throw NSError(domain: "BackgroundUpload", code: 2,
                    userInfo: [NSLocalizedDescriptionKey: "업로드 파일을 찾을 수 없습니다."])
    }
    let attributes = try FileManager.default.attributesOfItem(atPath: source.path)
    let actualLength = (attributes[.size] as? NSNumber)?.int64Value ?? 0
    let rawLength = (raw["uploadLength"] as? NSNumber)?.int64Value ?? actualLength
    guard actualLength > 0, rawLength == actualLength else {
      throw NSError(domain: "BackgroundUpload", code: 6,
                    userInfo: [NSLocalizedDescriptionKey: "업로드 파일 크기가 올바르지 않습니다."])
    }
    let uploadProtocol = (raw["protocol"] as? String)?.lowercased() == "tus"
      ? "tus" : "multipart"
    return Upload(id: id, source: source, uploadURL: url,
                  uploadProtocol: uploadProtocol, uploadLength: actualLength)
  }

  /// body path -> multipart boundary. URLSession task 생성 직전의 매우 짧은 구간에만 필요하다.
  private var bodyBoundaries: [String: String] = [:]
  private func takeBoundary(for body: URL) -> String? {
    stateQueue.sync { bodyBoundaries.removeValue(forKey: body.path) }
  }

  private func makeMultipartBody(id: String, source: URL) throws -> URL {
    let directory = try applicationSupportDirectory().appendingPathComponent("background_uploads", isDirectory: true)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    var body = directory.appendingPathComponent("\(id)-\(UUID().uuidString).multipart")
    let boundary = "skysnap-\(UUID().uuidString)"
    let safeName = source.lastPathComponent.replacingOccurrences(of: "\"", with: "")
    let header = "--\(boundary)\r\nContent-Disposition: form-data; name=\"file\"; filename=\"\(safeName)\"\r\nContent-Type: application/octet-stream\r\n\r\n"
    do {
      FileManager.default.createFile(atPath: body.path, contents: nil)
      var values = URLResourceValues()
      values.isExcludedFromBackup = true
      try body.setResourceValues(values)
      let output = try FileHandle(forWritingTo: body)
      defer { try? output.close() }
      try output.write(contentsOf: Data(header.utf8))

      let input = InputStream(url: source)!
      input.open()
      defer { input.close() }
      let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: 64 * 1024)
      defer { buffer.deallocate() }
      while true {
        let count = input.read(buffer, maxLength: 64 * 1024)
        if count < 0 { throw input.streamError ?? NSError(domain: "BackgroundUpload", code: 4) }
        if count == 0 { break }
        try output.write(contentsOf: Data(bytes: buffer, count: count))
      }
      try output.write(contentsOf: Data("\r\n--\(boundary)--\r\n".utf8))
      stateQueue.sync { bodyBoundaries[body.path] = boundary }
      return body
    } catch {
      try? FileManager.default.removeItem(at: body)
      throw error
    }
  }

  private func makeTusChunkTask(upload: Upload, offset: Int64)
    throws -> (URLSessionUploadTask, URL) {
    guard offset >= 0, offset < upload.uploadLength else {
      throw NSError(domain: "BackgroundUpload", code: 7,
                    userInfo: [NSLocalizedDescriptionKey: "영상 재개 위치가 올바르지 않습니다."])
    }
    let directory = try applicationSupportDirectory()
      .appendingPathComponent("background_uploads", isDirectory: true)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    var body = directory.appendingPathComponent(
      "\(upload.id)-\(offset)-\(UUID().uuidString).tus-chunk")
    let length = min(Self.tusChunkBytes, upload.uploadLength - offset)
    let input = try FileHandle(forReadingFrom: upload.source)
    defer { try? input.close() }
    try input.seek(toOffset: UInt64(offset))
    guard let data = try input.read(upToCount: Int(length)), data.count == Int(length) else {
      throw NSError(domain: "BackgroundUpload", code: 8,
                    userInfo: [NSLocalizedDescriptionKey: "영상 조각을 읽지 못했습니다."])
    }
    do {
      try data.write(to: body, options: .atomic)
      var values = URLResourceValues()
      values.isExcludedFromBackup = true
      try body.setResourceValues(values)
      var request = URLRequest(url: upload.uploadURL)
      request.httpMethod = "PATCH"
      request.setValue(Self.tusVersion, forHTTPHeaderField: "Tus-Resumable")
      request.setValue(String(offset), forHTTPHeaderField: "Upload-Offset")
      request.setValue("application/offset+octet-stream", forHTTPHeaderField: "Content-Type")
      request.setValue(String(length), forHTTPHeaderField: "Content-Length")
      let task = session.uploadTask(with: request, fromFile: body)
      task.taskDescription = upload.id
      return (task, body)
    } catch {
      try? FileManager.default.removeItem(at: body)
      throw error
    }
  }

  private func applicationSupportDirectory() throws -> URL {
    let base = try FileManager.default.url(for: .applicationSupportDirectory,
                                           in: .userDomainMask, appropriateFor: nil, create: true)
    var directory = base.appendingPathComponent("skysnap", isDirectory: true)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    var values = URLResourceValues()
    values.isExcludedFromBackup = true
    try directory.setResourceValues(values)
    return directory
  }

  /// URLSession background upload은 multipart body를 파일로 한 번 더 만들어야 한다.
  /// 준비 전에 남은 공간을 확인해 중간 파일만 남기고 실패하는 상황을 막는다.
  private func ensureAvailableSpace(for uploads: [Upload]) throws {
    let directory = try applicationSupportDirectory()
    let preparationBytes = try uploads.reduce(Int64(0)) { total, upload in
      let attributes = try FileManager.default.attributesOfItem(atPath: upload.source.path)
      let bytes = (attributes[.size] as? NSNumber)?.int64Value ?? 0
      return total + (upload.uploadProtocol == "tus" ? min(bytes, Self.tusChunkBytes) : bytes)
    }
    let values = try directory.resourceValues(forKeys: [
      .volumeAvailableCapacityForImportantUsageKey,
      .volumeAvailableCapacityKey,
    ])
    let available = values.volumeAvailableCapacityForImportantUsage ??
      values.volumeAvailableCapacity.map(Int64.init)
    // filesystem 메타데이터와 다음 앱 동작에 쓸 최소 여유 8 MiB를 남긴다.
    if let available, available < preparationBytes + 8 * 1024 * 1024 {
      throw NSError(
        domain: "BackgroundUpload",
        code: 5,
        userInfo: [NSLocalizedDescriptionKey: "업로드 준비 공간이 부족합니다."]
      )
    }
  }

  func urlSession(_ session: URLSession, task: URLSessionTask,
                  didSendBodyData bytesSent: Int64, totalBytesSent: Int64,
                  totalBytesExpectedToSend: Int64) {
    if let id = id(for: task) { updateStatus(id: id, status: "running", error: nil) }
  }

  func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
    guard let id = id(for: task) else { return }
    if task.taskDescription?.hasPrefix("tus-head:") == true {
      handleTusHead(id: id, task: task, error: error)
      return
    }
    if records()[id]?.uploadProtocol == "tus" {
      handleTusPatch(id: id, task: task, error: error)
      return
    }
    let code = (task.response as? HTTPURLResponse)?.statusCode ?? 0
    if error == nil && (200...299).contains(code) {
      updateStatus(id: id, status: "success", error: nil)
    } else {
      let description = error?.localizedDescription ?? "HTTP \(code)"
      updateStatus(id: id, status: "failed", error: description)
    }
  }

  func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask,
                  didFinishDownloadingTo location: URL) {
    // tus HEAD는 응답 body가 필요 없다. background download task로 만든 이유는
    // 앱 프로세스가 사라진 뒤에도 OS가 offset 확인을 수행하게 하기 위해서다.
    try? FileManager.default.removeItem(at: location)
  }

  private func handleTusPatch(id: String, task: URLSessionTask, error: Error?) {
    guard let record = records()[id] else { return }
    let bodyBytes: Int64 = record.bodyPath.flatMap {
      guard let attributes = try? FileManager.default.attributesOfItem(atPath: $0),
            let size = attributes[.size] as? NSNumber else { return nil }
      return size.int64Value
    } ?? 0
    if let body = record.bodyPath { try? FileManager.default.removeItem(atPath: body) }
    let code = (task.response as? HTTPURLResponse)?.statusCode ?? 0
    if error == nil && (200...299).contains(code) {
      let headerOffset = (task.response as? HTTPURLResponse)?
        .value(forHTTPHeaderField: "Upload-Offset").flatMap(Int64.init)
      let next = headerOffset ?? ((record.tusOffset ?? 0) + bodyBytes)
      let current = record.tusOffset ?? 0
      guard bodyBytes > 0, next > current, next <= (record.uploadLength ?? 0) else {
        scheduleTusHead(id: id, incrementRetry: true)
        return
      }
      continueTus(id: id, offset: next, resetRetry: true)
      return
    }
    if code == 0 || code == 408 || code == 409 || code == 425 || code == 429 ||
        code >= 500 || error != nil {
      scheduleTusHead(id: id, incrementRetry: true)
      return
    }
    updateStatus(id: id, status: "failed", error: "HTTP \(code)")
  }

  private func handleTusHead(id: String, task: URLSessionTask, error: Error?) {
    let code = (task.response as? HTTPURLResponse)?.statusCode ?? 0
    if error == nil && (200...299).contains(code),
       let rawOffset = (task.response as? HTTPURLResponse)?
         .value(forHTTPHeaderField: "Upload-Offset"),
       let offset = Int64(rawOffset) {
      let advanced = offset > (records()[id]?.tusOffset ?? 0)
      continueTus(id: id, offset: offset, resetRetry: advanced)
      return
    }
    if code == 0 || code == 408 || code == 409 || code == 425 || code == 429 ||
        code >= 500 || error != nil {
      scheduleTusHead(id: id, incrementRetry: true)
      return
    }
    updateStatus(id: id, status: "failed", error: "HTTP \(code)")
  }

  private func continueTus(id: String, offset: Int64, resetRetry: Bool) {
    pendingTusContinuations.enter()
    preparationQueue.async { [weak self] in
      defer { self?.pendingTusContinuations.leave() }
      guard let self, var record = self.records()[id],
            let sourcePath = record.sourcePath,
            let uploadURLText = record.uploadURL,
            let uploadURL = URL(string: uploadURLText),
            let total = record.uploadLength,
            offset >= 0, offset <= total else {
        self?.updateStatus(id: id, status: "failed", error: "tus_record_invalid")
        return
      }
      if offset == total {
        self.updateStatus(id: id, status: "success", error: nil)
        return
      }
      do {
        let upload = Upload(id: id, source: URL(fileURLWithPath: sourcePath),
                            uploadURL: uploadURL, uploadProtocol: "tus",
                            uploadLength: total)
        let (task, body) = try self.makeTusChunkTask(upload: upload, offset: offset)
        record.status = "queued"
        record.error = nil
        record.bodyPath = body.path
        record.taskIdentifier = task.taskIdentifier
        record.updatedAt = Date().timeIntervalSince1970
        record.tusOffset = offset
        if resetRetry { record.tusRetryCount = 0 }
        self.updateRecord(id: id, record: record)
        task.resume()
      } catch {
        self.updateStatus(id: id, status: "failed", error: error.localizedDescription)
      }
    }
  }

  private func scheduleTusHead(id: String, incrementRetry: Bool) {
    guard var record = records()[id], let uploadURLText = record.uploadURL,
          let uploadURL = URL(string: uploadURLText) else {
      updateStatus(id: id, status: "failed", error: "tus_record_invalid")
      return
    }
    if let body = record.bodyPath { try? FileManager.default.removeItem(atPath: body) }
    let retry = (record.tusRetryCount ?? 0) + (incrementRetry ? 1 : 0)
    if retry > 20 {
      updateStatus(id: id, status: "failed", error: "tus_retry_exhausted")
      return
    }
    var request = URLRequest(url: uploadURL)
    request.httpMethod = "HEAD"
    request.setValue(Self.tusVersion, forHTTPHeaderField: "Tus-Resumable")
    let task = session.downloadTask(with: request)
    task.taskDescription = "tus-head:\(id)"
    if retry > 0 {
      task.earliestBeginDate = Date().addingTimeInterval(min(300, pow(2, Double(retry))))
    }
    record.status = "queued"
    record.error = nil
    record.bodyPath = nil
    record.taskIdentifier = task.taskIdentifier
    record.updatedAt = Date().timeIntervalSince1970
    record.tusRetryCount = retry
    updateRecord(id: id, record: record)
    task.resume()
  }

  func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
    pendingTusContinuations.notify(queue: .main) { [weak self] in
      let handler = self?.completionHandler
      self?.completionHandler = nil
      handler?()
    }
  }

  /// 실제 URLSession task와 저장된 레코드를 대조한다. 사용자 강제 종료 뒤에는
  /// background URLSession 작업이 남지 않으므로, 오래된 queued/running 레코드를
  /// failed(task_missing)로 바꿔 Dart가 안전한 기존 업로더로 복구할 수 있게 한다.
  private func stateRows(ids: [String], completion: @escaping ([[String: String]]) -> Void) {
    session.getAllTasks { [weak self] tasks in
      guard let self else {
        completion(ids.map { ["id": $0, "status": "missing", "error": "" ] })
        return
      }
      let activeDescriptions = Set(tasks.compactMap { task -> String? in
        switch task.state {
        case .running, .suspended, .canceling:
          return self.idFromDescription(task.taskDescription)
        case .completed:
          return nil
        @unknown default:
          return self.idFromDescription(task.taskDescription)
        }
      }.filter { !$0.isEmpty })
      let activeTaskIdentifiers = Set(tasks.compactMap { task -> Int? in
        switch task.state {
        case .running, .suspended, .canceling:
          return task.taskIdentifier
        case .completed:
          return nil
        @unknown default:
          return task.taskIdentifier
        }
      })
      self.reconcileStoredStates(
        ids: ids,
        activeDescriptions: activeDescriptions,
        activeTaskIdentifiers: activeTaskIdentifiers
      )
      completion(self.storedStateRows(ids: ids))
    }
  }

  private func storedStateRows(ids: [String]) -> [[String: String]] {
    let current = records()
    return ids.map { id in
      let record = current[id]
      return ["id": id, "status": record?.status ?? "missing", "error": record?.error ?? ""]
    }
  }

  private func reconcileStoredStates(
    ids: [String],
    activeDescriptions: Set<String>,
    activeTaskIdentifiers: Set<Int>
  ) {
    let now = Date().timeIntervalSince1970
    let current = records()
    for id in ids {
      guard let record = current[id], record.status == "queued" || record.status == "running" else {
        continue
      }
      if activeDescriptions.contains(id) ||
          (record.taskIdentifier != nil && activeTaskIdentifiers.contains(record.taskIdentifier!)) {
        // URLSession이 실제로 관리하고 있다. queued가 오래 남아도 작업을 취소하지 않는다.
        continue
      }
      // task.resume() 직후 getAllTasks의 아주 짧은 반영 지연은 실패로 오인하지 않는다.
      // 반대로 이전 버전의 timestamp 없는 레코드는 검증할 방법이 없으므로 바로 복구한다.
      let age = now - (record.updatedAt ?? 0)
      if age >= 5 {
        if record.uploadProtocol == "tus" {
          scheduleTusHead(id: id, incrementRetry: false)
        } else {
          updateStatus(id: id, status: "failed", error: "task_missing")
        }
      }
    }
  }

  private func records() -> [String: Record] {
    stateQueue.sync {
      guard let data = UserDefaults.standard.data(forKey: Self.storageKey),
            let decoded = try? JSONDecoder().decode([String: Record].self, from: data) else { return [:] }
      return decoded
    }
  }

  private func updateStatus(id: String, status: String, error: String?) {
    let current = records()
    guard var record = current[id] else { return }
    let body = record.bodyPath
    if (status == "success" || status == "failed"), let body = body {
      try? FileManager.default.removeItem(atPath: body)
    }
    record.status = status
    record.error = error
    record.bodyPath = (status == "success" || status == "failed") ? nil : body
    record.updatedAt = Date().timeIntervalSince1970
    updateRecord(id: id, record: record)
  }

  /// iOS가 앱을 다시 띄워 delegate를 복구한 경우에도 taskDescription이 비어 있을 수
  /// 있으므로, 영속화한 URLSession task identifier로 한 번 더 찾는다.
  private func id(for task: URLSessionTask) -> String? {
    if let id = idFromDescription(task.taskDescription) { return id }
    return records().first { $0.value.taskIdentifier == task.taskIdentifier }?.key
  }

  private func idFromDescription(_ description: String?) -> String? {
    guard let description, !description.isEmpty else { return nil }
    return description.hasPrefix("tus-head:")
      ? String(description.dropFirst("tus-head:".count)) : description
  }

  private func updateRecord(id: String, record: Record) {
    stateQueue.sync {
      var current: [String: Record] = [:]
      if let data = UserDefaults.standard.data(forKey: Self.storageKey),
         let decoded = try? JSONDecoder().decode([String: Record].self, from: data) { current = decoded }
      current[id] = record
      if let encoded = try? JSONEncoder().encode(current) { UserDefaults.standard.set(encoded, forKey: Self.storageKey) }
    }
  }

  private func removeRecords(ids: [String]) {
    stateQueue.sync {
      guard let data = UserDefaults.standard.data(forKey: Self.storageKey),
            var current = try? JSONDecoder().decode([String: Record].self, from: data) else { return }
      ids.forEach { current.removeValue(forKey: $0) }
      if let encoded = try? JSONEncoder().encode(current) {
        UserDefaults.standard.set(encoded, forKey: Self.storageKey)
      }
    }
  }
}
