import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CommentHeaderWidget extends StatelessWidget {
  const CommentHeaderWidget({super.key, required this.listLength, required this.getData, required this.isDarkTheme});
  final int listLength;
  final VoidCallback getData;
  final bool isDarkTheme;

  @override
  Widget build(BuildContext context) {
    Color backgroundColor = isDarkTheme ? const Color(0xFF0F0F0F) : Colors.white;
    Color textColor = isDarkTheme ? Colors.white : Colors.black;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(color: textColor.withOpacity(0.4), borderRadius: BorderRadius.circular(100)),
          ),
          Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 15),
                child: Text(
                  "댓글",
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: textColor,
                    fontSize: 16,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 6.0),
                child: Text(
                  listLength.toString(),
                  style: TextStyle(
                    fontWeight: FontWeight.w400,
                    color: textColor.withOpacity(0.7),
                    fontSize: 13,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () {
                  getData();
                },
                icon: Icon(
                  Icons.replay,
                  size: 26,
                  color: textColor,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 10.0, right: 10),
                child: IconButton(
                  onPressed: () {
                    Get.back();
                  },
                  icon: Icon(
                    Icons.close,
                    size: 26,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
          Container(
            color: isDarkTheme ? const Color(0xFF292929) : const Color(0xFFE4E4E4),
            width: double.infinity,
            height: 1,
          ),
        ],
      ),
    );
  }
}
