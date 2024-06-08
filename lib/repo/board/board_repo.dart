import 'package:dio/dio.dart';
import 'package:project1/config/url_config.dart';
import 'package:project1/repo/api/auth_dio.dart';
import 'package:project1/repo/board/data/board_save_data.dart';
import 'package:project1/repo/common/res_data.dart';

class BoardRepo {
  final dio = authDio();

  // Board 저장
  Future<ResData> save(BoardSaveData data) async {
    try {
      var url = '${UrlConfig.baseURL}/board/saveAll';
      Response response = await dio.post(url, data: data.toJson());
      return dioResponse(response);
    } on DioException catch (e) {
      return dioException(e);
    } finally {}
  }

  // Board 조회
//   {
//   "lat": "37.5683",
//   "lon": "126.9778",
//   "custId": false,
//   "followCustId": false,
//   "pageNum": 1,
//   "pageSize": 2
// }
  Future<ResData> list(String lat, String lon, int pageNum, int pageSize) async {
    try {
      var url = '${UrlConfig.baseURL}/board/searchBoardBylatlon';

      Response response = await dio.post(url, data: {'lat': lat, 'lon': lon, 'pageNum': pageNum, 'pageSize': pageSize});
      return dioResponse(response);
    } on DioException catch (e) {
      return dioException(e);
    } finally {}
  }

  Future<ResData> searchOriginList(String typeCd, String typeDtCd, int pageNum, int pageSize) async {
    try {
      var url = '${UrlConfig.baseURL}/board/searchOriginList';

      Response response =
          await dio.post(url, data: {'typeCd': typeCd, 'typeDtCd': typeDtCd, 'pageNum': pageNum, 'pageSize': pageSize, "topYn": "N"});
      return dioResponse(response);
    } on DioException catch (e) {
      return dioException(e);
    } finally {}
  }

  // 댓글 조회
  Future<ResData> searchComment(String boardId, int pageNum, int pageSize) async {
    try {
      var url = '${UrlConfig.baseURL}/board/searchComment';
      Response response = await dio.post(url, data: {'boardId': boardId, 'pageNum': pageNum, 'pageSize': pageSize});
      return dioResponse(response);
    } on DioException catch (e) {
      return dioException(e);
    } finally {}
  }

  // 댓글 저장
  Future<ResData> saveComment(String boardId, String comment) async {
    try {
      var url = '${UrlConfig.baseURL}/board/saveComment';
      Response response = await dio.post(url, data: {'boardId': boardId, 'comment': comment});
      return dioResponse(response);
    } on DioException catch (e) {
      return dioException(e);
    } finally {}
  }

  // 좋아요 클릭시
  Future<ResData> like(String boardId) async {
    try {
      var url = '${UrlConfig.baseURL}/like/save?boardId=$boardId';
      Response response = await dio.post(url);
      return dioResponse(response);
    } on DioException catch (e) {
      return dioException(e);
    } finally {}
  }

  // 좋아요 취소 클릭시
  Future<ResData> likeCancle(String boardId) async {
    try {
      var url = '${UrlConfig.baseURL}/like/cancle?boardId=$boardId';
      Response response = await dio.post(url);
      return dioResponse(response);
    } on DioException catch (e) {
      return dioException(e);
    } finally {}
  }

  // follow 클릭시
  Future<ResData> follow(String followCustId) async {
    try {
      var url = '${UrlConfig.baseURL}/follow/save?custId=$followCustId';
      Response response = await dio.post(url);
      return dioResponse(response);
    } on DioException catch (e) {
      return dioException(e);
    } finally {}
  }

  // follow 클릭시
  Future<ResData> followCancle(String followCustId) async {
    try {
      var url = '${UrlConfig.baseURL}/follow/cancle?custId=$followCustId';
      Response response = await dio.post(url);
      return dioResponse(response);
    } on DioException catch (e) {
      return dioException(e);
    } finally {}
  }

  // follow list 가져오기
  Future<ResData> getFollowList(int followType, String custId) async {
    try {
      var url0 = '${UrlConfig.baseURL}/follow/getFollowList?custId=$custId';
      var url1 = '${UrlConfig.baseURL}/follow/getFollowerList?custId=$custId';

      Response response = await dio.post(followType == 0 ? url0 : url1);
      return dioResponse(response);
    } on DioException catch (e) {
      return dioException(e);
    } finally {}
  }

  // 내정보 > 게시물,팔로워,팔로잉 갯ㅅ수 가져오기
  Future<ResData> getCustCount(String custId) async {
    try {
      var url = '${UrlConfig.baseURL}/board/getCustCount?custId=$custId';
      Response response = await dio.post(url);
      return dioResponse(response);
    } on DioException catch (e) {
      return dioException(e);
    } finally {}
  }

  // 내 게시물 가져오기
  Future<ResData> getMyBoard(String custId, int pageNum, int pageSize) async {
    try {
      var url = '${UrlConfig.baseURL}/board/getMyBoard?custId=$custId&pageNum=$pageNum&pageSize=$pageSize';
      Response response = await dio.post(url);
      return dioResponse(response);
    } on DioException catch (e) {
      return dioException(e);
    } finally {}
  }

  // 팔로우 게시물 가져오기
  Future<ResData> getFollowBoard(String custId, int pageNum, int pageSize) async {
    try {
      var url = '${UrlConfig.baseURL}/board/getFollowBoard?custId=$custId&pageNum=$pageNum&pageSize=$pageSize';
      Response response = await dio.post(url);
      return dioResponse(response);
    } on DioException catch (e) {
      return dioException(e);
    } finally {}
  }

  // 공지사항 등등 일반 게시물 단건 조회
  Future<ResData> getDefBoardByBoardId(String baardId) async {
    try {
      var url = '${UrlConfig.baseURL}/board/findBoardById?boardId=$baardId';
      Response response = await dio.post(url);
      return dioResponse(response);
    } on DioException catch (e) {
      return dioException(e);
    } finally {}
  }

  // 검생어로 조회하기
  Future<ResData> getSearchBoard(String lat, String lon, int pageNum, int pageSize, String searchWord) async {
    try {
      var url = '${UrlConfig.baseURL}/board/getSearchBoard';
      Response response =
          await dio.post(url, data: {'lat': lat, 'lon': lon, 'pageNum': pageNum, 'pageSize': pageSize, 'searchWord': searchWord});
      return dioResponse(response);
    } on DioException catch (e) {
      return dioException(e);
    } finally {}
  }

  // follow alram y/n 변경
  Future<ResData> changeFollowAlram(String custId, String alramYn) async {
    try {
      var url = '${UrlConfig.baseURL}/follow/updateAlramYn?custId=$custId&alramYn=$alramYn';
      Response response = await dio.post(url);
      return dioResponse(response);
    } on DioException catch (e) {
      return dioException(e);
    } finally {}
  }
}
