import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:project1/app/auth/cntr/auth_cntr.dart';
import 'package:project1/app/common/widgets/animated_list_item.dart';
import 'package:project1/app/feel/cntr/feel_ranking_cntr.dart';
import 'package:project1/config/app_color.dart';
import 'package:project1/repo/feel/data/feel_ranking_data.dart';

class FeelRankingPage extends StatelessWidget {
  const FeelRankingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<FeelRankingCntr>(
      init: FeelRankingCntr(),
      builder: (cntr) => Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          iconTheme: const IconThemeData(color: AppColor.primaryColor),
          title: const Text(
            '체감 날씨 랭킹',
            style: TextStyle(
              color: AppColor.primaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: AppColor.primaryColor),
              tooltip: '새로고침',
              onPressed: () => cntr.fetchRanking(),
            ),
          ],
        ),
        body: Column(
          children: [
            _buildPeriodChips(cntr),
            Padding(
              padding: const EdgeInsets.only(
                  left: 16, right: 16, top: 2, bottom: 8),
              child: Text(
                '체감 태그를 가장 많이 남긴 SkySnapper 순위예요',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
            ),
            Expanded(
              child: Obx(() {
                if (cntr.isLoading.value) {
                  return const Center(
                    child:
                        CircularProgressIndicator(color: AppColor.primaryColor),
                  );
                }
                if (cntr.rankingList.isEmpty) {
                  return _buildEmptyState();
                }

                final top3 = cntr.rankingList.take(3).toList();
                final rest = cntr.rankingList.skip(3).toList();

                return SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    children: [
                      _buildMyRankCard(cntr),
                      _buildAreaCard(cntr),
                      if (top3.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _PodiumSection(top3: top3),
                      ],
                      if (rest.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              const Expanded(
                                child: Divider(),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                child: Text(
                                  '랭킹',
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const Expanded(
                                child: Divider(),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: rest.length,
                          itemBuilder: (ctx, i) {
                            final item = rest[i];
                            return _RankingTile(
                              rank: i + 4,
                              item: item,
                              isMe: item.custId.isNotEmpty &&
                                  item.custId == AuthCntr.to.custId.value,
                            );
                          },
                        ),
                      ],
                      _buildLoadMore(cntr),
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodChips(FeelRankingCntr cntr) {
    return Container(
      height: 48,
      margin: const EdgeInsets.only(bottom: 4),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: cntr.periods.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final p = cntr.periods[index];
          return Obx(() {
            final isSelected = cntr.selectedPeriod.value == p['code'];
            return AnimatedListItem(
              index: index,
              duration: const Duration(milliseconds: 300),
              staggerDelay: const Duration(milliseconds: 40),
              child: GestureDetector(
                onTap: () => cntr.changePeriod(p['code']!),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColor.primaryColor
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? AppColor.primaryColor
                          : Colors.grey.shade300,
                    ),
                  ),
                  child: Text(
                    p['name']!,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey.shade700,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            );
          });
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.emoji_people, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            '아직 체감 태그 데이터가 없어요',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '첫 체감을 남겨보세요!',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  /// 내 순위 카드. 리스트에서 나를 찾으면 primaryColor 강조, 없으면 muted 안내.
  Widget _buildMyRankCard(FeelRankingCntr cntr) {
    final my = cntr.myRank;
    if (my != null) {
      final data = my.data;
      final emoji = FeelCode.getEmoji(data.topFeelCd);
      final name = FeelCode.getName(data.topFeelCd);
      return Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColor.primaryColor.withOpacity(0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColor.primaryColor.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColor.primaryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                '내 순위',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '#${my.position} · ${data.feelCount}회 · $emoji $name',
                style: const TextStyle(
                  color: AppColor.primaryColor,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.emoji_events_outlined,
              color: Colors.grey.shade500, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '아직 순위권 안에 없어요 — 체감 태그를 남기고 순위에 도전해보세요!',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 우리 동네 체감 카드. best-effort 라 areaStats 가 비어있으면 아무것도 안 그린다.
  Widget _buildAreaCard(FeelRankingCntr cntr) {
    if (cntr.areaStats.isEmpty) return const SizedBox.shrink();
    final sorted = [...cntr.areaStats]
      ..sort((a, b) => b.count.compareTo(a.count));
    final top = sorted.take(5).toList();
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.place, color: AppColor.primaryColor, size: 18),
              SizedBox(width: 6),
              Text(
                '우리 동네 체감',
                style: TextStyle(
                  color: AppColor.primaryColor,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: top.map((s) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  '${FeelCode.getEmoji(s.feelCd)} ${FeelCode.getName(s.feelCd)} ${s.count}',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// 리스트 하단의 더 보기 / 로딩 / 마지막 안내.
  Widget _buildLoadMore(FeelRankingCntr cntr) {
    if (cntr.isLoadingMore.value) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              color: AppColor.primaryColor,
            ),
          ),
        ),
      );
    }
    if (cntr.hasMore.value) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
        child: SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => cntr.loadMore(),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColor.primaryColor,
              side: BorderSide(color: AppColor.primaryColor.withOpacity(0.4)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text(
              '더 보기',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Center(
        child: Text(
          '마지막이에요',
          style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
        ),
      ),
    );
  }
}

class _PodiumSection extends StatelessWidget {
  final List<FeelRankingData> top3;

  const _PodiumSection({required this.top3});

  @override
  Widget build(BuildContext context) {
    final first = top3.isNotEmpty ? top3[0] : null;
    final second = top3.length > 1 ? top3[1] : null;
    final third = top3.length > 2 ? top3[2] : null;

    final myId = AuthCntr.to.custId.value;

    return AnimatedListItem(
      index: 0,
      duration: const Duration(milliseconds: 500),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (second != null)
              Expanded(
                child: _PodiumItem(
                  rank: 2,
                  item: second,
                  height: 90,
                  color: const Color(0xFFC0C0C0),
                  isMe: second.custId.isNotEmpty && second.custId == myId,
                ),
              )
            else
              const Expanded(child: SizedBox()),
            const SizedBox(width: 10),
            if (first != null)
              Expanded(
                flex: 1,
                child: _PodiumItem(
                  rank: 1,
                  item: first,
                  height: 120,
                  color: const Color(0xFFFFD700),
                  isMe: first.custId.isNotEmpty && first.custId == myId,
                ),
              )
            else
              const Expanded(child: SizedBox()),
            const SizedBox(width: 10),
            if (third != null)
              Expanded(
                child: _PodiumItem(
                  rank: 3,
                  item: third,
                  height: 70,
                  color: const Color(0xFFCD7F32),
                  isMe: third.custId.isNotEmpty && third.custId == myId,
                ),
              )
            else
              const Expanded(child: SizedBox()),
          ],
        ),
      ),
    );
  }
}

class _PodiumItem extends StatelessWidget {
  final int rank;
  final FeelRankingData item;
  final double height;
  final Color color;
  final bool isMe;

  const _PodiumItem({
    required this.rank,
    required this.item,
    required this.height,
    required this.color,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    final emoji = FeelCode.getEmoji(item.topFeelCd);
    final rankEmojis = {1: '👑', 2: '🥈', 3: '🥉'};

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: rank == 1 ? 76 : 60,
              height: rank == 1 ? 76 : 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isMe ? AppColor.primaryColor : color,
                  width: isMe ? 3 : 2.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.18),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipOval(
                child: item.profilePath != null
                    ? CachedNetworkImage(
                        imageUrl: item.profilePath!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) =>
                            Container(color: Colors.grey.shade200),
                        errorWidget: (_, __, ___) =>
                            const Icon(Icons.person, color: Colors.grey),
                      )
                    : Container(
                        color: Colors.grey.shade100,
                        child: Icon(Icons.person,
                            color: Colors.grey.shade500, size: 28),
                      ),
              ),
            ),
            Positioned(
              bottom: -2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Text(
                  '$rank',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          rankEmojis[rank] ?? '',
          style: const TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 3),
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: rank == 1 ? 90 : 74),
          child: Text(
            item.nickNm,
            style: TextStyle(
              color: AppColor.primaryColor,
              fontSize: rank == 1 ? 14 : 13,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '${item.feelCount}회',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 3),
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: rank == 1 ? 90 : 74),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$emoji ${FeelCode.getName(item.topFeelCd)}',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withOpacity(0.45), color.withOpacity(0.15)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
        ),
      ],
    );
  }
}

class _RankingTile extends StatelessWidget {
  final int rank;
  final FeelRankingData item;
  final bool isMe;

  const _RankingTile({
    required this.rank,
    required this.item,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    final emoji = FeelCode.getEmoji(item.topFeelCd);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isMe ? AppColor.primaryColor.withOpacity(0.06) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isMe
              ? AppColor.primaryColor.withOpacity(0.3)
              : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: RepaintBoundary(
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '$rank',
                  style: const TextStyle(
                    color: AppColor.primaryColor,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isMe ? AppColor.primaryColor : Colors.grey.shade200,
                  width: isMe ? 2 : 1,
                ),
              ),
              child: ClipOval(
                child: item.profilePath != null
                    ? CachedNetworkImage(
                        imageUrl: item.profilePath!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) =>
                            Container(color: Colors.grey.shade200),
                        errorWidget: (_, __, ___) =>
                            const Icon(Icons.person, color: Colors.grey),
                      )
                    : Container(
                        color: Colors.grey.shade100,
                        child: Icon(Icons.person, color: Colors.grey.shade500),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.nickNm,
                    style: const TextStyle(
                      color: AppColor.primaryColor,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '$emoji ${FeelCode.getName(item.topFeelCd)}',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isMe ? AppColor.primaryColor : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${item.feelCount}회',
                style: TextStyle(
                  color: isMe ? Colors.white : AppColor.primaryColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
