import 'dart:async';
import 'dart:io';

import 'package:cloudflare/cloudflare.dart';
import 'package:dio/dio.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:project1/config/url_config.dart';
import 'package:project1/repo/api/auth_dio.dart';
import 'package:project1/repo/cloudflare/data/cloudflare_req_save_data.dart';
import 'package:project1/repo/common/res_data.dart';
import 'package:project1/utils/log_utils.dart';
import 'package:project1/utils/utils.dart';

// acountId:ad6b2fffd96d70c66c0c32fa5aeefdf3
// https://ad6b2fffd96d70c66c0c32fa5aeefdf3.r2.cloudflarestorage.com
// var cloudflare = Cloudflare(
//   // apiUrl: 'https://api.cloudflare.com/client/v4',
//   accountId: 'ad6b2fffd96d70c66c0c32fa5aeefdf3',
//   token: 'ZYEgrnJDPreio35s73cYSANoajaY7FXz',
//   // apiKey: 'SBAhvasTLyxb9QFL9S6WSD11UGuaDvR_4io4Y-ag',
//   // accountEmail: 'rambozzang@gmail.com',
//   // userServiceKey: userServiceKey,
//   // httpClient: Dio(),
// );

/*
curl -X GET "https://api.cloudflare.com/client/v4/user/tokens/verify" \
     -H "Authorization: Bearer SBAhvasTLyxb9QFL9S6WSD11UGuaDvR_4io4Y-ag" \
     -H "Content-Type:application/json"
     */
class CloudflareRepo {
  var cloudflare = Cloudflare.basic(apiUrl: 'https://api.cloudflare.com/client/v4');
  String token = 'POZZTG-V4np3iP8M8vJDscMcgHmiRXjSwFMQ21-9';
  String accountId = '1227ead63607f2c82ce09310ce378241';
  String apiKey = 'cd5249e49356cddf0c63d6594905d557dc2e3';
  String accountEmail = 'tigerbk007@gmail.com';
  String apiUrl = 'https://api.cloudflare.com/client/v4';

  init() async {
    // cloudflare = Cloudflare(
    //     apiUrl: 'https://api.cloudflare.com/client/v4',
    //     accountId: 'ad6b2fffd96d70c66c0c32fa5aeefdf3',
    //     token: 'ZYEgrnJDPreio35s73cYSANoajaY7FXz',
    //      apiKey: '1f3a9a77a16a1681409ac75e062eefbcc3de2'  // global api key
    //     apiKey:
    //         'v1.0-1ca22889d828b6a0e0d3c9aa-6e3e45fcbcd54b7aaec99c260d19f0aa7feb93e1c8d74051bd4fe9d781938c5e82737ad443a02db1b9ab3eda5b0642f5b69b7de79fecf7759b1b663c4ef4826ac1945aff05dbf197ba' // origin key
    //     );

    // tigerbk007
    // api token : POZZTG-V4np3iP8M8vJDscMcgHmiRXjSwFMQ21-9  => header : Authorization: Bearer POZZTG-V4np3iP8M8vJDscMcgHmiRXjSwFMQ21-9
    // apikey : cd5249e49356cddf0c63d6594905d557dc2e3 (global)
    // Stream
    // customer-r151saam0lb88khc.cloudflarestream.com

    // 이미지
    // 계정 ID : 1227ead63607f2c82ce09310ce378241
    // 계정 해시 : 9YWIIqEOHWVHkJjEYps8eQ
    // 이미지 제공 : https://imagedelivery.net/9YWIIqEOHWVHkJjEYps8eQ/<image_id>/<variant_name>

    cloudflare = Cloudflare(apiUrl: apiUrl, accountEmail: accountEmail, token: token, accountId: accountId, apiKey: apiKey);

    await cloudflare.init();
  }

  Future<void> imageFileDirectUpload(File imageFile, DataUploadDraft dataUploadDraft) async {
    final response = await cloudflare.imageAPI.directUpload(
        dataUploadDraft: dataUploadDraft!,
        contentFromFile: DataTransmit<File>(
            data: imageFile,
            progressCallback: (count, total) {
              print('Image upload to direct upload URL from file: $count/$total');
            }));
  }

  Future<CloudflareHTTPResponse<CloudflareImage?>?> imageFileUpload(File imageFile) async {
    //From file
    CloudflareHTTPResponse<CloudflareImage?> response = await cloudflare.imageAPI.upload(
      contentFromFile: DataTransmit<File>(
          data: imageFile,
          progressCallback: (count, total) {
            print('Upload progress: $count/$total');
          }),
      // metadata: {
      //   'name': 'imageFileUpload',
      //   'description': 'imageFileUpload',
      //   'tags': ['imageFileUpload', 'imageFileUpload'],
      // },
    );
    if (response.base.statusCode != 200) {
      lo.g("videoStreamUpload > CloudflareHTTPResponse : ${response.base.statusCode}");
      lo.g("videoStreamUpload > CloudflareHTTPResponse : ${response.base.reasonPhrase}");
      Utils.alert("비디오 업로드에 실패했습니다. ${response.base.reasonPhrase}");
      return null;
    }
    // lo.g("imageFileUpload > CloudflareHTTPResponse : ${response.base.statusCode}");
    return response;
  }

  Future<void> imagePathUpload(String imagePath) async {
    //From path
    CloudflareHTTPResponse<CloudflareImage?> responseFromPath = await cloudflare.imageAPI.upload(
        contentFromPath: DataTransmit<String>(
            data: imagePath,
            progressCallback: (count, total) {
              print('Upload progress: $count/$total');
            }));
  }

  // 이미지 가져오기
  Future<void> imageGet(String imageId) async {
    //Get image
    CloudflareHTTPResponse<CloudflareImage?> response = await cloudflare.imageAPI.get(id: imageId);
  }

  // 이미지 삭제
  Future<void> imageDelete(String imageId) async {
    //Delete image
    final response = await cloudflare.imageAPI.delete(id: imageId);
  }

  // 비디오 업로드
  Future<void> videoFileUpload(File videoFile) async {
    //From file
    // CloudflareHTTPResponse<CloudflareVideo?> responseFromFile = await cloudflare.videoAPI.upload(
    //     contentFromFile: DataTransmit<File>(
    //         data: videoFile,
    //         progressCallback: (count, total) {
    //           print('Upload progress: $count/$total');
    //         }));
  }

  // 비디오 Stream 업로드
  Future<CloudflareHTTPResponse<CloudflareStreamVideo?>?> videoStreamUpload(File videoFile) async {
    //From file
    CloudflareHTTPResponse<CloudflareStreamVideo?> response = await cloudflare.streamAPI.stream(
        contentFromFile: DataTransmit<File>(
            data: videoFile,
            progressCallback: (count, total) {
              Lo.g('Stream video progress: $count/$total');
            }));
    // if (response.base.statusCode != 200) {
    //   lo.g("videoStreamUpload > CloudflareHTTPResponse : ${response.base.statusCode}");
    //   lo.g("videoStreamUpload > CloudflareHTTPResponse : ${response.base.toString()}");
    //   Utils.alert("비디오 업로드에 실패했습니다. ${response.base.reasonPhrase}");
    // }
    // lo.g("videoStreamUpload > CloudflareHTTPResponse : ${response.base.statusCode}");
    return response;
  }

  // mp4 비디오 가져오기(cloudflare stream 에 mp4 생성요청 및 다운로드 URL 반환)
  Future videoDownload(String videoId) async {
    //Get video
    try {
      final dio = Dio();
      dio.interceptors.add(PrettyDioLogger(
        requestHeader: true,
        requestBody: true,
        responseBody: true,
        responseHeader: true,
        error: true,
        compact: true,
        maxWidth: 120,
      ));

      final response = await dio.post('https://api.cloudflare.com/client/v4/accounts/$accountId/stream/$videoId/downloads',
          options: Options(
            headers: {
              'Authorization': 'Bearer $token',
            },
          ));
      return response.data;
    } catch (e) {
      lo.g(e.toString());
    }
  }

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
