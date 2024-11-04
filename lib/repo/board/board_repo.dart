import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';
import 'package:project1/config/url_config.dart';
import 'package:project1/repo/api/auth_dio.dart';
import 'package:project1/repo/board/data/board_comment_data.dart';
import 'package:project1/repo/board/data/board_comment_update_req_data.dart';
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

  Future<ResData> searchBoardListByMaplonlatAndDay(LatLng southWest, LatLng northEast, int day, int pageNum, int pageSize) async {
    final dio = await AuthDio.instance.getDio();
    try {
      String minX = southWest.longitude.toString();
      String minY = southWest.latitude.toString();

      String maxX = northEast.longitude.toString();
      String maxY = northEast.latitude.toString();

      var url = '${UrlConfig.baseURL}/board/searchBoardListByMaplonlatAndDay';

      Response response = await dio
          .post(url, data: {'minX': minX, 'minY': minY, 'maxX': maxX, 'maxY': maxY, 'day': day, 'pageNum': pageNum, 'pageSize': pageSize});
      return AuthDio.instance.dioResponse(response);
    } on DioException catch (e) {
      return AuthDio.instance.dioException(e);
    } finally {}
  }

  Future<ResData> searchOriginList(String typeCd, String typeDtCd, int pageNum, int pageSize, String topYn) async {
    final dio = await AuthDio.instance.getDio();
    try {
      var url = '${UrlConfig.baseURL}/board/searchOriginList';

      Response response =
          await dio.post(url, data: {'typeCd': typeCd, 'typeDtCd': typeDtCd, 'pageNum': pageNum, 'pageSize': pageSize, "topYn": topYn});
      return AuthDio.instance.dioResponse(response);
    } on DioException catch (e) {
      return AuthDio.instance.dioException(e);
    } finally {}
  }

  // 댓글 조회
  Future<ResData> searchComment(String boardId, int pageNum, int pageSize) async {
    final dio = await AuthDio.instance.getDio(debug: false);
    try {
      var url = '${UrlConfig.baseURL}/board/searchComment';
      Response response = await dio.post(url, data: {'parentId': boardId, 'pageNum': pageNum, 'pageSize': pageSize});
      return AuthDio.instance.dioResponse(response);
    } on DioException catch (e) {
      return AuthDio.instance.dioException(e);
    } finally {}
  }

  // 좋아요 클릭시
  Future<ResData> like(String boardId, String custId, String pushYn, {String? alramCd}) async {
    final dio = await AuthDio.instance.getDio(debug: true);
    try {
      var url = '${UrlConfig.baseURL}/like/save?boardId=$boardId&custId=$custId&pushYn=$pushYn&alramCd=$alramCd';
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

  //신고하기
  Future<ResData> saveSingo(String boardId, String reasonCd, String custId, String reason) async {
    final dio = await AuthDio.instance.getDio();
    try {
      var url = '${UrlConfig.baseURL}/singo/save';
      Response response =
          await dio.post(url, queryParameters: {'boardId': boardId, 'reasonCd': reasonCd, 'custId': custId, 'reason': reason});
      return AuthDio.instance.dioResponse(response);
    } on DioException catch (e) {
      return AuthDio.instance.dioException(e);
    } finally {}
  }

  // 거리 + 태그 + 관심지역 3개 쿼리를 유니온으로 데이터 조회
  Future<ResData> getTotalBoardList(String lat, String lon, int pageNum, int pageSize) async {
    final dio = await AuthDio.instance.getDio(debug: true);
    try {
      var url = '${UrlConfig.baseURL}/board/getTotalBoardList';

      Response response = await dio.post(url, data: {'lat': lat, 'lon': lon, 'pageNum': pageNum, 'pageSize': pageSize});
      return AuthDio.instance.dioResponse(response);
    } on DioException catch (e) {
      return AuthDio.instance.dioException(e);
    } finally {}
  }

  // 관심지역  쿼리로 데이터 조회
  Future<ResData> getLocalBoardList(String lat, String lon, int pageNum, int pageSize) async {
    final dio = await AuthDio.instance.getDio();
    try {
      var url = '${UrlConfig.baseURL}/board/getLocalBoardList';

      Response response = await dio.post(url, data: {'lat': lat, 'lon': lon, 'pageNum': pageNum, 'pageSize': pageSize});
      return AuthDio.instance.dioResponse(response);
    } on DioException catch (e) {
      return AuthDio.instance.dioException(e);
    } finally {}
  }

  // 태그  쿼리로 데이터 조회
  Future<ResData> getTagBoardList(String lat, String lon, int pageNum, int pageSize) async {
    final dio = await AuthDio.instance.getDio();
    try {
      var url = '${UrlConfig.baseURL}/board/getTagBoardList';

      Response response = await dio.post(url, data: {'lat': lat, 'lon': lon, 'pageNum': pageNum, 'pageSize': pageSize});
      return AuthDio.instance.dioResponse(response);
    } on DioException catch (e) {
      return AuthDio.instance.dioException(e);
    } finally {}
  }

  // 거리  쿼리로 데이터 조회
  Future<ResData> getDistinceBoardList(String lat, String lon, int pageNum, int pageSize) async {
    final dio = await AuthDio.instance.getDio();
    try {
      var url = '${UrlConfig.baseURL}/board/getDistinceBoardList';

      Response response = await dio.post(url, data: {'lat': lat, 'lon': lon, 'pageNum': pageNum, 'pageSize': pageSize});
      return AuthDio.instance.dioResponse(response);
    } on DioException catch (e) {
      return AuthDio.instance.dioException(e);
    } finally {}
  }

  //  follow  쿼리로 데이터 조회
  Future<ResData> getFollowBoardList(String lat, String lon, int pageNum, int pageSize) async {
    final dio = await AuthDio.instance.getDio();
    try {
      var url = '${UrlConfig.baseURL}/board/getFollowBoardList';

      Response response = await dio.post(url, data: {'lat': lat, 'lon': lon, 'pageNum': pageNum, 'pageSize': pageSize});
      return AuthDio.instance.dioResponse(response);
    } on DioException catch (e) {
      return AuthDio.instance.dioException(e);
    } finally {}
  }
}
