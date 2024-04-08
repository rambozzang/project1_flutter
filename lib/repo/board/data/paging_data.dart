// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class PagingData {
  int? currPageNum;
  int? totalPageNum;
  int? pageSize;
  bool? isLast;
  double? totalElements;
  PagingData({
    this.currPageNum,
    this.totalPageNum,
    this.pageSize,
    this.isLast,
    this.totalElements,
  });

  PagingData copyWith({
    int? currPageNum,
    int? totalPageNum,
    int? pageSize,
    bool? isLast,
    double? totalElements,
  }) {
    return PagingData(
      currPageNum: currPageNum ?? this.currPageNum,
      totalPageNum: totalPageNum ?? this.totalPageNum,
      pageSize: pageSize ?? this.pageSize,
      isLast: isLast ?? this.isLast,
      totalElements: totalElements ?? this.totalElements,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'currPageNum': currPageNum,
      'totalPageNum': totalPageNum,
      'pageSize': pageSize,
      'isLast': isLast,
      'totalElements': totalElements,
    };
  }

  factory PagingData.fromMap(Map<String, dynamic> map) {
    return PagingData(
      currPageNum: map['currPageNum'] != null ? map['currPageNum'] as int : null,
      totalPageNum: map['totalPageNum'] != null ? map['totalPageNum'] as int : null,
      pageSize: map['pageSize'] != null ? map['pageSize'] as int : null,
      isLast: map['isLast'] != null ? map['isLast'] as bool : null,
      totalElements: map['totalElements'] != null ? map['totalElements'] as double : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory PagingData.fromJson(String source) => PagingData.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'PagingData(currPageNum: $currPageNum, totalPageNum: $totalPageNum, pageSize: $pageSize, isLast: $isLast, totalElements: $totalElements)';
  }

  @override
  bool operator ==(covariant PagingData other) {
    if (identical(this, other)) return true;

    return other.currPageNum == currPageNum &&
        other.totalPageNum == totalPageNum &&
        other.pageSize == pageSize &&
        other.isLast == isLast &&
        other.totalElements == totalElements;
  }

  @override
  int get hashCode {
    return currPageNum.hashCode ^ totalPageNum.hashCode ^ pageSize.hashCode ^ isLast.hashCode ^ totalElements.hashCode;
  }
}
