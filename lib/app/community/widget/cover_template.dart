import 'dart:io';

import 'package:cloudflare/cloudflare.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:project1/repo/cloudflare/cloudflare_repo.dart';
import 'package:project1/utils/log_utils.dart';
import 'package:project1/utils/utils.dart';

/// 앨범 표지 템플릿 1개(테마 + 무료 스톡사진). 백엔드 CommunityCoverTemplates와 templateId·URL을 동일하게 유지해야 한다.
@immutable
class CoverTemplate {
  const CoverTemplate(this.id, this.label, this.imageUrl);

  final String id;
  final String label;
  final String imageUrl;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoverTemplate &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          label == other.label &&
          imageUrl == other.imageUrl;

  @override
  int get hashCode => Object.hash(id, label, imageUrl);
}

/// 표지 템플릿 10종(순서 중요 — 첫 항목이 앨범 생성 시 기본 선택값).
/// 2026-07-02 전면 교체: 발랄·캐릭터 무드의 무료(Unsplash) 사진으로 통일(눈검수 완료).
const List<CoverTemplate> kCoverTemplates = [
  CoverTemplate('wedding', '결혼식', 'https://images.unsplash.com/photo-1465495976277-4387d4b0b4c6'), // 반지 낀 두 손 + 살구빛 부케
  CoverTemplate('reunion', '동창회', 'https://images.unsplash.com/photo-1527529482837-4698179dc6ce'), // 조명 아래 잔 들어 건배
  CoverTemplate('baby100', '100일 기념', 'https://images.unsplash.com/photo-1518946222227-364f22132616'), // 레고 유니콘 미니피규어
  CoverTemplate('party', '파티', 'https://images.unsplash.com/photo-1492684223066-81342ee5ff30'), // 쏟아지는 색종이
  CoverTemplate('yearend', '망년회', 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819'), // 무지개빛 콘서트 색종이
  CoverTemplate('birthday', '생일', 'https://images.unsplash.com/photo-1551024601-bec78aea704b'), // 스프링클 도넛 탑
  CoverTemplate('travel', '여행', 'https://images.unsplash.com/photo-1469854523086-cc02fe5d8800'), // 노란 미니밴 로드트립
  CoverTemplate('family', '가족모임', 'https://images.unsplash.com/photo-1546975490-e8b92a360b24'), // 티피 텐트 속 웰시코기
  CoverTemplate('friends', '친구모임', 'https://images.unsplash.com/photo-1516633630673-67bbad747022'), // 나무 장난감 요트 함대
  CoverTemplate('couple', '연애', 'https://images.unsplash.com/photo-1518199266791-5375a83190b7'), // 하트 보케
];

/// 갤러리에서 사진을 골라 Cloudflare에 업로드하고 URL을 반환한다.
/// 사용자가 취소하거나 업로드에 실패하면 null을 반환한다(에러는 Utils.alert로 이미 표시됨).
/// (myinfo_page.dart의 프로필 사진 업로드와 동일한 방식 재사용 — 크롭 단계는 생략해 범위를 최소화함.)
Future<String?> pickAndUploadCoverPhoto() async {
  try {
    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (pickedFile == null) return null;

    final File file = File(pickedFile.path);
    final CloudflareRepo cloudflare = CloudflareRepo();
    await cloudflare.init();
    final CloudflareHTTPResponse<CloudflareImage?>? res = await cloudflare.imageFileUpload(file);
    if (res?.isSuccessful != true) {
      // 실패 alert는 CloudflareRepo.imageFileUpload가 이미 표시하므로 여기선 조용히 null만 반환(중복 알림 방지).
      lo.g('표지 사진 업로드 실패');
      return null;
    }
    lo.g('표지 사진 업로드 성공: ${res?.body?.toString()}');
    return res!.body!.variants[0].toString();
  } catch (e) {
    // picker 권한거부·업로드 네트워크 예외 등이 호출부로 전파되지 않도록 여기서 처리(doc 주석의 "에러는 Utils.alert로 표시" 약속 유지).
    Utils.alert(e.toString());
    return null;
  }
}
