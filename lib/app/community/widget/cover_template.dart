import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:project1/repo/cloudflare/direct_upload_repo.dart';
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

/// Unsplash 원본 URL은 원본 해상도(수 MB)를 내려줘 그대로 쓰면 로딩이 수 초 걸린다.
/// images.unsplash.com URL에 리사이즈 파라미터를 붙여 표시용 경량 URL로 변환한다.
/// (다른 호스트나 이미 파라미터가 있는 URL은 그대로 반환 — 안전한 no-op)
String coverImageUrl(String url, {int width = 800}) {
  if (!url.contains('images.unsplash.com')) return url;
  if (url.contains('?')) return url;
  return '$url?w=$width&q=70&fm=jpg';
}

/// 표지 템플릿 10종(순서 중요 — 첫 항목이 앨범 생성 시 기본 선택값).
/// 2026-07-03 전면 교체: 밝고 귀여운 캐릭터·토이 무드의 무료(Unsplash) 사진으로 통일(눈검수 완료).
const List<CoverTemplate> kCoverTemplates = [
  CoverTemplate('wedding', '결혼식', 'https://images.unsplash.com/photo-1530092285049-1c42085fd395'), // 하늘 아래 흰 꽃(부케 무드)
  CoverTemplate('reunion', '동창회', 'https://images.unsplash.com/photo-1563396983906-b3795482a59a'), // 레트로 양철 로봇과 오리 친구들
  CoverTemplate('baby100', '100일 기념', 'https://images.unsplash.com/photo-1559454403-b8fb88521f11'), // 파스텔 테디베어 + 아기 바구니
  CoverTemplate('party', '파티', 'https://images.unsplash.com/photo-1499195333224-3ce974eecb47'), // 알록달록 젤리 파티
  CoverTemplate('yearend', '망년회', 'https://images.unsplash.com/photo-1587654780291-39c9404d746b'), // 쏟아진 컬러 레고 브릭
  CoverTemplate('birthday', '생일', 'https://images.unsplash.com/photo-1558326567-98ae2405596b'), // 파스텔 마카롱 탑
  CoverTemplate('travel', '여행', 'https://images.unsplash.com/photo-1596461404969-9ae70f2830c1'), // 나무 기차 장난감 마을
  CoverTemplate('family', '가족모임', 'https://images.unsplash.com/photo-1602734846297-9299fc2d4703'), // 나비넥타이 테디베어
  CoverTemplate('friends', '친구모임', 'https://images.unsplash.com/photo-1585366119957-e9730b6d0f60'), // 레고 미니피규어 4인방 횡단보도
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
    final ImageUploadResult? res = await DirectUploadRepo().uploadImageFile(file);
    if (res == null) {
      Utils.alert('표지 사진 업로드에 실패했습니다.');
      return null;
    }
    lo.g('표지 사진 업로드 성공: ${res.url}');
    return res.url;
  } catch (e) {
    // picker 권한거부·업로드 네트워크 예외 등이 호출부로 전파되지 않도록 여기서 처리(doc 주석의 "에러는 Utils.alert로 표시" 약속 유지).
    Utils.alert(e.toString());
    return null;
  }
}
