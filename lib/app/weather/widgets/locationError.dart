import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:project1/app/weather/cntr/weather_cntr.dart';
import 'package:provider/provider.dart';

import '../cntr/weatherProvider.dart';

class LocationError extends StatefulWidget {
  @override
  _LocationErrorState createState() => _LocationErrorState();
}

class _LocationErrorState extends State<LocationError> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.location_off,
            color: Colors.black,
            size: 75,
          ),
          SizedBox(height: 10),
          Text(
            'Your Location is Disabled',
            style: TextStyle(
              color: Colors.black,
              fontSize: 25,
              fontWeight: FontWeight.w500,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 75, vertical: 10),
            child: Text(
              "Please turn on your location service and refresh the app",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black,
                fontSize: 15,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              textStyle: TextStyle(color: Colors.white),
              padding: EdgeInsets.symmetric(horizontal: 50),
            ),
            child: Text('Enable Location'),
            onPressed: () async {
              await Get.find<WeatherCntr>().getWeatherData();
              // await Provider.of<WeatherProvider>(context, listen: false).getWeatherData(context);
            },
          ),
        ],
      ),
    );
  }
}
