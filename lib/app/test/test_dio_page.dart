import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:project1/app/auth/cntr/auth_cntr.dart';
import 'package:project1/app/test/rain/RainAnimation.dart';
import 'package:project1/app/test/raindrop_page.dart';

import 'package:project1/app/test/snow/SnowAnimation.dart';
import 'package:project1/app/test/sun_page.dart';

import 'package:project1/app/weather/cntr/weather_cntr.dart';
import 'package:project1/app/weatherCom/api/OpenWeatherMapclient.dart';
import 'package:project1/app/weathergogo/naver_scrapping_page.dart';
import 'package:project1/repo/weather_accu/accu_repo.dart';
import 'package:project1/app/weathergogo/cntr/weather_gogo_cntr.dart';
import 'package:project1/repo/weather_gogo/models/request/weather.dart';
import 'package:project1/repo/weather_gogo/models/response/fct/fct_model.dart';
import 'package:project1/repo/weather_gogo/models/response/fct_version/fct_version_model.dart';
import 'package:project1/repo/weather_gogo/models/response/midland_fct/midlan_fct_res.dart';
import 'package:project1/repo/weather_gogo/models/response/midta_fct/midta_fct_res.dart';
import 'package:project1/repo/weather_gogo/models/response/super_fct/super_fct_model.dart';
import 'package:project1/repo/weather_gogo/models/response/super_nct/super_nct_model.dart';
import 'package:project1/repo/cloudflare/R2_repo.dart';
import 'package:project1/repo/cloudflare/cloudflare_repo.dart';
import 'package:project1/repo/common/res_data.dart';
import 'package:project1/repo/mist_gogoapi/data/mist_data.dart';
import 'package:project1/repo/mist_gogoapi/mist_repo.dart';
import 'package:project1/repo/search/camping/camping_repo.dart';
import 'package:project1/repo/search/camping/camping_res_data.dart';
import 'package:project1/repo/search/school/school_repo.dart';
import 'package:project1/repo/search/school/school_res_data.dart';
import 'package:project1/repo/weather_gogo/repository/weather_alert_repo.dart';
import 'package:project1/repo/weather_gogo/repository/weather_gogo_caching.dart';
import 'package:project1/repo/weather_gogo/repository/weather_gogo_repo.dart';
import 'package:project1/utils/log_utils.dart';
import 'package:project1/utils/utils.dart';

import 'package:dio/src/response.dart' as dioRes;

class TestDioPage extends StatefulWidget {
  const TestDioPage({super.key});

  @override
  State<TestDioPage> createState() => _TestDioPageState();
}

class _TestDioPageState extends State<TestDioPage> {
  ValueNotifier<String> result = ValueNotifier<String>('');

  @override
  void initState() {
    super.initState();
  }

  Future<void> getDownloadUrl() async {
    CloudflareRepo repo = CloudflareRepo();
    var res = await repo.videoDownload('1111');
    Lo.g(res.toString());
    // var resData = json.decode(res.toString());
    Lo.g('resData : ' + res['result']['default']['status']);
    Lo.g('resData : ' + res['result']['default']['url']);
    // return resData.data;
  }

/*
curl --location --request PUT 'https://<account-id>.r2.cloudflarestorage.com/<r2-bucket>/<r2-object>' \
--header 'x-amz-content-sha256: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855' \
--header 'Content-Type: image/jpeg' \
--header 'X-Amz-Date: 20240422T105842Z' \
--header 'Authorization: AWS4-HMAC-SHA256 Credential=<r2-access-key-id>/20240422/auto/s3/aws4_request, SignedHeaders=content-length;content-type;host;x-amz-content-sha256;x-amz-date, Signature=962dee932e746854ca9323dab255a844e39aba29900b84b6e4a456e50872f736' \
--data '@GPeeGZTRk/cat-pic.jpg'

*/

// s3 api url : https://1227ead63607f2c82ce09310ce378241.r2.cloudflarestorage.com/p1-video
// account ID : 1227ead63607f2c82ce09310ce378241
// R2 token value :
// R2 access key Id : d6c11b486c284e8792696f6c337b9361
// R2 secret key : 21538c58031ea22aee7dc6d1e35e4ca9a681a5cd0185c463de03b38e198ec121
// default bucket : p1-video
// default url : https://1227ead63607f2c82ce09310ce378241.r2.cloudflarestorage.com

// token : f0c2KVedF1U3o1bR9ld_bf3ZzlOC1NEhI6v1ck3L
// access key : 27d0910cb888ca37d3a8fe57941bd3c9
// secret key : 6cd711e2614f3e62233af3bd687bbd1cde177096f3d59496d40e60b9cd6cbb64
// default bucket : p1-video
// default url : https://1227ead63607f2c82ce09310ce378241.r2.cloudflarestorage.com
// aws signV4 생성 하기
// https://aws.amazon.com/ko/blogs/opensource/introducing-the-aws-sigv4-signer-for-dart/
// flutter run --dart-define=AWS_ACCESS_KEY_ID=27d0910cb888ca37d3a8fe57941bd3c9 --dart-define=AWS_SECRET_ACCESS_KEY=6cd711e2614f3e62233af3bd687bbd1cde177096f3d59496d40e60b9cd6cbb64

  Future<void> aaa() async {
    String today = Utils.getToday();
    ImagePicker imagePicker = ImagePicker();
    final XFile? image = await imagePicker.pickMedia();

    // String? response = await AwsS3.uploadFile(
    //   accountId: "1227ead63607f2c82ce09310ce378241",
    //   accessKey: "27d0910cb888ca37d3a8fe57941bd3c9",
    //   secretKey: "6cd711e2614f3e62233af3bd687bbd1cde177096f3d59496d40e60b9cd6cbb64",
    //   file: File(image!.path),
    //   bucket: "p1-video",
    //   region: "us-east-1", //"Asia-Pacific",
    //   destDir: today,
    //   filename: image.path.split('/').last,
    //   //metadata: {"test": "test"}
    // );
    // lo.g("AwsS3 response : $response");
    File myfile = File(image!.path);

    BucketUpload bucketUpload = BucketUpload('p1-video', 'us-east-1', myfile);
    R2Repo r2Repo = R2Repo();
    ResData resData = await r2Repo.uploadFile(bucketUpload);
  }

  // 미세먼지 가져오기 테스트
  // 미세먼지 가져오기
  void getMistData(String localName) async {
    try {
      MistRepo mistRepo = MistRepo();
      Lo.g('미세먼지 가져오기 시작 :  $localName');

      dioRes.Response? res = await mistRepo.getMistData(localName);
      MistData mistData = MistData.fromJson(jsonEncode(res!.data['response']['body']));

      result.value = mistData.items![0].pm10Value.toString() + ' / ' + mistData.items![0].pm25Value.toString() + '㎍/㎥';
    } catch (e) {
      Lo.g('미세먼지 가져오기 오류 : $e');
    }
  }

  // 캠핑장 예보 가져오기 CampingRepo
  void getCampingData(String localName) async {
    try {
      CampingRepo campingRepo = CampingRepo();

      List<CampingResData> res = await campingRepo.searchCamping(localName);

      lo.g('res : $res');
      // result.value = res.forEach((action) => lo.g(action.))!;
    } catch (e) {
      Lo.g('미세먼지 가져오기 오류 : $e');
    }
  }

  // 초중고대학교 정보 가져오기
  void getSchoolata(String localName, String gubun) async {
    try {
      SchoolRepo repo = SchoolRepo();

      List<SchoolResData> res = await repo.searchSchools(localName, gubun);
      // result.value = res.forEach((action) => lo.g(action.))!;
    } catch (e) {
      Lo.g('미세먼지 가져오기 오류 : $e');
    }
  }

  // 골프장 검색

  // 전국 전철역 검색
  String weatherKey = 'CeGmiV26lUPH9guq1Lca6UA25Al/aZlWD3Bm8kehJ73oqwWiG38eHxcTOnEUzwpXKY3Ur+t2iPaL/LtEQdZebg==';
  // 기상청 초단기실황 가져오기
  void getSuperNctCast() async {
    try {
      // 초단기실황조회
      final List<ItemSuperNct> items = [];
      WeatherGogoRepo repo = WeatherGogoRepo();
      // List<ItemSuperNct> json =
      //     await repo.getSuperNctListJson(const LatLng(37.5546788388674, 126.970606917394), isLog: true, isChache: false);
      WeatherService weatherService = WeatherService();
      // List<ItemSuperNct> json =
      //     await weatherService.getWeatherData<List<ItemSuperNct>>(const LatLng(37.5546788388674, 126.970606917394), ForecastType.superNct);

      List<ItemSuperNct> json = await weatherService.getWeatherData<List<ItemSuperNct>>(
          const LatLng(37.5546788388674, 126.970606917394), ForecastType.superNctYesterDay);

      json.map((e) => setState(() => items.add(e))).toList();
      items?.forEach((element) {
        Lo.g('초단기실황 : element : $element');
      });
    } catch (e) {
      Lo.g('초단기실황 가져오기 오류 : $e');
    }
  }

  // 기상청 초단기예보 가져오기
  void getSuperFctCast() async {
    try {
      final List<ItemSuperFct> items = [];
      // final json = await SuperFctRepositoryImp(isLog: true).getItemListJSON(weather);
      // WeatherGogoRepo repo = WeatherGogoRepo();
      // List<ItemSuperFct> json = await repo.getSuperFctListJson(const LatLng(37.5546788388674, 126.970606917394));
      WeatherService weatherService = WeatherService();
      List<ItemSuperFct> json =
          await weatherService.getWeatherData<List<ItemSuperFct>>(const LatLng(37.5546788388674, 126.970606917394), ForecastType.superFct);

      json.map((e) => setState(() => items.add(e))).toList();
      items.forEach((element) {
        Lo.g('초단기예보 : element : $element');
      });
    } catch (e) {
      Lo.g('초단기예보 가져오기 오류 : $e');
    }
  }

  // 기상청 단기예보 가져오기
  void getNctCast() async {
    try {
      final weather = Weather(
        serviceKey: weatherKey,
        pageNo: 1,
        numOfRows: 12 * 24, //기준시간별 항목이 12개이므로 24시간치 데이터를 가져오기 위해 12 * 24
      );
      final List<ItemFct> items = [];
      // final json = await FctRepositoryImp(isLog: true).getItemListJSON(weather);
      WeatherGogoRepo repo = WeatherGogoRepo();
      List<ItemFct> json = await repo.getFctListJson(const LatLng(37.5546788388674, 126.970606917394));

      json.map((e) => setState(() => items.add(e))).toList();

      items.forEach((element) {
        Lo.g('단기예보 element : $element');
      });
    } catch (e) {
      Lo.g('단기예보 가져오기 오류 : $e');
    }
  }

  // 기상청 예보버전 가져오기
  void getFctVersion() async {
    try {
      final weather = Weather(
        serviceKey: weatherKey,
        pageNo: 1,
        numOfRows: 12 * 24, //기준시간별 항목이 12개이므로 24시간치 데이터를 가져오기 위해 12 * 24
      );
      final List<ItemFctVersion> items = [];
      // final json = await FctRepositoryImp(isLog: true).getItemListJSON(weather);
      WeatherGogoRepo repo = WeatherGogoRepo();
      List<ItemFctVersion> json = await repo.getFctVersionJson(const LatLng(37.5546788388674, 126.970606917394));

      json.map((e) => setState(() => items.add(e))).toList();

      items.forEach((element) {
        Lo.g('예보버전 element : $element');
      });
    } catch (e) {
      Lo.g('단기예보 가져오기 오류 : $e');
    }
  }

  // 기상청 중기육상예보 가져오기
  void getMidFctJson() async {
    try {
      // WeatherGogoRepo repo = WeatherGogoRepo();
      // MidLandFcstResponse? json = await repo.getMidFctJson(const LatLng(37.5546788388674, 126.970606917394));
      WeatherService weatherService = WeatherService();
      MidLandFcstResponse json = await weatherService.getWeatherData<MidLandFcstResponse>(
          const LatLng(37.5546788388674, 126.970606917394), ForecastType.midFctLand);

      lo.g(json!.toString());
    } catch (e) {
      Lo.g('중기육상예보 가져오기 오류 : $e');
    }
  }

  // 기상청 중기기온 예보 가져오기
  void getMidTaJson() async {
    try {
      WeatherGogoRepo repo = WeatherGogoRepo();
      // MidTaResponse? json = await repo.getMidTaJson(const LatLng(37.5546788388674, 126.970606917394));
      // 중기기온 날씨 가져오기
      // MidTaResponse? midTaResponse = await weatherGogoRepo.getMidTaJson(location);
      WeatherService weatherService = WeatherService();
      MidTaResponse midTaResponse =
          await weatherService.getWeatherData<MidTaResponse>(const LatLng(37.5546788388674, 126.970606917394), ForecastType.midTa);

      lo.g(midTaResponse.toString());
    } catch (e) {
      Lo.g('중기기온 가져오기 오류 : $e');
    }
  }

  // 특보예보
  void getAlertJson() async {
    try {
      WeatherService weatherService = WeatherService();
      List<WeatherAlert> weatherAlertList = await weatherService.getWeatherData<List<WeatherAlert>>(
          const LatLng(37.5546788388674, 126.970606917394), ForecastType.weatherAlert);

      lo.g(weatherAlertList.toString());
    } catch (e) {
      Lo.g('특보예보 가져오기 오류 : $e');
    }
  }

  // accu weather
  void getAccWeatherCast() async {
    try {
      AccuRepo repo = AccuRepo();
      String locationKey = await repo.getLocation(Get.find<WeatherCntr>().currentLocation.value!.latLng);

      await repo.getCurrentWeather(locationKey);
    } catch (e) {
      Lo.g('Accu weather가져오기 오류 : $e');
    }
  }

  test() {
    var a = Get.put(WeatherGogoCntr());

    a.getInitWeatherData(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: Colors.black,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                height: 60,
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(context).push(MaterialPageRoute(
                    // fullscreenDialog: true,
                    builder: (context) => SunlightAnimationPage(),
                  ));
                },
                child: Text('썬 화면'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(context).push(MaterialPageRoute(
                    // fullscreenDialog: true,
                    builder: (context) => AnimatedWaterDrops(),
                  ));
                },
                child: Text('눈모듈 화면'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(context).push(MaterialPageRoute(
                    // fullscreenDialog: true,
                    builder: (context) => SnowAnimation2(
                      isVisibleNotifier: ValueNotifier(true),
                    ),
                  ));
                },
                child: Text('눈모듈 화면'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(context).push(MaterialPageRoute(
                      // fullscreenDialog: true,
                      builder: (context) => RainAnimation2(
                            isVisibleNotifier: ValueNotifier(true),
                          )));
                },
                child: Text('비 모듈 화면'),
              ),
              ElevatedButton(
                onPressed: () async {
                  await AuthCntr.to.logout();
                },
                child: Text('로그아웃'),
              ),
              ElevatedButton(
                onPressed: () async {
                  await Openweathermapclient().getForecast(const LatLng(37.5546788388674, 126.970606917394));
                },
                child: const Text('openweathermapclient '),
              ),
              ElevatedButton(
                onPressed: () => Get.to(NaverScrappingPage()),
                child: const Text('NaverScraPpingPage '),
              ),
              ElevatedButton(
                onPressed: () =>
                    Get.find<WeatherGogoCntr>().fetchYesterDayWeather(Get.find<WeatherGogoCntr>().currentLocation.value!.latLng),
                child: const Text('어제날씨조회 '),
              ),
              ElevatedButton(
                onPressed: () => Get.find<WeatherGogoCntr>().fetchSuperNct(Get.find<WeatherGogoCntr>().currentLocation.value!.latLng),
                child: const Text('초단기실황 '),
              ),
              ElevatedButton(
                onPressed: () => Get.find<WeatherGogoCntr>().fetchSuperFct(Get.find<WeatherGogoCntr>().currentLocation.value!.latLng),
                child: const Text('초단기예보 '),
              ),
              ElevatedButton(
                onPressed: () => Get.find<WeatherGogoCntr>().fetchFct(Get.find<WeatherGogoCntr>().currentLocation.value!.latLng),
                child: const Text('단기예보 '),
              ),
              ElevatedButton(
                onPressed: () => Get.toNamed('/WeatherComPage'),
                child: const Text('WeatherComPage '),
              ),
              ElevatedButton(
                onPressed: () => Get.toNamed('/WeathgergogoPage'),
                child: const Text('신규 페이지 '),
              ),
              ElevatedButton(
                onPressed: () => Get.toNamed('/AgreePage/${Get.find<AuthCntr>().custId}'),
                child: const Text('동의 화면 페이지 '),
              ),
              ElevatedButton(
                onPressed: () => test(),
                child: const Text('기상청 날씨 가져오기 '),
              ),
              ElevatedButton(
                onPressed: () => Get.toNamed('/JoinPage'),
                child: const Text('회원가입 화면 '),
              ),
              ElevatedButton(
                onPressed: () => Get.toNamed('/AuthPage'),
                child: const Text('로그인 로딩 화면 '),
              ),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: () => Utils.bottomNotiAlert(context, '최신 버전 업데이트', '최신 버전이 있습니다. 플레이스토어로 이동합니다.'),
                    child: const Text('초기화면 알림'),
                  ),
                  ElevatedButton(
                    onPressed: () => Utils.appUpdateAlert(context, 'https://www.daum.net'),
                    child: const Text('초기화면 알림'),
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: () => getCampingData('서울'),
                child: const Text('캠피장'),
              ),
              ElevatedButton(
                onPressed: () => getSchoolata('선덕', '고등학교'),
                child: const Text('학교'),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ElevatedButton(
                      onPressed: () => getSuperNctCast(),
                      child: const Text('초단기실황'),
                    ),
                    ElevatedButton(
                      onPressed: () => getSuperFctCast(),
                      child: const Text('초단기'),
                    ),
                    ElevatedButton(
                      onPressed: () => getNctCast(),
                      child: const Text('단기'),
                    ),
                    ElevatedButton(
                      onPressed: () => getFctVersion(),
                      child: const Text('예보버전'),
                    ),
                    ElevatedButton(
                      onPressed: () => getMidFctJson(),
                      child: const Text('중기육상'),
                    ),
                    ElevatedButton(
                      onPressed: () => getMidTaJson(),
                      child: const Text('중기기온'),
                    ),
                    ElevatedButton(
                      onPressed: () => getAlertJson(),
                      child: const Text('특보'),
                    ),
                  ],
                ),
              ),
              ElevatedButton(onPressed: () => aaa(), child: const Text('video')),
              Container(
                  width: 210,
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: ValueListenableBuilder<String>(
                    valueListenable: result,
                    builder: (context, value, child) {
                      return Text(
                        value,
                        style: const TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
                      );
                    },
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
