import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:project1/app/weather/provider/weatherProvider.dart';
import 'package:project1/app/weather/provider/weather_cntr.dart';
import 'package:provider/provider.dart';

class RequestError extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 150),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.wrong_location_outlined,
            color: Colors.blue,
            size: 100,
          ),
          const SizedBox(height: 10),
          const Text(
            'No Search Result',
            style: TextStyle(
              color: Colors.blue,
              fontSize: 30,
              fontWeight: FontWeight.w700,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 75, vertical: 10),
            child: Text(
              "Please make sure that you entered the correct location or check your device internet connection",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 15,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25.0),
              ),
            ),
            child: const Text('Return Home'),
            onPressed: () => Get.find<WeatherCntr>()
                .getWeatherData(), //  Provider.of<WeatherProvider>(context, listen: false).getWeatherData(context, notify: true),
          ),
        ],
      ),
    );
  }
}
