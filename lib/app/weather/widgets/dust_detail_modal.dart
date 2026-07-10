import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:project1/app/weather/theme/textStyle.dart';
import 'package:project1/repo/mist_gogoapi/data/mist_data.dart';
import 'package:project1/utils/utils.dart';

// ── 팔레트 ──────────────────────────────────────────────────────────────────
// 한국 대기질 관례색(좋음 파랑 · 보통 초록 · 나쁨 주황 · 매우나쁨 빨강).
// 보통을 '초록'으로 두어 cyan-on-dark(AI 느낌)를 피하고, 채도를 살짝 낮춰 리포트 톤 유지.
const _cGood = Color(0xFF4C8DF5);
const _cModerate = Color(0xFF35B37A);
const _cBad = Color(0xFFE9A13A);
const _cVeryBad = Color(0xFFE05B49);

const _surface = Color(0xFF0F1626); // 시트 바탕 — 플랫(글로우 없음)
const _panel = Color(0xFF18213B); // 섹션 패널 — 플랫(반투명 유리 아님)
const _hair = Color(0xFF2A3654); // 헤어라인 구분선
const _ink = Color(0xFFE9EDF7); // 본문 — 순백 대신 남색 틴트
const _muted = Color(0xFF8A93AC); // 보조 텍스트

/// 날씨 메인 — 미세/초미세 상세 시트.
/// 편집형(에어 리포트) 톤: 플랫 서피스 + 수평 스케일 바("현 위치" 마커) + 스펙시트 리스트.
/// 원형 게이지·앰비언트 글로우·반투명 유리카드 등 정형화된 표현을 배제하고,
/// 정보(지금 값이 좋음~매우나쁨 스펙트럼의 어디인지)를 또렷하게 전달하는 데 집중한다.
class DustDetailModal extends StatelessWidget {
  const DustDetailModal({
    super.key,
    required this.mistData,
    this.locationName = '현재 위치',
  });

  final MistData mistData;
  final String locationName;

  static void show(
    BuildContext context,
    MistData? mistData, {
    String? pm10,
    String? pm25,
    String? pm10Grade,
    String? pm25Grade,
    String locationName = '현재 위치',
  }) {
    final effective = mistData ??
        _createFallback(
          pm10: pm10,
          pm25: pm25,
          pm10Grade: pm10Grade,
          pm25Grade: pm25Grade,
        );
    if (effective == null || effective.items == null || effective.items!.isEmpty) {
      Utils.alert('미세먼지 상세 정보를 불러오지 못했습니다.');
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DustDetailModal(
        mistData: effective,
        locationName: locationName,
      ),
    );
  }

  static MistData? _createFallback({
    String? pm10,
    String? pm25,
    String? pm10Grade,
    String? pm25Grade,
  }) {
    if ((pm10 == null || pm10.isEmpty) && (pm25 == null || pm25.isEmpty)) {
      return null;
    }
    return MistData(
      items: [
        MistItemData(
          pm10Value: pm10,
          pm25Value: pm25,
          pm10Grade: _gradeCode(pm10Grade),
          pm25Grade: _gradeCode(pm25Grade),
        ),
      ],
    );
  }

  static String? _gradeCode(String? grade) {
    return switch (grade) {
      '좋음' => '1',
      '보통' => '2',
      '나쁨' => '3',
      '매우나쁨' => '4',
      _ => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    final item = mistData.items?.firstOrNull;
    final statusGrade = _worstGrade(item);
    final statusColor = _colorForGrade(statusGrade);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 4),
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 26),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _header(context, item, statusGrade, statusColor),
                    const SizedBox(height: 22),
                    _pmSection(item),
                    const SizedBox(height: 24),
                    _indexSection(item),
                    const SizedBox(height: 24),
                    _standardTable(),
                    const SizedBox(height: 20),
                    _healthNote(item, statusColor),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 헤더 ──────────────────────────────────────────────────────────────────
  Widget _header(BuildContext context, MistItemData? item, String statusGrade, Color statusColor) {
    final dataTime = item?.dataTime;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const PhosphorIcon(PhosphorIconsFill.mapPin, color: _muted, size: 15),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                locationName,
                style: semiboldText.copyWith(fontSize: 15, color: _ink),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              behavior: HitTestBehavior.opaque,
              // 배경 없이(투명) 아이콘만 — 탭 영역은 넉넉히, 아이콘은 크게.
              child: Container(
                color: Colors.transparent,
                padding: const EdgeInsets.all(6),
                child: const PhosphorIcon(PhosphorIconsFill.x, color: _ink, size: 26),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        // 히어로 — 대표(최악) 등급 + 한 줄 안내. 좌측 정렬·비대칭 편집형 구성.
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              statusGrade,
              style: boldText.copyWith(
                fontSize: 32,
                height: 1.0,
                color: statusColor,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  _statusHeadline(statusGrade),
                  style: lightText.copyWith(fontSize: 12.5, height: 1.35, color: _muted),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          dataTime != null ? '측정 $dataTime 기준' : '측정시간 -',
          style: lightText.copyWith(fontSize: 11, color: _muted.withValues(alpha: 0.8)),
        ),
        const SizedBox(height: 16),
        Container(height: 1, color: _hair),
      ],
    );
  }

  // ── 미세/초미세 — 수평 스케일 바 ─────────────────────────────────────────
  Widget _pmSection(MistItemData? item) {
    return Column(
      children: [
        _pmRow('미세먼지', 'PM10', _parse(item?.pm10Value), _gradeText(item?.pm10Grade), pm10Breaks),
        const SizedBox(height: 20),
        _pmRow('초미세먼지', 'PM2.5', _parse(item?.pm25Value), _gradeText(item?.pm25Grade), pm25Breaks),
      ],
    );
  }

  Widget _pmRow(String name, String code, double value, String grade, List<double> breaks) {
    final color = _colorForGrade(grade);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(name, style: semiboldText.copyWith(fontSize: 15, color: _ink)),
            const SizedBox(width: 6),
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(code, style: lightText.copyWith(fontSize: 10.5, color: _muted)),
            ),
            const Spacer(),
            Text(
              value >= 0 ? value.toStringAsFixed(0) : '-',
              style: boldText.copyWith(
                fontSize: 25,
                height: 1.0,
                color: color,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(width: 3),
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Text('㎍/㎥', style: lightText.copyWith(fontSize: 10, color: _muted)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _ScaleBar(value: value, breaks: breaks, color: color),
        const SizedBox(height: 7),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('좋음', style: lightText.copyWith(fontSize: 10.5, color: _muted)),
            Text(
              grade == '-' ? '' : grade,
              style: TextStyle(fontSize: 11.5, color: color, fontWeight: FontWeight.w700),
            ),
            Text('매우나쁨', style: lightText.copyWith(fontSize: 10.5, color: _muted)),
          ],
        ),
      ],
    );
  }

  // ── 대기 지수 — 스펙시트 리스트(카드 그리드 대신 헤어라인 구분 행) ─────────
  Widget _indexSection(MistItemData? item) {
    final rows = <Widget>[
      _dataRow('통합대기환경지수', _fmt(_parse(item?.khaiValue), 0), '', _gradeText(item?.khaiGrade)),
      _dataRow('오존', _fmt(_parse(item?.o3Value), 3), 'ppm', _gradeText(item?.o3Grade)),
      _dataRow('이산화질소', _fmt(_parse(item?.no2Value), 3), 'ppm', _gradeText(item?.no2Grade)),
      _dataRow('아황산가스', _fmt(_parse(item?.so2Value), 3), 'ppm', _gradeText(item?.so2Grade)),
      _dataRow('일산화탄소', _fmt(_parse(item?.coValue), 2), 'ppm', _gradeText(item?.coGrade)),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('대기 지수', style: boldText.copyWith(fontSize: 15, color: _ink, letterSpacing: -0.2)),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              for (int i = 0; i < rows.length; i++) ...[
                if (i > 0) Container(height: 1, color: _hair),
                rows[i],
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _dataRow(String name, String valueStr, String unit, String grade) {
    final color = _colorForGrade(grade);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: Row(
        children: [
          Expanded(child: Text(name, style: mediumText.copyWith(fontSize: 13.5, color: _ink))),
          Text(
            valueStr,
            style: semiboldText.copyWith(
              fontSize: 14,
              color: _ink,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          if (unit.isNotEmpty) ...[
            const SizedBox(width: 3),
            Text(unit, style: lightText.copyWith(fontSize: 10.5, color: _muted)),
          ],
          const SizedBox(width: 12),
          SizedBox(
            width: 52,
            child: Text(
              grade,
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 12.5, color: color, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  // ── 기준표 — 플랫 테이블 ──────────────────────────────────────────────────
  Widget _standardTable() {
    final rows = [
      _StandardRow('좋음', '0~30', '0~15', '0~50', _cGood),
      _StandardRow('보통', '31~80', '16~35', '51~100', _cModerate),
      _StandardRow('나쁨', '81~150', '36~75', '101~250', _cBad),
      _StandardRow('매우나쁨', '151~', '76~', '251~', _cVeryBad),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('대기질 기준표', style: boldText.copyWith(fontSize: 15, color: _ink, letterSpacing: -0.2)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(16)),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(flex: 3, child: Text('등급', style: lightText.copyWith(fontSize: 11, color: _muted))),
                  Expanded(flex: 3, child: Text('미세', style: lightText.copyWith(fontSize: 11, color: _muted))),
                  Expanded(flex: 3, child: Text('초미세', style: lightText.copyWith(fontSize: 11, color: _muted))),
                  Expanded(flex: 3, child: Text('통합', style: lightText.copyWith(fontSize: 11, color: _muted))),
                ],
              ),
              const SizedBox(height: 6),
              for (int i = 0; i < rows.length; i++) ...[
                if (i > 0) Container(height: 1, color: _hair.withValues(alpha: 0.55)),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Row(
                          children: [
                            Container(width: 7, height: 7, decoration: BoxDecoration(color: rows[i].color, shape: BoxShape.circle)),
                            const SizedBox(width: 7),
                            Flexible(
                              child: Text(
                                rows[i].grade,
                                style: TextStyle(fontSize: 12, color: rows[i].color, fontWeight: FontWeight.w700),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(flex: 3, child: Text(rows[i].pm10, style: lightText.copyWith(fontSize: 11.5, color: _ink))),
                      Expanded(flex: 3, child: Text(rows[i].pm25, style: lightText.copyWith(fontSize: 11.5, color: _ink))),
                      Expanded(flex: 3, child: Text(rows[i].khai, style: lightText.copyWith(fontSize: 11.5, color: _ink))),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ── 건강 가이드 — 플랫 노트(그라디언트/글로우 없음) ───────────────────────
  Widget _healthNote(MistItemData? item, Color statusColor) {
    final pm10 = _parse(item?.pm10Value);
    final pm25 = _parse(item?.pm25Value);
    final worst = math.max(pm10 >= 0 ? pm10 / 150 : 0, pm25 >= 0 ? pm25 / 75 : 0);
    final tip = worst > 0.66
        ? '실외 활동을 자제하고 외출 시 마스크를 착용하세요. 창문을 닫아 실내 공기를 관리하는 것도 좋아요.'
        : worst > 0.33
            ? '민감하신 분은 실외 활동 시 마스크를 챙기고, 장시간 야외 활동은 줄이는 게 좋아요.'
            : '오늘은 공기가 깨끗해요. 가벼운 실외 활동을 즐기기 좋은 날이에요.';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(16)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 3),
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('오늘의 건강 가이드', style: semiboldText.copyWith(fontSize: 13, color: _ink)),
                const SizedBox(height: 6),
                Text(tip, style: lightText.copyWith(fontSize: 12.5, height: 1.55, color: _muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 로직 헬퍼 ─────────────────────────────────────────────────────────────
  // 최악(높은) 등급을 대표 상태로 — pm10/pm25 등급 중 나쁜 쪽.
  String _worstGrade(MistItemData? item) {
    final g10 = int.tryParse(item?.pm10Grade ?? '') ?? 0;
    final g25 = int.tryParse(item?.pm25Grade ?? '') ?? 0;
    final worst = math.max(g10, g25);
    return _gradeText(worst == 0 ? null : worst.toString());
  }

  String _statusHeadline(String grade) {
    return switch (grade) {
      '좋음' => '공기가 아주 깨끗해요.\n야외 활동을 즐기기 좋아요.',
      '보통' => '무난한 대기질이에요.\n민감군은 컨디션을 살펴보세요.',
      '나쁨' => '공기가 좋지 않아요.\n외출 시 마스크를 챙기세요.',
      '매우나쁨' => '대기질이 매우 나빠요.\n실외 활동을 자제하세요.',
      _ => '측정 정보를 확인해 보세요.',
    };
  }

  double _parse(String? value) {
    if (value == null) return -1;
    return double.tryParse(value) ?? -1;
  }

  String _fmt(double v, int digits) => v >= 0 ? v.toStringAsFixed(digits) : '-';

  String _gradeText(String? gradeCode) {
    switch (gradeCode) {
      case '1':
        return '좋음';
      case '2':
        return '보통';
      case '3':
        return '나쁨';
      case '4':
        return '매우나쁨';
      default:
        return '-';
    }
  }

  Color _colorForGrade(String grade) {
    return switch (grade) {
      '좋음' => _cGood,
      '보통' => _cModerate,
      '나쁨' => _cBad,
      '매우나쁨' => _cVeryBad,
      _ => _muted,
    };
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 수평 스케일 바 — 좋음→보통→나쁨→매우나쁨 4구간 위에 현재 값 위치를 마커로 표시.
// (원형 게이지 대신, "지금 값이 스펙트럼의 어디인지"를 직관적으로 보여주는 편집형 표현)
// ─────────────────────────────────────────────────────────────────────────────
class _ScaleBar extends StatelessWidget {
  final double value;
  final List<double> breaks; // [구간0끝, 구간1끝, 구간2끝]
  final Color color;

  const _ScaleBar({required this.value, required this.breaks, required this.color});

  // 값 → 트랙상의 위치(0~1). 각 구간을 등폭으로 두고 구간 내부 비율로 배치.
  double _markerPos() {
    if (value < 0) return -1;
    final b0 = breaks[0], b1 = breaks[1], b2 = breaks[2];
    double seg;
    double frac;
    if (value <= b0) {
      seg = 0;
      frac = b0 == 0 ? 0 : value / b0;
    } else if (value <= b1) {
      seg = 1;
      frac = (value - b0) / (b1 - b0);
    } else if (value <= b2) {
      seg = 2;
      frac = (value - b1) / (b2 - b1);
    } else {
      seg = 3;
      frac = ((value - b2) / b2).clamp(0.0, 1.0);
    }
    return ((seg + frac) / 4).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    const gradeColors = [_cGood, _cModerate, _cBad, _cVeryBad];
    final pos = _markerPos();
    final activeSeg = pos < 0 ? -1 : (pos * 4).floor().clamp(0, 3);

    return LayoutBuilder(
      builder: (ctx, c) {
        final w = c.maxWidth;
        const trackH = 9.0;
        const boxH = 16.0;
        return SizedBox(
          height: boxH,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                top: (boxH - trackH) / 2,
                left: 0,
                right: 0,
                child: Row(
                  children: List.generate(4, (i) {
                    return Expanded(
                      child: Container(
                        height: trackH,
                        margin: EdgeInsets.only(right: i < 3 ? 3 : 0),
                        decoration: BoxDecoration(
                          color: gradeColors[i].withValues(alpha: i == activeSeg ? 0.92 : 0.16),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              if (pos >= 0)
                Positioned(
                  left: (pos * w - 7).clamp(0.0, w - 14),
                  top: 1,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: color, width: 2.5),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 4, offset: const Offset(0, 1)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

const pm10Breaks = [30.0, 80.0, 150.0];
const pm25Breaks = [15.0, 35.0, 75.0];

class _StandardRow {
  final String grade;
  final String pm10;
  final String pm25;
  final String khai;
  final Color color;
  _StandardRow(this.grade, this.pm10, this.pm25, this.khai, this.color);
}
