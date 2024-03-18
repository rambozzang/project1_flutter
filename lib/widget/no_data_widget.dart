import 'package:flutter/material.dart';

class NoDataWidget extends StatelessWidget {
  final String? msg;
  const NoDataWidget({Key? key, this.msg}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Container(
          height: 200,
          // color: Colors.red,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              //Image.asset(Constants.noData, width: 120.w, height: 120.h),
              Text(msg ?? '조회된 데이터가 없습니다.', style: TextStyle(fontSize: 16, color: Colors.black)),
            ],
          ),
        ),
      ),
    );
  }
}
