import 'package:dio/dio.dart';
import 'package:project1/repo/api/auth_dio.dart';
import 'package:project1/repo/search/school/school_req_data.dart';
import 'package:project1/repo/search/school/school_res_data.dart';
import 'package:project1/utils/log_utils.dart';

class SchoolRepo {
  // api 상세 정보 : https://www.career.go.kr/cnet/front/openapi/openApiSchoolCenter.do

  String apiKey = '26dc748c10a29f1c899402458d88782c';
  String baseUrl = 'https://www.career.go.kr/cnet/openapi/getOpenApi';

// www.career.go.kr/cnet/openapi/getOpenApi?apiKey=26dc748c10a29f1c899402458d88782c&svcType=api&svcCode=SCHOOL&contentType=json&gubun=high_list&searchSchulNm=%EC%84%A0%EB%8D%95
// https://www.career.go.kr/cnet/front/openapi/openApiSchoolCenter.do?apiKey=26dc748c10a29f1c899402458d88782c&svcType=api&svcCode=SCHOOL&contentType=json&gubun=high_list&region&sch1&sch2&est&thisPage=1&perPage=100&searchSchulNm=%EC%84%A0%EB%8D%95
  Future<List<SchoolResData>> searchSchools(String searchWord, String gubun) async {
    try {
      // 기본 필수값
      SchoolReqData reqData = SchoolReqData();
      reqData.apiKey = apiKey;
      reqData.svcType = 'api';
      reqData.svcCode = 'SCHOOL';
      reqData.contentType = 'json';
      reqData.perPage = '100';
      reqData.thisPage = '1';
      reqData.searchSchulNm = searchWord;
      //초등 : elem_list ,  중학교 : middle_list, 고등학교 : high_list , 대학교 : univ_list ,  특수학교 : seet_list , 기타 : alte_list
      reqData.gubun = 'high_list';

      final dio = await AuthDio.instance.getNoAuthCathDio(cachehour: 1000);
      Response response = await dio.get(baseUrl, queryParameters: reqData.toMap());
      if (response.statusCode == 200) {
        List<SchoolResData> list = [];
        for (var item in response.data['dataSearch']['content']) {
          list.add(SchoolResData.fromMap(item));
        }
        return list;
      } else {
        lo.g('error');
        return [];
      }
    } catch (e) {
      lo.g(e.toString());
      return [];
    }
  }
}
