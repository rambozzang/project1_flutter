import Foundation
import Flutter
import UIKit
import BackgroundTasks
import Network

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

  // ── 전송 제한·재시도·이어서 처리 (모모앨범 2026-09-26·10-10 실측에서 옮김) ──
  //
  // 사진 전송은 한 번에 몇 장씩만 실제로 시작한다. HTTP/2·3은 연결 하나에 전송을 전부
  // 겹쳐 싣기 때문에 30장을 한꺼번에 시작하면 장마다 회선의 1/30만 받는다. 한 장이 끝나는
  // 데 수 분이 걸리고, 그 사이 연결이 통째로 끊겨(-1005) 처음부터 다시 했다.
  // 데이터 통신(LTE·5G)에서는 4장도 많았다 — 장마다 22~35초, Cloudflare 408로 끊겼다.
  // 그래서 데이터 통신이거나 한 장이라도 일시 실패가 나면 대기열이 빌 때까지 한 장씩 보낸다.
  // tus(영상)는 조각 단위로 따로 이어지므로 이 제한에 넣지 않는다.
  private static let maxActiveUploads = 4
  private static let constrainedActiveUploads = 1
  // 차례를 기다리는 동안 끊기지 않도록 무응답 한도를 넉넉히 준다(기본 60초에 -1001로 끊겼다).
  private static let requestIdleTimeout: TimeInterval = 900
  private static let livePrefix = "live:"
  private let limiterQueue = DispatchQueue(label: "com.skysnap.background-upload-limiter")
  private let pathMonitor = NWPathMonitor()
  // 아래는 모두 limiterQueue에서만 만진다.
  private var heldTasks: [URLSessionTask] = []
  private var activeKeys = Set<String>()
  private var trackedKeys = Set<String>()
  private var inBackground = false
  private var onExpensiveNetwork = false
  private var congested = false
  // iOS 26+ 이어서 처리(BGContinuedProcessingTask). 사진이 남은 채 앱을 벗어나면 신청한다.
  // 그 동안은 앱이 살아 있어 위 제한을 지키며 하나 끝날 때마다 다음을 보낼 수 있다.
  private var continuedTask: BGTask?
  private var continuedPending = false
  private var continuedRequestID: String?
  private var continuedFailed = false
  private var progressTotal: Int64 = 0
  private var progressDone: Int64 = 0
  private var partialProgress: [String: Double] = [:]
  private var lastProgressReport = Date.distantPast
  private var lastSubtitle = ""

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
    // 사진 한 장을 같은 URL로 다시 보낸 횟수(retryTransientMultipart).
    var retryCount: Int? = nil
    // 이어서 처리 중 앱 내 세션(liveSession)으로 보내는 중인가.
    var live: Bool? = nil
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
    config.timeoutIntervalForRequest = Self.requestIdleTimeout
    config.timeoutIntervalForResource = 24 * 60 * 60
    return URLSession(configuration: config, delegate: self, delegateQueue: nil)
  }()

  /// 이어서 처리 중(앱이 백그라운드지만 iOS가 살려 두는 동안)에만 쓰는 앱 내 세션.
  /// 백그라운드 세션은 앱이 백그라운드일 때 시작한 전송을 "나중에 해도 되는 일"로 미룬다
  /// (모모앨범 실측: 7분 넘게 안 나감). 앱 내 세션은 그 판단을 받지 않는다. 대신 앱이 멈추면
  /// 같이 끊기므로 이어서 처리가 끝날 때 백그라운드 세션으로 되돌린다.
  private lazy var liveSession: URLSession = {
    let config = URLSessionConfiguration.default
    config.timeoutIntervalForRequest = Self.requestIdleTimeout
    config.timeoutIntervalForResource = 24 * 60 * 60
    config.allowsCellularAccess = true
    return URLSession(configuration: config, delegate: self, delegateQueue: nil)
  }()

  private func key(_ task: URLSessionTask) -> String {
    (task.taskDescription?.hasPrefix(Self.livePrefix) == true ? "L" : "B") + String(task.taskIdentifier)
  }

  private override init() {
    super.init()
    // 세션을 즉시 만들어야 OS가 백그라운드 완료를 위해 재기동했을 때 delegate가 붙는다.
    _ = session
    pathMonitor.pathUpdateHandler = { [weak self] path in
      guard let self else { return }
      self.onExpensiveNetwork = path.isExpensive || path.usesInterfaceType(.cellular)
    }
    pathMonitor.start(queue: limiterQueue)
    // 화면을 벗어나기 직전(아직 화면에 있을 때)에만 이어서 처리를 신청할 수 있다.
    NotificationCenter.default.addObserver(
      forName: UIApplication.willResignActiveNotification, object: nil, queue: nil
    ) { [weak self] _ in
      // 사진 고르기·공유 창은 앱 밖이라 이 알림이 오지만 사용자는 앱 안에 있다.
      if Self.isPresentingSystemSheet() { return }
      self?.submitContinuedIfNeeded()
    }
    NotificationCenter.default.addObserver(
      forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: nil
    ) { [weak self] _ in
      self?.releaseHeldForBackground()
    }
    NotificationCenter.default.addObserver(
      forName: UIApplication.willEnterForegroundNotification, object: nil, queue: nil
    ) { [weak self] _ in
      self?.limiterQueue.async {
        self?.inBackground = false
        self?.pumpLocked()
      }
    }
    // 차례를 기다리던 작업은 앱이 죽으면 대기 목록과 함께 사라진다. OS에는 멈춘 작업으로
    // 남으므로 다시 붙잡아 차례대로 시작한다. 이미 돌던 작업은 자리 수에 넣는다.
    session.getAllTasks { [weak self] tasks in
      guard let self else { return }
      self.limiterQueue.async {
        for task in tasks where task.taskDescription?.hasPrefix("tus-head:") != true {
          guard self.records()[self.idFromDescription(task.taskDescription) ?? ""]?
            .uploadProtocol != "tus" else { continue }
          if task.state == .running {
            self.activeKeys.insert(self.key(task))
          } else if task.state == .suspended {
            self.heldTasks.append(task)
          }
        }
        self.pumpLocked()
      }
    }
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
        // URLRequest마다 기본 60초가 따로 박혀 있어 세션 설정과 같은 값을 넣는다.
        request.timeoutInterval = Self.requestIdleTimeout
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
    // 영상(tus)은 바로 시작하고, 사진은 대기열에 넣어 몇 장씩만 시작한다.
    tasks.filter { $0.0.uploadProtocol == "tus" }.forEach { $0.1.resume() }
    let photos: [URLSessionTask] = tasks.filter { $0.0.uploadProtocol != "tus" }.map { $0.1 }
    limiterQueue.async { self.scheduleLocked(photos) }
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
    if let id = id(for: task), records()[id]?.status != "running" {
      updateStatus(id: id, status: "running", error: nil)
    }
    guard totalBytesExpectedToSend > 0 else { return }
    let fraction = min(1, Double(totalBytesSent) / Double(totalBytesExpectedToSend))
    let taskKey = key(task)
    limiterQueue.async {
      guard self.trackedKeys.contains(taskKey) else { return }
      self.partialProgress[taskKey] = fraction
      // 이어서 처리는 진행 보고가 끊기면 iOS가 멈춘 것으로 보고 "작업 실패"로 끝낸다.
      if Date().timeIntervalSince(self.lastProgressReport) >= 1 {
        self.updateContinuedProgressLocked()
      }
    }
  }

  func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
    // 세션을 옮기며 취소한 옛 작업(앱 내 ↔ 백그라운드)의 콜백은 무시한다.
    if (error as NSError?)?.code == NSURLErrorCancelled, !isCurrentTask(task) {
      limiterQueue.async { self.recordFinishedLocked(key: self.key(task), succeeded: false, tracked: false) }
      return
    }
    guard let id = id(for: task) else { return }
    if task.taskDescription?.hasPrefix("tus-head:") == true {
      handleTusHead(id: id, task: task, error: error)
      return
    }
    if records()[id]?.uploadProtocol == "tus" {
      handleTusPatch(id: id, task: task, error: error)
      return
    }
    if retryTransientMultipart(id: id, task: task, error: error) { return }
    let code = (task.response as? HTTPURLResponse)?.statusCode ?? 0
    // 409: 같은 URL로 이미 도착한 사진을 다시 보낸 경우다(재시도 중 앞선 전송이 사실 성공).
    let succeeded = error == nil && ((200...299).contains(code) || code == 409)
    if succeeded {
      updateStatus(id: id, status: "success", error: nil)
    } else {
      let description = error?.localizedDescription ?? "HTTP \(code)"
      updateStatus(id: id, status: "failed", error: description)
    }
    taskFinished(task, succeeded: succeeded)
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
    liveSession.getAllTasks { [weak self] liveTasks in
      guard let self else {
        completion(ids.map { ["id": $0, "status": "missing", "error": "" ] })
        return
      }
      self.session.getAllTasks { [weak self] backgroundTasks in
      guard let self else {
        completion(ids.map { ["id": $0, "status": "missing", "error": "" ] })
        return
      }
      // 앱 내 세션으로 보내는 중인 사진도 살아 있는 작업이다(이어서 처리 중).
      let tasks = backgroundTasks + liveTasks
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
    if description.hasPrefix(Self.livePrefix) { return String(description.dropFirst(Self.livePrefix.count)) }
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
  // MARK: 전송 제한(한 번에 몇 장씩)

  /// 지금 한 번에 보낼 장수. limiterQueue 안에서만 부른다.
  private func activeLimitLocked() -> Int {
    (onExpensiveNetwork || congested) ? Self.constrainedActiveUploads : Self.maxActiveUploads
  }

  /// 사진 전송을 대기열에 넣고 자리가 나는 만큼만 시작한다. limiterQueue 안에서만.
  private func scheduleLocked(_ tasks: [URLSessionTask]) {
    guard !tasks.isEmpty else { return }
    heldTasks.append(contentsOf: tasks)
    tasks.forEach { trackedKeys.insert(key($0)) }
    progressTotal += Int64(tasks.count)
    updateContinuedProgressLocked()
    pumpLocked()
  }

  private func pumpLocked() {
    heldTasks.removeAll { $0.state == .completed || $0.state == .canceling }
    // 대기열이 비면 다음 업로드는 다시 여러 장씩 시작한다.
    if congested, heldTasks.isEmpty, activeKeys.isEmpty { congested = false }
    while activeKeys.count < activeLimitLocked(), !heldTasks.isEmpty {
      let task = heldTasks.removeFirst()
      // 이어서 처리로 살아 있는 백그라운드에서는 앱 내 세션으로 바꿔 보낸다(liveSession 참고).
      if inBackground, continuedTask != nil, let live = makeLiveTaskLocked(replacing: task) {
        partialProgress.removeValue(forKey: key(task))
        if trackedKeys.remove(key(task)) != nil { trackedKeys.insert(key(live)) }
        activeKeys.insert(key(live))
        live.resume()
        task.cancel()
        continue
      }
      activeKeys.insert(key(task))
      task.resume()
    }
    if inBackground && continuedTask == nil && !continuedPending {
      releaseHeldLocked()
    }
    finishContinuedIfIdleLocked()
  }

  /// 끝난 작업의 자리를 비우고 다음 작업을 시작한다.
  private func taskFinished(_ task: URLSessionTask, succeeded: Bool) {
    limiterQueue.async {
      self.recordFinishedLocked(key: self.key(task), succeeded: succeeded, tracked: true)
      self.pumpLocked()
    }
  }

  /// limiterQueue 안에서만. tracked=false면 자리만 비우고 집계하지 않는다(세션 이동으로 취소한 옛 작업).
  private func recordFinishedLocked(key: String, succeeded: Bool, tracked: Bool) {
    activeKeys.remove(key)
    partialProgress.removeValue(forKey: key)
    guard tracked, trackedKeys.remove(key) != nil else { return }
    if !succeeded { continuedFailed = true }
    progressDone += 1
    updateContinuedProgressLocked()
  }

  /// 이 작업이 레코드가 가리키는 현재 작업인가(세션을 옮기며 버린 옛 작업이 아닌가).
  private func isCurrentTask(_ task: URLSessionTask) -> Bool {
    guard let id = idFromDescription(task.taskDescription), let record = records()[id] else { return false }
    let isLive = task.taskDescription?.hasPrefix(Self.livePrefix) == true
    if (record.live == true) != isLive { return false }
    if !isLive, let current = record.taskIdentifier, current != task.taskIdentifier { return false }
    return true
  }

  /// 앱이 백그라운드로 가면 iOS가 곧 앱을 멈춘다. 이어서 처리가 없으면 "하나 끝나면 다음 시작"을
  /// 해 줄 사람이 없으므로 남은 작업을 전부 OS에 넘긴다(예전 방식). 무응답 한도를 길게 둬서
  /// 한꺼번에 겹쳐도 끊기지 않게 했다.
  private func releaseHeldForBackground() {
    var identifier = UIBackgroundTaskIdentifier.invalid
    identifier = UIApplication.shared.beginBackgroundTask(withName: "skysnap-upload-release") {
      UIApplication.shared.endBackgroundTask(identifier)
    }
    limiterQueue.sync {
      inBackground = true
      if continuedTask == nil && !continuedPending { releaseHeldLocked() }
    }
    if identifier != .invalid { UIApplication.shared.endBackgroundTask(identifier) }
  }

  /// limiterQueue 안에서만.
  private func releaseHeldLocked() {
    heldTasks.removeAll { $0.state == .completed || $0.state == .canceling }
    guard !heldTasks.isEmpty else { return }
    for task in heldTasks {
      activeKeys.insert(key(task))
      task.resume()
    }
    heldTasks.removeAll()
  }

  // MARK: 한 장 재시도

  /// 사진 한 장이 일시적으로 실패하면(408·429·5xx·연결 끊김·시간 초과) 그 한 장만 같은 URL로
  /// 다시 보낸다. 실패한 전송은 URL을 쓰지 않았으므로 같은 URL이 유효하다. 혹시 서버에 도착했었다면
  /// 409가 오고 그건 성공으로 본다. 3번까지만 하고 그 뒤엔 실패로 넘긴다.
  private func retryTransientMultipart(id: String, task: URLSessionTask, error: Error?) -> Bool {
    guard var record = records()[id], record.uploadProtocol != "tus" else { return false }
    let code = (task.response as? HTTPURLResponse)?.statusCode ?? 0
    let nsError = error as NSError?
    if nsError?.code == NSURLErrorCancelled { return false }
    let transient = nsError != nil || code == 408 || code == 429 || code >= 500
    let attempts = record.retryCount ?? 0
    guard transient, attempts < 3,
          let bodyPath = record.bodyPath, FileManager.default.fileExists(atPath: bodyPath),
          let request = task.originalRequest else { return false }
    // 새 작업은 백그라운드 세션에 만들어 대기열 맨 앞에 둔다. 이어서 처리 중이면 pumpLocked가
    // 앱 내 세션으로 바꿔 보낸다.
    let retry = session.uploadTask(with: request, fromFile: URL(fileURLWithPath: bodyPath))
    retry.taskDescription = id
    record.live = false
    record.taskIdentifier = retry.taskIdentifier
    record.status = "queued"
    record.retryCount = attempts + 1
    record.updatedAt = Date().timeIntervalSince1970
    updateRecord(id: id, record: record)
    NSLog("[BackgroundUpload] 한 장 재시도 %d회차 (%@)", attempts + 1,
          nsError?.localizedDescription ?? "HTTP \(code)")
    limiterQueue.async {
      // 회선이 버거운 신호다. 남은 사진은 한 장씩 보낸다.
      self.congested = true
      self.activeKeys.remove(self.key(task))
      self.partialProgress.removeValue(forKey: self.key(task))
      if self.trackedKeys.remove(self.key(task)) != nil { self.trackedKeys.insert(self.key(retry)) }
      self.heldTasks.insert(retry, at: 0)
      self.pumpLocked()
    }
    return true
  }

  // MARK: 앱 내 세션 ↔ 백그라운드 세션

  /// 아직 시작 안 한 백그라운드 작업과 같은 요청·본문으로 앱 내 세션 작업을 만든다. limiterQueue 안에서만.
  private func makeLiveTaskLocked(replacing task: URLSessionTask) -> URLSessionTask? {
    guard let id = idFromDescription(task.taskDescription),
          var record = records()[id], record.uploadProtocol != "tus",
          let bodyPath = record.bodyPath, FileManager.default.fileExists(atPath: bodyPath),
          let request = task.originalRequest else { return nil }
    let live = liveSession.uploadTask(with: request, fromFile: URL(fileURLWithPath: bodyPath))
    live.taskDescription = Self.livePrefix + id
    record.live = true
    record.updatedAt = Date().timeIntervalSince1970
    updateRecord(id: id, record: record)
    return live
  }

  /// 앱 내 세션으로 보내던 것을 백그라운드 세션으로 되돌린다(앱이 멈추면 같이 끊기므로).
  /// 처음부터 다시 보내게 되지만 잃지는 않는다. limiterQueue 안에서 부르고, 완료도 limiterQueue에서 온다.
  private func handLiveTasksBackToSystem(completion: @escaping () -> Void) {
    liveSession.getAllTasks { [weak self] tasks in
      guard let self else { completion(); return }
      self.limiterQueue.async {
        for live in tasks where live.state == .running || live.state == .suspended {
          guard let id = self.idFromDescription(live.taskDescription),
                var record = self.records()[id],
                let bodyPath = record.bodyPath, FileManager.default.fileExists(atPath: bodyPath),
                let request = live.originalRequest else { continue }
          let background = self.session.uploadTask(with: request, fromFile: URL(fileURLWithPath: bodyPath))
          background.taskDescription = id
          record.live = false
          record.taskIdentifier = background.taskIdentifier
          record.updatedAt = Date().timeIntervalSince1970
          self.updateRecord(id: id, record: record)
          self.activeKeys.remove(self.key(live))
          self.partialProgress.removeValue(forKey: self.key(live))
          if self.trackedKeys.remove(self.key(live)) != nil { self.trackedKeys.insert(self.key(background)) }
          self.activeKeys.insert(self.key(background))
          background.resume()
          live.cancel()
        }
        completion()
      }
    }
  }

  // MARK: 이어서 처리(iOS 26+)

  /// 앱 위에 앱 밖 시스템 화면(사진 고르기·파일 고르기·공유)이 떠 있는가. 메인 스레드에서만.
  private static func isPresentingSystemSheet() -> Bool {
    let windows = UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap { $0.windows }
    for window in windows {
      var top = window.rootViewController
      while let presented = top?.presentedViewController { top = presented }
      guard let top else { continue }
      let name = String(describing: type(of: top))
      if top is UIImagePickerController || top is UIDocumentPickerViewController
        || top is UIActivityViewController || name.contains("PHPicker") {
        return true
      }
    }
    return false
  }

  /// 앱이 화면을 벗어나기 직전(willResignActive, 메인 스레드). 보낼 사진이 남았을 때만 신청한다.
  /// 홈으로 나간 뒤(didEnterBackground)에는 신청 자체가 안 된다.
  private func submitContinuedIfNeeded() {
    guard #available(iOS 26.0, *) else { return }
    let bundle = Bundle.main.bundleIdentifier ?? "com.codelabtiger.skysnap"
    let identifier = "\(bundle).upload.\(UUID().uuidString.prefix(8))"
    let shouldSubmit: Bool = limiterQueue.sync {
      guard continuedTask == nil, !continuedPending else { return false }
      heldTasks.removeAll { $0.state == .completed || $0.state == .canceling }
      guard !heldTasks.isEmpty || !trackedKeys.isEmpty else { return false }
      continuedPending = true
      continuedRequestID = identifier
      continuedFailed = false
      return true
    }
    guard shouldSubmit else { return }
    // 신청과 시작 사이에 앱이 멈추면 시작 콜백을 못 받는다. 시작하거나 포기할 때까지 시간을 빌린다.
    var holdId = UIBackgroundTaskIdentifier.invalid
    holdId = UIApplication.shared.beginBackgroundTask(withName: "skysnap-upload-continued") {
      UIApplication.shared.endBackgroundTask(holdId)
      holdId = .invalid
    }
    let releaseHold = {
      DispatchQueue.main.async {
        if holdId != .invalid {
          UIApplication.shared.endBackgroundTask(holdId)
          holdId = .invalid
        }
      }
    }
    let registered = BGTaskScheduler.shared.register(forTaskWithIdentifier: identifier, using: nil) {
      [weak self] task in
      self?.continuedTaskStarted(task, requestID: identifier)
      releaseHold()
    }
    let texts = Self.continuedTexts()
    let subtitle: String = limiterQueue.sync {
      progressTotal == 0 ? texts.preparing : String(format: texts.progress, progressDone, progressTotal)
    }
    let request = BGContinuedProcessingTaskRequest(identifier: identifier, title: texts.title, subtitle: subtitle)
    // 지금 바로 못 돌면 실패시킨다. 나중에 돌아 봐야 이미 늦다.
    request.strategy = .fail
    do {
      guard registered else { throw NSError(domain: "BackgroundUpload", code: 20) }
      try BGTaskScheduler.shared.submit(request)
      NSLog("[BackgroundUpload] 앱을 벗어나며 이어서 처리 신청: %@", identifier)
      // 신청은 받아 줬는데 시작되지 않으면 대기 사진이 묶인다. 잠시 뒤에도 시작 전이면 포기한다.
      limiterQueue.asyncAfter(deadline: .now() + 5) {
        defer { releaseHold() }
        guard self.continuedRequestID == identifier, self.continuedPending, self.continuedTask == nil else { return }
        NSLog("[BackgroundUpload] 이어서 처리가 시작되지 않아 포기")
        self.continuedPending = false
        self.continuedRequestID = nil
        if self.inBackground { self.releaseHeldLocked() }
      }
    } catch {
      NSLog("[BackgroundUpload] 이어서 처리 신청 실패: %@", error.localizedDescription)
      limiterQueue.async {
        self.continuedPending = false
        self.continuedRequestID = nil
        if self.inBackground { self.releaseHeldLocked() }
      }
      releaseHold()
    }
  }

  private func continuedTaskStarted(_ task: BGTask, requestID: String) {
    guard #available(iOS 26.0, *), let continued = task as? BGContinuedProcessingTask else {
      task.setTaskCompleted(success: false)
      return
    }
    limiterQueue.sync {
      guard self.continuedRequestID == requestID, self.continuedPending else {
        continued.setTaskCompleted(success: false)
        return
      }
      self.continuedPending = false
      self.continuedTask = continued
      // ⚠️ 만료 콜백은 시간 만료·진행 멈춤("작업 실패")·사용자가 진행 창에서 취소를 누른 경우
      // 모두에서 온다. 구별할 수 없으므로 업로드를 취소하지 않고 백그라운드 세션으로 넘겨 계속
      // 보낸다(모모앨범 2026-10-10: 취소로 봤더니 데이터 통신에서 사진이 통째로 사라졌다).
      continued.expirationHandler = { [weak self] in
        guard let self else { return }
        self.limiterQueue.async {
          guard self.continuedTask === continued else { return }
          NSLog("[BackgroundUpload] 이어서 처리 만료 — 취소하지 않고 백그라운드 세션으로 넘김")
          self.resetContinuedLocked()
          self.handLiveTasksBackToSystem {
            if self.inBackground { self.releaseHeldLocked() }
            continued.setTaskCompleted(success: false)
          }
        }
      }
      self.updateContinuedProgressLocked()
      // 이미 백그라운드다. 대기 사진을 앱 내 세션으로 이어 보낸다.
      self.pumpLocked()
    }
  }

  /// limiterQueue 안에서만.
  private func resetContinuedLocked() {
    continuedTask = nil
    continuedPending = false
    continuedRequestID = nil
    continuedFailed = false
    progressTotal = 0
    progressDone = 0
    partialProgress.removeAll()
    lastSubtitle = ""
  }

  /// limiterQueue 안에서만.
  private func updateContinuedProgressLocked() {
    guard #available(iOS 26.0, *), let task = continuedTask as? BGContinuedProcessingTask else { return }
    lastProgressReport = Date()
    // 사진 한 장 = 1000단위. 전송 중인 사진은 보낸 비율만큼 채운다.
    let total = max(progressTotal, 1) * 1000
    let partial = partialProgress.values.reduce(0, +)
    let completed = progressDone * 1000 + Int64(partial * 1000)
    task.progress.totalUnitCount = total
    task.progress.completedUnitCount = min(completed, total)
    let texts = Self.continuedTexts()
    let subtitle = progressTotal == 0
      ? texts.preparing : String(format: texts.progress, progressDone, progressTotal)
    if subtitle != lastSubtitle {
      lastSubtitle = subtitle
      task.updateTitle(texts.title, subtitle: subtitle)
    }
  }

  /// 대기·전송 중인 사진이 하나도 없으면 빌린 시간을 돌려준다. limiterQueue 안에서만.
  private func finishContinuedIfIdleLocked() {
    guard heldTasks.isEmpty, activeKeys.isEmpty else { return }
    let done = progressDone, total = progressTotal, failed = continuedFailed
    // 이어서 처리 없이 끝난 묶음의 개수도 비운다. 안 비우면 다음 진행 막대가 지난 몫을 안고 시작한다.
    progressTotal = 0
    progressDone = 0
    partialProgress.removeAll()
    trackedKeys.removeAll()
    lastSubtitle = ""
    continuedFailed = false
    guard !continuedPending, let task = continuedTask else { return }
    continuedTask = nil
    continuedRequestID = nil
    if #available(iOS 26.0, *), let continued = task as? BGContinuedProcessingTask {
      let units = max(total, 1) * 1000
      continued.progress.totalUnitCount = units
      continued.progress.completedUnitCount = failed ? min(done * 1000, units) : units
      let texts = Self.continuedDoneTexts(failed: failed)
      continued.updateTitle(texts.title, subtitle: texts.subtitle)
    }
    limiterQueue.asyncAfter(deadline: .now() + 0.6) {
      task.setTaskCompleted(success: !failed)
    }
  }

  private static func continuedTexts() -> (title: String, preparing: String, progress: String) {
    let language = Locale.preferredLanguages.first ?? "en"
    if language.hasPrefix("ko") { return ("사진 올리는 중", "준비하고 있어요", "%lld / %lld장") }
    if language.hasPrefix("ja") { return ("写真をアップロード中", "準備しています", "%lld / %lld枚") }
    return ("Uploading photos", "Preparing", "%lld of %lld")
  }

  private static func continuedDoneTexts(failed: Bool) -> (title: String, subtitle: String) {
    let language = Locale.preferredLanguages.first ?? "en"
    if language.hasPrefix("ko") {
      return failed ? ("일부 사진을 보내지 못했어요", "앱에서 다시 시도해 주세요") : ("사진을 보냈어요", "곧 올라가요")
    }
    if language.hasPrefix("ja") {
      return failed ? ("一部の写真を送信できませんでした", "アプリで再試行してください") : ("写真を送信しました", "まもなく公開されます")
    }
    return failed ? ("Some photos weren't sent", "Try again in the app") : ("Photos sent", "Posting shortly")
  }
}
