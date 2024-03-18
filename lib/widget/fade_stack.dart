import 'package:flutter/material.dart';

class FadeIndexedStack extends StatefulWidget {
  final int index;
  final List<Widget> children;

  const FadeIndexedStack({
    required Key key,
    required this.index,
    required this.children,
  }) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _FadeIndexedStackState createState() => _FadeIndexedStackState();
}

class _FadeIndexedStackState extends State<FadeIndexedStack> with TickerProviderStateMixin {
  late AnimationController _fadeController;

  late final AnimationController _slideController;
  late final Animation<Offset> _animation;

  final Duration _fadeDuration = const Duration(milliseconds: 550);
  final Duration _slideDuration = const Duration(milliseconds: 250);

  @override
  void didUpdateWidget(FadeIndexedStack oldWidget) {
    if (widget.index != oldWidget.index) {
      _fadeController.forward(from: 0.3);
      _slideController.forward(from: 0.0);
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void initState() {
    _fadeController = AnimationController(vsync: this, duration: _fadeDuration)..forward();

    _slideController = AnimationController(
      duration: _slideDuration,
      vsync: this,
    )..forward();

    _animation = Tween<Offset>(
      begin: const Offset(-0.02, 0.0),
      end: const Offset(0.0, 0.0),
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeInOutSine,
    ));

    super.initState();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _animation,
      child: FadeTransition(
        opacity: _fadeController,
        child: IndexedStack(
          index: widget.index,
          children: widget.children,
        ),
      ),
    );
  }
}
