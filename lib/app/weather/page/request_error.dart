import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:material_floating_search_bar_2/material_floating_search_bar_2.dart';
import 'package:project1/app/weather/theme/colors.dart';
import 'package:project1/app/weather/cntr/weather_cntr.dart';

import '../theme/textStyle.dart';

class RequestErrorDisplay extends StatelessWidget {
  const RequestErrorDisplay({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width * 0.4,
              minWidth: 70,
              maxHeight: MediaQuery.sizeOf(context).height / 3,
            ),
            child: Image.asset('assets/images/requestError.png'),
          ),
          Center(
            child: Text(
              '검색시 오류가 발생했습니다.',
              style: boldText.copyWith(color: primaryBlue),
            ),
          ),
          const SizedBox(height: 4.0),
          Center(
            child: Text(
              ' Error, 잠시 후 다시 시도해주세요.',
              style: mediumText.copyWith(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16.0),
          GetBuilder<WeatherCntr>(builder: (weatherProv) {
            return SizedBox(
              width: MediaQuery.sizeOf(context).width / 2,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  textStyle: mediumText,
                  padding: const EdgeInsets.all(7.0),
                  shape: StadiumBorder(),
                ),
                onPressed: weatherProv.isLoading.value
                    ? null
                    : () async {
                        await weatherProv.getWeatherData();
                      },
                child: const Text(
                  '다시 요청',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// class SearchErrorDisplay extends StatelessWidget {
//   const SearchErrorDisplay({
//     Key? key,
//     required this.fsc,
//   }) : super(key: key);

//   final FloatingSearchBarController fsc;

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.all(12.0),
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         crossAxisAlignment: CrossAxisAlignment.center,
//         children: [
//           ConstrainedBox(
//             constraints: BoxConstraints(
//               maxWidth: MediaQuery.sizeOf(context).width,
//               minWidth: 70,
//               maxHeight: MediaQuery.sizeOf(context).height / 3,
//             ),
//             child: Image.asset('assets/images/searchError.png'),
//           ),
//           Center(
//             child: Text(
//               '검색시 오류가 발생했습니다.',
//               style: boldText.copyWith(color: primaryBlue),
//             ),
//           ),
//           const SizedBox(height: 4.0),
//           Center(
//             child: Text(
//               'Unable to find "${fsc.query}", check for typo or check your internet connection',
//               style: mediumText.copyWith(color: Colors.grey.shade700),
//               textAlign: TextAlign.center,
//             ),
//           ),
//           const SizedBox(height: 16.0),
//           GetBuilder<WeatherCntr>(builder: (weatherProv) {
//             return SizedBox(
//               width: MediaQuery.sizeOf(context).width / 2,
//               child: ElevatedButton(
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: primaryBlue,
//                   textStyle: mediumText,
//                   padding: const EdgeInsets.all(7.0),
//                   shape: StadiumBorder(),
//                 ),
//                 child: Text('날씨 홈으로'),
//                 onPressed: weatherProv.isLoading.value
//                     ? null
//                     : () async {
//                         await weatherProv.getWeatherData();
//                       },
//               ),
//             );
//           }),
//         ],
//       ),
//     );
//   }
// }
