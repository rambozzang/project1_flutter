import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:intl/intl.dart';
import 'package:project1/app/weather/provider/weatherProvider.dart';
import 'package:project1/app/weather/theme/colors.dart';
import 'package:project1/app/weather/theme/textStyle.dart';
import 'package:project1/app/weather/widgets/customShimmer.dart';
import 'package:project1/app/weather/provider/weather_cntr.dart';
import 'package:provider/provider.dart';

class WeatherInfoHeader extends StatelessWidget {
  static const double boxWidth = 52.0;
  static const double boxHeight = 40.0;
  @override
  Widget build(BuildContext context) {
    return GetBuilder<WeatherCntr>(
      builder: (weatherProv) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            weatherProv.isLoading.value
                ? const SizedBox.shrink()
                : Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FittedBox(
                          child: RichText(
                            textAlign: TextAlign.start,
                            text: TextSpan(
                              text: '${weatherProv.weather.value!.city}, ',
                              style: semiboldText,
                              children: [
                                TextSpan(
                                  text: Country.tryParse(weatherProv.weather.value!.countryCode!)?.name,
                                  style: regularText.copyWith(fontSize: 18.0),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 4.0),
                        FittedBox(
                          child: Text(
                            DateFormat('y/MM/dd E , a hh:mm ', 'ko').format(DateTime.now()),
                            style: regularText.copyWith(color: Colors.grey.shade200),
                          ),
                        )
                      ],
                    ),
                  ),
            const SizedBox(width: 8.0),
            // ClipRRect(
            //   borderRadius: BorderRadius.circular(12.0),
            //   child: Container(
            //     padding: const EdgeInsets.all(4.0),
            //     color: Colors.grey.shade200,
            //     child: Stack(
            //       children: [
            //         AnimatedSwitcher(
            //           duration: Duration(milliseconds: 150),
            //           transitionBuilder: (Widget child, Animation<double> animation) {
            //             return SlideTransition(
            //               position: Tween<Offset>(
            //                 begin: weatherProv.isCelsius ? Offset(1.0, 0.0) : Offset(-1.0, 0.0),
            //                 end: Offset(0.0, 0.0),
            //               ).animate(animation),
            //               child: child,
            //             );
            //           },
            //           child: weatherProv.isCelsius
            //               ? GestureDetector(
            //                   key: ValueKey<int>(0),
            //                   child: Row(
            //                     children: [
            //                       Container(
            //                         height: boxHeight,
            //                         width: boxWidth,
            //                         alignment: Alignment.center,
            //                         decoration: BoxDecoration(
            //                           borderRadius: BorderRadius.circular(8.0),
            //                           color: weatherProv.isLoading ? Colors.grey : primaryBlue,
            //                         ),
            //                       ),
            //                       Container(
            //                         height: boxHeight,
            //                         width: boxWidth,
            //                         alignment: Alignment.center,
            //                         decoration: BoxDecoration(
            //                           borderRadius: BorderRadius.circular(8.0),
            //                           color: Colors.grey.shade200,
            //                         ),
            //                       ),
            //                     ],
            //                   ),
            //                   onTap: () => weatherProv.isLoading ? null : weatherProv.switchTempUnit(),
            //                 )
            //               : GestureDetector(
            //                   key: ValueKey<int>(1),
            //                   child: Row(
            //                     children: [
            //                       Container(
            //                         height: boxHeight,
            //                         width: boxWidth,
            //                         alignment: Alignment.center,
            //                         decoration: BoxDecoration(
            //                           borderRadius: BorderRadius.circular(8.0),
            //                           color: Colors.grey.shade200,
            //                         ),
            //                       ),
            //                       Container(
            //                         height: boxHeight,
            //                         width: boxWidth,
            //                         alignment: Alignment.center,
            //                         decoration: BoxDecoration(
            //                           borderRadius: BorderRadius.circular(8.0),
            //                           color: weatherProv.isLoading ? Colors.grey : primaryBlue,
            //                         ),
            //                       ),
            //                     ],
            //                   ),
            //                   onTap: () => weatherProv.switchTempUnit(),
            //                 ),
            //         ),
            //         IgnorePointer(
            //           child: Row(
            //             children: [
            //               Container(
            //                 height: boxHeight,
            //                 width: boxWidth,
            //                 alignment: Alignment.center,
            //                 child: Text(
            //                   '°C',
            //                   style: semiboldText.copyWith(
            //                     fontSize: 16,
            //                     color: weatherProv.isCelsius ? Colors.white : Colors.grey.shade600,
            //                   ),
            //                 ),
            //               ),
            //               Container(
            //                 height: boxHeight,
            //                 width: boxWidth,
            //                 alignment: Alignment.center,
            //                 child: Text(
            //                   '°F',
            //                   style: semiboldText.copyWith(
            //                     fontSize: 16,
            //                     color: weatherProv.isCelsius ? Colors.grey.shade600 : Colors.white,
            //                   ),
            //                 ),
            //               ),
            //             ],
            //           ),
            //         ),
            //       ],
            //     ),
            //   ),
            // )
          ],
        );
      },
    );
  }
}
