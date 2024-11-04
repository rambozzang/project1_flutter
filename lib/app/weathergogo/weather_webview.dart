import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:project1/app/weather/theme/textStyle.dart';
import 'package:project1/app/webview/common_webview.dart';

class WeatherWEbviewPage extends StatelessWidget {
  const WeatherWEbviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    // const webViewUrl = 'https://earth.nullschool.net/#current/wind/surface/level/orthographic=127.20,36.33,2780/loc=';
    const webViewUrl = 'https://earth.nullschool.net/#current/wind/surface/level/orthographic=126.12,37.16,1280/loc=127.030,37.221';
    // const webViewUrl = 'https://www.windy.com/37.567/126.978?radar,37.073,126.978,8';
    // const webViewUrl = 'https://www.ventusky.com/ko';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const Row(
            children: [
              PhosphorIcon(PhosphorIconsRegular.wind, color: Colors.white),
              SizedBox(width: 4.0),
              Text(
                '대기 흐름',
                style: TextStyle(fontSize: 17, color: Colors.white, fontWeight: FontWeight.bold),
              ),
              Spacer(),
            ],
          ),
          const Gap(15),
          const SizedBox(
            height: 600,
            child: CommonWebView(
              isBackBtn: false,
              url: webViewUrl,
            ),
          ),
          const Gap(10),
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: Colors.white12,
              padding: const EdgeInsets.symmetric(horizontal: 0),
              minimumSize: const Size(50, 22),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                  fullscreenDialog: false,
                  builder: (context) => const CommonWebView(
                        isBackBtn: true,
                        url: webViewUrl,
                      )),
            ), // Get.toNamed('/WeatherWebView'),
            child: Text('전체화면으로 ', style: semiboldText.copyWith(fontSize: 11.0)),
          ),
          const Gap(40)
        ],
      ),
    );
  }
}
