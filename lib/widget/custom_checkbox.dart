// autor - <a.a.ustinoff@gmail.com> Anton Ustinoff

import 'package:flutter/material.dart';

class CheckBoxRounded extends StatefulWidget {
  const CheckBoxRounded({
    this.onTap,
    this.size,
    this.borderWidth = 1.0,
    this.borderColor,
    this.checkedColor,
    this.uncheckedColor,
    this.checkedWidget,
    this.uncheckedWidget,
    this.animationDuration,
    this.isChecked,
    this.disable = false,
    Key? key,
  }) : super(key: key);

  final bool? isChecked;

  final bool disable;

  /// Define the size of the checkbox
  final double? size;

  /// Define the width of the border checkbox
  final double borderWidth;

  /// Define the border of the widget
  final Color? borderColor;

  /// Define the color that is shown when Widgets is checked
  final Color? checkedColor;

  /// Define the color that is shown when Widgets is unchecked
  final Color? uncheckedColor;

  /// Define the widget that is shown when Widgets is checked
  final Widget? checkedWidget;

  /// Define the widget that is shown when Widgets is unchecked
  final Widget? uncheckedWidget;

  /// Define Function that os executed when user tap on checkbox
  final void Function(bool?)? onTap;

  /// Define the duration of the animation. If any
  final Duration? animationDuration;

  @override
  State<CheckBoxRounded> createState() => _CheckBoxRoundedState();
}

class _CheckBoxRoundedState extends State<CheckBoxRounded> {
  bool _isChecked = false;

  @override
  void initState() {
    super.initState();

    if (widget.isChecked != null) {
      _isChecked = widget.isChecked ?? false;
    }
  }

  @override
  dispose() {
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant CheckBoxRounded oldWidget) {
    if (widget.isChecked != null && oldWidget.isChecked != widget.isChecked) {
      _isChecked = widget.isChecked!;
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    debugCheckHasMaterial(context);

    final ThemeData themeData = Theme.of(context);

    final double effectiveIconSize = widget.size ?? 24.0;

    final Color effectiveBorderColor = widget.borderColor ?? themeData.dividerColor;

    final Color effectiveCheckedColor = widget.checkedColor ?? Colors.yellow.shade700;

    final Color effectiveUncheckedColor = widget.uncheckedColor ?? themeData.scaffoldBackgroundColor;

    final effectiveAnimationDuration = widget.animationDuration ?? const Duration(milliseconds: 100);

    final Widget checkedWidget = widget.checkedWidget ??
        Icon(
          Icons.check_rounded,
          color: Colors.white,
          size: effectiveIconSize / 1.2,
        );

    final Widget uncheckedWidget = widget.uncheckedWidget != null ? SizedBox(child: widget.uncheckedWidget) : const SizedBox.shrink();

    final Widget child = ClipRRect(
      borderRadius: const BorderRadius.all(Radius.circular(100)),
      child: AnimatedContainer(
        duration: effectiveAnimationDuration,
        width: effectiveIconSize,
        height: effectiveIconSize,
        decoration: BoxDecoration(
          border: Border.all(
            width: widget.borderWidth,
            color: _isChecked ? Colors.transparent : effectiveBorderColor,
          ),
          borderRadius: const BorderRadius.all(Radius.circular(100)),
          color: _isChecked ? effectiveCheckedColor : effectiveUncheckedColor,
        ),
        child: _isChecked ? checkedWidget : uncheckedWidget,
      ),
    );

    return widget.disable
        ? child
        : GestureDetector(
            onTap: () {
              widget.onTap?.call(!_isChecked);
              setState(() => _isChecked = !_isChecked);
            },
            child: child,
          );
  }
}
