import 'dart:io';

// import 'package:image_picker/image_picker.dart';
// import 'package:project1/repo/cloudflare/aws_s3/aws_s3_upload.dart';
// import 'package:http/http.dart' as http;

// s3 api url : https://1227ead63607f2c82ce09310ce378241.r2.cloudflarestorage.com/p1-video
// account ID : 1227ead63607f2c82ce09310ce378241
// R2 token value : sD7229xU9wBYda5-yPOshWQPYiXgku8RzPaENkOV
// R2 access key Id : d6c11b486c284e8792696f6c337b9361
// R2 secret key : 21538c58031ea22aee7dc6d1e35e4ca9a681a5cd0185c463de03b38e198ec121
// default bucket : p1-video
// default url : https://1227ead63607f2c82ce09310ce378241.r2.cloudflarestorage.com

// s3 api url : https://1227ead63607f2c82ce09310ce378241.r2.cloudflarestorage.com/p1-video
// account ID : 1227ead63607f2c82ce09310ce378241
// R2 token value :
// R2 access key Id : d6c11b486c284e8792696f6c337b9361
// R2 secret key : 21538c58031ea22aee7dc6d1e35e4ca9a681a5cd0185c463de03b38e198ec121
// default bucket : p1-video
// default url : https://1227ead63607f2c82ce09310ce378241.r2.cloudflarestorage.com

import 'dart:async';
import 'dart:typed_data';

import 'package:aws_common/aws_common.dart';
import 'package:aws_signature_v4/aws_signature_v4.dart';
import 'package:path/path.dart' as p;
import 'package:project1/repo/common/res_data.dart';
import 'package:project1/utils/log_utils.dart';

String region = 'auto';
String accoutId = '1227ead63607f2c82ce09310ce378241';
String accessKey = '27d0910cb888ca37d3a8fe57941bd3c9';
String secretKey = '6cd711e2614f3e62233af3bd687bbd1cde177096f3d59496d40e60b9cd6cbb64';
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

    // Create a pre-signed URL for downloading the file
    // final urlRequest = AWSHttpRequest.get(
    //   Uri.https(host, path),
    //   headers: {
    //     AWSHeaders.host: host,
    //   },
    // );
    // final signedUrl = await signer.presign(
    //   urlRequest,
    //   credentialScope: scope,
    //   serviceConfiguration: serviceConfiguration,
    //   expiresIn: const Duration(minutes: 10),
    // );
    // safePrint('Download URL: $signedUrl');
  }
}

class BucketUpload {
  const BucketUpload(this.bucketName, this.region, this.file);

  final String bucketName;
  final String region;
  final File file;
}

// BucketUpload? getBucketUpload(File file) {
//   final accoutId = 'p1-video';
//   final bucketName = 'p1-video';
//   final region = 'auto';
//   final files = file;
//   final hasInvalidProps = bucketName == null || bucketName.isEmpty || region == null || region.isEmpty || files == null;
//   if (hasInvalidProps) {
//     return null;
//   }
//   return BucketUpload(accoutId, bucketName, region, files);
// }

// class R2Repository {
//   // Global api key : 1f3a9a77a16a1681409ac75e062eefbcc3de2
//   Future<String> uploadFile(String imageYn, File file) async {
//     try {
//       var result = await AwsS3.uploadFile(
//         accessKey: "ad6b2fffd96d70c66c0c32fa5aeefdf3",
//         secretKey: "key",
//         file: file,
//         bucket: imageYn == 'Y' ? 'p1-thumbnail' : 'p1-video',
//         region: "auto",
//       );
//       return result!;
//     } catch (e) {
//       print(e.toString());
//       throw e; // Throw the error
//     }
//   }

//   // Future<void> uploadImage(String user, XFile image, File compressedFile) async {
//   //   await uploadFile('${user}/${image.name}', compressedFile);
//   // }

//   Future<String?> uploadFileToR2(File file) async {
//     // Replace 'YOUR_API_TOKEN' with your actual Cloudflare R2 API token
//     String apiUrl = 'https://api.cloudflare.com/client/v4/accounts/ad6b2fffd96d70c66c0c32fa5aeefdf3/image/upload/p1-thumbnail';
//     String apiToken = 'ZYEgrnJDPreio35s73cYSANoajaY7FXz';

//     // Create a multipart request
//     var request = http.MultipartRequest('POST', Uri.parse(apiUrl));

//     // Add file to the request
//     request.files.add(await http.MultipartFile.fromPath('file', file.path));

//     // Set authorization header
//     request.headers['Authorization'] = 'Bearer $apiToken';

//     // Send the request
//     var response = await request.send();
//     return response.reasonPhrase;
//     ;

//     // Check the response status
//     if (response.statusCode == 200) {
//       // File uploaded successfully
//       print('File uploaded successfully!');
//     } else {
//       // Error occurred
//       print('Error uploading file: ${response.reasonPhrase}');
//     }
//   }
// }
