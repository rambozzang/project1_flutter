import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:project1/app/root/root_cntr.dart';
import 'package:project1/utils/utils.dart';

class ColorPage extends StatelessWidget {
  const ColorPage({super.key});

  Widget title(String title) {
    return SizedBox(
        //width: 642,
        height: 50,
        child: Text(
          title,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 30,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
          ),
        ));
  }

  Widget colorBox(Color color, String colorName) {
    return colorBox2(color, colorName);
  }

  Widget colorBox2(Color color, String colorName) {
    return Column(
      children: [
        InkWell(
          onTap: () {
            Clipboard.setData(ClipboardData(text: colorName)).then((_) => Utils.alert("클립보드에 복사되었습니다."));
          },
          child: Ink(
            child: Container(
              width: 100,
              height: 45,
              color: color,
            ),
          ),
        ),
        const Gap(4),
        Text(
          "#${color.toString().split('(0xff')[1].split(')')[0]}",
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 8,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w400,
          ),
        ),
        Text(
          colorName,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 8,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        controller: RootCntr.to.hideButtonController11,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Gap(90),
              title('Logo Color'),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    colorBox(Colors.yellow, 'C.logoYellow'),
                    colorBox(Colors.yellow, 'C.logoBrown'),
                  ],
                ),
              ),
              const Gap(40),
              title('Main Color'),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    colorBox(Colors.yellow, 'C.mainOrange600'),
                    colorBox(Colors.yellow, 'C.mainOrange500'),
                    colorBox(Colors.yellow, 'C.mainOrange300'),
                    colorBox(Colors.yellow, 'C.mainOrange100'),
                    colorBox(Colors.yellow, 'C.mainOrange50'),
                  ],
                ),
              ),
            ],
          ),
        ));
  }
}
