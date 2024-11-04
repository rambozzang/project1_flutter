import 'package:flutter/material.dart';

class AnimatedFloatingButton extends StatefulWidget {
  final VoidCallback onPressed;
  final String text;
  final IconData icon;

  const AnimatedFloatingButton({
    Key? key,
    required this.onPressed,
    required this.text,
    required this.icon,
  }) : super(key: key);

  @override
  _AnimatedFloatingButtonState createState() => _AnimatedFloatingButtonState();
}

class _AnimatedFloatingButtonState extends State<AnimatedFloatingButton> {
  bool _isExpanded = true;

  @override
  void initState() {
    super.initState();
    // 2초 후에 버튼 크기를 줄임
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _isExpanded = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.fastEaseInToSlowEaseOut,
      width: _isExpanded ? 100.0 : 50.0,
      height: 45.0,
      child: Material(
        color: const Color.fromARGB(255, 133, 157, 97),
        borderRadius: BorderRadius.circular(28.0),
        child: InkWell(
          onTap: widget.onPressed,
          borderRadius: BorderRadius.circular(28.0),
          child: AnimatedPadding(
            duration: const Duration(milliseconds: 300),
            padding: EdgeInsets.symmetric(
              horizontal: _isExpanded ? 16.0 : 0.0,
            ),
            child: Row(
              mainAxisAlignment: _isExpanded ? MainAxisAlignment.spaceBetween : MainAxisAlignment.center,
              children: [
                Icon(
                  widget.icon,
                  color: Colors.white,
                ),
                if (_isExpanded)
                  AnimatedOpacity(
                    duration: Duration(milliseconds: 300),
                    opacity: _isExpanded ? 1.0 : 0.0,
                    child: Text(
                      widget.text,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
