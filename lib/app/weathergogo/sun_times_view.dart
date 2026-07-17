import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' as intl;
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:project1/app/weathergogo/cntr/weather_gogo_cntr.dart';
import 'package:project1/app/weathergogo/services/sun_times.dart';

/// 주간예보 아래 — 오늘 일출·일몰을 '작은 지구 반원(위성사진) + 태양 궤도'로 컴팩트 표현.
/// 탭하면 7일 일출·일몰 리스트가 모달로 뜬다. (위·경도 로컬 계산, 외부 API 없음)
class SunTimesView extends StatelessWidget {
  const SunTimesView({super.key});

  static const Color _riseColor = Color(0xFFFFC066); // 일출
  static const Color _setColor = Color(0xFF9FB6FF); // 일몰
  static const double _earthR = 50; // 지구(반원) 반지름
  static const double _orbitGap = 15; // 지표~태양궤도 간격
  static const double _stackH = 98; // 아크 영역 높이(컴팩트)
  static const double _earthVisibleFrac =
      0.6; // 지구 원의 상단 노출 비율(heightFactor와 동일해야 궤도가 동심)

  @override
  Widget build(BuildContext context) {
    final cntr = Get.find<WeatherGogoCntr>();
    return Obx(() {
      final latLng = cntr.currentLocation.value.latLng;
      if (latLng.latitude.abs() < 0.001 && latLng.longitude.abs() < 0.001) {
        return const SizedBox.shrink();
      }
      final double lat = latLng.latitude;
      final double lng = latLng.longitude;
      final DateTime nowKst =
          DateTime.now().toUtc().add(const Duration(hours: 9));
      final DateTime base = DateTime(nowKst.year, nowKst.month, nowKst.day);
      final SunTimes sun = computeSunTimes(lat, lng, base);
      if (!sun.hasData) return const SizedBox.shrink();

      final int riseM = sun.sunrise!.hour * 60 + sun.sunrise!.minute;
      final int setM = sun.sunset!.hour * 60 + sun.sunset!.minute;
      final int nowM = nowKst.hour * 60 + nowKst.minute;
      final double progress = (setM > riseM)
          ? ((nowM - riseM) / (setM - riseM)).clamp(0.0, 1.0)
          : 0.0;
      final bool isDay = nowM >= riseM && nowM <= setM;
      final String rise = intl.DateFormat('HH:mm').format(sun.sunrise!);
      final String set = intl.DateFormat('HH:mm').format(sun.sunset!);

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 14),
            _buildHeader(),
            const SizedBox(height: 6),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _showWeekModal(context, lat, lng, base),
              child: Container(
                padding: const EdgeInsets.fromLTRB(10, 1, 10, 7),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(18),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.06)),
                ),
                child: Column(
                  children: [
                    SizedBox(
                      height: _stackH,
                      child: _AnimatedSunOrbit(
                        progress: progress,
                        isDay: isDay,
                        rise: rise,
                        set: set,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('7일 일출·일몰',
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.white.withValues(alpha: 0.55),
                                fontWeight: FontWeight.w500)),
                        Icon(Icons.chevron_right,
                            size: 14,
                            color: Colors.white.withValues(alpha: 0.55)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],
        ),
      );
    });
  }

  Widget _buildHeader() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        children: [
          PhosphorIcon(PhosphorIconsRegular.sunHorizon,
              color: Colors.white, size: 20),
          SizedBox(width: 5),
          Text('일출 · 일몰',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
        ],
      ),
    );
  }

  Widget _timeTag(IconData icon, String time, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        PhosphorIcon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Text(
          time,
          style: TextStyle(
              fontSize: 16,
              color: color,
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()]),
        ),
      ],
    );
  }

  // ── 7일 모달 ────────────────────────────────────────────────────────────
  void _showWeekModal(
      BuildContext context, double lat, double lng, DateTime base) {
    final List<DateTime> days =
        List.generate(7, (i) => base.add(Duration(days: i)));
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF121834),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 6),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2)),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 6, 20, 10),
                  child: Row(
                    children: [
                      PhosphorIcon(PhosphorIconsRegular.sunHorizon,
                          color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text('7일 일출 · 일몰',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                  child: Column(
                    children: [
                      for (final d in days)
                        _weekRow(
                            d, computeSunTimes(lat, lng, d), d.day == base.day),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _weekRow(DateTime date, SunTimes sun, bool isToday) {
    final String dateLabel =
        isToday ? '오늘' : intl.DateFormat('dd(E)', 'ko').format(date);
    final String rise = sun.sunrise != null
        ? intl.DateFormat('HH:mm').format(sun.sunrise!)
        : '--:--';
    final String set = sun.sunset != null
        ? intl.DateFormat('HH:mm').format(sun.sunset!)
        : '--:--';
    return Container(
      margin: const EdgeInsets.only(bottom: 3),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color:
            isToday ? Colors.white.withValues(alpha: 0.10) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 62,
            child: Text(dateLabel,
                style: TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: isToday ? FontWeight.bold : FontWeight.w500)),
          ),
          const Spacer(),
          _timeTag(PhosphorIconsFill.sunHorizon, rise, _riseColor),
          const SizedBox(width: 22),
          _timeTag(PhosphorIconsFill.moonStars, set, _setColor),
        ],
      ),
    );
  }
}

/// 일출 지점에서 현재 위치까지 태양과 지나온 궤도를 한 번만 함께 보여준다.
/// 야간 및 시스템의 모션 줄이기 설정에서는 현재 상태를 즉시 표시한다.
class _AnimatedSunOrbit extends StatefulWidget {
  final double progress;
  final bool isDay;
  final String rise;
  final String set;

  const _AnimatedSunOrbit(
      {required this.progress,
      required this.isDay,
      required this.rise,
      required this.set});

  @override
  State<_AnimatedSunOrbit> createState() => _AnimatedSunOrbitState();
}

class _AnimatedSunOrbitState extends State<_AnimatedSunOrbit>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final AnimationController _fadeController;
  late final Animation<double> _travel;
  late final Animation<double> _arrivalPulse;
  bool _motionConfigured = false;
  bool _reduceMotion = false;
  bool _cycleRunning = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _fadeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 260), value: 1);
    _travel = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, 0.78, curve: Curves.easeOutQuart),
    );
    _arrivalPulse = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween<double>(0), weight: 78),
      TweenSequenceItem(
          tween: Tween<double>(begin: 0, end: 1)
              .chain(CurveTween(curve: Curves.easeOutQuart)),
          weight: 11),
      TweenSequenceItem(
          tween: Tween<double>(begin: 1, end: 0)
              .chain(CurveTween(curve: Curves.easeInOut)),
          weight: 11),
    ]).animate(_controller);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_motionConfigured) return;
    _motionConfigured = true;
    _reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (_reduceMotion || !widget.isDay) {
      _controller.value = 1;
    } else {
      _startCycle();
    }
  }

  @override
  void didUpdateWidget(covariant _AnimatedSunOrbit oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_motionConfigured ||
        _reduceMotion ||
        oldWidget.isDay == widget.isDay) {
      return;
    }
    if (widget.isDay) {
      _startCycle();
    } else {
      _controller
        ..stop()
        ..value = 1;
      _fadeController
        ..stop()
        ..value = 1;
    }
  }

  Future<void> _startCycle() async {
    if (_cycleRunning) return;
    _cycleRunning = true;
    try {
      while (mounted && widget.isDay && !_reduceMotion) {
        _controller.value = 0;
        _fadeController.forward(from: 0);
        await _controller.forward().orCancel;
        await Future<void>.delayed(const Duration(seconds: 4));
        if (!mounted || !widget.isDay || _reduceMotion) break;
        await _fadeController.reverse(from: 1).orCancel;
        await Future<void>.delayed(const Duration(milliseconds: 500));
      }
    } on TickerCanceled {
      // 위젯이 사라지거나 낮/밤 상태가 바뀌면 현재 반복을 조용히 종료한다.
    } finally {
      _cycleRunning = false;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: LayoutBuilder(
        builder: (context, cons) {
          final double cx = cons.maxWidth / 2;
          const double r = SunTimesView._earthR + SunTimesView._orbitGap;
          const double earthCy = SunTimesView._stackH -
              SunTimesView._earthR * 2 * SunTimesView._earthVisibleFrac +
              SunTimesView._earthR;
          const double horizonDy = SunTimesView._stackH - earthCy;
          final double sunkAngle = math.asin((horizonDy / r).clamp(-1.0, 1.0));
          final double startAngle = math.pi - sunkAngle;
          final double sweepAngle = math.pi + 2 * sunkAngle;

          return AnimatedBuilder(
            animation: Listenable.merge([_controller, _fadeController]),
            builder: (context, _) {
              final double animatedProgress = widget.progress * _travel.value;
              final double theta = startAngle + sweepAngle * animatedProgress;
              final Offset sunPos = Offset(
                  cx + r * math.cos(theta), earthCy + r * math.sin(theta));
              const double sunSize = 26;
              final double daylight =
                  math.sin(math.pi * animatedProgress).clamp(0.0, 1.0);

              return Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.bottomCenter,
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _SunOrbitPainter(
                        progress: animatedProgress,
                        isDay: widget.isDay,
                        earthR: SunTimesView._earthR,
                        orbitGap: SunTimesView._orbitGap,
                        earthCenterY: earthCy,
                        startAngle: startAngle,
                        sweepAngle: sweepAngle,
                        highlightOpacity: _fadeController.value,
                        travelPhase: _controller.value,
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: ClipRect(
                      child: Align(
                        alignment: Alignment.topCenter,
                        heightFactor: SunTimesView._earthVisibleFrac,
                        child: SizedBox(
                          width: SunTimesView._earthR * 2,
                          height: SunTimesView._earthR * 2,
                          child: ClipOval(
                            child: Transform.scale(
                              scale: 1.15,
                              child: const _RotatingEarth(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // 태양 고도에 맞춰 지구 표면에도 아주 얕은 낮빛을 얹는다.
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: ClipRect(
                      child: Align(
                        alignment: Alignment.topCenter,
                        heightFactor: SunTimesView._earthVisibleFrac,
                        child: Opacity(
                          opacity:
                              _fadeController.value * (0.06 + daylight * 0.12),
                          child: Container(
                            width: SunTimesView._earthR * 2,
                            height: SunTimesView._earthR * 2,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                center: Alignment(-0.25, -0.85),
                                radius: 0.9,
                                colors: [Color(0xFFFFD77B), Colors.transparent],
                                stops: [0, 0.78],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (widget.isDay)
                    Positioned(
                      left: sunPos.dx - sunSize / 2,
                      top: sunPos.dy - sunSize / 2,
                      child: Opacity(
                        opacity: _fadeController.value,
                        child: Transform.scale(
                          scale: 1 + _arrivalPulse.value * 0.07,
                          child: _sunWidget(sunSize),
                        ),
                      ),
                    ),
                  Positioned(
                    left: 2,
                    bottom: 0,
                    child: _timeTag(PhosphorIconsFill.sunHorizon, widget.rise,
                        SunTimesView._riseColor),
                  ),
                  Positioned(
                    right: 2,
                    bottom: 0,
                    child: _timeTag(PhosphorIconsFill.moonStars, widget.set,
                        SunTimesView._setColor),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _sunWidget(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
              color: const Color(0xFFFFD36E).withValues(alpha: 0.65),
              blurRadius: 12,
              spreadRadius: 1),
        ],
      ),
      child: ClipOval(
        child: Transform.scale(
          scale: 1.28,
          child: Image.asset('assets/images/sun_disk.jpg', fit: BoxFit.cover),
        ),
      ),
    );
  }

  Widget _timeTag(IconData icon, String time, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        PhosphorIcon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Text(
          time,
          style: TextStyle(
            fontSize: 16,
            color: color,
            fontWeight: FontWeight.w700,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

/// 2:1 지구 표면 텍스처를 원 안에서 이어 흘려 보내고 명암을 얹어 가벼운 3D 자전을 만든다.
/// 별도 3D 엔진 없이 transform만 움직이며, TickerMode/모션 줄이기 설정을 따른다.
class _RotatingEarth extends StatefulWidget {
  const _RotatingEarth();

  @override
  State<_RotatingEarth> createState() => _RotatingEarthState();
}

class _RotatingEarthState extends State<_RotatingEarth>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rotation;
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    _rotation = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 24),
      value: 0.58, // 첫 화면은 한국이 포함된 아시아 쪽에서 시작한다.
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bool reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (_reduceMotion == reduceMotion &&
        (_rotation.isAnimating || reduceMotion)) {
      return;
    }
    _reduceMotion = reduceMotion;
    if (_reduceMotion) {
      _rotation.stop();
    } else {
      _rotation.repeat();
    }
  }

  @override
  void dispose() {
    _rotation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: ClipOval(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double textureWidth = constraints.maxWidth * 2;
            return AnimatedBuilder(
              animation: _rotation,
              builder: (context, _) {
                final double offset = -textureWidth * _rotation.value;
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    Transform.translate(
                      offset: Offset(offset, 0),
                      child: OverflowBox(
                        alignment: Alignment.centerLeft,
                        minWidth: textureWidth * 2,
                        maxWidth: textureWidth * 2,
                        child: Row(
                          children: [
                            _earthTexture(textureWidth),
                            _earthTexture(textureWidth),
                          ],
                        ),
                      ),
                    ),
                    // 가장자리 음영이 평면 지도를 구체처럼 보이게 한다.
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0x99051020),
                            Color(0x12051020),
                            Color(0x08051020),
                            Color(0x8F051020),
                          ],
                          stops: [0, 0.32, 0.6, 1],
                        ),
                      ),
                    ),
                    // 좌상단의 작은 반사광으로 구면 방향을 고정한다.
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment(-0.42, -0.58),
                          radius: 0.78,
                          colors: [Color(0x38FFFFFF), Colors.transparent],
                          stops: [0, 0.72],
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _earthTexture(double width) {
    return SizedBox(
      width: width,
      height: double.infinity,
      child: Image.asset(
        'assets/images/earth_equirectangular_v2.jpg',
        fit: BoxFit.fill,
        filterQuality: FilterQuality.low,
      ),
    );
  }
}

/// 지구 반원 위로 태양 궤도(반원)와 현재 태양/달 위치를 그린다.
class _SunOrbitPainter extends CustomPainter {
  final double progress; // 0(일출)~1(일몰)
  final bool isDay;
  final double earthR;
  final double orbitGap;
  final double earthCenterY; // 지구 원의 실제 중심 y(상단만 노출되므로 하단보다 위)
  final double startAngle; // 궤도 시작각(지구 노출 하단=수평선에 맞춤)
  final double sweepAngle; // 궤도 스윕각(π + 2·내림각)
  final double highlightOpacity; // 반복 사이에 현재 궤도만 자연스럽게 숨긴다.
  final double travelPhase; // 전체 이동 애니메이션 진행률.
  _SunOrbitPainter(
      {required this.progress,
      required this.isDay,
      required this.earthR,
      required this.orbitGap,
      required this.earthCenterY,
      required this.startAngle,
      required this.sweepAngle,
      required this.highlightOpacity,
      required this.travelPhase});

  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2;
    final double baseY = earthCenterY; // 지구와 동심원 — 지표~궤도 간격이 전 구간 일정
    final double r = earthR + orbitGap; // 태양 궤도 반지름
    final Rect rect = Rect.fromCircle(center: Offset(cx, baseY), radius: r);
    final double p = progress.clamp(0.0, 1.0);

    // 일출 직후 지평선에 번지는 여명. 태양이 오르면 빠르게 잦아든다.
    if (isDay && highlightOpacity > 0) {
      final double dawn =
          (1 - travelPhase / 0.42).clamp(0.0, 1.0) * highlightOpacity;
      final Offset horizon = Offset(
        cx + r * math.cos(startAngle),
        baseY + r * math.sin(startAngle),
      );
      final Rect glowRect = Rect.fromCircle(center: horizon, radius: 34);
      canvas.drawCircle(
        horizon,
        34,
        Paint()
          ..shader = RadialGradient(colors: [
            const Color(0xFFFFD078).withValues(alpha: dawn * 0.34),
            const Color(0xFFFFB25C).withValues(alpha: dawn * 0.12),
            Colors.transparent,
          ], stops: const [
            0,
            0.42,
            1
          ]).createShader(glowRect),
      );
    }

    // 궤도 배경.
    canvas.drawArc(
      rect,
      startAngle,
      sweepAngle,
      false,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.16)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round,
    );

    // 지나온 낮 부분(일출→현재).
    if (p > 0) {
      canvas.drawArc(
        rect,
        startAngle,
        sweepAngle * p,
        false,
        Paint()
          ..shader = LinearGradient(colors: [
            const Color(0xFFFFB65C).withValues(alpha: highlightOpacity),
            const Color(0xFFFFE49A).withValues(alpha: highlightOpacity),
            const Color(0xFF9FB6FF).withValues(alpha: highlightOpacity),
          ]).createShader(rect)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round,
      );

      // 태양 뒤를 따라오는 소수의 빛 입자. 개수를 제한해 작은 화면에서도 절제한다.
      if (isDay && highlightOpacity > 0) {
        for (int i = 1; i <= 3; i++) {
          final double particleP = p - i * 0.035;
          if (particleP <= 0) continue;
          final double particleTheta = startAngle + sweepAngle * particleP;
          final Offset particle = Offset(
            cx + r * math.cos(particleTheta),
            baseY + r * math.sin(particleTheta),
          );
          final double alpha = highlightOpacity * (0.58 - i * 0.11);
          final double radius = 2.5 - i * 0.35;
          canvas.drawCircle(
            particle,
            radius + 2,
            Paint()
              ..color = const Color(0xFFFFD77B).withValues(alpha: alpha * 0.18),
          );
          canvas.drawCircle(
            particle,
            radius,
            Paint()..color = const Color(0xFFFFE9AC).withValues(alpha: alpha),
          );
        }
      }

      // 도착 순간 현재 위치 주위로 한 번만 퍼지는 얇은 빛의 고리.
      final double arrival = ((travelPhase - 0.78) / 0.22).clamp(0.0, 1.0);
      if (arrival > 0 && isDay) {
        final double theta = startAngle + sweepAngle * p;
        final Offset current = Offset(
          cx + r * math.cos(theta),
          baseY + r * math.sin(theta),
        );
        canvas.drawCircle(
          current,
          15 + arrival * 7,
          Paint()
            ..color = const Color(0xFFFFE49A)
                .withValues(alpha: (1 - arrival) * 0.28 * highlightOpacity)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2,
        );
      }
    }

    // 태양은 위성사진(Positioned Image)으로 궤도 위에 얹으므로 여기선 궤도만 그린다.
  }

  @override
  bool shouldRepaint(covariant _SunOrbitPainter old) =>
      old.progress != progress ||
      old.isDay != isDay ||
      old.startAngle != startAngle ||
      old.sweepAngle != sweepAngle ||
      old.highlightOpacity != highlightOpacity ||
      old.travelPhase != travelPhase;
}
