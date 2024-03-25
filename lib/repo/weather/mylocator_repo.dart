import 'package:geolocator/geolocator.dart';

class MyLocatorRepo {
  // MyLocatorRepo._();

  Future<Position?> getCurrentLocation() async {
    try {
      return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best, timeLimit: const Duration(seconds: 5));
    } catch (e) {
      return await Geolocator.getLastKnownPosition();
    }
  }
}
