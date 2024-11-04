import 'package:get/get.dart';
import 'package:rxdart/subjects.dart';
import 'package:project1/repo/alram/alram_repo.dart';
import 'package:project1/repo/alram/data/alram_req_data.dart';
import 'package:project1/repo/alram/data/alram_res_data.dart';
import 'package:project1/repo/common/res_stream.dart';
import 'package:project1/app/auth/cntr/auth_cntr.dart';

class AlramController extends GetxController {
  final listCtrl = BehaviorSubject<ResStream<List<AlramResData>>>();
  final List<AlramResData> list = <AlramResData>[];

  int page = 0;
  final int pageSize = 15;
  bool isLastPage = false;
  final isMoreLoading = false.obs;
  bool isSending = false;

  Future<void> getDataInit() async {
    page = 0;
    await getData(page);
  }

  Future<void> getData(int page) async {
    try {
      if (page == 0) {
        listCtrl.sink.add(ResStream.loading());
        list.clear();
      }
      isSending = true;

      final repo = AlramRepo();
      final reqData = AlramReqData()
        ..receiverCustId = AuthCntr.to.custId.value
        ..senderCustId = ''
        ..alramCd = ''
        ..pageNum = page
        ..pageSize = pageSize;

      final res = await repo.getAlramList(reqData);

      if (res.data == null) {
        isLastPage = true;
        isSending = false;

        listCtrl.sink.add(ResStream.completed(list));
        return;
      }

      final newList = (res.data as List).map((data) => AlramResData.fromMap(data)).toList();
      list.addAll(newList);

      if (newList.length < pageSize) {
        isLastPage = true;
      }

      isMoreLoading.value = false;
      listCtrl.sink.add(ResStream.completed(list));
    } catch (e) {
      listCtrl.sink.add(ResStream.error(e.toString()));
    } finally {
      isSending = false;
    }
  }

  @override
  void onClose() {
    listCtrl.close();
    super.onClose();
  }
}
