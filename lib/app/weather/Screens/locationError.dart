import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:project1/app/weather/theme/colors.dart';
import 'package:project1/app/weather/provider/weather_cntr.dart';
import 'package:provider/provider.dart';

import '../provider/weatherProvider.dart';
import '../theme/textStyle.dart';

class LocationPermissionErrorDisplay extends StatelessWidget {
  const LocationPermissionErrorDisplay({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<WeatherCntr>(builder: (weatherProv) {
      return Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.sizeOf(context).width,
                minWidth: 100,
                maxHeight: MediaQuery.sizeOf(context).height / 3,
              ),
              child: Image.asset('assets/images/locError.png'),
            ),
            Center(
              child: Text(
                'Location Permission Error',
                style: boldText.copyWith(color: primaryBlue),
              ),
            ),
            const SizedBox(height: 4.0),
            Center(
              child: Text(
                weatherProv.locationPermission == LocationPermission.deniedForever
                    ? 'Location permissions are permanently denied, Please enable manually from app settings and restart the app'
                    : 'Location permission not granted, please check your location permission',
                style: mediumText.copyWith(color: Colors.grey.shade700),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16.0),
            SizedBox(
              width: MediaQuery.sizeOf(context).width / 2,
              child: Column(
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      textStyle: mediumText,
                      padding: const EdgeInsets.all(12.0),
                      shape: const StadiumBorder(),
                    ),
                    child: weatherProv.isLoading.value
                        ? const SizedBox(
                            width: 16.0,
                            height: 16.0,
                            child: CircularProgressIndicator(
                              strokeWidth: 3.0,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            weatherProv.locationPermission == LocationPermission.deniedForever ? 'Open App Settings' : 'Request Permission',
                          ),
                    onPressed: weatherProv.isLoading.value
                        ? null
                        : () async {
                            if (weatherProv.locationPermission == LocationPermission.deniedForever) {
                              await Geolocator.openAppSettings();
                            } else {
                              weatherProv.getWeatherData();
                            }
                          },
                  ),
                  const SizedBox(height: 4.0),
                  if (weatherProv.locationPermission == LocationPermission.deniedForever)
                    TextButton(
                      style: TextButton.styleFrom(foregroundColor: primaryBlue),
                      child: const Text('Restart'),
                      onPressed: weatherProv.isLoading.value ? null : () => weatherProv.getWeatherData(),
                    )
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}

class LocationServiceErrorDisplay extends StatefulWidget {
  const LocationServiceErrorDisplay({Key? key}) : super(key: key);

  @override
  State<LocationServiceErrorDisplay> createState() => _LocationServiceErrorDisplayState();
}

class _LocationServiceErrorDisplayState extends State<LocationServiceErrorDisplay> {
  late StreamSubscription<ServiceStatus> serviceStatusStream;

  @override
  void initState() {
    super.initState();
    serviceStatusStream = Geolocator.getServiceStatusStream().listen((_) {});
    serviceStatusStream.onData((ServiceStatus status) {
      if (status == ServiceStatus.enabled) {
        print('enabled');
        // Provider.of<WeatherProvider>(context, listen: false).getWeatherData(context);
        //  Get.find<WeatherCntr>().getWeatherData();
      }
    });
  }

  @override
  void dispose() {
    serviceStatusStream.cancel();
    super.dispose();
  }

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
              maxWidth: MediaQuery.sizeOf(context).width,
              minWidth: 100,
              maxHeight: MediaQuery.sizeOf(context).height / 3,
            ),
            child: Image.asset('assets/images/locError.png'),
          ),
          Center(
            child: Text(
              'Location Service Disabled',
              style: boldText.copyWith(color: primaryBlue),
            ),
          ),
          const SizedBox(height: 4.0),
          Center(
            child: Text(
              'Your device location service is disabled, please turn it on before continuing',
              style: mediumText.copyWith(color: Colors.grey.shade700),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16.0),

          SizedBox(
            width: MediaQuery.sizeOf(context).width / 2,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                textStyle: mediumText,
                padding: const EdgeInsets.all(12.0),
                shape: const StadiumBorder(),
              ),
              child: const Text('Turn On Service'),
              onPressed: () async {
                await Geolocator.openLocationSettings();
              },
            ),
          )

          // Consumer<WeatherProvider>(builder: (context, weatherProv, _) {
          //   return SizedBox(
          //     width: MediaQuery.sizeOf(context).width / 2,
          //     child: ElevatedButton(
          //       style: ElevatedButton.styleFrom(
          //         backgroundColor: primaryBlue,
          //         textStyle: mediumText,
          //         padding: const EdgeInsets.all(12.0),
          //         shape: StadiumBorder(),
          //       ),
          //       child: Text('Turn On Service'),
          //       onPressed: () async {
          //         await Geolocator.openLocationSettings();
          //       },
          //     ),
          //   );
          // }),
        ],
      ),
    );
  }
}

// Get.find<WeatherCntr>()