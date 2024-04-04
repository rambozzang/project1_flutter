import 'package:flutter/material.dart';

class GrabbingWidget extends StatelessWidget {
  const GrabbingWidget({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0F0F0F),
        borderRadius: BorderRadius.only(
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
            decoration: BoxDecoration(color: Colors.white60, borderRadius: BorderRadius.circular(100)),
          ),
          Row(
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 15),
                child: Text(
                  "댓글",
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(left: 6.0),
                child: Text(
                  "48",
                  style: TextStyle(
                    fontWeight: FontWeight.w400,
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.menu_sharp,
                size: 26,
                color: Colors.white,
              ),
              Padding(
                padding: const EdgeInsets.only(left: 10.0, right: 10),
                child: IconButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(
                    Icons.close,
                    size: 26,
                    color: Colors.white,
                  ),
                ),
              )
            ],
          ),
          Container(
            color: const Color(0xFF292929),
            width: double.infinity,
            height: 1,
          ),
        ],
      ),
    );
  }
}
