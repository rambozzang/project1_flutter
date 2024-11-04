// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class BbsSearchData {
  int? pageNum;
  int? pageSize;
  String? typeCd;
  String? typeDtCd;
  String? depthNo;
  String? searchWord;
  String? searchCustId;
  String? rootId;
  String? parentId;
  String? sortDesc;
  BbsSearchData(
      {this.pageNum,
      this.pageSize,
      this.typeCd,
      this.typeDtCd,
      this.depthNo,
      this.searchWord,
      this.searchCustId,
      this.rootId,
      this.parentId,
      this.sortDesc});

  BbsSearchData copyWith(
      {int? pageNum,
      int? pageSize,
      String? typeCd,
      String? typeDtCd,
      String? depthNo,
      String? searchWord,
      String? searchCustId,
      String? rootId,
      String? parentId,
      String? sortDesc}) {
    return BbsSearchData(
      pageNum: pageNum ?? this.pageNum,
      pageSize: pageSize ?? this.pageSize,
      typeCd: typeCd ?? this.typeCd,
      typeDtCd: typeDtCd ?? this.typeDtCd,
      depthNo: depthNo ?? this.depthNo,
      searchWord: searchWord ?? this.searchWord,
      searchCustId: searchCustId ?? this.searchCustId,
      rootId: rootId ?? this.rootId,
      parentId: parentId ?? this.parentId,
      sortDesc: sortDesc ?? this.sortDesc,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'pageNum': pageNum,
      'pageSize': pageSize,
      'typeCd': typeCd,
      'typeDtCd': typeDtCd,
      'depthNo': depthNo,
      'searchWord': searchWord,
      'searchCustId': searchCustId,
      'rootId': rootId,
      'parentId': parentId,
      'sortDesc': sortDesc
    };
  }

  factory BbsSearchData.fromMap(Map<String, dynamic> map) {
    return BbsSearchData(
      pageNum: map['pageNum'] != null ? map['pageNum'] as int : null,
      pageSize: map['pageSize'] != null ? map['pageSize'] as int : null,
      typeCd: map['typeCd'] != null ? map['typeCd'] as String : null,
      typeDtCd: map['typeDtCd'] != null ? map['typeDtCd'] as String : null,
      depthNo: map['depthNo'] != null ? map['depthNo'] as String : null,
      searchWord: map['searchWord'] != null ? map['searchWord'] as String : null,
      searchCustId: map['searchCustId'] != null ? map['searchCustId'] as String : null,
      rootId: map['rootId'] != null ? map['rootId'] as String : null,
      parentId: map['parentId'] != null ? map['parentId'] as String : null,
      sortDesc: map['sortDesc'] != null ? map['sortDesc'] as String : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory BbsSearchData.fromJson(String source) => BbsSearchData.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'BbsSearchData(pageNum: $pageNum, pageSize: $pageSize, typeCd: $typeCd, typeDtCd: $typeDtCd, depthNo: $depthNo,rootId :$rootId,  searchWord: $searchWord, searchCustId: $searchCustId, parentId: $parentId)';
  }

  @override
  bool operator ==(covariant BbsSearchData other) {
    if (identical(this, other)) return true;

    return other.pageNum == pageNum &&
        other.pageSize == pageSize &&
        other.typeCd == typeCd &&
        other.typeDtCd == typeDtCd &&
        other.depthNo == depthNo &&
        other.searchWord == searchWord &&
        other.searchCustId == searchCustId &&
        other.rootId == rootId &&
        other.parentId == parentId &&
        other.sortDesc == sortDesc;
  }

  @override
  int get hashCode {
    return pageNum.hashCode ^
        pageSize.hashCode ^
        typeCd.hashCode ^
        typeDtCd.hashCode ^
        depthNo.hashCode ^
        searchWord.hashCode ^
        searchCustId.hashCode ^
        rootId.hashCode ^
        parentId.hashCode ^
        sortDesc.hashCode;
  }
}
