import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:camera/camera.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:project1/app/camera/bloc/camera_bloc.dart';
import 'package:project1/app/camera/bloc/camera_state.dart';
import 'package:project1/app/camera/page/video_reg_page.dart';
import 'package:project1/app/camera/page/widgets/animated_bar.dart';
import 'package:project1/app/camera/utils/zoom_widget.dart';
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

  @override
  void initState() {
    super.initState();
    cameraBloc = BlocProvider.of<CameraBloc>(context);
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
      //pickedFile에 ImagePicker로 가져온 이미지가 담긴다.
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

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
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
            top: 5,
            right: 5,
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
            top: 5,
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
                    duration: const Duration(milliseconds: 150),
                    switchInCurve: Curves.easeInOut,
                    child: Builder(builder: (context) {
                      var controller = cameraBloc.getController();
                      lo.g("################################ controller in builder ==> ${controller?.value.isInitialized}");

                      if (controller == null || !controller.value.isInitialized) {
                        return const SizedBox.shrink();
                      }

                      // final mediaSize = MediaQuery.of(context).size;
                      final isBackCamera = controller.description.lensDirection == CameraLensDirection.back;
                      // final previewSize = controller.value.previewSize!;
                      // final previewRatio = previewSize.height / previewSize.width;
                      // final screenRatio = mediaSize.height / mediaSize.width;

                      // var scale = 1.0;
                      // if (screenRatio > previewRatio) {
                      //   scale = mediaSize.height / (previewSize.width * previewRatio);
                      // } else {
                      //   scale = mediaSize.width / previewSize.width;
                      // }

                      Size mediaSize = MediaQuery.of(context).size;
                      // mediaSize.height -= MediaQuery.of(context).padding.top;
                      // mediaSize. -= MediaQuery.of(context).padding.top;
                      final deviceRatio = mediaSize.aspectRatio;

                      final scale = 1 / (controller.value.aspectRatio * deviceRatio);

                      // 프론트 카메라일 경우 줌 레벨 조정
                      if (!isBackCamera) {
                        controller.setZoomLevel(1.0); // 줌 레벨을 1.0으로 설정 (기본값)
                      }

                      lo.g("scale ==> $scale");

                      return Stack(
                        children: [
                          ZoomableWidget(
                            onTapUp: (scaledPoint) {
                              controller.setFocusPoint(scaledPoint);
                            },
                            onZoom: (zoom) {
                              if (zoom < 11) {
                                controller.setZoomLevel(zoom);
                              }
                            },
                            child: ClipRect(
                              clipper: _MediaSizeClipper(mediaSize),
                              child: Transform.scale(
                                scale: scale,
                                alignment: Alignment.topCenter,
                                child: CameraPreview(controller),
                              ),
                            ),
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
                            bottom: Platform.isIOS ? 40 : 40,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Visibility(
                                    visible: !disableButtons,
                                    child: StatefulBuilder(builder: (context, localSetState) {
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
                                    ignoring: state is! CameraReady || state.decativateRecordButton,
                                    child: Opacity(
                                      opacity: state is! CameraReady || state.decativateRecordButton ? 0.4 : 1,
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
    bool isRecording = state is CameraReady && state.isRecordingVideo;
    return GestureDetector(
      onTap: () async {
        if (isRecording) {
          stopRecording();
        } else {
          startRecording();
        }
      },
      onLongPress: () => startRecording(),
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

class _MediaSizeClipper extends CustomClipper<Rect> {
  final Size mediaSize;
  const _MediaSizeClipper(this.mediaSize);
  @override
  Rect getClip(Size size) {
    return Rect.fromLTWH(0, 0, mediaSize.width, mediaSize.height);
  }

  @override
  bool shouldReclip(CustomClipper<Rect> oldClipper) {
    return true;
  }
}
