import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:project1/app/setting/open_source_detail_page.dart';
import 'package:project1/app/shared_album/theme/sa_colors.dart';
import 'package:project1/app/shared_album/theme/sa_text_styles.dart';
import 'package:project1/oss_licenses.dart';
import 'package:project1/repo/board/board_repo.dart';
import 'package:project1/repo/board/data/board_main_detail_data.dart';
import 'package:project1/repo/common/res_data.dart';
import 'package:project1/repo/common/res_stream.dart';
import 'package:project1/utils/log_utils.dart';
import 'package:project1/utils/utils.dart';

/// 오픈소스 라이선스 목록 — 설정 화면(setting_page)과 같은 디자인 토큰(SaColors/SaText)을 쓴다.
/// 라이트 고정: `SaColors.syncWith(context)`를 부르지 않는다. 라이선스 원문/패키지 정보는 손대지 않는다.
class OpenSourcePage extends StatefulWidget {
  const OpenSourcePage({super.key});

  @override
  State<OpenSourcePage> createState() => _OpenSourcePageState();
}

class _OpenSourcePageState extends State<OpenSourcePage> {
  final StreamController<ResStream<List<BoardDetailData>>> listCtrl = StreamController();

  List<BoardDetailData> boardList = [];

  String typeCd = 'OPEN';
  String typeDtCd = 'OPEN';
  int page = 0;
  int pageSzie = 2000;
  String topYn = 'N';

  @override
  initState() {
    super.initState();
    getData();
  }

  Future<List<Package>> loadLicenses() async {
    try {
      lo.g("111111");
      // merging non-dart dependency list using LicenseRegistry.
      final lm = <String, List<String>>{};
      await for (var l in LicenseRegistry.licenses) {
        for (var p in l.packages) {
          final lp = lm.putIfAbsent(p, () => []);
          lp.addAll(l.paragraphs.map((p) => p.text));
        }
      }
      lo.g("2222");
      final licenses = allDependencies.toList();

      // for (var key in lm.keys) {
      //   licenses.add(Package(
      //     name: key,
      //     description: '',
      //     authors: [],
      //     version: '',
      //     license: lm[key]!.join('\n\n'),
      //     isMarkdown: false,
      //     isSdk: false,
      //     dependencies: [],
      //   ));
      // }

      lo.g("33333 : ${licenses.length}");
      return licenses..sort((a, b) => a.name.compareTo(b.name));
    } catch (e) {
      lo.g(e.toString());
      return [];
    }
  }

  // final _licenses = loadLicenses();

  Future<void> getData() async {
    try {
      // listCtrl.sink.add(ResStream.loading());
      BoardRepo repo = BoardRepo();
      ResData resData = await repo.searchOriginList(typeCd, typeDtCd, page, pageSzie, topYn);

      if (resData.code != '00') {
        Utils.alert(resData.msg.toString());
        listCtrl.sink.add(ResStream.error(resData.msg.toString()));
        return;
      }

      boardList = ((resData.data['list']) as List).map((data) => BoardDetailData.fromMap(data)).toList();

      listCtrl.sink.add(ResStream.completed(boardList, message: '조회가 완료되었습니다.'));
    } catch (e) {
      listCtrl.sink.add(ResStream.error(e.toString()));
    }
  }

  @override
  void dispose() {
    listCtrl.close();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        forceMaterialTransparency: true,
        automaticallyImplyLeading: false,
        // 뒤로가기 — setting_page와 같은 원형 surface 버튼(pill). 화면 좌측 패딩 16에 맞춘다.
        leadingWidth: 72,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Center(
            child: SizedBox(
              width: 40,
              height: 40,
              child: Material(
                color: SaColors.surface,
                shape: CircleBorder(side: BorderSide(color: SaColors.borderStrong)),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => Navigator.pop(context),
                  child: Center(
                    child: PhosphorIcon(PhosphorIconsBold.caretLeft, size: 17, color: SaColors.textPrimary),
                  ),
                ),
              ),
            ),
          ),
        ),
        title: Text('오픈소스 라이센스', style: SaText.titleS),
        centerTitle: true,
        elevation: 0,
      ),
      backgroundColor: SaColors.bgBase,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Utils.commonStreamList<BoardDetailData>(listCtrl, buildList, getData, noDataWidget: const SizedBox.shrink()),
          FutureBuilder<List<Package>>(
            future: loadLicenses(),
            initialData: const [],
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return Center(
                    child: Padding(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 200), child: Utils.progressbar()));
              }
              return buildPubDevList(snapshot.data!);
            },
          ),
          const Gap(30),
        ]),
      ),
    );
  }

  // 카드 r26 / surface / border / 내부 패딩 14 — setting_page의 SettingsGroup과 같은 규격.
  // 배경은 Container가 아니라 Material이 그린다(항목의 잉크 리플이 가려지지 않도록).
  Widget _listCard({required Widget child}) {
    return Material(
      color: SaColors.surface,
      borderRadius: BorderRadius.circular(26),
      clipBehavior: Clip.antiAlias,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: SaColors.border),
        ),
        padding: const EdgeInsets.all(14),
        child: child,
      ),
    );
  }

  // pub.dev 오픈 소스 리스트
  Widget buildPubDevList(List<Package> list) {
    if (list.isEmpty) return const SizedBox.shrink();
    return _listCard(
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: list.length,
        padding: EdgeInsets.zero,
        physics: const NeverScrollableScrollPhysics(),
        separatorBuilder: (context, index) => Divider(color: SaColors.border, height: 13, thickness: 1),
        itemBuilder: (BuildContext context, int index) {
          return buildPubDevItem(list[index]);
        },
      ),
    );
  }

// 오픈 소스 리스트
  Widget buildPubDevItem(Package package) {
    return Column(
      children: [
        ElevatedButton(
          clipBehavior: Clip.none,
          style: ElevatedButton.styleFrom(
            shadowColor: Colors.transparent,
            // fixedSize: Size(0, 0),
            minimumSize: Size.zero, // Set this
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: const VisualDensity(horizontal: 0, vertical: 0),
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            backgroundColor: Colors.transparent,
          ),
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => OpenSourceDetailPage(package: package),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //   crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${package.name} ${package.version}',
                      // softWrap: true,
                      overflow: TextOverflow.clip,
                      style: SaText.bodyMedium,
                    ),
                    const Gap(5),
                    Text(
                      package.description.isNotEmpty ? package.description : '',
                      style: SaText.body,
                    ),
                  ],
                ),
              ),
              // const Spacer(),
              PhosphorIcon(PhosphorIconsBold.caretRight, size: 16, color: SaColors.textTertiary),
            ],
          ),
        ),
      ],
    );
  }

// 오픈 소스 리스트
  Widget buildList(List<BoardDetailData> list) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: _listCard(
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: list.length,
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          separatorBuilder: (context, index) => Divider(color: SaColors.border, height: 13, thickness: 1),
          itemBuilder: (BuildContext context, int index) {
            return buildItem(list[index]);
          },
        ),
      ),
    );
  }

// 오픈 소스 리스트
  Widget buildItem(BoardDetailData data) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Column(
        children: [
          ElevatedButton(
            clipBehavior: Clip.none,
            style: ElevatedButton.styleFrom(
              shadowColor: Colors.transparent,
              // fixedSize: Size(0, 0),
              minimumSize: Size.zero, // Set this
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: const VisualDensity(horizontal: 0, vertical: 0),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              backgroundColor: Colors.transparent,
            ),
            onPressed: () => Lo.g('data.ptupSeq'),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              //   crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Flexible(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.subject.toString(),
                        // softWrap: true,
                        overflow: TextOverflow.clip,
                        style: SaText.bodyMedium,
                      ),
                      const Gap(5),
                      Text(
                        data.contents.toString().substring(0, data.contents!.length > 30 ? 30 : data.contents!.length),
                        style: SaText.body,
                      ),
                    ],
                  ),
                ),
                // const Spacer(),
                PhosphorIcon(PhosphorIconsBold.caretRight, size: 16, color: SaColors.textTertiary),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
