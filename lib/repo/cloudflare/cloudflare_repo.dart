import 'package:dio/dio.dart';
import 'package:project1/config/url_config.dart';
import 'package:project1/repo/api/auth_dio.dart';
import 'package:project1/repo/cloudflare/data/cloudflare_req_save_data.dart';
import 'package:project1/repo/common/res_data.dart';

/// Cloudflare 업로드 메타데이터를 백엔드에 저장하는 repo.
/// 실제 파일 업로드는 [DirectUploadRepo] 사용 — Cloudflare 자격증명은 앱에 존재하지 않는다.
class CloudflareRepo {
  Future<ResData> save(CloudflareReqSaveData data) async {
    final dio = await AuthDio.instance.getDio();
    try {
      var url = '${UrlConfig.baseURL}/cloudflare/save';
      Response response = await dio.post(url, data: data.toJson());
      return AuthDio.instance.dioResponse(response);
    } on DioException catch (e) {
      return AuthDio.instance.dioException(e);
    } finally {}
  }
}
