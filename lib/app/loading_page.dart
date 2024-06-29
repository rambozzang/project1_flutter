// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_inappwebview/flutter_inappwebview.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:get/get.dart';
// import 'package:project1/app/weather/provider/weather_cntr.dart';
// import 'package:project1/utils/log_utils.dart';
// import 'package:project1/utils/utils.dart';

// class LoadingPage extends StatefulWidget {
//   const LoadingPage({super.key});

//   @override
//   State<LoadingPage> createState() => _LoadingPageState();
// }

// class _LoadingPageState extends State<LoadingPage> {
//   @override
//   void initState() {
//     super.initState();

//     // initS();
//   }

//   Future<void> initS() async {
//     bool isLocationserviceEnabled = await Geolocator.isLocationServiceEnabled();
//     if (!isLocationserviceEnabled) {
//       Utils.alert('Location services are disabled.');

//       return Future.error('Location services are disabled.');
//     }

//     LocationPermission locationPermission = await Geolocator.checkPermission();
//     lo.g(locationPermission.toString());

//     if (locationPermission == LocationPermission.denied || locationPermission == LocationPermission.deniedForever) {
//       locationPermission = await Geolocator.requestPermission();
//       if (locationPermission == LocationPermission.denied || locationPermission == LocationPermission.deniedForever) {
//         await Geolocator.requestPermission();
//       }
//       if (locationPermission == LocationPermission.denied || locationPermission == LocationPermission.deniedForever) {
//         Utils.alert('Location permissions are denied');

//         return Future.error('Location permissions are disabled.');
//       }
//     }
//     Get.put(WeatherCntr());
//     Future.delayed(const Duration(seconds: 1), () {
//       Get.offAllNamed('/rootPage');
//     });
//   }

//   @override
//   void dispose() {
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//         backgroundColor: Colors.black87,
//         body: Container(
//           alignment: Alignment.center,
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Utils.progressbar(),
//               const SizedBox(height: 20),
//               const Text(
//                 "Loading...",
//                 style: TextStyle(color: Colors.white),
//               ),
//             ],
//           ),
//         ));
//   }
// }
