// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class BbsListPaging {
  int currPageNum;
  int totalPageNum;
  int pageSize;
  int totalElements;
  bool last;
  BbsListPaging({
    required this.currPageNum,
    required this.totalPageNum,
    required this.pageSize,
    required this.totalElements,
    required this.last,
  });

  BbsListPaging copyWith({
    int? currPageNum,
    int? totalPageNum,
    int? pageSize,
    int? totalElements,
    bool? last,
  }) {
    return BbsListPaging(
      currPageNum: currPageNum ?? this.currPageNum,
      totalPageNum: totalPageNum ?? this.totalPageNum,
      pageSize: pageSize ?? this.pageSize,
      totalElements: totalElements ?? this.totalElements,
      last: last ?? this.last,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'currPageNum': currPageNum,
      'totalPageNum': totalPageNum,
      'pageSize': pageSize,
      'totalElements': totalElements,
      'last': last,
    };
  }

  factory BbsListPaging.fromMap(Map<String, dynamic> map) {
    return BbsListPaging(
      currPageNum: map['currPageNum'] as int,
      totalPageNum: map['totalPageNum'] as int,
      pageSize: map['pageSize'] as int,
      totalElements: map['totalElements'] as int,
      last: map['last'] as bool,
    );
  }

  String toJson() => json.encode(toMap());

  factory BbsListPaging.fromJson(String source) => BbsListPaging.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'BbsListPaging(currPageNum: $currPageNum, totalPageNum: $totalPageNum, pageSize: $pageSize, totalElements: $totalElements, last: $last)';
  }

  @override
  bool operator ==(covariant BbsListPaging other) {
    if (identical(this, other)) return true;

    return other.currPageNum == currPageNum &&
        other.totalPageNum == totalPageNum &&
        other.pageSize == pageSize &&
        other.totalElements == totalElements &&
        other.last == last;
  }

  @override
  int get hashCode {
    return currPageNum.hashCode ^ totalPageNum.hashCode ^ pageSize.hashCode ^ totalElements.hashCode ^ last.hashCode;
  }
}
