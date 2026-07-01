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
    // 이미 로그인된 상태에서 컨트롤러가 생성될 때(챌린지 화면 진입 등)
    // 출석 현황을 즉시 불러온다. ever는 값이 변할 때만 실행되므로 이것만으로는
    // 로드되지 않아 출석 카드가 0으로만 표시되던 문제를 방지한다.
    // 화면 진입 시에는 표시용 현황만 조회하고, 실제 출석 체크(check-in)는
    // 로그인 시점(auth 흐름)과 로그인 상태 전환 시에만 수행한다.
    if (AuthCntr.to.isLogged.value == true) {
      fetchMyAttendance();
    }
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
