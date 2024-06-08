import 'dart:io';

import 'dart:async';
import 'dart:typed_data';

import 'package:aws_common/aws_common.dart';
import 'package:aws_signature_v4/aws_signature_v4.dart';
import 'package:path/path.dart' as p;
import 'package:project1/repo/common/res_data.dart';

String region = '';
String accoutId = '';
String accessKey = '';
String secretKey = '';
String directDownLoadUrl = 'https://pub-04277866e93d44679b87b060c5553b33.r2.dev';

class R2Repo {
  Future<ResData> uploadFile(BucketUpload bucketUpload) async {
    final bucketName = bucketUpload.bucketName;
    final region = bucketUpload.region;
    final file = bucketUpload.file;
    final filename = p.basename(bucketUpload.file.path);

    ResData resData = ResData();

    var signer = AWSSigV4Signer(
      credentialsProvider: AWSCredentialsProvider(
        AWSCredentials(accessKey, secretKey),
      ),
    );

    // Set up S3 values
    final scope = AWSCredentialScope(
      region: region,
      service: AWSService.s3,
    );
    final serviceConfiguration = S3ServiceConfiguration();
    final host = '$accoutId.r2.cloudflarestorage.com'; //  '$bucketName.s3.$region.amazonaws.com';
    final path = '/$bucketName/$filename';

    // Read the file's bytes
    // final fileBlob = file.slice();
    // final reader = FileReader()..readAsArrayBuffer(fileBlob);
    // await reader.onLoadEnd.first;
    // final fileBytes = reader.result as Uint8List?;
    Uint8List fileBytes = file.readAsBytesSync();
    if (fileBytes == null) {
      //throw Exception('Cannot read bytes from Blob.');
      resData.code = '99';
      resData.msg = 'Cannot read bytes from Blob.';
      return resData;
    }

    // Upload the file
    final uploadRequest = AWSHttpRequest.put(
      Uri.https(host, path),
      body: fileBytes,
      headers: {
        AWSHeaders.host: host,
        AWSHeaders.contentType: 'video/mp4',
      },
    );

    safePrint('Uploading file $filename to $path...');
    final signedUploadRequest = await signer.sign(
      uploadRequest,
      credentialScope: scope,
      serviceConfiguration: serviceConfiguration,
    );
    final uploadResponse = await signedUploadRequest.send().response;
    final uploadStatus = uploadResponse.statusCode;
    safePrint('Upload File Response: $uploadStatus');
    if (uploadStatus != 200) {
      //throw Exception('Could not upload file');
      resData.code = '99';
      resData.msg = 'Could not upload file';
      return resData;
    }
    safePrint('File uploaded successfully!');
    resData.code = '00';
    resData.data = '$directDownLoadUrl/$filename';
    return resData;
  }
}

class BucketUpload {
  const BucketUpload(this.bucketName, this.region, this.file);

  final String bucketName;
  final String region;
  final File file;
}
