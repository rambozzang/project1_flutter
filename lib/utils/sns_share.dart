import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:project1/utils/log_utils.dart';
import 'package:project1/utils/utils.dart';

/// SNS(틱톡·인스타그램 등) 공유 헬퍼.
///
/// 영상/사진을 임시 파일로 내려받아 OS 공유 시트(share_plus)로 전달한다.
/// 사용자는 시트에서 틱톡·인스타그램·카카오톡 등 원하는 앱을 선택해 올린다.
/// (인스타·틱톡은 HLS(m3u8)를 받지 못하므로 반드시 mp4/이미지 URL을 넘길 것 —
///  mp4가 없으면 썸네일 이미지로 자동 폴백한다.)
class SnsShare {
  static const Color _accent = Color(0xFFEA3799);
  static bool _busy = false;

  /// [videoUrl](mp4 권장)이 유효하면 영상을, 아니면 [imageUrl]을 공유한다.
  /// 둘 다 없으면 [text]만 공유한다.
  static Future<void> shareMedia(
    BuildContext context, {
    String? videoUrl,
    String? imageUrl,
    String? text,
  }) async {
    if (_busy) return; // 연타 방지

    final String v = (videoUrl ?? '').trim();
    final String i = (imageUrl ?? '').trim();
    // mp4만 영상으로 취급(HLS는 SNS가 못 받음).
    final bool useVideo = v.startsWith('http') && !v.contains('.m3u8');
    final String? url = useVideo ? v : (i.startsWith('http') ? i : null);

    // 공유할 미디어가 없으면 텍스트만.
    if (url == null) {
      if ((text ?? '').isNotEmpty) await Share.share(text!);
      return;
    }

    _busy = true;
    final progress = ValueNotifier<double>(0);
    final cancelToken = CancelToken();
    _showProgressDialog(progress, cancelToken);

    try {
      final dir = await getTemporaryDirectory();
      final ext = useVideo ? 'mp4' : 'jpg';
      final path = '${dir.path}/skysnap_share_${DateTime.now().millisecondsSinceEpoch}.$ext';

      await Dio().download(
        url,
        path,
        cancelToken: cancelToken,
        onReceiveProgress: (rec, total) {
          if (total > 0) progress.value = rec / total;
        },
      );

      _closeDialog();
      await Share.shareXFiles(
        [XFile(path, mimeType: useVideo ? 'video/mp4' : 'image/jpeg')],
        text: text,
      );
    } on DioException catch (e) {
      _closeDialog();
      if (!CancelToken.isCancel(e)) {
        Utils.alert('공유할 파일을 불러오지 못했습니다. 잠시 후 다시 시도해주세요.');
      }
      lo.g('SnsShare download error: $e');
    } catch (e) {
      _closeDialog();
      Utils.alert('공유 중 오류가 발생했습니다.');
      lo.g('SnsShare error: $e');
    } finally {
      _busy = false;
    }
  }

  static void _showProgressDialog(ValueNotifier<double> progress, CancelToken cancelToken) {
    Get.dialog(
      PopScope(
        canPop: false,
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 22),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ValueListenableBuilder<double>(
                  valueListenable: progress,
                  builder: (_, v, __) => SizedBox(
                    width: 46,
                    height: 46,
                    child: CircularProgressIndicator(
                      value: v > 0 ? v : null,
                      strokeWidth: 4,
                      color: _accent,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('공유 준비 중...', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                ValueListenableBuilder<double>(
                  valueListenable: progress,
                  builder: (_, v, __) => Text(
                    '${(v * 100).clamp(0, 100).toStringAsFixed(0)}%',
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    if (!cancelToken.isCancelled) cancelToken.cancel('user_cancel');
                    _closeDialog();
                  },
                  child: const Text('취소', style: TextStyle(color: Colors.black54)),
                ),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  static void _closeDialog() {
    if (Get.isDialogOpen ?? false) Get.back();
  }
}
