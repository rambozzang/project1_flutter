import 'package:project1/repo/weather_gogo/models/response/super_nct/super_nct_model.dart';
import 'package:project1/repo/weather_gogo/repository/weather_repository.dart';

abstract class SuperNctRepository with WeatherRepository<ItemSuperNct, SuperNctModel> {}
