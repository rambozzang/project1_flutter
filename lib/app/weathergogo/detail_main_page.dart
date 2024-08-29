// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:math' as math;

import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:project1/app/weather/theme/colors.dart';
import 'package:project1/app/weather/theme/textStyle.dart';
import 'package:project1/app/weathergogo/cntr/weather_gogo_cntr.dart';

class DetailMainPage extends GetView<WeatherGogoCntr> {
  const DetailMainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () {
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.4),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            decoration: BoxDecoration(
              // color: const Color(0xFF262B49),
              borderRadius: BorderRadius.circular(16.0),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10.0),
                _buildInfoRow([
                  _buildInfoTile(
                    icon: PhosphorIconsRegular.clock,
                    title: '발표시각',
                    data: controller.currentWeather.value.fcsTime == null
                        ? ''
                        : '${controller.currentWeather.value.fcsTime.toString().substring(0, 2)}:${controller.currentWeather.value.fcsTime.toString().substring(2, 4)}',
                  ),
                  _buildInfoTile(
                    icon: PhosphorIconsRegular.drop,
                    title: '강수량1h',
                    data: '${controller.currentWeather.value.rain1h ?? 0}mm',
                  ),
                  _buildInfoTile(
                    icon: PhosphorIconsRegular.navigationArrow,
                    title: '풍 향',
                    data: '${controller.currentWeather.value.deg ?? 0.0}',
                    isWindDirection: true,
                  ),
                ]),
                const Divider(
                  thickness: 1.0,
                  color: backgroundBlue,
                  indent: 12.0,
                  endIndent: 12.0,
                ),
                _buildInfoRow([
                  _buildInfoTile(
                    icon: PhosphorIconsRegular.wind,
                    title: '바 람',
                    data: '${controller.currentWeather.value.speed ?? 0}m/s',
                  ),
                  _buildInfoTile(
                    icon: PhosphorIconsRegular.dropHalfBottom,
                    title: '습 도',
                    data: '${controller.currentWeather.value.humidity ?? 0}%',
                  ),
                  _buildInfoTile(
                    icon: PhosphorIconsRegular.cloud,
                    title: '낙 뢰',
                    data: '${controller.currentWeather.value.skyDesc ?? ''}kA',
                  ),
                ]),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(List<Widget> tiles) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Row(
        children: List.generate(tiles.length * 2 - 1, (index) {
          if (index.isEven) {
            return Expanded(child: tiles[index ~/ 2]);
          } else {
            return const VerticalDivider(
              thickness: 1.0,
              indent: 4.0,
              endIndent: 4.0,
              color: backgroundBlue,
            );
          }
        }),
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String data,
    bool isWindDirection = false,
  }) {
    return DetailInfoTile(
      icon: PhosphorIcon(icon, color: Colors.white),
      title: title,
      subtitle: '',
      data: data,
      isWindDirection: isWindDirection,
    );
  }
}

class DetailInfoTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String data;
  final Widget icon;
  final bool isWindDirection;

  const DetailInfoTile({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.data,
    required this.icon,
    this.isWindDirection = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(backgroundColor: primaryBlue, child: icon),
          const SizedBox(width: 8.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: lightText),
                if (isWindDirection)
                  WindDirectionArrow(direction: double.parse(data))
                else
                  Text(
                    data,
                    style: mediumText,
                    maxLines: 1,
                  ),
                if (subtitle != '') Text(subtitle!, style: const TextStyle(color: Colors.amber, fontSize: 12.0)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// WindDirectionArrow 클래스는 변경 없이 유지

class WindDirectionArrow extends StatelessWidget {
  final double direction; // 풍향 (도 단위, 0-360)
  final Color color;
  final double size;

  const WindDirectionArrow({
    super.key,
    required this.direction,
    this.color = Colors.white, // const Color.fromARGB(255, 160, 123, 223),
    this.size = 22.0,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: (direction - 180) * (math.pi / 180),
      child: Icon(
        Icons.navigation,
        color: color,
        size: size,
      ),
    );
  }
}
