import 'dart:async';
import 'dart:io';
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
    try {
      await _checkPermissionAndInitializeCamera(emit); // checking and asking for camera permission and initializing camera
    } catch (e) {
      emit(CameraError(error: e == CameraErrorType.permission ? CameraErrorType.permission : CameraErrorType.other));
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
      if (_cameraController != null && _cameraController!.value.isInitialized) {
        // emit(CameraReady(isRecordingVideo: false));
      } else {
        emit(CameraError(error: CameraErrorType.other));
      }
    } catch (e) {
      emit(CameraError(error: CameraErrorType.other));
    }
  }

  // Handle CameraRecordingStart event
  void _onCameraRecordingStart(CameraRecordingStart event, Emitter<CameraState> emit) async {
    if (!isRecording()) {
      try {
        await _startRecording().then((onValue) {
          emit(CameraReady(isRecordingVideo: true));
        });
      } catch (e) {
        await _reInitialize(emit);
        // emit(CameraReady(isRecordingVideo: false));
      }
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
    if (!isInitialized() && _cameraController != null) {
      if (await permissionUtils.getCameraAndMicrophonePermissionStatus()) {
        await _initializeCamera(emit);
        // emit(CameraReady(isRecordingVideo: false));
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
    currentLensDirection = CameraLensDirection.front;
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

  // Stop video recording and return the recorded video file
  Future<File> _stopRecording() async {
    try {
      XFile video = await _cameraController!.stopVideoRecording();
      _stopTimerAndResetDuration();

      File videoFile = File(video.path);

      // 확장자 확인 및 수정
      videoFile = await ensureMP4Extension(videoFile);

      return File(videoFile.path);
      // return File(video.path);
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
      _cameraController = null;
      _cameraController = await cameraUtils.getCameraController(lensDirection: currentLensDirection);

      await _cameraController?.initialize().then((_) async {
        // isInitialized 가 바로 true 를 반환하지 않아 딜레이를 줍니다.
        Platform.isIOS ? await Future.delayed(const Duration(milliseconds: 150)) : null;
        if (_cameraController!.value.isInitialized) {
          if (Platform.isIOS) {
            //ios 에서만 필요한 코드
            await _cameraController?.prepareForVideoRecording();

            // 화면 깜빡임을 속이기 위해 딜레이를 주고 Ready로 상태변경
            await Future.delayed(const Duration(milliseconds: 150));
          }

          emit(CameraReady(isRecordingVideo: false, decativateRecordButton: false));
          _cameraController?.lockCaptureOrientation(DeviceOrientation.portraitUp);

          _cameraController!.addListener(() {
            if (_cameraController!.value.isRecordingVideo) {
              _startTimer();
            }
          });
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
    _stopTimerAndResetDuration();
    // _cameraController = await cameraUtils.getCameraController(
    //     lensDirection:
    //         currentLensDirection); // it's important to remove old camera controller instances otherwise _cameraController!.value will remain unchanged hence _cameraController!.value.isInitialized will always true
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
        print('Error renaming file: ${e.message}');
        // 이름 변경에 실패한 경우, 파일을 복사하는 방법을 시도
        try {
          final File copiedFile = await videoFile.copy(newPath);
          await videoFile.delete(); // 원본 파일 삭제
          return copiedFile;
        } catch (e) {
          print('Error copying file: $e');
          // 모든 시도가 실패하면 원본 파일 반환
          return videoFile;
        }
      }
    }

    return videoFile; // 이미 .mp4 확장자를 가진 경우 원본 반환
  }
}
