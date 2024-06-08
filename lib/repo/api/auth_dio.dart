// auth_dio.dart

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:dio/src/response.dart' as R;
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:project1/app/auth/cntr/auth_cntr.dart';

import 'dart:developer' as d;

import 'package:project1/config/url_config.dart';
import 'package:project1/repo/common/res_data.dart';
import 'package:project1/utils/StringUtils.dart';

Dio authDio() {
  final dio = Dio(BaseOptions(
      headers: {'Content-Type': 'application/json', 'accept': 'application/json'},
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 60)));

  dio.interceptors.clear();
  dio.interceptors.add(interceptorsWrapper(dio));
  // dio.interceptors.add(PrettyDioLogger(
  //   requestHeader: true,
  //   requestBody: true,
  //   responseBody: true,
  //   responseHeader: true,
  //   error: true,
  //   compact: true,
  //   maxWidth: 120,
  // ));

  return dio;
}

Future<dynamic> getRefreshToken() async {
  String? aToken = AuthCntr.to.resLoginData.value.accessToken;
  String? rToken = AuthCntr.to.resLoginData.value.refreshToken;
  final rDio = Dio();

  rDio.interceptors.clear();
  rDio.interceptors.add(refreshInterCepter());

  final refreshResponse = await rDio.request(
    '${UrlConfig.baseURL}/auth/refreshtoken',
    data: {'accessToken': aToken ?? 'aa', 'refreshToken': rToken ?? 'bvb'},
    options: Options(method: 'POST'),
  );

  final rMap = json.decode(refreshResponse.toString());
  final naToken = rMap["accessToken"];
  final nrToken = rMap["refreshToken"];

  if (naToken == "") {
    return naToken;
  }

  d.log("[새로운 토큰 발급 완료]");
  d.log("newAccessToken : $naToken");

  AuthCntr.to.resLoginData.value.accessToken = naToken;
  AuthCntr.to.resLoginData.value.refreshToken = (nrToken);

  // AuthCntr.to.saveStorgeAll(TokenData(
  //     accessToken: naToken,
  //     refreshToken: nrToken,
  //     firebaseToken: "",
  //     userid: ""));

  return naToken;
}

InterceptorsWrapper interceptorsWrapper(dio) {
  return InterceptorsWrapper(onRequest: (options, handler) async {
    try {
      if (!StringUtils.isEmpty(AuthCntr.to.resLoginData.value.accessToken)) {
        options.headers['Authorization'] = 'Bearer ${AuthCntr.to.resLoginData.value.accessToken}';
      }
      return handler.next(options);
    } catch (e) {
      return handler.next(options);
    }
  }, onError: (error, handler) async {
    if (error.response?.statusCode == 401) {
      final naToken = await getRefreshToken() ?? '';
      if (naToken == "") {
        Get.snackbar("리플레쉬 토큰 오류!", "토큰이 재발급에 오류가 발생했습니다. 다시 로그인해주세요!");
        Get.offAllNamed('/login');
        return;
      }
      error.requestOptions.headers['Authorization'] = 'Bearer $naToken';
      dynamic clonedRequest;
      try {
        clonedRequest = await dio.request(error.requestOptions.path,
            options: Options(method: error.requestOptions.method, headers: error.requestOptions.headers),
            data: error.requestOptions.data,
            queryParameters: error.requestOptions.queryParameters);
      } catch (e) {
        e.printError();
      }
      return handler.resolve(clonedRequest);
    }

    // pring("error:  $ error.response?.statusCode");
    return handler.reject(error);
    //return handler.resolve(error.response!);
  });
}

InterceptorsWrapper refreshInterCepter() {
  return InterceptorsWrapper(onError: (error, handler) async {
    if (error.response?.statusCode != 200) {
      Get.snackbar("리플레쉬 토큰만료!", "토큰이 만료되었습니다. 다시 로그인해주세요!");
      Get.offAllNamed('/login');
    }
    return handler.next(error);
  });
}

ResData dioResponse(R.Response response) {
  if (response.statusCode == 200) {
    try {
      return ResData.fromMap(response.data);
    } catch (e1) {
      return ResData.fromJson(response.data);
    }
  }
  // 200이 아니면
  try {
    return ResData.fromMap(jsonDecode(response.toString()));
  } catch (e1) {
    return ResData.fromJson(jsonEncode(response.toString()));
  }
}

ResData dioException(DioException e) {
  String message = "모바일 네트워크 장애가 발생했습니다.  ${e.message}";
  debugPrint("========================================");
  debugPrint("###  DioException 2: ${e.response}");
  debugPrint("========================================");
  if (e.response != null) {
    try {
      message = ResData.fromMap(e.response!.data).msg!;
    } catch (e1) {
      try {
        message = ResData.fromJson(e.response!.data).msg!;
      } catch (e2) {
        return ResData(code: "99", msg: message);
      }
    }
  }

  return ResData(code: "99", msg: message);
}


// // abstract class AuthDio
// abstract class AuthDio {
//   AuthDio._();

//   static Dio run() {
//     final dio = Dio(BaseOptions(
//         headers: {'Content-Type': 'application/json', 'accept': 'application/json'},
//         connectTimeout: const Duration(seconds: 5),
//         receiveTimeout: const Duration(seconds: 60)));

//     dio.interceptors.clear();
//     dio.interceptors.add(interceptorsWrapper(dio));
//     dio.interceptors.add(PrettyDioLogger(
//       requestHeader: true,
//       requestBody: true,
//       responseBody: true,
//       responseHeader: true,
//       error: true,
//       compact: true,
//       maxWidth: 120,
//     ));

//     return dio;
//   }

//   static Future<dynamic> getRefreshToken() async {
//     String? aToken = AuthCntr.to.resLoginData.value.accessToken;
//     String? rToken = AuthCntr.to.resLoginData.value.refreshToken;
//     final rDio = Dio();

//     rDio.interceptors.clear();
//     rDio.interceptors.add(refreshInterCepter());

//     final refreshResponse = await rDio.request(
//       '${UrlConfig.baseURL}/auth/refreshtoken',
//       data: {'accessToken': aToken ?? 'aa', 'refreshToken': rToken ?? 'bvb'},
//       options: Options(method: 'POST'),
//     );

//     final rMap = json.decode(refreshResponse.toString());
//     final naToken = rMap["accessToken"];
//     final nrToken = rMap["refreshToken"];

//     if (naToken == "") {
//       return naToken;
//     }

//     d.log("[새로운 토큰 발급 완료]");
//     d.log("newAccessToken : $naToken");

//     AuthCntr.to.resLoginData.value.accessToken = naToken;
//     AuthCntr.to.resLoginData.value.refreshToken = (nrToken);

//     // AuthCntr.to.saveStorgeAll(TokenData(
//     //     accessToken: naToken,
//     //     refreshToken: nrToken,
//     //     firebaseToken: "",
//     //     userid: ""));

//     return naToken;
//   }

//   static InterceptorsWrapper interceptorsWrapper(dio) {
//     return InterceptorsWrapper(onRequest: (options, handler) async {
//       try {
//         if (!StringUtils.isEmpty(AuthCntr.to.resLoginData.value.accessToken)) {
//           options.headers['Authorization'] = 'Bearer ${AuthCntr.to.resLoginData.value.accessToken}';
//         }
//         return handler.next(options);
//       } catch (e) {
//         return handler.next(options);
//       }
//     }, onError: (error, handler) async {
//       if (error.response?.statusCode == 401) {
//         final naToken = await getRefreshToken() ?? '';
//         if (naToken == "") {
//           Get.snackbar("리플레쉬 토큰 오류!", "토큰이 재발급에 오류가 발생했습니다. 다시 로그인해주세요!");
//           Get.offAllNamed('/login');
//           return;
//         }
//         error.requestOptions.headers['Authorization'] = 'Bearer $naToken';
//         dynamic clonedRequest;
//         try {
//           clonedRequest = await dio.request(error.requestOptions.path,
//               options: Options(method: error.requestOptions.method, headers: error.requestOptions.headers),
//               data: error.requestOptions.data,
//               queryParameters: error.requestOptions.queryParameters);
//         } catch (e) {
//           e.printError();
//         }
//         return handler.resolve(clonedRequest);
//       }

//       // pring("error:  $ error.response?.statusCode");
//       return handler.reject(error);
//       //return handler.resolve(error.response!);
//     });
//   }

//   static InterceptorsWrapper refreshInterCepter() {
//     return InterceptorsWrapper(onError: (error, handler) async {
//       if (error.response?.statusCode != 200) {
//         Get.snackbar("리플레쉬 토큰만료!", "토큰이 만료되었습니다. 다시 로그인해주세요!");
//         Get.offAllNamed('/login');
//       }
//       return handler.next(error);
//     });
//   }

//   static ResData dioResponse(R.Response response) {
//     if (response.statusCode == 200) {
//       try {
//         return ResData.fromMap(response.data);
//       } catch (e1) {
//         return ResData.fromJson(response.data);
//       }
//     }
//     // 200이 아니면
//     try {
//       return ResData.fromMap(jsonDecode(response.toString()));
//     } catch (e1) {
//       return ResData.fromJson(jsonEncode(response.toString()));
//     }
//   }

//   static ResData dioException(DioException e) {
//     String message = "모바일 네트워크 장애가 발생했습니다.  ${e.message}";
//     debugPrint("========================================");
//     debugPrint("###  DioException 2: ${e.response}");
//     debugPrint("========================================");
//     if (e.response != null) {
//       try {
//         message = ResData.fromMap(e.response!.data).msg!;
//       } catch (e1) {
//         message = ResData.fromJson(e.response!.data).msg!;
//       }
//     }

//     return ResData(code: "99", msg: message);
//   }
// }
