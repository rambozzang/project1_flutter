import 'dart:async';
import 'dart:ui';

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:project1/repo/common/res_stream.dart';
import 'package:project1/widget/custom_button.dart';
import 'package:project1/widget/custom_sec_button.dart';
import 'package:project1/widget/error_page.dart';
import 'package:project1/widget/no_data_widget.dart';

abstract class Utils {
  Utils._();

  static void alert(String msg) {
    BotToast.showCustomText(
      duration: const Duration(seconds: 2),
      backButtonBehavior: BackButtonBehavior.none,
      animationDuration: const Duration(milliseconds: 300),
      animationReverseDuration: const Duration(milliseconds: 200),
      toastBuilder: (_) => Align(
        alignment: const Alignment(0, 0.77),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.7),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Text(
            msg,
            style: TextStyle(fontSize: 14, color: Colors.white),
          ),
        ),
      ),
    );
  }

  static void alertLong(String msg) {
    BotToast.showText(
        text: msg,
        contentColor: Colors.black.withOpacity(0.67),
        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
        textStyle: const TextStyle(fontSize: 14, color: Colors.white),
        duration: const Duration(seconds: 5),
        onlyOne: false);
  }

  static void alertIcon(String msg, {String? icontype, Duration? duration}) {
    Color clr = const Color(0xFF4BCB1E);
    IconData icondata = Icons.check_rounded;
    if (icontype == 'E') {
      clr = const Color(0xFFE23E28);
      icondata = Icons.clear_rounded;
    } else if (icontype == 'W') {
      clr = const Color(0xFFFF9900);
      icondata = Icons.priority_high_rounded;
    }
    BotToast.showCustomText(
      duration: duration ?? const Duration(seconds: 2),
      // onlyOne: onlyOne,
      //  clickClose: clickClose,
      //  crossPage: crossPage,
      //  ignoreContentClick: ignoreContentClick,
      //   backgroundColor: Color(backgroundColor),
      backButtonBehavior: BackButtonBehavior.none,
      animationDuration: const Duration(milliseconds: 300),
      animationReverseDuration: const Duration(milliseconds: 200),
      toastBuilder: (_) => Align(
        alignment: const Alignment(0, 0.77),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.7),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 22,
                height: 22,
                decoration: ShapeDecoration(
                  color: clr,
                  shape: const OvalBorder(),
                ),
                child: Center(
                  child: Icon(
                    icondata,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
              const Gap(5),
              Flexible(
                child: Text(
                  msg,
                  softWrap: true,
                  maxLines: 2,
                  style: const TextStyle(fontSize: 14, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void showAlertDialog(String? title, String? subtitle, String? buttonText, BackButtonBehavior backButtonBehavior,
      {VoidCallback? confirm, VoidCallback? backgroundReturn}) {
    BotToast.showAnimationWidget(
        clickClose: false,
        allowClick: false,
        onlyOne: true,
        crossPage: true,
        backButtonBehavior: backButtonBehavior,
        wrapToastAnimation: (controller, cancel, child) => Stack(
              children: <Widget>[
                GestureDetector(
                  onTap: () {
                    cancel();
                    backgroundReturn?.call();
                  },
                  //The DecoratedBox here is very important,he will fill the entire parent component
                  child: AnimatedBuilder(
                    builder: (_, child) => Opacity(
                      opacity: controller.value,
                      child: child,
                    ),
                    animation: controller,
                    child: const DecoratedBox(
                      decoration: BoxDecoration(color: Colors.black26),
                      child: SizedBox.expand(),
                    ),
                  ),
                ),
                CustomOffsetAnimation(
                  controller: controller,
                  child: child,
                )
              ],
            ),
        toastBuilder: (cancelFunc) => AlertDialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              title: SizedBox(
                width: Get.width,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.toString(),
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const Gap(5),
                      Text(
                        subtitle.toString(),
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ]
                  ],
                ),
              ),
              actions: <Widget>[
                CustomButton(
                    text: '$buttonText',
                    type: 'L',
                    isEnable: true,
                    widthValue: Get.width,
                    heightValue: 46,
                    onPressed: () {
                      cancelFunc();
                      confirm?.call();
                    }),
              ],
            ),
        animationDuration: const Duration(milliseconds: 300));
  }

  static void showConfirmDialog(String title, String subtitle, BackButtonBehavior backButtonBehavior,
      {VoidCallback? cancel, VoidCallback? confirm, VoidCallback? backgroundReturn}) {
    BotToast.showAnimationWidget(
        clickClose: false,
        allowClick: false,
        onlyOne: true,
        crossPage: true,
        backButtonBehavior: backButtonBehavior,
        wrapToastAnimation: (controller, cancel, child) => Stack(
              children: <Widget>[
                GestureDetector(
                  onTap: () {
                    cancel();
                    backgroundReturn?.call();
                  },
                  //The DecoratedBox here is very important,he will fill the entire parent component
                  child: AnimatedBuilder(
                    builder: (_, child) => Opacity(
                      opacity: controller.value,
                      child: child,
                    ),
                    animation: controller,
                    child: const DecoratedBox(
                      decoration: BoxDecoration(color: Colors.black26),
                      child: SizedBox.expand(),
                    ),
                  ),
                ),
                CustomOffsetAnimation(
                  controller: controller,
                  child: child,
                )
              ],
            ),
        toastBuilder: (cancelFunc) => AlertDialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              title: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title.toString(),
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const Gap(10),
                    Text(
                      subtitle.toString(),
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ]
                ],
              ),
              actions: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      flex: 1,
                      child: CustomSecButton(
                          text: '취소',
                          type: 'S',
                          widthValue: double.infinity,
                          heightValue: 46,
                          onPressed: () {
                            cancelFunc();
                            cancel?.call();
                          }),
                    ),
                    const Gap(20),
                    Flexible(
                      flex: 1,
                      child: CustomButton(
                          text: '확인',
                          type: 'XS',
                          widthValue: double.infinity,
                          heightValue: 46,
                          isEnable: true,
                          onPressed: () {
                            cancelFunc();
                            confirm?.call();
                          }),
                    ),
                  ],
                ),
              ],
            ),
        animationDuration: const Duration(milliseconds: 300));
  }

  static Widget progressbar({double? size, Color? color}) {
    return Center(
      child: LoadingAnimationWidget.threeRotatingDots(
        color: color ?? Colors.pink,
        size: size ?? 40,
      ),
    );
  }

  static Widget progressUpload({double? size}) {
    return Center(
      child: LoadingAnimationWidget.discreteCircle(
        color: Colors.pink,
        size: size ?? 40,
      ),
    );
  }

  // 예) 서울특별시 => 서울
  static String localReplace(String) {
    return String.replaceAll('특별시', '').replaceAll('광역시', '').replaceAll('특별자치시', '').replaceAll('특별자치도', '');
  }

  static void showAutomaticCloseDialog(
    String? title,
    String? subtitle,
    Duration? duration, {
    VoidCallback? close,
  }) {
    BotToast.showAnimationWidget(
      allowClick: false,
      clickClose: false,
      onlyOne: true,
      crossPage: true,
      wrapToastAnimation: (controller, cancel, child) => Stack(
        children: <Widget>[
          GestureDetector(
            //The DecoratedBox here is very important,he will fill the entire parent component
            child: AnimatedBuilder(
              builder: (_, child) => Opacity(
                opacity: controller.value,
                child: child,
              ),
              animation: controller,
              child: const DecoratedBox(
                decoration: BoxDecoration(color: Colors.black26),
                child: SizedBox.expand(),
              ),
            ),
          ),
          CustomOffsetAnimation(
            controller: controller,
            child: child,
          )
        ],
      ),
      toastBuilder: (cancelFunc) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: SizedBox(
          width: Get.width,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(title.toString(), style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
              if (subtitle != null) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    subtitle.toString(),
                    style: TextStyle(
                      color: Colors.grey[300],
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ]
            ],
          ),
        ),
      ),
      animationDuration: const Duration(milliseconds: 300),
      duration: duration,
      onClose: () {
        close?.call();
        // Navigator.of(Get.context!).pop();
      },
    );
  }

  static Widget commonStreamList<T>(StreamController stream, Widget Function(List<T>) buildBody, Function()? onRetryPressed) {
    return StreamBuilder<ResStream<List<T>>>(
      stream: stream.stream as Stream<ResStream<List<T>>>?,
      builder: (BuildContext context, AsyncSnapshot<ResStream<List<T>>> snapshot) {
        if (snapshot.hasData) {
          switch (snapshot.data?.status) {
            case Status.LOADING:
              return Center(
                  child: Padding(
                padding: const EdgeInsets.all(68.0),
                child: Utils.progressbar(),
              ));
            case Status.COMPLETED:
              var list = snapshot.data!.data;
              return list!.isEmpty ? const NoDataWidget() : buildBody(list);
            case Status.ERROR:
              return ErrorPage(
                errorMessage: snapshot.data!.message ?? '',
                onRetryPressed: onRetryPressed,
              );
            case null:
              return const SizedBox(
                width: 200,
                height: 300,
                child: Text("조회 중 오류가 발생했습니다."),
              );
          }
        }
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(48.0),
            child: Text("조회 된 데이터가 없습니다."),
          ),
        );
      },
    );
  }

  static Widget commonStreamBody<T>(StreamController stream, Widget Function(T) buildBody, Function()? onRetryPressed) {
    return StreamBuilder<ResStream<T>>(
      stream: stream.stream as Stream<ResStream<T>>?,
      builder: (BuildContext context, AsyncSnapshot<ResStream<T>> snapshot) {
        if (snapshot.hasData) {
          switch (snapshot.data?.status) {
            case Status.LOADING:
              return Center(
                  child: Padding(
                padding: const EdgeInsets.all(68.0),
                child: Utils.progressbar(),
              ));
            case Status.COMPLETED:
              var result = snapshot.data!.data;
              return result == null ? const NoDataWidget() : buildBody(result);
            case Status.ERROR:
              return ErrorPage(
                errorMessage: snapshot.data!.message ?? '',
                onRetryPressed: onRetryPressed,
              );
            case null:
              return const SizedBox(
                width: 200,
                height: 300,
                child: Text("조회 중 오류가 발생했습니다."),
              );
          }
        }
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(48.0),
            child: Text("조회 된 데이터가 없습니다."),
          ),
        );
      },
    );
  }

  static String getToday() {
    DateTime now = DateTime.now();
    DateFormat formatter = DateFormat('yyyyMMdd');
    String strToday = formatter.format(now);
    return strToday;
  }

  static String getTime() {
    DateTime now = DateTime.now();
    DateFormat formatter = DateFormat('HH:mm');
    String strToday = formatter.format(now);
    return strToday;
  }
}

class CustomOffsetAnimation extends StatefulWidget {
  final AnimationController controller;
  final Widget child;

  const CustomOffsetAnimation({super.key, required this.controller, required this.child});

  @override
  // ignore: library_private_types_in_public_api
  _CustomOffsetAnimationState createState() => _CustomOffsetAnimationState();
}

class _CustomOffsetAnimationState extends State<CustomOffsetAnimation> {
  late Tween<Offset> tweenOffset;
  late Tween<double> tweenScale;

  late Animation<double> animation;

  @override
  void initState() {
    tweenOffset = Tween<Offset>(
      begin: const Offset(0.0, 0.8),
      end: Offset.zero,
    );
    tweenScale = Tween<double>(begin: 0.3, end: 1.0);
    animation = CurvedAnimation(parent: widget.controller, curve: Curves.decelerate);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (BuildContext context, Widget? child) {
        return FractionalTranslation(
            translation: tweenOffset.evaluate(animation),
            child: ClipRect(
              child: Transform.scale(
                scale: tweenScale.evaluate(animation),
                child: Opacity(
                  opacity: animation.value,
                  child: child,
                ),
              ),
            ));
      },
      child: widget.child,
    );
  }
}
