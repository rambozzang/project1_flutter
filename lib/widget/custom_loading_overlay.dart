import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';

showLoadingOverLay({required Future<dynamic> Function() asyncFunction, String? msg}) async {
  await Get.showOverlay(
    asyncFunction: () async {
      try {
        await asyncFunction();
      } catch (error) {
        //rethrow;
        print(error);
        //Logger().e(StackTrace.current);
      }
    },
    loadingWidget: Center(
      child: LoadingIndicator(msg: msg),
    ),
    opacity: 0.7,
    opacityColor: Colors.black,
  );
}

class LoadingIndicator extends StatelessWidget {
  final String? msg;
  final bool hasShadow;
  const LoadingIndicator({super.key, this.msg, this.hasShadow = false});

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 30,
        vertical: 40,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.background,
        borderRadius: BorderRadius.circular(10),
        boxShadow: !hasShadow
            ? null
            : [
                BoxShadow(
                  color: theme.shadowColor,
                  offset: const Offset(0.0, 1.0),
                  blurRadius: 6.0,
                ),
              ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SpinKitCubeGrid(
            color: theme.primaryColor,
            size: 30.0,
          ),
          const Gap(30),
          Text(msg ?? "Loading....", style: theme.textTheme.displayMedium),
        ],
      ),
    );
  }
}
