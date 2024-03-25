import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:project1/repo/api/auth_dio.dart';
import 'package:project1/repo/weather/mylocator_repo.dart';
import 'package:project1/utils/log_utils.dart';

class OpenWheatherRepo {
  Future getWeather(String city) async {
    final dio = Dio();
    try {
      MyLocatorRepo myLocatorRepo = MyLocatorRepo();

      Position? position = await myLocatorRepo.getCurrentLocation();
    } catch (e) {
      Lo.g(e.toString());
    }
  }
}
