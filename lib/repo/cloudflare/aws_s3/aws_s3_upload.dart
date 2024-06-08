library aws_s3_upload;

import 'dart:convert';
import 'dart:io';

import 'package:amazon_cognito_identity_dart_2/sig_v4.dart';
import 'package:aws_signature_v4/aws_signature_v4.dart';

import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:path/path.dart' as path;
import 'package:project1/repo/cloudflare/aws_s3/acl.dart';
import 'package:project1/repo/cloudflare/aws_s3/policy.dart';
import 'package:project1/repo/cloudflare/aws_s3/utils.dart';
import 'package:project1/utils/log_utils.dart';
import 'package:recase/recase.dart';

/// Convenience class for uploading files to AWS S3
class AwsS3 {
  /// Upload a file, returning the file's public URL on success.
  static Future<String?> uploadFile({
    /// AWS access key
    required String accessKey,
    required String accountId,

    /// AWS secret key
    required String secretKey,

    /// The name of the S3 storage bucket to upload  to
    required String bucket,

    /// The file to upload
    required File file,

    /// The key to save this file as. Will override destDir and filename if set.
    String? key,

    /// The path to upload the file to (e.g. "uploads/public"). Defaults to the root "directory"
    String destDir = '',

    /// The AWS region. Must be formatted correctly, e.g. us-west-1
    String region = 'us-west-1',

    /// Access control list enables you to manage access to bucket and objects
    /// For more information visit [https://docs.aws.amazon.com/AmazonS3/latest/userguide/acl-overview.html]
    ACL acl = ACL.private,

    /// The filename to upload as. If null, defaults to the given file's current filename.
    String? filename,

    /// The content-type of file to upload. defaults to binary/octet-stream.
    String contentType = 'video/mp4', // 'binary/octet-stream', //

    /// If set to true, https is used instead of http. Default is true.
    bool useSSL = true,

    /// Additional metadata to be attached to the upload
    Map<String, String>? metadata,
  }) async {
    var httpStr = 'http';
    if (useSSL) {
      httpStr += 's';
    }
    final endpoint = '$httpStr://$accountId.r2.cloudflarestorage.com/$bucket/$filename';
    // final endpoint = '$httpStr://$bucket.s3.$region.amazonaws.com';
    //https: //<account-id>.r2.cloudflarestorage.com/<r2-bucket>/<r2-object>
    //https://1227ead63607f2c82ce09310ce378241.r2.cloudflarestorage.com/p1-video

    lo.g("url : $endpoint");

    String? uploadKey;

    if (key != null) {
      uploadKey = key;
    } else if (destDir.isNotEmpty) {
      uploadKey = '$destDir/${filename ?? path.basename(file.path)}';
    } else {
      uploadKey = '${filename ?? path.basename(file.path)}';
    }

    final stream = http.ByteStream(Stream.castFrom(file.openRead()));
    final length = await file.length();

    final uri = Uri.parse(endpoint);

    final req = http.MultipartRequest("PUT", uri);
    final multipartFile = http.MultipartFile('file', stream, length, filename: path.basename(file.path));

    // Convert metadata to AWS-compliant params before generating the policy.
    final metadataParams = _convertMetadataToParams(metadata);

    // Generate pre-signed policy.
    final policy = Policy.fromS3PresignedPost(
      uploadKey,
      bucket,
      accessKey,
      15,
      length,
      acl,
      region: region,
      metadata: metadataParams,
    );

    final signingKey = SigV4.calculateSigningKey(secretKey, policy.datetime, region, 's3');
    final signature = SigV4.calculateSignature(signingKey, policy.encode());

    const signer = AWSSigV4Signer();

    req.files.add(multipartFile);
    // req.fields['key'] = policy.key;
    // req.fields['acl'] = aclToString(acl);
    // req.fields['X-Amz-Credential'] = policy.credential;
    // req.fields['X-Amz-Algorithm'] = 'AWS4-HMAC-SHA256';
    // req.fields['X-Amz-Date'] = policy.datetime;
    // req.fields['Policy'] = policy.encode();
    // req.fields['X-Amz-Signature'] = signature;
    // req.fields['Content-Type'] = contentType;

    req.headers['acl'] = aclToString(acl);

    req.headers['KEY_TYPE_IDENTIFIER'] = "aws4_request";
    // req.headers['MAX_PRESIGNED_TTL'] = 60 * 60 * 24 * 7;
    req.headers['EVENT_ALGORITHM_IDENTIFIER'] = "AWS4-HMAC-SHA256-PAYLOAD";

    req.headers['x-amz-content-sha256'] = 'UNSIGNED-PAYLOAD';
    req.headers['Content-Type'] = contentType;
    req.headers['X-Amz-Date'] = policy.datetime;
    req.headers['Authorization'] =
        'AWS4-HMAC-SHA256 Credential=${policy.credential}, SignedHeaders=content-length;content-type;host;range;x-amz-content-sha256;x-amz-date, Signature=$signature';

// curl --location --request PUT 'https://<account-id>.r2.cloudflarestorage.com/<r2-bucket>/<r2-object>' \
// --header 'x-amz-content-sha256: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855' \
// --header 'Content-Type: image/jpeg' \
// --header 'X-Amz-Date: 20240422T064318Z' \
// --header 'Authorization: AWS4-HMAC-SHA256 Credential=<r2-access-key-id>/20240422/auto/s3/aws4_request, SignedHeaders=content-length;content-type;host;x-amz-content-sha256;x-amz-date, Signature=2a6ead269a01355408abee7c36b3c287bcd4f85a52a04bd99ac0efe0445539dc' \
// --data '@GPeeGZTRk/cat-pic.jpg'

// {key: 20240422/VID_2024-04-22 03-32-00-1330319080.mp4,
// acl: public-read,
// X-Amz-Credential: d6c11b486c284e8792696f6c337b9361/20240422/Asia-Pacific/s3/aws4_request,
//  X-Amz-Algorithm: AWS4-HMAC-SHA256,
//  X-Amz-Date: 20240422T063204Z,
//  Policy: eyJleHBpcmF0aW9uIjoiMjAyNC0wNC0yMlQwNjo0NzowNC40OTQxNjlaIiwiY29uZGl0aW9ucyI6W3siYnVja2V0IjoicDEtdmlkZW8ifSxbInN0YXJ0cy13aXRoIiwiJGtleSIsIjIwMjQwNDIyL1ZJRF8yMDI0LTA0LTIyIDAzLTMyLTAwLTEzMzAzMTkwODAubXA0Il0sWyJzdGFydHMtd2l0aCIsIiRDb250ZW50LVR5cGUiLCIiXSx7ImFjbCI6InB1YmxpYy1yZWFkIn0sWyJjb250ZW50LWxlbmd0aC1yYW5nZSIsMSwxOTY2OTIzXSx7IngtYW16LWNyZWRlbnRpYWwiOiJkNmMxMWI0ODZjMjg0ZTg3OTI2OTZmNmMzMzdiOTM2MS8yMDI0MDQyMi9Bc2lhLVBhY2lmaWMvczMvYXdzNF9yZXF1ZXN0In0seyJ4LWFtei1hbGdvcml0aG0iOiJBV1M0LUhNQUMtU0hBMjU2In0seyJ4LWFtei1kYXRlIjoiMjAyNDA0MjJUMDYzMjA0WiJ9LHsieC1hbXotbWV0YS10ZXN0IjoidGVzdCJ9XX0=, X-Amz-Signature: b0ef3335192cc4278bc05250ff3a427533b1549c38185a7d04ea65c9e51667bf,
//  Content-Type: binary/octet-stream,

    // If metadata isn't null, add metadata params to the request.
    if (metadata != null) {
      req.fields.addAll(metadataParams);
    }

    try {
      Lo.g('req : ${req.toString()}');
      Lo.g('req fields : ${req.fields.toString()}');
      Lo.g('req headers : ${req.headers.toString()}');

      final StreamedResponse res = await req.send();
      res.stream.transform(utf8.decoder).listen((value) {
        Lo.g("streamRes : $value");
      });
      Lo.g("res : ${res.toString()}");

      return '${res.statusCode.toString()} : ${res.reasonPhrase.toString()} ';

      // if (res.statusCode == 204) return '$endpoint/$uploadKey';
    } catch (e) {
      Lo.g('Failed to upload to AWS, with exception:');
      Lo.g(e);
      return null;
    }
  }

  /// A method to transform the map keys into the format compliant with AWS.
  /// AWS requires that each metadata param be sent as `x-amz-meta-*`.
  static Map<String, String> _convertMetadataToParams(Map<String, String>? metadata) {
    Map<String, String> updatedMetadata = {};

    if (metadata != null) {
      for (var k in metadata.keys) {
        updatedMetadata['x-amz-meta-${k.paramCase}'] = metadata[k]!;
      }
    }

    return updatedMetadata;
  }
}
