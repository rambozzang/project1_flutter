import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:project1/repo/cloudflare/R2_repo.dart';
import 'package:project1/repo/cloudflare/cloudflare_repo.dart';
import 'package:project1/repo/common/res_data.dart';
import 'package:project1/utils/log_utils.dart';
import 'package:project1/utils/utils.dart';

class TestDioPage extends StatefulWidget {
  const TestDioPage({super.key});

  @override
  State<TestDioPage> createState() => _TestDioPageState();
}

class _TestDioPageState extends State<TestDioPage> {
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

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Test Dio Page'),
            ElevatedButton(
              onPressed: () => getDownloadUrl(),
              child: Text('data'),
            ),
            ElevatedButton(onPressed: () => aaa(), child: Text('video'))
          ],
        ),
      ),
    );
  }
}
