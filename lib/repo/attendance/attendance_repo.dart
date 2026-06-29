import 'package:dio/dio.dart';
import 'package:project1/config/url_config.dart';
import 'package:project1/repo/api/auth_dio.dart';
import 'package:project1/repo/attendance/data/attendance_check_data.dart';
import 'package:project1/repo/attendance/data/attendance_me_data.dart';
import 'package:project1/repo/common/res_data.dart';

class AttendanceRepo {
  Future<ResData> checkAttendance(String custId, {String attendanceType = 'OPEN'}) async {
    final dio = await AuthDio.instance.getDio();
    try {
      var url = '${UrlConfig.baseURL}/attendance/check';
      Response response = await dio.post(url, data: {
        'custId': custId,
        'attendanceType': attendanceType,
      });
      return AuthDio.instance.dioResponse(response);
    } on DioException catch (e) {
      return AuthDio.instance.dioException(e);
    }
  }

  Future<ResData> getMyAttendance(String custId) async {
    final dio = await AuthDio.instance.getDio();
    try {
      var url = '${UrlConfig.baseURL}/attendance/me?custId=$custId';
      Response response = await dio.post(url);
      return AuthDio.instance.dioResponse(response);
    } on DioException catch (e) {
      return AuthDio.instance.dioException(e);
    }
  }

  static AttendanceCheckData? parseCheckData(dynamic data) {
    if (data == null) return null;
    return AttendanceCheckData.fromMap(data as Map<String, dynamic>);
  }

  static AttendanceMeData? parseMeData(dynamic data) {
    if (data == null) return null;
    return AttendanceMeData.fromMap(data as Map<String, dynamic>);
  }
}
