import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:project1/utils/log_utils.dart';
import 'package:project1/utils/utils.dart';
import 'package:share_plus/share_plus.dart';

/// SkySnap을 SNS에 소개할 때 쓰는 공통 공유 흐름.
///
/// 인스타그램은 텍스트/URL만으로는 피드·스토리 공유 대상으로 표시되지 않는 경우가 있어,
/// 앱 아이콘을 함께 전달한다. OS 공유 시트에서 인스타그램을 선택할 수 있으며, 설치되어
/// 있지 않은 기기에서는 카카오톡·메시지 등 다른 공유 수단으로 자연스럽게 폴백한다.
class AppPromoShare {
  AppPromoShare._();

  static const _promoAsset = 'assets/icon/app_icon_v10_square.png';
  static const _promoFileName = 'skysnap-instagram-promo.png';
  static const _text = '오늘 날씨와 현장 영상을 한눈에 ☁️\n\n'
      'SkySnap에서 우리 동네의 지금을 만나보세요.\n'
      'https://skysnap.co.kr/download/\n\n'
      '#SkySnap #스카이스냅 #날씨앱';

  /// 앱 아이콘과 소개 문구를 시스템 공유 시트에 전달한다.
  static Future<void> shareToInstagram() async {
    try {
      final directory = await getTemporaryDirectory();
      final promoFile = File('${directory.path}/$_promoFileName');
      final asset = await rootBundle.load(_promoAsset);
      final bytes =
          asset.buffer.asUint8List(asset.offsetInBytes, asset.lengthInBytes);
      await promoFile.writeAsBytes(bytes, flush: true);

      await Share.shareXFiles(
        [XFile(promoFile.path, mimeType: 'image/png')],
        text: _text,
      );
    } catch (e) {
      // 파일 공유가 지원되지 않는 환경도 소개 링크 자체는 보낼 수 있게 한다.
      lo.g('App promo media share error: $e');
      try {
        await Share.share(_text);
      } catch (fallbackError) {
        lo.g('App promo text share error: $fallbackError');
        Utils.alert('공유를 열지 못했습니다. 잠시 후 다시 시도해주세요.');
      }
    }
  }
}
