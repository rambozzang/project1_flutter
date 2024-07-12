import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:project1/app/setting/open_source_detail_page.dart';
import 'package:project1/oss_licenses.dart';
import 'package:project1/repo/board/board_repo.dart';
import 'package:project1/repo/board/data/board_main_detail_data.dart';
import 'package:project1/repo/common/res_data.dart';
import 'package:project1/repo/common/res_stream.dart';
import 'package:project1/utils/log_utils.dart';
import 'package:project1/utils/utils.dart';
import 'package:url_launcher/url_launcher.dart';

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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('오픈소스 라이센스'),
        centerTitle: true,
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
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

  // pub.dev 오픈 소스 리스트
  Widget buildPubDevList(List<Package> list) {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: list.length,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (BuildContext context, int index) {
        return buildPubDevItem(list[index]);
      },
    );
  }

// 오픈 소스 리스트
  Widget buildPubDevItem(Package package) {
    return Column(
      children: [
        // Divider(
        //   height: 1,
        //   thickness: 1,
        //   color: Colors.grey[300],
        // ),
        const Gap(2),
        ElevatedButton(
          clipBehavior: Clip.none,
          style: ElevatedButton.styleFrom(
            shadowColor: Colors.grey[50],
            // fixedSize: Size(0, 0),
            minimumSize: Size.zero, // Set this
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: const VisualDensity(horizontal: 0, vertical: 0),
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
            backgroundColor: Colors.grey[200],
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
                      style: const TextStyle(fontSize: 14),
                    ),
                    const Gap(5),
                    Text(
                      package.description.isNotEmpty ? package.description : '',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
                ),
              ),
              // const Spacer(),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ],
    );
  }

// 오픈 소스 리스트
  Widget buildList(List<BoardDetailData> list) {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: list.length,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (BuildContext context, int index) {
        return buildItem(list[index]);
      },
    );
  }

// 오픈 소스 리스트
  Widget buildItem(BoardDetailData data) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Column(
        children: [
          // Divider(
          //   height: 1,
          //   thickness: 1,
          //   color: Colors.grey[300],
          // ),
          const Gap(2),
          ElevatedButton(
            clipBehavior: Clip.none,
            style: ElevatedButton.styleFrom(
              shadowColor: Colors.grey[50],
              // fixedSize: Size(0, 0),
              minimumSize: Size.zero, // Set this
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: const VisualDensity(horizontal: 0, vertical: 0),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
              backgroundColor: Colors.grey[200],
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
                        style: const TextStyle(fontSize: 14),
                      ),
                      const Gap(5),
                      Text(
                        data.contents.toString().substring(0, data.contents!.length > 30 ? 30 : data.contents!.length),
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ),
                ),
                // const Spacer(),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
