import 'dart:io';

import 'package:cloudflare/cloudflare.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:korean_profanity_filter/korean_profanity_filter.dart';
import 'package:project1/app/bbs/cntr/bbs_list_cntr.dart';
import 'package:project1/repo/bbs/bbs_repo.dart';
import 'package:project1/repo/bbs/data/bbs_register_req_data.dart';
import 'package:project1/repo/bbs/data/bbs_file_req_data.dart';
import 'package:project1/repo/cloudflare/cloudflare_repo.dart';
import 'package:project1/repo/common/res_data.dart';
import 'package:project1/utils/log_utils.dart';
import 'package:project1/utils/utils.dart';

class BbsWriteBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<BbsWriteController>(() => BbsWriteController());
  }
}

class BbsWriteController extends GetxController {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController contentController = TextEditingController();
  final FocusNode titleFocus = FocusNode();
  final FocusNode contentsFocus = FocusNode();

  CloudflareRepo cloudflare = CloudflareRepo();

  // 이미지 정보 리스트 (선택된 이미지와 업로드된 이미지 정보를 함께 관리)
  final RxList<ImageData> imageList = <ImageData>[].obs;
  RxBool isSaving = false.obs;

  RxString typeDtCd = 'FREE'.obs;

  @override
  void onInit() async {
    super.onInit();
    init();
  }

  Future<void> init() async {
    await cloudflare.init();
    typeDtCd.value = Get.find<BbsListController>().typeDtCd.value == 'ALL' ? 'FREE' : Get.find<BbsListController>().typeDtCd.value;
  }

  // 업로드되지 않은 이미지 목록 가
  List<ImageData> get notUploadedImages => imageList.where((image) => !image.isUploaded).toList();

  // 업로드된 이미지 목록 가져오기
  List<ImageData> get uploadedImages => imageList.where((image) => image.isUploaded).toList();

  Future<void> pickImage() async {
    // 최대 10개
    if (imageList.length >= 10) {
      Utils.alert('이미지는 최대 10개까지 업로드 가능합니다.');
      return;
    }

    final ImagePicker picker = ImagePicker();
    final List<XFile>? _list = await picker.pickMultiImage();

    if (_list != null && _list.isNotEmpty) {
      for (var file in _list) {
        // 파일 크기 확인 (10MB = 10 * 1024 * 1024 bytes)
        final fileSize = await file.length();
        if (fileSize > 10 * 1024 * 1024) {
          Utils.alert('${file.name}의 크기가 10MB를 초과합니다. 이 파일은 업로드되지 않습니다.');
          continue; // 이 파일을 건너뛰고 다음 파일로 진행
        }

        imageList.add(ImageData(
          file: file,
          fileName: file.name,
          imageKey: '',
          imageUrl: '',
        ));
      }

      // 이미지 업로드 처리
      for (var image in notUploadedImages) {
        await uploadImage(image);
      }
    }
  }

  // 모든 이미지 일괄 삭제
  Future<void> removeAllImages() async {
    List<ImageData> imagesToRemove = List.from(imageList);

    // 모든 이미지의 isDeleting 상태를 true로 설정
    for (var image in imagesToRemove) {
      image.isDeleting = true;
    }
    imageList.refresh();

    // 병렬로 모든 이미지 삭제 처리
    await Future.wait(imagesToRemove.map((image) async {
      if (image.imageKey.isNotEmpty) {
        bool result = await cloudflare.imageDelete(image.imageKey);
        if (!result) {
          Utils.alert('이미지 삭제에 실패했습니다: ${image.fileName}');
          image.isDeleting = false;
        }
      }
    }));

    // 삭제 성공한 이미지만 리스트에서 제거
    imageList.removeWhere((image) => image.isDeleting);
    imageList.refresh();
  }

  // 이미지 삭제
  Future<void> removeImage(ImageData image) async {
    int index = imageList.indexOf(image);
    if (index == -1) return; // 이미지가 리스트에 없으면 무시

    image.isDeleting = true;
    imageList.refresh();

    if (image.imageKey.isNotEmpty) {
      bool result = await cloudflare.imageDelete(image.imageKey);
      if (!result) {
        Utils.alert('이미지 삭제에 실패했습니다.');
        image.isDeleting = false;
        imageList.refresh();
        return;
      }
    }
    imageList.remove(image);
    imageList.refresh();
  }

  // 이미지 서버에 저장
  Future<void> uploadImage(ImageData image) async {
    File uploadFile = File(image.file!.path);

    CloudflareHTTPResponse<CloudflareImage?>? resthumbnail = await cloudflare.imageFileUpload(uploadFile);
    if (resthumbnail?.isSuccessful == false) {
      Utils.alert('이미지 업로드에 실패했습니다.');
      return;
    }
    Lo.g('file 업로드 : ${resthumbnail?.body.toString()}');

    int index = imageList.indexOf(image);
    imageList[index] = ImageData(
      imageKey: resthumbnail!.body!.id,
      fileName: image.fileName,
      imageUrl: resthumbnail.body!.variants[0].toString(),
    );
    imageList.refresh(); // 리스트 갱신을 강제로 트리거
  }

  Future<bool> submitPost() async {
    try {
      if (titleController.text.isEmpty) {
        Utils.alert('제목을 입력해주세요');
        titleFocus.requestFocus();
        return false;
      }
      if (contentController.text.isEmpty) {
        Utils.alert('내용을 입력해주세요');
        contentsFocus.requestFocus();
        return false;
      }

      // 모든 이미지가 업로드되었는지 확인
      if (imageList.any((image) => !image.isUploaded)) {
        Utils.alert('이미지 업로드가 완료되지 않았습니다. 잠시 후 다시 시도해주세요.');
        return false;
      }
      isSaving.value = true;

      // 비속어 치환
      String titleText = titleController.text;
      String contentsText = contentController.text;
      titleText = titleText.replaceBadWords('🤬');
      contentsText = contentsText.replaceBadWords('🤬');

      BbsRepo bbsRepo = BbsRepo();
      BbsRegisterData bbsRegisterData = BbsRegisterData(
          typeCd: 'BBS',
          typeDtCd: typeDtCd.value,
          title: titleText,
          contents: contentsText,
          fileListData:
              imageList.map((e) => BbsFileData(fileKey: e.imageKey, fileNm: e.fileName, filePath: e.imageUrl, fileType: 'image')).toList(),
          depthNo: '0',
          boardId: '',
          parentId: 0);

      lo.g("bbsRegisterData : ${bbsRegisterData.toJson()}");

      ResData resData = await bbsRepo.save(bbsRegisterData);
      if (resData.code != '00') {
        Utils.alert(resData.msg.toString());
        return false;
      }
      Utils.alert('게시글 저장되었습니다.');
      return true;
    } catch (e) {
      Utils.alert('게시글 저장에 실패했습니다.');
      return false;
    } finally {
      isSaving.value = false;
    }
  }
}

// 데이터 클래스
class ImageData {
  XFile? file; // 로컬 파일 참조 (업로드 전)
  String imageKey;
  final String fileName;
  String imageUrl;
  bool isDeleting = false;

  ImageData({
    this.file,
    required this.imageKey,
    required this.fileName,
    required this.imageUrl,
    this.isDeleting = false,
  });

  // 이미지가 업로드되었는지 확인하는 getter
  bool get isUploaded => imageKey.isNotEmpty;

  // equals 메소드 추가
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ImageData && runtimeType == other.runtimeType && fileName == other.fileName && imageKey == other.imageKey;

  // hashCode 메소드 추가
  @override
  int get hashCode => fileName.hashCode ^ imageKey.hashCode;
}
