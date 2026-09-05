import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:project1/app/shared_album/theme/sa_colors.dart';
import 'package:project1/app/shared_album/theme/sa_text_styles.dart';
import 'package:project1/oss_licenses.dart';

import 'package:url_launcher/url_launcher.dart';

/// 오픈소스 라이선스 상세 — 설정 화면(setting_page)과 같은 디자인 토큰(SaColors/SaText)을 쓴다.
/// 라이트 고정: `SaColors.syncWith(context)`를 부르지 않는다.
/// 라이선스 원문([_bodyText])은 손대지 않고 표현만 바꾼다.
class OpenSourceDetailPage extends StatelessWidget {
  final Package package;

  const OpenSourceDetailPage({super.key, required this.package});

  String _bodyText() {
    return package.license!.split('\n').map((line) {
      if (line.startsWith('//')) line = line.substring(2);
      line = line.trim();
      return line;
    }).join('\n');
  }

  @override
  Widget build(BuildContext context) {
    SaColors.isLight = true; // 라이트 고정 — 앨범 다크모드 잔류 방지
    return Scaffold(
      backgroundColor: SaColors.bgBase,
      appBar: AppBar(
        forceMaterialTransparency: true,
        automaticallyImplyLeading: false,
        // 뒤로가기 — setting_page와 같은 원형 surface 버튼(pill). 화면 좌측 패딩 16에 맞춘다.
        leadingWidth: 72,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Center(
            child: SizedBox(
              width: 40,
              height: 40,
              child: Material(
                color: SaColors.surface,
                shape: CircleBorder(side: BorderSide(color: SaColors.borderStrong)),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => Navigator.pop(context),
                  child: Center(
                    child: PhosphorIcon(PhosphorIconsBold.caretLeft, size: 17, color: SaColors.textPrimary),
                  ),
                ),
              ),
            ),
          ),
        ),
        title: Text('${package.name} ${package.version}', style: SaText.titleS),
        centerTitle: true,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: <Widget>[
          // 카드 r26 / surface / border / 내부 패딩 14 — 핸드오프 규격
          Material(
            color: SaColors.surface,
            borderRadius: BorderRadius.circular(26),
            clipBehavior: Clip.antiAlias,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: SaColors.border),
              ),
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (package.description.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(package.description,
                          style: SaText.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
                    ),
                  if (package.homepage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        child: Text(package.homepage!,
                            style: SaText.body.copyWith(
                              color: SaColors.accentTeal,
                              decoration: TextDecoration.underline,
                              decorationColor: SaColors.accentTeal,
                            )),
                        onTap: () => launch(package.homepage!),
                      ),
                    ),
                  if (package.description.isNotEmpty || package.homepage != null)
                    Divider(color: SaColors.border, height: 13, thickness: 1),
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(_bodyText(), style: SaText.body.copyWith(color: SaColors.textPrimary)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
