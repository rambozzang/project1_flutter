import 'package:project1/repo/weather_gogo/models/response/super_fct/super_fct_model.dart';
import 'package:project1/repo/weather_gogo/repository/weather_repository.dart';

abstract class SuperFctRepository with WeatherRepository<ItemSuperFct, SuperFctModel> {}
