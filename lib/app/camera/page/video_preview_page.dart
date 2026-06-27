import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:video_player/video_player.dart';

/// 영상 미리보기 페이지 — 인스타/틱톡 스타일 고도화
/// 기능: 재생/일시정지, 시크바, 배속(6단계), 음소거, 더블탭 스킵,
///       볼륨/밝기 드래그, 핀치줌, 필터(6종), 텍스트 스티커, 스냅샷
class VideoPreviewPage extends StatefulWidget {
  final VideoPlayerController videoPlayerController;

  const VideoPreviewPage({super.key, required this.videoPlayerController});

  @override
  State<VideoPreviewPage> createState() => _VideoPreviewPageState();
}

class _VideoPreviewPageState extends State<VideoPreviewPage>
    with SingleTickerProviderStateMixin {
  static const Color _accent = Color(0xFF4C8DFF);
  static const Color _textHi = Color(0xFFF2F5FA);

  bool _initialized = false;
  bool _showControls = true;
  bool _isDragging = false;
  bool _muted = false;
  double _speed = 1.0;
  double _volume = 1.0;
  double _brightness = 1.0; // 0(어두움) ~ 1(원본)
  late Timer _hideTimer;

  // 더블탭 리플
  AnimationController? _rippleAnim;
  bool _rippleIsForward = true;

  // 핀치줌
  double _scale = 1.0;
  double _prevScale = 1.0;

  // 필터
  int _filterIndex = 0;
  static const _filterList = <String>['원본', '따뜻', '시원', '흑백', '빈티지', '선명'];

  // 텍스트 스티커
  final List<_TextSticker> _stickers = [];
  bool _showStickerInput = false;
  final TextEditingController _stickerController = TextEditingController();

  // 스냅샷
  final GlobalKey _screenshotKey = GlobalKey();

  static const List<double> _speeds = [0.25, 0.5, 1.0, 1.5, 2.0, 3.0];

  @override
  void initState() {
    super.initState();
    _ensureInit();
    _hideTimer = Timer(const Duration(seconds: 4), _hideControls);
  }

  Future<void> _ensureInit() async {
    if (!widget.videoPlayerController.value.isInitialized) {
      await widget.videoPlayerController.initialize();
    }
    widget.videoPlayerController.setLooping(true);
    widget.videoPlayerController.setVolume(1.0);
    widget.videoPlayerController.play();
    widget.videoPlayerController.addListener(_listener);
    if (mounted) setState(() => _initialized = true);
  }

  void _listener() {
    if (mounted && !_isDragging) setState(() {});
  }

  void _togglePlayPause() {
    final c = widget.videoPlayerController;
    if (c.value.isPlaying) {
      c.pause();
    } else {
      c.play();
    }
    _showControlsOverlay();
  }

  void _toggleMute() {
    _muted = !_muted;
    widget.videoPlayerController.setVolume(_muted ? 0 : _volume);
    _showControlsOverlay();
  }

  void _cycleSpeed() {
    final idx = _speeds.indexOf(_speed);
    _speed = _speeds[(idx + 1) % _speeds.length];
    widget.videoPlayerController.setPlaybackSpeed(_speed);
    _showControlsOverlay();
  }

  void _seekRelative(int seconds) {
    final c = widget.videoPlayerController;
    var pos = c.value.position + Duration(seconds: seconds);
    if (pos < Duration.zero) pos = Duration.zero;
    if (pos > c.value.duration) pos = c.value.duration;
    c.seekTo(pos);
  }

  void _triggerRipple(bool forward) {
    _rippleIsForward = forward;
    _rippleAnim?.dispose();
    _rippleAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))..forward();
    setState(() {});
  }

  void _showControlsOverlay() {
    if (!_showControls) setState(() => _showControls = true);
    _hideTimer.cancel();
    _hideTimer = Timer(const Duration(seconds: 4), _hideControls);
  }

  void _hideControls() {
    if (mounted) setState(() => _showControls = false);
  }

  String _fmt(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.inMinutes)}:${two(d.inSeconds.remainder(60))}';
  }

  void _addSticker() {
    final text = _stickerController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _stickers.add(_TextSticker(text: text));
      _showStickerInput = false;
    });
    _stickerController.clear();
  }

  Future<void> _captureSnapshot() async {
    try {
      final boundary = _screenshotKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final bytes = byteData.buffer.asUint8List();
      final tempDir = Directory.systemTemp;
      final file = File('${tempDir.path}/snapshot_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(bytes);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('스냅샷 저장됨: ${file.path}'),
            backgroundColor: _accent,
          ),
        );
      }
    } catch (e) {
      debugPrint('snapshot error: $e');
    }
  }

  @override
  void dispose() {
    _hideTimer.cancel();
    _rippleAnim?.dispose();
    _stickerController.dispose();
    widget.videoPlayerController.removeListener(_listener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _showControls
          ? AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              forceMaterialTransparency: true,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: _textHi),
                onPressed: () => Navigator.pop(context),
              ),
              title: const Text('미리보기', style: TextStyle(color: _textHi, fontSize: 16)),
              actions: [
                IconButton(
                  icon: const Icon(Icons.photo_camera_outlined, color: _textHi, size: 22),
                  onPressed: _captureSnapshot,
                  tooltip: '스냅샷',
                ),
              ],
            )
          : null,
      body: !_initialized
          ? const Center(child: CircularProgressIndicator(color: _accent))
          : GestureDetector(
              onTap: _showControlsOverlay,
              onDoubleTapDown: (details) {
                final w = MediaQuery.of(context).size.width;
                final isLeft = details.globalPosition.dx < w / 2;
                _seekRelative(isLeft ? -10 : 10);
                _triggerRipple(!isLeft);
              },
              onVerticalDragUpdate: (details) {
                final w = MediaQuery.of(context).size.width;
                final dx = details.globalPosition.dx;
                if (dx >= w / 2) {
                  // 우측: 볼륨
                  setState(() {
                    _volume = (_volume - details.delta.dy * 0.005).clamp(0.0, 1.0);
                    _muted = _volume == 0;
                    widget.videoPlayerController.setVolume(_volume);
                  });
                } else {
                  // 좌측: 밝기
                  setState(() {
                    _brightness = (_brightness - details.delta.dy * 0.005).clamp(0.2, 1.0);
                  });
                }
              },
              onScaleStart: (_) => _prevScale = _scale,
              onScaleUpdate: (details) {
                setState(() {
                  _scale = (_prevScale * details.scale).clamp(1.0, 4.0);
                });
              },
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // 영상 + 필터 + 밝기 + 스티커 (RepaintBoundary로 스냅샷 캡처)
                  RepaintBoundary(
                    key: _screenshotKey,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // 영상 (핀치줌 + cover)
                        Transform.scale(
                          scale: _scale,
                          child: ColorFiltered(
                            colorFilter: ColorFilter.matrix(_filterMatrix(_filterIndex)),
                            child: FittedBox(
                              fit: BoxFit.cover,
                              clipBehavior: Clip.hardEdge,
                              child: SizedBox(
                                width: widget.videoPlayerController.value.size.width,
                                height: widget.videoPlayerController.value.size.height,
                                child: VideoPlayer(widget.videoPlayerController),
                              ),
                            ),
                          ),
                        ),
                        // 밝기 오버레이 (어둡게)
                        if (_brightness < 1.0)
                          IgnorePointer(
                            child: Container(
                              color: Colors.black.withOpacity((1.0 - _brightness) * 0.6),
                            ),
                          ),
                        // 텍스트 스티커
                        ..._stickers.map((s) => s.build(
                              onMove: (offset) => setState(() => s.offset += offset),
                              onRemove: () => setState(() => _stickers.remove(s)),
                            )),
                      ],
                    ),
                  ),
                  // 더블탭 리플
                  _buildRippleFeedback(),
                  // 중앙 재생/일시정지
                  if (_showControls) _buildCenterPlayPause(),
                  // 하단 컨트롤
                  if (_showControls) _buildBottomControls(),
                  // 상단 우측 버튼
                  if (_showControls) _buildTopControls(),
                  // 필터 선택 바 (하단 위)
                  if (_showControls) _buildFilterBar(),
                  // 텍스트 스티커 입력
                  if (_showStickerInput) _buildStickerInput(),
                ],
              ),
            ),
    );
  }

  // ==================== 위젯 빌더 ====================

  Widget _buildRippleFeedback() {
    if (_rippleAnim == null) return const SizedBox.shrink();
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _rippleAnim!,
        builder: (context, child) {
          if (_rippleAnim!.value > 0.9) return const SizedBox.shrink();
          final opacity = (1 - _rippleAnim!.value).clamp(0.0, 1.0);
          return Align(
            alignment: _rippleIsForward ? Alignment.centerRight : Alignment.centerLeft,
            child: Padding(
              padding: EdgeInsets.only(right: _rippleIsForward ? 60 : 0, left: _rippleIsForward ? 0 : 60),
              child: Opacity(
                opacity: opacity,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _rippleIsForward ? Icons.fast_forward_rounded : Icons.fast_rewind_rounded,
                      color: Colors.white,
                      size: 40 * (1 + _rippleAnim!.value * 0.3),
                    ),
                    const SizedBox(height: 4),
                    Text(_rippleIsForward ? '+10초' : '-10초',
                        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCenterPlayPause() {
    return Center(
      child: GestureDetector(
        onTap: _togglePlayPause,
        child: AnimatedOpacity(
          opacity: widget.videoPlayerController.value.isPlaying ? 0.0 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
            child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 40),
          ),
        ),
      ),
    );
  }

  Widget _buildTopControls() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      right: 12,
      child: Row(
        children: [
          _circleBtn(onTap: _toggleMute, icon: _muted ? Icons.volume_off_rounded : Icons.volume_up_rounded),
          const Gap(8),
          _circleBtn(
            onTap: _cycleSpeed,
            child: Text('${_speed}x', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
          ),
          const Gap(8),
          _circleBtn(
            onTap: () => setState(() => _showStickerInput = !_showStickerInput),
            icon: Icons.text_fields_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: MediaQuery.of(context).padding.bottom + 80,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(_filterList.length, (i) {
              final active = i == _filterIndex;
              return GestureDetector(
                onTap: () => setState(() => _filterIndex = i),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: active ? _accent : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    _filterList[i],
                    style: TextStyle(
                      color: active ? Colors.white : Colors.white60,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    final c = widget.videoPlayerController;
    final pos = c.value.position;
    final dur = c.value.duration;
    final progress = dur.inMilliseconds > 0 ? pos.inMilliseconds / dur.inMilliseconds : 0.0;

    return Positioned(
      left: 12,
      right: 12,
      bottom: MediaQuery.of(context).padding.bottom + 8,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_fmt(pos), style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600)),
                Text(_fmt(dur), style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(height: 4),
          LayoutBuilder(
            builder: (context, constraints) {
              final barWidth = constraints.maxWidth;
              return GestureDetector(
                onTapDown: (details) {
                  final ratio = (details.localPosition.dx / barWidth).clamp(0.0, 1.0);
                  c.seekTo(Duration(milliseconds: (ratio * dur.inMilliseconds).toInt()));
                },
                onHorizontalDragUpdate: (details) {
                  setState(() => _isDragging = true);
                  final ratio = (details.localPosition.dx / barWidth).clamp(0.0, 1.0);
                  c.seekTo(Duration(milliseconds: (ratio * dur.inMilliseconds).toInt()));
                },
                onHorizontalDragEnd: (_) {
                  _isDragging = false;
                  _showControlsOverlay();
                },
                child: Container(
                  height: 28,
                  alignment: Alignment.center,
                  child: Stack(
                    clipBehavior: Clip.hardEdge,
                    children: [
                      Container(
                        height: _isDragging ? 5 : 3,
                        decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(3)),
                      ),
                      FractionallySizedBox(
                        widthFactor: progress.clamp(0.0, 1.0),
                        child: Container(
                          height: _isDragging ? 5 : 3,
                          decoration: BoxDecoration(color: _accent, borderRadius: BorderRadius.circular(3)),
                        ),
                      ),
                      if (_isDragging)
                        Positioned(
                          left: (progress.clamp(0.0, 1.0) * barWidth) - 7,
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 4)],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStickerInput() {
    return Positioned(
      left: 16,
      right: 16,
      bottom: MediaQuery.of(context).padding.bottom + 150,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _stickerController,
                style: const TextStyle(color: Colors.white, fontSize: 15),
                decoration: const InputDecoration(
                  hintText: '텍스트 입력...',
                  hintStyle: TextStyle(color: Colors.white38),
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => _addSticker(),
                autofocus: true,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.check_circle, color: _accent),
              onPressed: _addSticker,
            ),
          ],
        ),
      ),
    );
  }

  Widget _circleBtn({required VoidCallback onTap, IconData? icon, Widget? child}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.black54,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white24),
        ),
        child: child ?? Icon(icon, size: 20, color: Colors.white),
      ),
    );
  }

  // ==================== 필터 매트릭스 ====================

  List<double> _filterMatrix(int index) {
    switch (index) {
      case 1: // 따뜻
        return [
          1.1, 0.0, 0.0, 0.0, 10.0,
          0.0, 1.05, 0.0, 0.0, 0.0,
          0.0, 0.0, 0.9, 0.0, 0.0,
          0.0, 0.0, 0.0, 1.0, 0.0,
        ];
      case 2: // 시원
        return [
          0.9, 0.0, 0.0, 0.0, 0.0,
          0.0, 1.0, 0.0, 0.0, 0.0,
          0.0, 0.0, 1.1, 0.0, 10.0,
          0.0, 0.0, 0.0, 1.0, 0.0,
        ];
      case 3: // 흑백
        return [
          0.299, 0.587, 0.114, 0.0, 0.0,
          0.299, 0.587, 0.114, 0.0, 0.0,
          0.299, 0.587, 0.114, 0.0, 0.0,
          0.0, 0.0, 0.0, 1.0, 0.0,
        ];
      case 4: // 빈티지
        return [
          0.9, 0.5, 0.1, 0.0, 0.0,
          0.3, 0.8, 0.1, 0.0, 0.0,
          0.2, 0.3, 0.5, 0.0, 0.0,
          0.0, 0.0, 0.0, 1.0, 0.0,
        ];
      case 5: // 선명 (채도 증가)
        return [
          1.2, 0.0, 0.0, 0.0, 0.0,
          0.0, 1.2, 0.0, 0.0, 0.0,
          0.0, 0.0, 1.2, 0.0, 0.0,
          0.0, 0.0, 0.0, 1.0, 0.0,
        ];
      default: // 원본
        return const [
          1.0, 0.0, 0.0, 0.0, 0.0,
          0.0, 1.0, 0.0, 0.0, 0.0,
          0.0, 0.0, 1.0, 0.0, 0.0,
          0.0, 0.0, 0.0, 1.0, 0.0,
        ];
    }
  }
}

/// 드래그 가능한 텍스트 스티커
class _TextSticker {
  String text;
  Offset offset;
  final Color color;

  _TextSticker({
    required this.text,
    this.offset = const Offset(0, -100),
    this.color = Colors.white,
  });

  Widget build({required Function(Offset) onMove, required VoidCallback onRemove}) {
    return Positioned(
      left: offset.dx,
      top: offset.dy,
      child: GestureDetector(
        onPanUpdate: (details) => onMove(details.delta),
        onLongPress: onRemove,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              shadows: const [
                Shadow(color: Colors.black87, blurRadius: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
