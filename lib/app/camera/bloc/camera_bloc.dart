import 'dart:async';
import 'dart:io';
// import 'package:camera/camera.dart'; // 임시 주석 처리
import 'package:camera/camera.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:project1/app/camera/bloc/camera_state.dart';
import 'package:project1/app/camera/utils/camera_utils.dart';
import 'package:project1/app/camera/utils/permission_utils.dart';
import 'package:project1/utils/log_utils.dart';
import 'package:path/path.dart' as path;
part 'camera_event.dart';

// A BLoC class that handles camera-related operations
class CameraBloc extends Bloc<CameraEvent, CameraState> {
  //....... Dependencies ..............
  final CameraUtils cameraUtils;
  final PermissionUtils permissionUtils;
  // final CurrentWeather? currentWeather;
  final int limitSec = 2;

  //....... Internal variables ........
  int recordDurationLimit = 15;
  CameraController? _cameraController;
  bool _initializing = false; // 중복 초기화(컨트롤러 2개 생성) 방지 가드
  CameraLensDirection currentLensDirection = CameraLensDirection.back;
  Timer? recordingTimer;
  ValueNotifier<int> recordingDuration = ValueNotifier(0);

  //....... Getters ..........
  CameraController? getController() => _cameraController;
  bool isInitialized() => _cameraController?.value.isInitialized ?? false;
  bool isRecording() => _cameraController?.value.isRecordingVideo ?? false;

  //setters
  set setRecordDurationLimit(int val) {
    recordDurationLimit = val;
  }

  //....... Constructor ........
  CameraBloc({required this.cameraUtils, required this.permissionUtils}) : super(CameraInitial()) {
    on<CameraReset>(_onCameraReset);
    on<CameraInitialize>(_onCameraInitialize);
    on<CameraSwitch>(_onCameraSwitch);
    on<CameraRecordingStart>(_onCameraRecordingStart);
    on<CameraRecordingStop>(_onCameraRecordingStop);
    on<CameraEnable>(_onCameraEnable);
    on<CameraDisable>(_onCameraDisable);
    on<CameraDispose>(_onCameraDispose);
  }

  // ...................... event handler ..........................

  // 카메라 페이지가 dispose될 때 호출되는 이벤트 핸들러
  void _onCameraDispose(CameraDispose event, Emitter<CameraState> emit) async {
    if (isRecording()) {
      await _stopRecording();
    }
    await _disposeCamera();
    _resetCameraBloc();
    emit(CameraDisposed());
  }

  // Handle CameraReset event
  void _onCameraReset(CameraReset event, Emitter<CameraState> emit) async {
    await _disposeCamera(); // Dispose of the camera before resetting
    _resetCameraBloc(); // Reset the camera BLoC state
    emit(CameraInitial()); // Emit the initial state
  }

  // Handle CameraInitialize event
  void _onCameraInitialize(CameraInitialize event, Emitter<CameraState> emit) async {
    recordDurationLimit = event.recordingLimit;

    // 중복 초기화 방지:
    // root_page에서 미리 1번(선행 초기화) + camera_page initState에서 1번 → CameraInitialize가
    // 같은 bloc에 2번 들어온다. 가드 없이 동시에 _initializeCamera가 돌면 컨트롤러가 2개 생성돼
    // CameraX 세션이 충돌(Long monitor contention)하고 프리뷰가 검은화면으로 멈춘다.
    if (_initializing) return; // 진행 중이면 무시 → 첫 초기화의 CameraReady가 UI를 갱신한다.
    if (isInitialized()) {
      // 이미 초기화 완료 → 프리뷰가 확실히 그려지도록 현재 상태만 다시 방출.
      emit(CameraReady(isRecordingVideo: isRecording(), decativateRecordButton: false));
      return;
    }

    _initializing = true;
    try {
      await _checkPermissionAndInitializeCamera(emit); // checking and asking for camera permission and initializing camera
    } catch (e) {
      emit(CameraError(error: e == CameraErrorType.permission ? CameraErrorType.permission : CameraErrorType.other));
    } finally {
      _initializing = false;
    }
  }

  // Handle CameraSwitch event
  void _onCameraSwitch(CameraSwitch event, Emitter<CameraState> emit) async {
    // emit(CameraInitial());
    // await _switchCamera();
    // emit(CameraReady(isRecordingVideo: false));
    emit(CameraInitial());
    try {
      await _switchCamera(emit);
      // if (_cameraController != null && _cameraController!.value.isInitialized) {
      //   // emit(CameraReady(isRecordingVideo: false));
      // } else {
      //   emit(CameraError(error: CameraErrorType.other));
      // }
    } catch (e) {
      emit(CameraError(error: CameraErrorType.other));
    }
  }

  // Handle CameraRecordingStart event
  void _onCameraRecordingStart(CameraRecordingStart event, Emitter<CameraState> emit) async {
    if (!isRecording()) {
      // 낙관적 UI: 실제 startVideoRecording 완료를 기다리지 않고
      // 즉시 녹화 상태로 전환 → 버튼이 누르는 즉시 반응(빨간 링/사각형).
      // 실제 녹화 시작은 백그라운드로 처리되어 UI block을 최소화한다.
      emit(CameraReady(isRecordingVideo: true));
      // startVideoRecording은 Android Camera2에서 치메라 세션 재구성에
      // ~1초가 걸릴 수 있고, platform channel은 메인 스레드에서 실행되므로
      // await하면 UI가 멈춰 보인다. unawaited로 실행하고 결과는 콜백으로 처리.
      _startRecording().then((_) {
        lo.g('startVideoRecording success');
      }).catchError((e) {
        lo.g('startVideoRecording error: $e');
        // 실패 시 치메라 재초기화를 별도 이벤트로 발행 (BLoC emit 규칙 준수)
        add(CameraInitialize(recordingLimit: recordDurationLimit));
      });
    }
  }

  // Handle CameraRecordingStop event
  void _onCameraRecordingStop(CameraRecordingStop event, Emitter<CameraState> emit) async {
    if (isRecording()) {
      // Check if the recorded video duration is less than 3 seconds to prevent
      // potential issues with very short videos resulting in corrupt files.
      bool hasRecordingLimitError = recordingDuration.value < limitSec ? true : false;
      emit(CameraReady(isRecordingVideo: false, hasRecordingError: hasRecordingLimitError, decativateRecordButton: true));
      File? videoFile;
      try {
        videoFile = await _stopRecording(); // Stop video recording and get the recorded video file
        if (hasRecordingLimitError) {
          await Future.delayed(const Duration(milliseconds: 1500),
              () {}); // To prevent rapid consecutive clicks, we introduce a debounce delay of 2 seconds,
          // 다음 촬영도 즉시 시작되도록 레코더를 재준비
          try {
            await _cameraController?.prepareForVideoRecording();
          } catch (_) {}
          emit(CameraReady(isRecordingVideo: false, hasRecordingError: false, decativateRecordButton: false));
        } else {
          emit(CameraRecordingSuccess(file: videoFile));
        }
      } catch (e) {
        await _reInitialize(emit); // On Camera Exception, initialize the camera again
        // emit(CameraReady(isRecordingVideo: false));
      }
    }
  }

  // Handle CameraEnable event on app resume
  void _onCameraEnable(CameraEnable event, Emitter<CameraState> emit) async {
    if (!isInitialized()) {
      if (await permissionUtils.getCameraAndMicrophonePermissionStatus()) {
        await _initializeCamera(emit);
      } else {
        emit(CameraError(error: CameraErrorType.permission));
      }
    }
  }

  // Handle CameraDisable event when camera is not in use
  void _onCameraDisable(CameraDisable event, Emitter<CameraState> emit) async {
    if (isInitialized() && isRecording()) {
      // if app minimize while recording then save the the video then disable the camera
      add(CameraRecordingStop());
      await Future.delayed(const Duration(seconds: 2));
    }
    await _disposeCamera();
    emit(CameraInitial());
  }

  // ................... Other methods ......................

  // Reset the camera BLoC to its initial state
  void _resetCameraBloc() {
    _cameraController = null;
    currentLensDirection = CameraLensDirection.back;
    _stopTimerAndResetDuration();
  }

  // Start the recording timer
  void _startTimer() async {
    lo.g("################################ startTimer");
    recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      recordingDuration.value++;
      if (recordingDuration.value == recordDurationLimit) {
        add(CameraRecordingStop());
      }
    });
  }

  // Stop the recording timer and reset the duration
  void _stopTimerAndResetDuration() async {
    recordingTimer?.cancel();
    recordingDuration.value = 0;
  }

  // Start video recording
  Future<void> _startRecording() async {
    try {
      await _cameraController!.startVideoRecording();
    } catch (e) {
      return Future.error(e);
    }
  }

  // 사진 촬영(사진 모드 전용). 녹화 중이 아닐 때만 동작하며, 촬영한 파일(XFile)을 반환.
  Future<XFile?> takePhoto() async {
    final c = _cameraController;
    if (c == null || !c.value.isInitialized || c.value.isRecordingVideo) return null;
    try {
      return await c.takePicture();
    } catch (e) {
      lo.g('takePhoto error: $e');
      return null;
    }
  }

  // Stop video recording and return the recorded video file
  Future<File> _stopRecording() async {
    try {
      XFile video = await _cameraController!.stopVideoRecording();
      _stopTimerAndResetDuration();

      File videoFile = File(video.path);

      // 확장자 확인 및 수정
      videoFile = await ensureMP4Extension(videoFile);

      return File(videoFile.path);
    } catch (e) {
      return Future.error(e);
    }
  }

  // Check and ask for camera permission and initialize camera
  Future<void> _checkPermissionAndInitializeCamera(Emitter<CameraState> emit) async {
    if (await permissionUtils.getCameraAndMicrophonePermissionStatus()) {
      await _initializeCamera(emit);
    } else {
      if (await permissionUtils.askForPermission()) {
        // 릴레이를 쭤야 함 안그럼 빨간딱지 나옴 - 여긴 최초한번만 실행되니까
        sleep(const Duration(milliseconds: 500));
        await _initializeCamera(emit);
      } else {
        return Future.error(CameraErrorType.permission); // Throw the specific error type for permission denial
      }
    }
  }

  // Initialize the camera controller
  Future<void> _initializeCamera(Emitter<CameraState> emit) async {
    try {
      // 기존 컨트롤러가 남아있으면 먼저 정리(중복 세션/누수 방지).
      if (_cameraController != null) {
        await _disposeCamera();
      }
      _cameraController = await cameraUtils.getCameraController(lensDirection: currentLensDirection);
      await _cameraController!.initialize();

      // 1) 프리뷰를 "즉시" 표시 → 화면 로드 체감 속도 향상.
      //    (기존엔 prepare/딜레이가 Ready 방출을 막아 로드가 느렸음)
      emit(CameraReady(isRecordingVideo: false, decativateRecordButton: false));
      _cameraController?.lockCaptureOrientation(DeviceOrientation.portraitUp);

      // 2) prepareForVideoRecording은 iOS에서만 효과가 있다.
      //    Android(Camera2)에서는 no-op 수준이므로 skip하여 초기화 시간을 줄인다.
      if (Platform.isIOS) {
        _cameraController?.prepareForVideoRecording().catchError((e) {
          lo.g('prepareForVideoRecording skip: $e');
        });
      }

      _cameraController!.addListener(() {
        if (_cameraController!.value.isRecordingVideo) {
          _startTimer();
        }
      });
    } on CameraException catch (error) {
      Future.error(error);
    } catch (e) {
      Future.error(e);
    }
  }

  // Switch between front and back cameras
  Future<void> _switchCamera(Emitter<CameraState> emit) async {
    currentLensDirection = currentLensDirection == CameraLensDirection.back ? CameraLensDirection.front : CameraLensDirection.back;
    await _reInitialize(emit);
  }

  // Reinitialize the camera
  Future<void> _reInitialize(Emitter<CameraState> emit) async {
    await _disposeCamera();
    await _initializeCamera(emit);
  }

  // Dispose of the camera controller
  Future<void> _disposeCamera() async {
    _cameraController?.removeListener(() {});
    await _cameraController?.dispose();
    _cameraController = null;
    _stopTimerAndResetDuration();
  }

  Future<File> ensureMP4Extension(File videoFile) async {
    if (!videoFile.existsSync()) {
      throw FileSystemException('Video file does not exist', videoFile.path);
    }

    if (!videoFile.path.toLowerCase().endsWith('.mp4')) {
      final String directory = path.dirname(videoFile.path);
      final String fileName = path.basenameWithoutExtension(videoFile.path);
      final String newPath = path.join(directory, '$fileName.mp4');

      try {
        // 파일 이름 변경
        final File renamedFile = await videoFile.rename(newPath);

        // 변경된 파일이 실제로 존재하는지 확인
        if (!renamedFile.existsSync()) {
          throw FileSystemException('Failed to rename the file', newPath);
        }

        return renamedFile;
      } on FileSystemException catch (e) {
        lo.g('Error renaming file: ${e.message}');
        // 이름 변경에 실패한 경우, 파일을 복사하는 방법을 시도
        try {
          final File copiedFile = await videoFile.copy(newPath);
          await videoFile.delete(); // 원본 파일 삭제
          return copiedFile;
        } catch (e) {
          lo.g('Error copying file: $e');
          // 모든 시도가 실패하면 원본 파일 반환
          return videoFile;
        }
      }
    }

    return videoFile; // 이미 .mp4 확장자를 가진 경우 원본 반환
  }
}
