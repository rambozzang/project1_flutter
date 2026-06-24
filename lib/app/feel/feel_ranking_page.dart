import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:project1/app/feel/cntr/feel_ranking_cntr.dart';
import 'package:project1/repo/feel/data/feel_ranking_data.dart';

class FeelRankingPage extends StatelessWidget {
  const FeelRankingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<FeelRankingCntr>(
      init: FeelRankingCntr(),
      builder: (cntr) => Scaffold(
        appBar: AppBar(
          title: const Text('체감 날씨 랭킹'),
          centerTitle: true,
        ),
        body: Column(
          children: [
            // 기간 탭
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: cntr.periods.map((p) {
                  return Obx(() {
                    final isSelected = cntr.selectedPeriod.value == p['code'];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(p['name']!),
                        selected: isSelected,
                        onSelected: (_) => cntr.changePeriod(p['code']!),
                      ),
                    );
                  });
                }).toList(),
              ),
            ),
            // 랭킹 리스트
            Expanded(
              child: Obx(() {
                if (cntr.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (cntr.rankingList.isEmpty) {
                  return const Center(
                    child: Text('아직 체감 태그 데이터가 없어요'),
                  );
                }
                return ListView.builder(
                  itemCount: cntr.rankingList.length,
                  itemBuilder: (ctx, i) {
                    final item = cntr.rankingList[i];
                    return _RankingTile(rank: i + 1, item: item);
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _RankingTile extends StatelessWidget {
  final int rank;
  final FeelRankingData item;

  const _RankingTile({required this.rank, required this.item});

  @override
  Widget build(BuildContext context) {
    final emoji = FeelCode.getEmoji(item.topFeelCd);
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: rank <= 3 ? const Color(0xFFFFD700) : Colors.grey[200],
        child: Text(
          '$rank',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      title: Text(item.nickNm),
      subtitle: Text(
        '${item.feelCount}회 기여 · 주요: $emoji ${FeelCode.getName(item.topFeelCd)}',
      ),
      trailing: item.profilePath != null
          ? CircleAvatar(backgroundImage: NetworkImage(item.profilePath!))
          : const CircleAvatar(child: Icon(Icons.person)),
    );
  }
}
