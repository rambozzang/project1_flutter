import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:project1/app/bbs/cntr/bbs_list_cntr.dart';
import 'package:project1/utils/log_utils.dart';

class AnimSearchBar extends StatefulWidget {
  ///  width - double ,isRequired : Yes
  ///  textController - TextEditingController  ,isRequired : Yes
  ///  onSuffixTap - Function, isRequired : Yes
  ///  onSubmitted - Function, isRequired : Yes
  ///  rtl - Boolean, isRequired : No
  ///  autoFocus - Boolean, isRequired : No
  ///  style - TextStyle, isRequired : No
  ///  closeSearchOnSuffixTap - bool , isRequired : No
  ///  suffixIcon - Icon ,isRequired :  No
  ///  prefixIcon - Icon  ,isRequired : No
  ///  animationDurationInMilli -  int ,isRequired : No
  ///  helpText - String ,isRequired :  No
  ///  inputFormatters - TextInputFormatter, Required - No
  ///  boxShadow - bool ,isRequired : No
  ///  textFieldColor - Color ,isRequired : No
  ///  searchIconColor - Color ,isRequired : No
  ///  textFieldIconColor - Color ,isRequired : No
  ///  textInputAction  -TextInputAction, isRequired : No

  final double width;
  final double height;
  final TextEditingController textController;
  final Icon? suffixIcon;
  final Icon? prefixIcon;
  final String helpText;
  final int animationDurationInMilli;
  final onSuffixTap;
  final bool rtl;
  final bool autoFocus;
  final TextStyle? style;
  final bool closeSearchOnSuffixTap;
  final Color? color;
  final Color? textFieldColor;
  final Color? searchIconColor;
  final Color? textFieldIconColor;
  final List<TextInputFormatter>? inputFormatters;
  final bool boxShadow;
  final Function(String) onSubmitted;
  final TextInputAction textInputAction;
  final Function(int) searchBarOpen;

  const AnimSearchBar({
    super.key,

    /// The width cannot be null
    required this.width,
    required this.searchBarOpen,

    /// The textController cannot be null
    required this.textController,
    this.suffixIcon,
    this.prefixIcon,
    this.helpText = "Search...",

    /// Height of wrapper container
    this.height = 100,

    /// choose your custom color
    this.color = Colors.white,

    /// choose your custom color for the search when it is expanded
    this.textFieldColor = Colors.white,

    /// choose your custom color for the search when it is expanded
    this.searchIconColor = Colors.black,

    /// choose your custom color for the search when it is expanded
    this.textFieldIconColor = Colors.black,
    this.textInputAction = TextInputAction.done,

    /// The onSuffixTap cannot be null
    required this.onSuffixTap,
    this.animationDurationInMilli = 305,

    /// The onSubmitted cannot be null
    required this.onSubmitted,

    /// make the search bar to open from right to left
    this.rtl = false,

    /// make the keyboard to show automatically when the searchbar is expanded
    this.autoFocus = false,

    /// TextStyle of the contents inside the searchbar
    this.style,

    /// close the search on suffix tap
    this.closeSearchOnSuffixTap = false,

    /// enable/disable the box shadow decoration
    this.boxShadow = true,

    /// can add list of inputformatters to control the input
    this.inputFormatters,
  });

  @override
  _AnimSearchBarState createState() => _AnimSearchBarState();
}

///toggle - 0 => false or closed
///toggle 1 => true or open
int toggle = 0;

/// * use this variable to check current text from OnChange
String textFieldValue = '';

class _AnimSearchBarState extends State<AnimSearchBar> with SingleTickerProviderStateMixin {
  late AnimationController _con;
  late Animation<double> _widthAnimation;
  late Animation<double> _fadeAnimation;
  FocusNode focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _con = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.animationDurationInMilli),
    );

    _widthAnimation = Tween<double>(
      begin: 48.0,
      end: widget.width,
    ).animate(CurvedAnimation(
      parent: _con,
      curve: Curves.easeOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _con,
      curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
    ));
  }

  unfocusKeyboard() {
    final FocusScopeNode currentScope = FocusScope.of(context);
    if (!currentScope.hasPrimaryFocus && currentScope.hasFocus) {
      FocusManager.instance.primaryFocus?.unfocus();
    }
    Future.delayed(const Duration(milliseconds: 1500), () => Get.find<BbsListController>().isShowRegButton.value = true);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      alignment: widget.rtl ? Alignment.centerRight : const Alignment(-1.0, 0.0),
      child: AnimatedBuilder(
        animation: _con,
        builder: (context, child) {
          return Container(
            height: widget.height,
            width: _widthAnimation.value,
            decoration: BoxDecoration(
              color: Color.lerp(widget.color, widget.textFieldColor, _con.value),
              borderRadius: BorderRadius.circular(15.0),
            ),
            child: Stack(
              children: [
                // 검색 필드
                Positioned(
                  left: 40.0,
                  top: 11.0,
                  child: Opacity(
                    opacity: _fadeAnimation.value,
                    child: Container(
                      padding: const EdgeInsets.only(left: 10),
                      alignment: Alignment.topCenter,
                      width: widget.width / 1.7,
                      child: _buildTextField(),
                    ),
                  ),
                ),
                // 닫기 버튼
                if (_con.value > 0)
                  Positioned(
                    top: 6.0,
                    right: 7.0,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: _buildCloseButton(),
                    ),
                  ),
                // 검색 아이콘
                _buildSearchIcon(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTextField() {
    return TextField(
      controller: widget.textController,
      inputFormatters: widget.inputFormatters,
      focusNode: focusNode,
      textInputAction: widget.textInputAction,
      cursorRadius: const Radius.circular(10.0),
      cursorWidth: 2.0,
      onChanged: (value) {
        textFieldValue = value;
      },
      onSubmitted: (value) => {
        widget.onSubmitted(value),
        unfocusKeyboard(),
        setState(() {
          toggle = 0;
        }),
        widget.textController.clear(),
        _con.reverse(),
      },
      onEditingComplete: () {
        /// on editing complete the keyboard will be closed and the search bar will be closed
        ///
        unfocusKeyboard();
        setState(() {
          toggle = 0;
        });
      },
      style: widget.style ?? const TextStyle(color: Colors.black, decorationThickness: 0),
      cursorColor: Colors.black,
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.only(bottom: 5),
        isDense: true,
        floatingLabelBehavior: FloatingLabelBehavior.never,
        labelText: widget.helpText,
        labelStyle: const TextStyle(
          color: Color(0xff5B5B5B),
          fontSize: 17.0,
          fontWeight: FontWeight.w500,
        ),
        alignLabelWithHint: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20.0),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildCloseButton() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: widget.color,
        borderRadius: BorderRadius.circular(30.0),
      ),
      child: AnimatedBuilder(
        builder: (context, widget) {
          return Transform.rotate(
            angle: _con.value * 2.0 * pi,
            child: widget,
          );
        },
        animation: _con,
        child: GestureDetector(
          onTap: () {
            try {
              widget.onSuffixTap();
              // * if field empty then the user trying to close bar
              if (textFieldValue == '') {
                unfocusKeyboard();
                setState(() {
                  toggle = 0;
                });

                ///reverse == close
                _con.reverse();
              }

              // * why not clear textfield here?
              widget.textController.clear();
              textFieldValue = '';

              ///closeSearchOnSuffixTap will execute if it's true
              if (widget.closeSearchOnSuffixTap) {
                unfocusKeyboard();
                setState(() {
                  toggle = 0;
                });
              }
            } catch (e) {
              print(e);
            }
          },

          ///suffixIcon is of type Icon
          child: widget.suffixIcon ??
              Icon(
                Icons.close,
                size: 20.0,
                color: widget.textFieldIconColor,
              ),
        ),
      ),
    );
  }

  Widget _buildSearchIcon() {
    return Material(
      color: Color.lerp(widget.color, widget.textFieldColor, _con.value),
      borderRadius: BorderRadius.circular(30.0),
      child: IconButton(
        splashRadius: 19.0,
        icon: widget.prefixIcon != null
            ? _con.value > 0
                ? Icon(
                    Icons.arrow_back_ios,
                    color: widget.textFieldIconColor,
                  )
                : widget.prefixIcon!
            : Icon(
                _con.value > 0 ? Icons.arrow_back_ios : Icons.search,
                // 검색 아이콘 색상을 올바르게 설정
                color: _con.value > 0 ? widget.textFieldIconColor : widget.searchIconColor,
                size: 23.0,
              ),
        onPressed: () {
          setState(() {
            if (_con.value == 0) {
              _con.forward();
              if (widget.autoFocus) {
                FocusScope.of(context).requestFocus(focusNode);
              }
            } else {
              _con.reverse();
              if (widget.autoFocus) {
                unfocusKeyboard();
              }
              Future.delayed(const Duration(milliseconds: 1500), () => Get.find<BbsListController>().isShowRegButton.value = true);
            }
          });
          widget.searchBarOpen(_con.value > 0 ? 1 : 0);
        },
      ),
    );
  }
}
