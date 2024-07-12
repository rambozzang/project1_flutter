import 'dart:convert';
import 'dart:io';

import 'package:bot_toast/bot_toast.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:get/get_connect/http/src/response/response.dart';
import 'package:giffy_dialog/giffy_dialog.dart';
import 'package:image_picker/image_picker.dart';
import 'package:project1/app/weather/cntr/weather_cntr.dart';
import 'package:project1/repo/weather_accu/accu_repo.dart';
import 'package:project1/repo/weather_gogo/interface/imp_fct_repository.dart';
import 'package:project1/repo/weather_gogo/interface/imp_super_fct_repository.dart';
import 'package:project1/repo/weather_gogo/interface/imp_super_nct_repository.dart';
import 'package:project1/repo/weather_gogo/models/request/weather.dart';
import 'package:project1/repo/weather_gogo/models/response/fct/fct_model.dart';
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

  // 기상청 초단기예보 가져오기
  void getSuperShortCast() async {
    try {
      String _key = 'CeGmiV26lUPH9guq1Lca6UA25Al/aZlWD3Bm8kehJ73oqwWiG38eHxcTOnEUzwpXKY3Ur+t2iPaL/LtEQdZebg==';
      final weather = Weather(
        serviceKey: _key,
        pageNo: 1,
        numOfRows: 12 * 24, //기준시간별 항목이 12개이므로 24시간치 데이터를 가져오기 위해 12 * 24
      );
      final List<ItemFct> items = [];
      final json = await FctRepositoryImp(isLog: true).getItemListJSON(weather);

      json.map((e) => setState(() => items.add(e))).toList();

      items.forEach((element) {
        Lo.g('element : $element');
      });

      //초단기실황조회
      // final weather = Weather(
      //   serviceKey: _key,
      //   pageNo: 1,
      //   numOfRows: 10000,
      // );
      // final List<ItemSuperNct> items = [];
      // final json = await SuperNctRepositoryImp(isLog: true).getItemListJSON(weather);

      // json.map((e) => setState(() => items.add(e))).toList();
      // items.forEach((element) {
      //   Lo.g('element : $element');
      // });

      // accu weather
      AccuRepo repo = AccuRepo();
      String locationKey = await repo.getLocation(Get.find<WeatherCntr>().currentLocation.value!.latLng);

      await repo.getCurrentWeather(locationKey);
    } catch (e) {
      Lo.g('초단기실황 가져오기 오류 : $e');
    }
  }

  // NotiShow2(){

  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            WeatherLineChartWidget(),

            ElevatedButton(
              onPressed: () => Utils.bottomNotiAlert(context, '최신 버전 업데이트', '최신 버전이 있습니다. 플레이스토어로 이동합니다.'),
              child: const Text('초기화면 알림'),
            ),
            ElevatedButton(
              onPressed: () => Utils.appUpdateAlert(context, 'https://www.daum.net'),
              child: const Text('초기화면 알림'),
            ),
            ElevatedButton(
              onPressed: () => getCampingData('서울'),
              child: const Text('캠피장'),
            ),
            ElevatedButton(
              onPressed: () => getSchoolata('선덕', '고등학교'),
              child: const Text('학교'),
            ),

            ElevatedButton(
              onPressed: () => getSuperShortCast(),
              child: const Text('초단기예보'),
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

            // child: Marquee(
            //   key: GlobalKey(),
            //   moveDuration: const Duration(milliseconds: 500),
            //   items: [
            //     Container(
            //         padding: const EdgeInsets.all(2),
            //         decoration: BoxDecoration(
            //           color: Colors.green.withOpacity(0.9),
            //           borderRadius: BorderRadius.circular(5),
            //         ),
            //         child: const Icon(Icons.location_on, color: Colors.white, size: 15)),
            //     const SizedBox(width: 5),
            //     Text(
            //       '111111 f',
            //       textAlign: TextAlign.right,
            //       style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold),
            //     ),
            //     const Gap(5),
            //     Text(
            //       'asdasdfa°',
            //       textAlign: TextAlign.right,
            //       style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold),
            //     ),
            //     Text(
            //       '12333',
            //       style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold),
            //     ),
            //     const Gap(10),
            //   ],
            // )),
          ],
        ),
      ),
    );
  }
}

class WeatherLineChartWidget extends StatelessWidget {
  final List<double> dataPoints = [10, 12, 14, 15, 13, 11, 10, 9, 8, 7, 6, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17];
  final List<String> hours = [
    '0h',
    '1h',
    '2h',
    '3h',
    '4h',
    '5h',
    '6h',
    '7h',
    '8h',
    '9h',
    '10h',
    '11h',
    '12h',
    '13h',
    '14h',
    '15h',
    '16h',
    '17h',
    '18h',
    '19h',
    '20h',
    '21h',
    '22h',
    '23h'
  ];
  final double maxValue = 17;
  final double minValue = 5;

  @override
  Widget build(BuildContext context) {
    return Container(
      // color: Colors.white,
      height: 250,
      padding: const EdgeInsets.only(bottom: 30, left: 40), // Padding for x-axis labels
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: CustomPaint(
          size: Size(dataPoints.length * 50.0, 200), // Adjust width as needed
          painter: WeatherLineChartPainter(dataPoints, hours, maxValue, minValue),
        ),
      ),
    );
  }
}

class WeatherLineChartPainter extends CustomPainter {
  final List<double> dataPoints;
  final List<String> hours;
  final double maxValue;
  final double minValue;

  WeatherLineChartPainter(this.dataPoints, this.hours, this.maxValue, this.minValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final path = Path();
    final double step = size.width / (dataPoints.length - 1);
    final double heightRange = maxValue - minValue;

    final dotPaint = Paint()
      ..color = Colors.red
      ..strokeWidth = 4.0
      ..style = PaintingStyle.fill;

    // Start drawing the path
    path.moveTo(0, size.height - ((dataPoints[0] - minValue) / heightRange * size.height));

    for (int i = 0; i < dataPoints.length - 1; i++) {
      double x1 = i * step;
      double y1 = size.height - ((dataPoints[i] - minValue) / heightRange * size.height);
      double x2 = (i + 1) * step;
      double y2 = size.height - ((dataPoints[i + 1] - minValue) / heightRange * size.height);
      double xc = (x1 + x2) / 2;
      double yc = (y1 + y2) / 2;

      path.quadraticBezierTo(x1, y1, xc, yc);
      path.quadraticBezierTo(xc, yc, x2, y2);
    }

    // Draw the path
    canvas.drawPath(path, paint);

    // Draw dots and labels
    for (int i = 0; i < dataPoints.length; i++) {
      double x = i * step;
      double y = size.height - ((dataPoints[i] - minValue) / heightRange * size.height);

      // Draw dot
      canvas.drawCircle(Offset(x, y), 4.0, dotPaint);

      // Draw temperature text
      TextSpan span = TextSpan(style: const TextStyle(color: Colors.black, fontSize: 12), text: dataPoints[i].toString());
      TextPainter tp = TextPainter(text: span, textAlign: TextAlign.center, textDirection: TextDirection.ltr);
      tp.layout();
      tp.paint(canvas, Offset(x - tp.width / 2, y - tp.height - 8));
    }

    // Draw x-axis labels (hours)
    for (int i = 0; i < hours.length; i++) {
      double x = i * step;
      double y = size.height;

      TextSpan span = TextSpan(style: const TextStyle(color: Colors.black, fontSize: 12), text: hours[i]);
      TextPainter tp = TextPainter(text: span, textAlign: TextAlign.center, textDirection: TextDirection.ltr);
      tp.layout();
      tp.paint(canvas, Offset(x - tp.width / 2, y + 4));
    }

    // Draw y-axis labels (temperatures)
    for (int i = 0; i <= 5; i++) {
      double y = size.height - (i / 5 * size.height);
      double value = minValue + (i / 5 * heightRange);

      TextSpan span = TextSpan(style: const TextStyle(color: Colors.black, fontSize: 12), text: value.toStringAsFixed(1));
      TextPainter tp = TextPainter(text: span, textAlign: TextAlign.right, textDirection: TextDirection.ltr);
      tp.layout();
      tp.paint(canvas, Offset(-tp.width - 4, y - tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
