import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';
import 'package:project1/config/url_config.dart';
import 'package:project1/repo/api/auth_dio.dart';
import 'package:project1/repo/board/data/board_comment_data.dart';
import 'package:project1/repo/board/data/board_save_data.dart';
import 'package:project1/repo/board/data/board_update_data.dart';
import 'package:project1/repo/common/res_data.dart';

class BoardRepo {
  // Board 저장
  Future<ResData> save(BoardSaveData data) async {
    final dio = await AuthDio.instance.getDio();
    try {
      var url = '${UrlConfig.baseURL}/board/saveAll';
      Response response = await dio.post(url, data: data.toJson());
      return AuthDio.instance.dioResponse(response);
    } on DioException catch (e) {
      return AuthDio.instance.dioException(e);
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
  Future<ResData> searchBoardBylatlon(String lat, String lon, int pageNum, int pageSize) async {
    final dio = await AuthDio.instance.getDio();
    try {
      var url = '${UrlConfig.baseURL}/board/searchBoardBylatlon';

      Response response = await dio.post(url, data: {'lat': lat, 'lon': lon, 'pageNum': pageNum, 'pageSize': pageSize});
      return AuthDio.instance.dioResponse(response);
    } on DioException catch (e) {
      return AuthDio.instance.dioException(e);
    } finally {}
  }

  Future<ResData> searchBoardListByMaplonlat(LatLng southWest, LatLng northEast, int pageNum, int pageSize) async {
    final dio = await AuthDio.instance.getDio();
    try {
      String minX = southWest.longitude.toString();
      String minY = southWest.latitude.toString();

      String maxX = northEast.longitude.toString();
      String maxY = northEast.latitude.toString();

      var url = '${UrlConfig.baseURL}/board/searchBoardListByMaplonlat';

      Response response =
          await dio.post(url, data: {'minX': minX, 'minY': minY, 'maxX': maxX, 'maxY': maxY, 'pageNum': pageNum, 'pageSize': pageSize});
      return AuthDio.instance.dioResponse(response);
    } on DioException catch (e) {
      return AuthDio.instance.dioException(e);
    } finally {}
  }

  Future<ResData> searchOriginList(String typeCd, String typeDtCd, int pageNum, int pageSize) async {
    final dio = await AuthDio.instance.getDio();
    try {
      var url = '${UrlConfig.baseURL}/board/searchOriginList';

      Response response =
          await dio.post(url, data: {'typeCd': typeCd, 'typeDtCd': typeDtCd, 'pageNum': pageNum, 'pageSize': pageSize, "topYn": "N"});
      return AuthDio.instance.dioResponse(response);
    } on DioException catch (e) {
      return AuthDio.instance.dioException(e);
    } finally {}
  }

  // 댓글 조회
  Future<ResData> searchComment(String boardId, int pageNum, int pageSize) async {
    final dio = await AuthDio.instance.getDio();
    try {
      var url = '${UrlConfig.baseURL}/board/searchComment';
      Response response = await dio.post(url, data: {'parentId': boardId, 'pageNum': pageNum, 'pageSize': pageSize});
      return AuthDio.instance.dioResponse(response);
    } on DioException catch (e) {
      return AuthDio.instance.dioException(e);
    } finally {}
  }

  // 좋아요 클릭시
  Future<ResData> like(String boardId, String custId, String pushYn) async {
    final dio = await AuthDio.instance.getDio();
    try {
      var url = '${UrlConfig.baseURL}/like/save?boardId=$boardId&custId=$custId%pushYn=$pushYn';
      Response response = await dio.post(url);
      return AuthDio.instance.dioResponse(response);
    } on DioException catch (e) {
      return AuthDio.instance.dioException(e);
    } finally {}
  }

  // 좋아요 취소 클릭시
  Future<ResData> likeCancle(String boardId) async {
    final dio = await AuthDio.instance.getDio();
    try {
      var url = '${UrlConfig.baseURL}/like/cancle?boardId=$boardId';
      Response response = await dio.post(url);
      return AuthDio.instance.dioResponse(response);
    } on DioException catch (e) {
      return AuthDio.instance.dioException(e);
    } finally {}
  }

  // follow 클릭시
  Future<ResData> follow(String followCustId) async {
    final dio = await AuthDio.instance.getDio();
    try {
      var url = '${UrlConfig.baseURL}/follow/save?custId=$followCustId';
      Response response = await dio.post(url);
      return AuthDio.instance.dioResponse(response);
    } on DioException catch (e) {
      return AuthDio.instance.dioException(e);
    } finally {}
  }

  // follow 클릭시
  Future<ResData> followCancle(String followCustId) async {
    final dio = await AuthDio.instance.getDio();
    try {
      var url = '${UrlConfig.baseURL}/follow/cancle?custId=$followCustId';
      Response response = await dio.post(url);
      return AuthDio.instance.dioResponse(response);
    } on DioException catch (e) {
      return AuthDio.instance.dioException(e);
    } finally {}
  }

  // follow list 가져오기
  Future<ResData> getFollowList(int followType, String custId) async {
    final dio = await AuthDio.instance.getDio();
    try {
      var url0 = '${UrlConfig.baseURL}/follow/getFollowList?custId=$custId';
      var url1 = '${UrlConfig.baseURL}/follow/getFollowingList?custId=$custId';

      Response response = await dio.post(followType == 1 ? url0 : url1);
      return AuthDio.instance.dioResponse(response);
    } on DioException catch (e) {
      return AuthDio.instance.dioException(e);
    } finally {}
  }

  // 내정보 > 게시물,팔로워,팔로잉 갯ㅅ수 가져오기
  Future<ResData> getCustCount(String custId) async {
    final dio = await AuthDio.instance.getDio();
    try {
      var url = '${UrlConfig.baseURL}/board/getCustCount?custId=$custId';
      Response response = await dio.post(url);
      return AuthDio.instance.dioResponse(response);
    } on DioException catch (e) {
      return AuthDio.instance.dioException(e);
    } finally {}
  }

  // 내 게시물 가져오기
  Future<ResData> getMyBoard(String custId, int pageNum, int pageSize) async {
    final dio = await AuthDio.instance.getDio();
    try {
      var url = '${UrlConfig.baseURL}/board/getMyBoard?custId=$custId&pageNum=$pageNum&pageSize=$pageSize';
      Response response = await dio.post(url);
      return AuthDio.instance.dioResponse(response);
    } on DioException catch (e) {
      return AuthDio.instance.dioException(e);
    } finally {}
  }

  // boardId로 게시물 가져오기
  Future<ResData> getBoardByBoardId(String boardId) async {
    final dio = await AuthDio.instance.getDio();
    try {
      var url = '${UrlConfig.baseURL}/board/getBoardByBoardId?boardId=$boardId';
      Response response = await dio.post(url);
      return AuthDio.instance.dioResponse(response);
    } on DioException catch (e) {
      return AuthDio.instance.dioException(e);
    } finally {}
  }

  // 팔로우 게시물 가져오기
  Future<ResData> getFollowBoard(String custId, int pageNum, int pageSize) async {
    final dio = await AuthDio.instance.getDio();
    try {
      var url = '${UrlConfig.baseURL}/board/getFollowBoard?custId=$custId&pageNum=$pageNum&pageSize=$pageSize';
      Response response = await dio.post(url);
      return AuthDio.instance.dioResponse(response);
    } on DioException catch (e) {
      return AuthDio.instance.dioException(e);
    } finally {}
  }

  // 내가 List 게시물 가져오기\
  Future<ResData> getLikeBoard(String custId, int pageNum, int pageSize) async {
    final dio = await AuthDio.instance.getDio();
    try {
      var url = '${UrlConfig.baseURL}/board/getLikeBoard?custId=$custId&pageNum=$pageNum&pageSize=$pageSize';
      Response response = await dio.post(url);
      return AuthDio.instance.dioResponse(response);
    } on DioException catch (e) {
      return AuthDio.instance.dioException(e);
    } finally {}
  }

  // 공지사항 등등 일반 게시물 단건 조회
  Future<ResData> getDefBoardByBoardId(String baardId) async {
    final dio = await AuthDio.instance.getDio();
    try {
      var url = '${UrlConfig.baseURL}/board/findBoardById?boardId=$baardId';
      Response response = await dio.post(url);
      return AuthDio.instance.dioResponse(response);
    } on DioException catch (e) {
      return AuthDio.instance.dioException(e);
    } finally {}
  }

  // 검생어로 조회하기
  Future<ResData> getSearchBoard(String lat, String lon, int pageNum, int pageSize, String searchWord) async {
    final dio = await AuthDio.instance.getDio();
    try {
      var url = '${UrlConfig.baseURL}/board/getSearchBoard';
      Response response =
          await dio.post(url, data: {'lat': lat, 'lon': lon, 'pageNum': pageNum, 'pageSize': pageSize, 'searchWord': searchWord});
      return AuthDio.instance.dioResponse(response);
    } on DioException catch (e) {
      return AuthDio.instance.dioException(e);
    } finally {}
  }

  // follow alram y/n 변경
  Future<ResData> changeFollowAlram(String custId, String alramYn) async {
    final dio = await AuthDio.instance.getDio();
    try {
      var url = '${UrlConfig.baseURL}/follow/updateAlramYn?custId=$custId&alramYn=$alramYn';
      Response response = await dio.post(url);
      return AuthDio.instance.dioResponse(response);
    } on DioException catch (e) {
      return AuthDio.instance.dioException(e);
    } finally {}
  }

  // 카운트수 올리기
  Future<ResData> updateBoardCount(String boardId) async {
    final dio = await AuthDio.instance.getDio();
    try {
      var url = '${UrlConfig.baseURL}/view/crtviewcount?boardId=$boardId';
      Response response = await dio.post(url);
      return AuthDio.instance.dioResponse(response);
    } on DioException catch (e) {
      return AuthDio.instance.dioException(e);
    } finally {}
  }

  // 댓글 달기
  Future<ResData> saveComment(BoardCommentData data) async {
    final dio = await AuthDio.instance.getDio();
    try {
      var url = '${UrlConfig.baseURL}/board/saveComment';
      Response response = await dio.post(url, data: data.toJson());
      return AuthDio.instance.dioResponse(response);
    } on DioException catch (e) {
      return AuthDio.instance.dioException(e);
    } finally {}
  }

  //
  Future<ResData> updateBoard(BoardUpdateData data) async {
    final dio = await AuthDio.instance.getDio();
    try {
      var url = '${UrlConfig.baseURL}/board/updateBoard';
      Response response = await dio.post(url, data: data.toJson());
      return AuthDio.instance.dioResponse(response);
    } on DioException catch (e) {
      return AuthDio.instance.dioException(e);
    } finally {}
  }
}
