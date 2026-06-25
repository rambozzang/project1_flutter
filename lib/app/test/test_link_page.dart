import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';

import 'package:project1/root/cntr/root_cntr.dart';
import 'package:project1/root/main_view1.dart';

class TestLinkPage extends StatefulWidget {
  const TestLinkPage({super.key});

  @override
  State<TestLinkPage> createState() => _TestLinkPageState();
}

class _TestLinkPageState extends State<TestLinkPage> {
  // 테스트 페이지 링크 작업
  List<Map<String, String>> testMenuList = [
    {'name': '', 'link': '/ImageMain'},
    {'name': '서류등록2', 'link': '/ImageRegPage'},
    {'name': '서류보기 ', 'link': '/ImageViewPage'},
    {'name': 'List', 'link': '/VideoListPage'},
    {'name': '회원가입 ', 'link': '/JoAg001Page'},
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 46), // <------ root_page.dart 113줄에 값에 따라 추가됨.
        Expanded(
          child: CustomScrollView(
            controller: RootCntr.to.hideButtonController12,
            slivers: [
              SliverToBoxAdapter(
                child: Container(
                  //  height: 400.h,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(5.0),
                  color: Colors.amberAccent,
                  child: Column(
                    children: [
                      const Gap(20),
                      GridView.builder(
                        shrinkWrap: true,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2, // 1개의 행에 항목을 3개씩
                          childAspectRatio: 4.5 / 1, //item 의 가로 1, 세로 1 의 비율
                          mainAxisSpacing: 1, //수평 Padding
                          crossAxisSpacing: 1, //수직 Padding
                        ),
                        itemCount: testMenuList.length,
                        itemBuilder: (BuildContext context, int index) {
                          return Container(
                            // color: Colors.grey,
                            //   child: Text('f'),
                            child: customButton(testMenuList[index]['name'].toString(), testMenuList[index]['link'].toString()),
                          );
                        },
                      ),
                      const Gap(20),
                    ],
                  ),

                  //   child: Column(
                  //     mainAxisAlignment: MainAxisAlignment.center,
                  //     crossAxisAlignment: CrossAxisAlignment.start,
                  //     children: [
                  //       ...List.generate(
                  //         testMenuList.length,
                  //         (index) => customButton(testMenuList[index]['name'].toString(), testMenuList[index]['link'].toString()),
                  //       ),
                  //       const Gap(12),
                  //       customButton('이미지업로드', '/ImageRegPage'),
                  //       const Gap(12),
                  //       customButton('이미지', '/ImageMain'),
                  //       const Gap(12),
                  //       customButton('이미지뷰어', '/ImageViewPage'),
                  //       const Gap(12),
                  //       customButton('갤러리', '/ImageGallery'),
                  //       const Gap(12),
                  //       customButton('List 페이지', '/listPage'),
                  //       const Gap(12),
                  //       customButton('MlkitPage', '/MlkitPage'),
                  //       const Gap(12),
                  //       customButton('GoogleMlkitListPage', '/GoogleMlkitListPage'),
                  //       const Gap(12),
                  //       customButton('회원가입', '/JoAg001Page'),
                  //       35.verticalSpace,
                  //       CustomIconButton(
                  //         onPressed: null,
                  //         icon: const Icon(Icons.arrow_back_rounded, color: Colors.redAccent),
                  //         //  backgroundColor: theme.primaryColor,
                  //         width: 30.w, height: 30.h,
                  //       ),
                  //       5.verticalSpace,
                  //       10.verticalSpaceFromWidth,
                  //       CustomButton(
                  //         width: 130.w,
                  //         text: 'Try Again',
                  //         onPressed: () => CustomSnackBar.showCustomErrorToast(message: "오류났어요"),
                  //         fontSize: 16.sp,
                  //         radius: 10.r,
                  //         verticalPadding: 12.h,
                  //         hasShadow: false,
                  //       ),
                  //     ],
                  //   ),
                ),
              ),
              const SliverPersistentHeader(pinned: true, delegate: CategoryBreadcrumbs()),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                    (context, index) => Container(
                          height: 45,
                          // 보는 재미를 위해 인덱스에 아무 숫자나 곱한 뒤 255로
                          // 나눠 다른 색이 보이도록 함.
                          color: Color.fromRGBO((index * 45) % 255, (index * 70) % 255, (index * 25), 1.0),
                        ),
                    childCount: 40),
              )
            ],
          ),
        ),
      ],
    );
  }

  Widget customButton(String message1, String path) {
    return Container(
      padding: const EdgeInsets.all(2.0),
      // width: 190,
      height: 60,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6.0),
            ),
            side: const BorderSide(
              width: 1.0,
              //   color: Colors.amber,
            )),
        onPressed: () {
          HapticFeedback.heavyImpact();
          Get.toNamed(path, arguments: {'loanNo': '1234123333', 'wkCd': 'CUST', 'attcFilCd': '23452434'});
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // const Icon(Icons.star_rate, size: 24, color: Colors.black),
            // const Gap(4),
            Text(
              '💥 $message1',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: Colors.black),
            ),
          ],
        ),
      ),
    );
  }
}
