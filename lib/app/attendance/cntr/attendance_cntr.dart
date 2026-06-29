import 'package:get/get.dart';
import 'package:project1/app/auth/cntr/auth_cntr.dart';
import 'package:project1/repo/attendance/attendance_repo.dart';
import 'package:project1/repo/attendance/data/attendance_check_data.dart';
import 'package:project1/repo/attendance/data/attendance_me_data.dart';
import 'package:project1/repo/common/res_data.dart';
import 'package:project1/utils/log_utils.dart';

class AttendanceCntr extends GetxController {
  static AttendanceCntr get to => Get.find();

  final AttendanceRepo _attendanceRepo = AttendanceRepo();

  final Rx<AttendanceMeData?> myAttendance = Rx<AttendanceMeData?>(null);
  final Rx<AttendanceCheckData?> todayCheck = Rx<AttendanceCheckData?>(null);
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    ever(AuthCntr.to.isLogged, (isLogged) {
      if (isLogged == true) {
        checkAttendance();
        fetchMyAttendance();
      }
    });
  }

  Future<AttendanceCheckData?> checkAttendance({String attendanceType = 'OPEN'}) async {
    final custId = AuthCntr.to.custId.value;
    if (custId.isEmpty) return null;

    isLoading.value = true;
    try {
      ResData resData = await _attendanceRepo.checkAttendance(custId, attendanceType: attendanceType);
      if (resData.code == '00') {
        todayCheck.value = AttendanceRepo.parseCheckData(resData.data);
        return todayCheck.value;
      } else {
        lo.g('checkAttendance error: ${resData.msg}');
      }
    } catch (e) {
      lo.g('checkAttendance exception: $e');
    } finally {
      isLoading.value = false;
    }
    return null;
  }

  Future<void> fetchMyAttendance() async {
    final custId = AuthCntr.to.custId.value;
    if (custId.isEmpty) return;

    try {
      ResData resData = await _attendanceRepo.getMyAttendance(custId);
      if (resData.code == '00') {
        myAttendance.value = AttendanceRepo.parseMeData(resData.data);
      } else {
        lo.g('fetchMyAttendance error: ${resData.msg}');
      }
    } catch (e) {
      lo.g('fetchMyAttendance exception: $e');
    }
  }
}
