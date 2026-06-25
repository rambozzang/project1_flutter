import 'dart:io';

// import 'package:camera/camera.dart'; // 임시 주석 처리

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:project1/app/camera/bloc/camera_bloc.dart';
import 'package:project1/app/camera/bloc/camera_state.dart';
import 'package:project1/app/camera/page/photo_reg_page.dart';
import 'package:project1/app/camera/page/video_reg_page.dart';
import 'package:project1/app/camera/page/widgets/animated_bar.dart';
import 'package:project1/app/camera/page/widgets/camera_preview_widget.dart';
import 'package:project1/utils/log_utils.dart';
import 'package:project1/utils/utils.dart';
import 'package:visibility_detector/visibility_detector.dart';

// https://github.com/rajaniket/camera_bloc
//  https://bettercoding.dev/flutter/tutorial-video-recording-and-replay/

// 카메라 기능 추가
//https://github.com/Lightsnap/flutter_better_camera/blob/master/example/lib/main.dart#L92

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> with WidgetsBindingObserver {
  late CameraBloc cameraBloc;
  final GlobalKey screenshotKey = GlobalKey();
  Uint8List? screenshotBytes;
  bool isThisPageVisibe = true;
  bool _photoMode = false; // 사진 모드 토글(false=영상 녹화)
  final List<File> _photos = []; // 사진 모드에서 촬영/선택한 사진들(순서 = 게시 순서)

  @override
  void initState() {
    super.initState();
    cameraBloc = BlocProvider.of<CameraBloc>(context);
    // 페이지 진입 즉시 칩떄 초기화 시작 (VisibilityDetector 의존 최소화)
    cameraBloc.add(CameraInitialize(recordingLimit: cameraBloc.recordDurationLimit));
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
  }

  void _cameraBlocListener(BuildContext context, CameraState state) {
    if (state is CameraRecordingSuccess) {
      Navigator.of(
        context,
      ).pushReplacement(
        MaterialPageRoute(
          builder: (_) => VideoRegPage(videoFile: state.file),
        ),
      );
    } else if (state is CameraReady && state.hasRecordingError) {
      Utils.alert("${cameraBloc.limitSec}초 이상 촬영해주세요!");
    }
  }

  void _handleVisibilityChanged(VisibilityInfo info) {
    if (info.visibleFraction == 0.0) {
      // Camera page is not visible, disable the camera.
      if (mounted) {
        cameraBloc.add(CameraDisable());
        isThisPageVisibe = false;
      }
    } else {
      // Camera page is visible, enable the camera.
      isThisPageVisibe = true;
      cameraBloc.add(CameraEnable());
    }
  }

  void startRecording() async {
    cameraBloc.add(CameraRecordingStart());
  }

  void stopRecording() async {
    if (cameraBloc.recordingDuration.value < cameraBloc.limitSec) {
      Utils.alert("${cameraBloc.limitSec}초 이상 촬영해주세요!");
      return;
    }

    // try {
    //   screenshotBytes = await takeCameraScreenshot(key: screenshotKey);
    // } catch (e) {
    //   // 스크린샷 에러 처리
    // }

    cameraBloc.add(CameraRecordingStop());
  }

  Future getImage(BuildContext context, ImageSource imageSource) async {
    try {
      // 사진 모드: 갤러리에서 여러 장 선택 → 바로 컴포저로 이동
      if (_photoMode) {
        final List<XFile> picked = await ImagePicker().pickMultiImage();
        if (picked.isNotEmpty) {
          setState(() => _photos.addAll(picked.map((e) => File(e.path))));
          _openPhotoComposer();
        }
        return;
      }
      // 영상 모드: 기존대로 영상 1개 선택
      final XFile? pickedFile = await ImagePicker().pickVideo(source: imageSource);
      if (pickedFile != null) {
        Navigator.of(
          context,
        ).pushReplacement(
          MaterialPageRoute(
            builder: (_) => VideoRegPage(videoFile: File(pickedFile.path)),
          ),
        );
      }
    } catch (e) {
      Utils.alert(e.toString());
    }
  }

  // 사진 1장 촬영 → 목록에 누적(셔터 연속 촬영 가능)
  Future<void> _capturePhoto() async {
    HapticFeedback.mediumImpact();
    final XFile? shot = await cameraBloc.takePhoto();
    if (shot != null && mounted) {
      setState(() => _photos.add(File(shot.path)));
    }
  }

  // 촬영/선택한 사진들을 들고 사진 등록 화면으로 이동
  void _openPhotoComposer() {
    if (_photos.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PhotoRegPage(photoFiles: List<File>.from(_photos)),
      ),
    ).then((_) {
      // 컴포저에서 돌아오면(게시 완료/취소) 목록 초기화
      if (mounted) setState(() => _photos.clear());
    });
  }

  @override
  void dispose() {
    // 카메라 종료 후에도 세로 고정 유지(가로 회전 허용 금지).
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    cameraBloc.add(CameraReset());
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /*
  Camera 패키지에서 제안한 카메라 생명주기 관리 코드
  */
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (cameraBloc.getController() == null) return;
    if (state == AppLifecycleState.inactive) {
      cameraBloc.add(CameraDisable());
    }
    if (state == AppLifecycleState.resumed) {
      cameraBloc.add(const CameraInitialize());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: false,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Stack(children: [
          //   SizedBox(height: MediaQuery.of(context).padding.top),
          VisibilityDetector(
            key: const Key("my_camera"),
            onVisibilityChanged: _handleVisibilityChanged,
            child: BlocConsumer<CameraBloc, CameraState>(
              listener: _cameraBlocListener,
              builder: _cameraBlocBuilder,
            ),
          ),
          Positioned(
            top: 10,
            right: 10,
            child: IconButton(
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              icon: const Icon(
                Icons.close,
                color: Colors.white,
                size: 17,
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ),
          Positioned(
            top: 10,
            left: 10,
            child: TextButton(
              style: TextButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              onPressed: () => getImage(context, ImageSource.gallery),
              child: const Text(
                "갤러리",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
          // Positioned(
          //   bottom: 0,
          //   left: 2,
          //   child: Text(
          //     "Camera Screen Auto Resized.",
          //     style: TextStyle(color: Colors.yellow[200], fontSize: 8),
          //   ),
          // )
        ]),
      ),
    );
  }

  Widget _cameraBlocBuilder(BuildContext context, CameraState state) {
    lo.g("################################ state ==> ${state.runtimeType}");

    bool disableButtons = !(state is CameraReady && !state.isRecordingVideo);
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              if (state is! CameraReady) const Center(child: CircularProgressIndicator()),
              if (state is CameraReady)
                RepaintBoundary(
                  key: screenshotKey,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 0),
                    switchInCurve: Curves.easeInOut,
                    child: Builder(builder: (context) {
                      final controller = cameraBloc.getController();
                      lo.g("################################ controller in builder ==> ${controller?.value.isInitialized}");

                      if (controller == null || !controller.value.isInitialized) {
                        return const Center(child: CircularProgressIndicator(color: Colors.white));
                      }

                      return Stack(
                        children: [
                          CameraPreviewWidget(
                            key: ValueKey(controller.description.lensDirection),
                            controller: controller,
                          ),
                          // AspectRatio(
                          //   aspectRatio: deviceRatio,
                          //   child: Transform(
                          //     alignment: Alignment.center,
                          //     transform: Matrix4.diagonal3Values(xScale, yScale, 1),
                          //     child: ZoomableWidget(
                          // onTapUp: (scaledPoint) {
                          //   controller.setFocusPoint(scaledPoint);
                          // },
                          // onZoom: (zoom) {
                          //   if (zoom < 11) {
                          //     controller.setZoomLevel(zoom);
                          //   }
                          // },
                          //         child: CameraPreview(controller)),
                          //   ),
                          // ),

                          // AspectRatio(`
                          //   aspectRatio: previewRatio,
                          //   child: ZoomableWidget(
                          //     child: ClipRRect(borderRadius: BorderRadius.circular(20), child: CameraPreview(controller)),
                          // onTapUp: (scaledPoint) {
                          //   controller.setFocusPoint(scaledPoint);
                          // },
                          // onZoom: (zoom) {
                          //   if (zoom < 11) {
                          //     controller.setZoomLevel(zoom);
                          //   }
                          // },
                          //   ),
                          // ),
                          Positioned(
                            bottom: Platform.isIOS ? 35 : 40,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Visibility(
                                    visible: !disableButtons,
                                    child: _photoMode
                                        ? _buildNextButton()
                                        : StatefulBuilder(builder: (context, localSetState) {
                                      return GestureDetector(
                                        onTap: () {
                                          final List<int> time = [15, 30, 60, 90];
                                          int currentIndex = time.indexOf(cameraBloc.recordDurationLimit);
                                          localSetState(() {
                                            cameraBloc.setRecordDurationLimit = time[(currentIndex + 1) % time.length];
                                          });
                                        },
                                        child: CircleAvatar(
                                          backgroundColor: Colors.white.withOpacity(0.5),
                                          radius: 25,
                                          child: FittedBox(
                                              child: Text(
                                            "${cameraBloc.recordDurationLimit}",
                                            style: const TextStyle(
                                              color: Colors.black,
                                            ),
                                          )),
                                        ),
                                      );
                                    }),
                                  ),
                                  const SizedBox(width: 20),
                                  IgnorePointer(
                                    ignoring: state.decativateRecordButton,
                                    child: Opacity(
                                      opacity: state.decativateRecordButton ? 0.4 : 1,
                                      child: animatedProgressButton(state),
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  Visibility(
                                    visible: !disableButtons,
                                    child: CircleAvatar(
                                      backgroundColor: Colors.white.withOpacity(0.5),
                                      radius: 25,
                                      child: IconButton(
                                        onPressed: () async {
                                          try {
                                            // screenshotBytes = await takeCameraScreenshot(key: screenshotKey);
                                            if (context.mounted) cameraBloc.add(CameraSwitch());
                                          } catch (e) {
                                            //screenshot error
                                          }
                                        },
                                        icon: const Icon(
                                          Icons.cameraswitch,
                                          color: Colors.black,
                                          size: 28,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // 사진/영상 모드 토글 (녹화 중이 아닐 때만)
                          if (!disableButtons) _buildModeTogglePositioned(),
                          // 사진 모드에서 촬영한 사진 썸네일 스트립
                          if (_photoMode && _photos.isNotEmpty) _buildPhotoStripPositioned(),
                        ],
                      );
                    }),
                  ),
                ),
              if (state is CameraError) errorWidget(state),
            ],
          ),
        ),
        // const SizedBox(height: 35),
      ],
    );
  }

  Widget animatedProgressButton(CameraState state) {
    if (_photoMode) return _buildShutterButton();
    bool isRecording = state is CameraReady && state.isRecordingVideo;
    return GestureDetector(
      onTap: () async {
        HapticFeedback.mediumImpact(); // 탭 즉시 촉각 피드백 → 체감 반응성
        if (isRecording) {
          stopRecording();
        } else {
          startRecording();
        }
      },
      onLongPress: () {
        HapticFeedback.mediumImpact();
        startRecording();
      },
      onLongPressEnd: (_) => stopRecording(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: isRecording ? 90 : 80,
        width: isRecording ? 90 : 80,
        child: Stack(
          children: [
            AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF978B8B).withOpacity(0.8),
                )),
            ValueListenableBuilder(
                valueListenable: cameraBloc.recordingDuration,
                builder: (context, val, child) {
                  return TweenAnimationBuilder<double>(
                      duration: Duration(milliseconds: isRecording ? 1100 : 0),
                      tween: Tween<double>(
                        begin: isRecording ? 1 : 0, //val.toDouble(),,
                        end: isRecording ? val.toDouble() + 1 : 0,
                      ),
                      curve: Curves.linear,
                      builder: (context, value, _) {
                        return Center(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            height: isRecording ? 90 : 30,
                            width: isRecording ? 90 : 30,
                            child: RecordingProgressIndicator(
                              value: value,
                              maxValue: cameraBloc.recordDurationLimit.toDouble(),
                            ),
                          ),
                        );
                      });
                }),
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.linear,
                    height: isRecording ? 25 : 64,
                    width: isRecording ? 25 : 64,
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 255, 255, 255), //Color(0xffe80415),
                      borderRadius: isRecording ? BorderRadius.circular(6) : BorderRadius.circular(100),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  } // 기존 코드에서

  // ───────────── 사진 모드 위젯들 ─────────────

  // 사진/영상 모드 토글 pill (녹화 버튼 위)
  Widget _buildModeTogglePositioned() {
    return Positioned(
      bottom: Platform.isIOS ? 130 : 138,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.35),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _modeChip('사진', _photoMode),
              _modeChip('영상', !_photoMode),
            ],
          ),
        ),
      ),
    );
  }

  Widget _modeChip(String label, bool selected) {
    return GestureDetector(
      onTap: () {
        final bool toPhoto = label == '사진';
        if (toPhoto == _photoMode) return; // 같은 모드면 무시
        setState(() => _photoMode = toPhoto);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.black : Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  // 셔터 버튼(사진 모드) — 탭하면 1장 촬영
  Widget _buildShutterButton() {
    return GestureDetector(
      onTap: _capturePhoto,
      child: Container(
        height: 80,
        width: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF978B8B).withOpacity(0.8),
        ),
        child: Center(
          child: Container(
            height: 64,
            width: 64,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  // "다음(N)" 버튼 — 촬영한 사진이 있을 때만 활성
  Widget _buildNextButton() {
    final int n = _photos.length;
    final bool enabled = n > 0;
    return GestureDetector(
      onTap: enabled ? _openPhotoComposer : null,
      child: Opacity(
        opacity: enabled ? 1 : 0.4,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF4A90E2),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('다음', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
              if (n > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.25), borderRadius: BorderRadius.circular(20)),
                  child: Text('$n', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // 촬영한 사진 썸네일 스트립 (삭제 가능)
  Widget _buildPhotoStripPositioned() {
    return Positioned(
      bottom: Platform.isIOS ? 185 : 193,
      left: 0,
      right: 0,
      child: SizedBox(
        height: 62,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _photos.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, i) {
            return Stack(
              clipBehavior: Clip.none,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(_photos[i], height: 62, width: 48, fit: BoxFit.cover),
                ),
                Positioned(
                  top: -4,
                  right: -4,
                  child: GestureDetector(
                    onTap: () => setState(() => _photos.removeAt(i)),
                    child: Container(
                      decoration: BoxDecoration(color: Colors.black.withOpacity(0.65), shape: BoxShape.circle),
                      padding: const EdgeInsets.all(2),
                      child: const Icon(Icons.close, color: Colors.white, size: 14),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget errorWidget(CameraState state) {
    bool isPermissionError = state is CameraError && state.error == CameraErrorType.permission;
    return Container(
      color: Colors.black,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              isPermissionError ? "카메라와 마이크에 대한 액세스 권한을 부여해주세요." : "Something went wrong",
              style: const TextStyle(
                color: Color(0xFF959393),
                fontFamily: "Montserrat",
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(
              height: 20,
            ),
            Row(
              children: [
                Expanded(
                  child: CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    onPressed: () async {
                      openAppSettings();
                      Navigator.maybePop(context);
                    },
                    child: Container(
                      height: 35,
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(136, 76, 75, 75).withOpacity(0.4),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: FittedBox(
                          child: Text(
                            "Open Setting",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                              fontFamily: "Montserrat",
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

