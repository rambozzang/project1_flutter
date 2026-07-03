import 'dart:io';

import 'package:exif/exif.dart';
import 'package:project1/utils/log_utils.dart';

/// 사진 파일의 EXIF 촬영일시(DateTimeOriginal)를 ISO-8601 문자열로 반환.
/// EXIF가 없으면 null(→ 서버가 업로드일로 폴백). 순수 Dart라 네이티브 의존 없음.
class ExifUtil {
  ExifUtil._();

  /// 여러 사진 중 가장 이른 촬영일(앨범 타임라인은 게시물 대표 촬영일 1개만 필요).
  static Future<String?> earliestCapturedAt(List<File> files) async {
    DateTime? earliest;
    for (final f in files) {
      final dt = await capturedAt(f);
      if (dt == null) continue;
      if (earliest == null || dt.isBefore(earliest)) earliest = dt;
    }
    return earliest?.toIso8601String();
  }

  static Future<DateTime?> capturedAt(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final data = await readExifFromBytes(bytes);
      if (data.isEmpty) return null;
      // 우선순위: DateTimeOriginal > DateTimeDigitized > DateTime
      final raw = (data['EXIF DateTimeOriginal'] ??
              data['EXIF DateTimeDigitized'] ??
              data['Image DateTime'])
          ?.printable;
      if (raw == null || raw.isEmpty) return null;
      // EXIF 형식: "2024:06:01 15:30:00" → DateTime
      final m = RegExp(r'^(\d{4}):(\d{2}):(\d{2})\s+(\d{2}):(\d{2}):(\d{2})').firstMatch(raw.trim());
      if (m == null) return null;
      return DateTime(
        int.parse(m.group(1)!),
        int.parse(m.group(2)!),
        int.parse(m.group(3)!),
        int.parse(m.group(4)!),
        int.parse(m.group(5)!),
        int.parse(m.group(6)!),
      );
    } catch (e) {
      lo.g('EXIF 촬영일 추출 실패: $e');
      return null;
    }
  }
}
