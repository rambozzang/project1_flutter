// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class CampingResData {
  String? firstImageUrl;
  String? siteMg3Vrticl;
  String? siteMg2Vrticl;
  String? siteMg1Co;
  String? siteMg2Co;
  String? siteMg3Co;
  String? siteBottomCl1;
  String? siteBottomCl2;
  String? siteBottomCl3;
  String? siteBottomCl4;
  String? fireSensorCo;
  String? themaEnvrnCl;
  String? eqpmnLendCl;
  String? animalCmgCl;
  String? tooltip;
  String? glampInnerFclty;
  String? caravInnerFclty;
  String? prmisnDe;
  String? operPdCl;
  String? operDeCl;
  String? trlerAcmpnyAt;
  String? caravAcmpnyAt;
  String? toiletCo;
  String? frprvtWrppCo;
  String? frprvtSandCo;
  String? induty;
  String? siteMg1Vrticl;
  String? posblFcltyEtc;
  String? clturEventAt;
  String? clturEvent;
  String? exprnProgrmAt;
  String? exprnProgrm;
  String? extshrCo;
  String? manageSttus;
  String? hvofBgnde;
  String? hvofEnddle;
  String? trsagntNo;
  String? bizrno;
  String? facltDivNm;
  String? mangeDivNm;
  String? mgcDiv;
  String? tourEraCl;
  String? lctCl;
  String? doNm;
  String? sigunguNm;
  String? zipcode;
  String? addr1;
  String? addr2;
  String? mapX;
  String? mapY;
  String? direction;
  String? tel;
  String? homepage;
  String? contentId;
  String? swrmCo;
  String? wtrplCo;
  String? brazierCl;
  String? sbrsCl;
  String? sbrsEtc;
  String? modifiedtime;
  String? facltNm;
  String? lineIntro;
  String? intro;
  String? allar;
  String? insrncAt;
  String? resveUrl;
  String? resveCl;
  String? manageNmpr;
  String? gnrlSiteCo;
  String? autoSiteCo;
  String? glampSiteCo;
  String? caravSiteCo;
  String? indvdlCaravSiteCo;
  String? sitedStnc;
  String? siteMg1Width;
  String? siteMg2Width;
  String? siteMg3Width;
  String? createdtime;
  String? posblFcltyCl;
  String? featureNm;
  String? siteBottomCl5;
  CampingResData({
    this.firstImageUrl,
    this.siteMg3Vrticl,
    this.siteMg2Vrticl,
    this.siteMg1Co,
    this.siteMg2Co,
    this.siteMg3Co,
    this.siteBottomCl1,
    this.siteBottomCl2,
    this.siteBottomCl3,
    this.siteBottomCl4,
    this.fireSensorCo,
    this.themaEnvrnCl,
    this.eqpmnLendCl,
    this.animalCmgCl,
    this.tooltip,
    this.glampInnerFclty,
    this.caravInnerFclty,
    this.prmisnDe,
    this.operPdCl,
    this.operDeCl,
    this.trlerAcmpnyAt,
    this.caravAcmpnyAt,
    this.toiletCo,
    this.frprvtWrppCo,
    this.frprvtSandCo,
    this.induty,
    this.siteMg1Vrticl,
    this.posblFcltyEtc,
    this.clturEventAt,
    this.clturEvent,
    this.exprnProgrmAt,
    this.exprnProgrm,
    this.extshrCo,
    this.manageSttus,
    this.hvofBgnde,
    this.hvofEnddle,
    this.trsagntNo,
    this.bizrno,
    this.facltDivNm,
    this.mangeDivNm,
    this.mgcDiv,
    this.tourEraCl,
    this.lctCl,
    this.doNm,
    this.sigunguNm,
    this.zipcode,
    this.addr1,
    this.addr2,
    this.mapX,
    this.mapY,
    this.direction,
    this.tel,
    this.homepage,
    this.contentId,
    this.swrmCo,
    this.wtrplCo,
    this.brazierCl,
    this.sbrsCl,
    this.sbrsEtc,
    this.modifiedtime,
    this.facltNm,
    this.lineIntro,
    this.intro,
    this.allar,
    this.insrncAt,
    this.resveUrl,
    this.resveCl,
    this.manageNmpr,
    this.gnrlSiteCo,
    this.autoSiteCo,
    this.glampSiteCo,
    this.caravSiteCo,
    this.indvdlCaravSiteCo,
    this.sitedStnc,
    this.siteMg1Width,
    this.siteMg2Width,
    this.siteMg3Width,
    this.createdtime,
    this.posblFcltyCl,
    this.featureNm,
    this.siteBottomCl5,
  });

  CampingResData copyWith({
    String? firstImageUrl,
    String? siteMg3Vrticl,
    String? siteMg2Vrticl,
    String? siteMg1Co,
    String? siteMg2Co,
    String? siteMg3Co,
    String? siteBottomCl1,
    String? siteBottomCl2,
    String? siteBottomCl3,
    String? siteBottomCl4,
    String? fireSensorCo,
    String? themaEnvrnCl,
    String? eqpmnLendCl,
    String? animalCmgCl,
    String? tooltip,
    String? glampInnerFclty,
    String? caravInnerFclty,
    String? prmisnDe,
    String? operPdCl,
    String? operDeCl,
    String? trlerAcmpnyAt,
    String? caravAcmpnyAt,
    String? toiletCo,
    String? frprvtWrppCo,
    String? frprvtSandCo,
    String? induty,
    String? siteMg1Vrticl,
    String? posblFcltyEtc,
    String? clturEventAt,
    String? clturEvent,
    String? exprnProgrmAt,
    String? exprnProgrm,
    String? extshrCo,
    String? manageSttus,
    String? hvofBgnde,
    String? hvofEnddle,
    String? trsagntNo,
    String? bizrno,
    String? facltDivNm,
    String? mangeDivNm,
    String? mgcDiv,
    String? tourEraCl,
    String? lctCl,
    String? doNm,
    String? sigunguNm,
    String? zipcode,
    String? addr1,
    String? addr2,
    String? mapX,
    String? mapY,
    String? direction,
    String? tel,
    String? homepage,
    String? contentId,
    String? swrmCo,
    String? wtrplCo,
    String? brazierCl,
    String? sbrsCl,
    String? sbrsEtc,
    String? modifiedtime,
    String? facltNm,
    String? lineIntro,
    String? intro,
    String? allar,
    String? insrncAt,
    String? resveUrl,
    String? resveCl,
    String? manageNmpr,
    String? gnrlSiteCo,
    String? autoSiteCo,
    String? glampSiteCo,
    String? caravSiteCo,
    String? indvdlCaravSiteCo,
    String? sitedStnc,
    String? siteMg1Width,
    String? siteMg2Width,
    String? siteMg3Width,
    String? createdtime,
    String? posblFcltyCl,
    String? featureNm,
    String? siteBottomCl5,
  }) {
    return CampingResData(
      firstImageUrl: firstImageUrl ?? this.firstImageUrl,
      siteMg3Vrticl: siteMg3Vrticl ?? this.siteMg3Vrticl,
      siteMg2Vrticl: siteMg2Vrticl ?? this.siteMg2Vrticl,
      siteMg1Co: siteMg1Co ?? this.siteMg1Co,
      siteMg2Co: siteMg2Co ?? this.siteMg2Co,
      siteMg3Co: siteMg3Co ?? this.siteMg3Co,
      siteBottomCl1: siteBottomCl1 ?? this.siteBottomCl1,
      siteBottomCl2: siteBottomCl2 ?? this.siteBottomCl2,
      siteBottomCl3: siteBottomCl3 ?? this.siteBottomCl3,
      siteBottomCl4: siteBottomCl4 ?? this.siteBottomCl4,
      fireSensorCo: fireSensorCo ?? this.fireSensorCo,
      themaEnvrnCl: themaEnvrnCl ?? this.themaEnvrnCl,
      eqpmnLendCl: eqpmnLendCl ?? this.eqpmnLendCl,
      animalCmgCl: animalCmgCl ?? this.animalCmgCl,
      tooltip: tooltip ?? this.tooltip,
      glampInnerFclty: glampInnerFclty ?? this.glampInnerFclty,
      caravInnerFclty: caravInnerFclty ?? this.caravInnerFclty,
      prmisnDe: prmisnDe ?? this.prmisnDe,
      operPdCl: operPdCl ?? this.operPdCl,
      operDeCl: operDeCl ?? this.operDeCl,
      trlerAcmpnyAt: trlerAcmpnyAt ?? this.trlerAcmpnyAt,
      caravAcmpnyAt: caravAcmpnyAt ?? this.caravAcmpnyAt,
      toiletCo: toiletCo ?? this.toiletCo,
      frprvtWrppCo: frprvtWrppCo ?? this.frprvtWrppCo,
      frprvtSandCo: frprvtSandCo ?? this.frprvtSandCo,
      induty: induty ?? this.induty,
      siteMg1Vrticl: siteMg1Vrticl ?? this.siteMg1Vrticl,
      posblFcltyEtc: posblFcltyEtc ?? this.posblFcltyEtc,
      clturEventAt: clturEventAt ?? this.clturEventAt,
      clturEvent: clturEvent ?? this.clturEvent,
      exprnProgrmAt: exprnProgrmAt ?? this.exprnProgrmAt,
      exprnProgrm: exprnProgrm ?? this.exprnProgrm,
      extshrCo: extshrCo ?? this.extshrCo,
      manageSttus: manageSttus ?? this.manageSttus,
      hvofBgnde: hvofBgnde ?? this.hvofBgnde,
      hvofEnddle: hvofEnddle ?? this.hvofEnddle,
      trsagntNo: trsagntNo ?? this.trsagntNo,
      bizrno: bizrno ?? this.bizrno,
      facltDivNm: facltDivNm ?? this.facltDivNm,
      mangeDivNm: mangeDivNm ?? this.mangeDivNm,
      mgcDiv: mgcDiv ?? this.mgcDiv,
      tourEraCl: tourEraCl ?? this.tourEraCl,
      lctCl: lctCl ?? this.lctCl,
      doNm: doNm ?? this.doNm,
      sigunguNm: sigunguNm ?? this.sigunguNm,
      zipcode: zipcode ?? this.zipcode,
      addr1: addr1 ?? this.addr1,
      addr2: addr2 ?? this.addr2,
      mapX: mapX ?? this.mapX,
      mapY: mapY ?? this.mapY,
      direction: direction ?? this.direction,
      tel: tel ?? this.tel,
      homepage: homepage ?? this.homepage,
      contentId: contentId ?? this.contentId,
      swrmCo: swrmCo ?? this.swrmCo,
      wtrplCo: wtrplCo ?? this.wtrplCo,
      brazierCl: brazierCl ?? this.brazierCl,
      sbrsCl: sbrsCl ?? this.sbrsCl,
      sbrsEtc: sbrsEtc ?? this.sbrsEtc,
      modifiedtime: modifiedtime ?? this.modifiedtime,
      facltNm: facltNm ?? this.facltNm,
      lineIntro: lineIntro ?? this.lineIntro,
      intro: intro ?? this.intro,
      allar: allar ?? this.allar,
      insrncAt: insrncAt ?? this.insrncAt,
      resveUrl: resveUrl ?? this.resveUrl,
      resveCl: resveCl ?? this.resveCl,
      manageNmpr: manageNmpr ?? this.manageNmpr,
      gnrlSiteCo: gnrlSiteCo ?? this.gnrlSiteCo,
      autoSiteCo: autoSiteCo ?? this.autoSiteCo,
      glampSiteCo: glampSiteCo ?? this.glampSiteCo,
      caravSiteCo: caravSiteCo ?? this.caravSiteCo,
      indvdlCaravSiteCo: indvdlCaravSiteCo ?? this.indvdlCaravSiteCo,
      sitedStnc: sitedStnc ?? this.sitedStnc,
      siteMg1Width: siteMg1Width ?? this.siteMg1Width,
      siteMg2Width: siteMg2Width ?? this.siteMg2Width,
      siteMg3Width: siteMg3Width ?? this.siteMg3Width,
      createdtime: createdtime ?? this.createdtime,
      posblFcltyCl: posblFcltyCl ?? this.posblFcltyCl,
      featureNm: featureNm ?? this.featureNm,
      siteBottomCl5: siteBottomCl5 ?? this.siteBottomCl5,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'firstImageUrl': firstImageUrl,
      'siteMg3Vrticl': siteMg3Vrticl,
      'siteMg2Vrticl': siteMg2Vrticl,
      'siteMg1Co': siteMg1Co,
      'siteMg2Co': siteMg2Co,
      'siteMg3Co': siteMg3Co,
      'siteBottomCl1': siteBottomCl1,
      'siteBottomCl2': siteBottomCl2,
      'siteBottomCl3': siteBottomCl3,
      'siteBottomCl4': siteBottomCl4,
      'fireSensorCo': fireSensorCo,
      'themaEnvrnCl': themaEnvrnCl,
      'eqpmnLendCl': eqpmnLendCl,
      'animalCmgCl': animalCmgCl,
      'tooltip': tooltip,
      'glampInnerFclty': glampInnerFclty,
      'caravInnerFclty': caravInnerFclty,
      'prmisnDe': prmisnDe,
      'operPdCl': operPdCl,
      'operDeCl': operDeCl,
      'trlerAcmpnyAt': trlerAcmpnyAt,
      'caravAcmpnyAt': caravAcmpnyAt,
      'toiletCo': toiletCo,
      'frprvtWrppCo': frprvtWrppCo,
      'frprvtSandCo': frprvtSandCo,
      'induty': induty,
      'siteMg1Vrticl': siteMg1Vrticl,
      'posblFcltyEtc': posblFcltyEtc,
      'clturEventAt': clturEventAt,
      'clturEvent': clturEvent,
      'exprnProgrmAt': exprnProgrmAt,
      'exprnProgrm': exprnProgrm,
      'extshrCo': extshrCo,
      'manageSttus': manageSttus,
      'hvofBgnde': hvofBgnde,
      'hvofEnddle': hvofEnddle,
      'trsagntNo': trsagntNo,
      'bizrno': bizrno,
      'facltDivNm': facltDivNm,
      'mangeDivNm': mangeDivNm,
      'mgcDiv': mgcDiv,
      'tourEraCl': tourEraCl,
      'lctCl': lctCl,
      'doNm': doNm,
      'sigunguNm': sigunguNm,
      'zipcode': zipcode,
      'addr1': addr1,
      'addr2': addr2,
      'mapX': mapX,
      'mapY': mapY,
      'direction': direction,
      'tel': tel,
      'homepage': homepage,
      'contentId': contentId,
      'swrmCo': swrmCo,
      'wtrplCo': wtrplCo,
      'brazierCl': brazierCl,
      'sbrsCl': sbrsCl,
      'sbrsEtc': sbrsEtc,
      'modifiedtime': modifiedtime,
      'facltNm': facltNm,
      'lineIntro': lineIntro,
      'intro': intro,
      'allar': allar,
      'insrncAt': insrncAt,
      'resveUrl': resveUrl,
      'resveCl': resveCl,
      'manageNmpr': manageNmpr,
      'gnrlSiteCo': gnrlSiteCo,
      'autoSiteCo': autoSiteCo,
      'glampSiteCo': glampSiteCo,
      'caravSiteCo': caravSiteCo,
      'indvdlCaravSiteCo': indvdlCaravSiteCo,
      'sitedStnc': sitedStnc,
      'siteMg1Width': siteMg1Width,
      'siteMg2Width': siteMg2Width,
      'siteMg3Width': siteMg3Width,
      'createdtime': createdtime,
      'posblFcltyCl': posblFcltyCl,
      'featureNm': featureNm,
      'siteBottomCl5': siteBottomCl5,
    };
  }

  factory CampingResData.fromMap(Map<String, dynamic> map) {
    return CampingResData(
      firstImageUrl: map['firstImageUrl'] != null ? map['firstImageUrl'] as String : null,
      siteMg3Vrticl: map['siteMg3Vrticl'] != null ? map['siteMg3Vrticl'] as String : null,
      siteMg2Vrticl: map['siteMg2Vrticl'] != null ? map['siteMg2Vrticl'] as String : null,
      siteMg1Co: map['siteMg1Co'] != null ? map['siteMg1Co'] as String : null,
      siteMg2Co: map['siteMg2Co'] != null ? map['siteMg2Co'] as String : null,
      siteMg3Co: map['siteMg3Co'] != null ? map['siteMg3Co'] as String : null,
      siteBottomCl1: map['siteBottomCl1'] != null ? map['siteBottomCl1'] as String : null,
      siteBottomCl2: map['siteBottomCl2'] != null ? map['siteBottomCl2'] as String : null,
      siteBottomCl3: map['siteBottomCl3'] != null ? map['siteBottomCl3'] as String : null,
      siteBottomCl4: map['siteBottomCl4'] != null ? map['siteBottomCl4'] as String : null,
      fireSensorCo: map['fireSensorCo'] != null ? map['fireSensorCo'] as String : null,
      themaEnvrnCl: map['themaEnvrnCl'] != null ? map['themaEnvrnCl'] as String : null,
      eqpmnLendCl: map['eqpmnLendCl'] != null ? map['eqpmnLendCl'] as String : null,
      animalCmgCl: map['animalCmgCl'] != null ? map['animalCmgCl'] as String : null,
      tooltip: map['tooltip'] != null ? map['tooltip'] as String : null,
      glampInnerFclty: map['glampInnerFclty'] != null ? map['glampInnerFclty'] as String : null,
      caravInnerFclty: map['caravInnerFclty'] != null ? map['caravInnerFclty'] as String : null,
      prmisnDe: map['prmisnDe'] != null ? map['prmisnDe'] as String : null,
      operPdCl: map['operPdCl'] != null ? map['operPdCl'] as String : null,
      operDeCl: map['operDeCl'] != null ? map['operDeCl'] as String : null,
      trlerAcmpnyAt: map['trlerAcmpnyAt'] != null ? map['trlerAcmpnyAt'] as String : null,
      caravAcmpnyAt: map['caravAcmpnyAt'] != null ? map['caravAcmpnyAt'] as String : null,
      toiletCo: map['toiletCo'] != null ? map['toiletCo'] as String : null,
      frprvtWrppCo: map['frprvtWrppCo'] != null ? map['frprvtWrppCo'] as String : null,
      frprvtSandCo: map['frprvtSandCo'] != null ? map['frprvtSandCo'] as String : null,
      induty: map['induty'] != null ? map['induty'] as String : null,
      siteMg1Vrticl: map['siteMg1Vrticl'] != null ? map['siteMg1Vrticl'] as String : null,
      posblFcltyEtc: map['posblFcltyEtc'] != null ? map['posblFcltyEtc'] as String : null,
      clturEventAt: map['clturEventAt'] != null ? map['clturEventAt'] as String : null,
      clturEvent: map['clturEvent'] != null ? map['clturEvent'] as String : null,
      exprnProgrmAt: map['exprnProgrmAt'] != null ? map['exprnProgrmAt'] as String : null,
      exprnProgrm: map['exprnProgrm'] != null ? map['exprnProgrm'] as String : null,
      extshrCo: map['extshrCo'] != null ? map['extshrCo'] as String : null,
      manageSttus: map['manageSttus'] != null ? map['manageSttus'] as String : null,
      hvofBgnde: map['hvofBgnde'] != null ? map['hvofBgnde'] as String : null,
      hvofEnddle: map['hvofEnddle'] != null ? map['hvofEnddle'] as String : null,
      trsagntNo: map['trsagntNo'] != null ? map['trsagntNo'] as String : null,
      bizrno: map['bizrno'] != null ? map['bizrno'] as String : null,
      facltDivNm: map['facltDivNm'] != null ? map['facltDivNm'] as String : null,
      mangeDivNm: map['mangeDivNm'] != null ? map['mangeDivNm'] as String : null,
      mgcDiv: map['mgcDiv'] != null ? map['mgcDiv'] as String : null,
      tourEraCl: map['tourEraCl'] != null ? map['tourEraCl'] as String : null,
      lctCl: map['lctCl'] != null ? map['lctCl'] as String : null,
      doNm: map['doNm'] != null ? map['doNm'] as String : null,
      sigunguNm: map['sigunguNm'] != null ? map['sigunguNm'] as String : null,
      zipcode: map['zipcode'] != null ? map['zipcode'] as String : null,
      addr1: map['addr1'] != null ? map['addr1'] as String : null,
      addr2: map['addr2'] != null ? map['addr2'] as String : null,
      mapX: map['mapX'] != null ? map['mapX'] as String : null,
      mapY: map['mapY'] != null ? map['mapY'] as String : null,
      direction: map['direction'] != null ? map['direction'] as String : null,
      tel: map['tel'] != null ? map['tel'] as String : null,
      homepage: map['homepage'] != null ? map['homepage'] as String : null,
      contentId: map['contentId'] != null ? map['contentId'] as String : null,
      swrmCo: map['swrmCo'] != null ? map['swrmCo'] as String : null,
      wtrplCo: map['wtrplCo'] != null ? map['wtrplCo'] as String : null,
      brazierCl: map['brazierCl'] != null ? map['brazierCl'] as String : null,
      sbrsCl: map['sbrsCl'] != null ? map['sbrsCl'] as String : null,
      sbrsEtc: map['sbrsEtc'] != null ? map['sbrsEtc'] as String : null,
      modifiedtime: map['modifiedtime'] != null ? map['modifiedtime'] as String : null,
      facltNm: map['facltNm'] != null ? map['facltNm'] as String : null,
      lineIntro: map['lineIntro'] != null ? map['lineIntro'] as String : null,
      intro: map['intro'] != null ? map['intro'] as String : null,
      allar: map['allar'] != null ? map['allar'] as String : null,
      insrncAt: map['insrncAt'] != null ? map['insrncAt'] as String : null,
      resveUrl: map['resveUrl'] != null ? map['resveUrl'] as String : null,
      resveCl: map['resveCl'] != null ? map['resveCl'] as String : null,
      manageNmpr: map['manageNmpr'] != null ? map['manageNmpr'] as String : null,
      gnrlSiteCo: map['gnrlSiteCo'] != null ? map['gnrlSiteCo'] as String : null,
      autoSiteCo: map['autoSiteCo'] != null ? map['autoSiteCo'] as String : null,
      glampSiteCo: map['glampSiteCo'] != null ? map['glampSiteCo'] as String : null,
      caravSiteCo: map['caravSiteCo'] != null ? map['caravSiteCo'] as String : null,
      indvdlCaravSiteCo: map['indvdlCaravSiteCo'] != null ? map['indvdlCaravSiteCo'] as String : null,
      sitedStnc: map['sitedStnc'] != null ? map['sitedStnc'] as String : null,
      siteMg1Width: map['siteMg1Width'] != null ? map['siteMg1Width'] as String : null,
      siteMg2Width: map['siteMg2Width'] != null ? map['siteMg2Width'] as String : null,
      siteMg3Width: map['siteMg3Width'] != null ? map['siteMg3Width'] as String : null,
      createdtime: map['createdtime'] != null ? map['createdtime'] as String : null,
      posblFcltyCl: map['posblFcltyCl'] != null ? map['posblFcltyCl'] as String : null,
      featureNm: map['featureNm'] != null ? map['featureNm'] as String : null,
      siteBottomCl5: map['siteBottomCl5'] != null ? map['siteBottomCl5'] as String : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory CampingResData.fromJson(String source) => CampingResData.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'CampingResData(firstImageUrl: $firstImageUrl, siteMg3Vrticl: $siteMg3Vrticl, siteMg2Vrticl: $siteMg2Vrticl, siteMg1Co: $siteMg1Co, siteMg2Co: $siteMg2Co, siteMg3Co: $siteMg3Co, siteBottomCl1: $siteBottomCl1, siteBottomCl2: $siteBottomCl2, siteBottomCl3: $siteBottomCl3, siteBottomCl4: $siteBottomCl4, fireSensorCo: $fireSensorCo, themaEnvrnCl: $themaEnvrnCl, eqpmnLendCl: $eqpmnLendCl, animalCmgCl: $animalCmgCl, tooltip: $tooltip, glampInnerFclty: $glampInnerFclty, caravInnerFclty: $caravInnerFclty, prmisnDe: $prmisnDe, operPdCl: $operPdCl, operDeCl: $operDeCl, trlerAcmpnyAt: $trlerAcmpnyAt, caravAcmpnyAt: $caravAcmpnyAt, toiletCo: $toiletCo, frprvtWrppCo: $frprvtWrppCo, frprvtSandCo: $frprvtSandCo, induty: $induty, siteMg1Vrticl: $siteMg1Vrticl, posblFcltyEtc: $posblFcltyEtc, clturEventAt: $clturEventAt, clturEvent: $clturEvent, exprnProgrmAt: $exprnProgrmAt, exprnProgrm: $exprnProgrm, extshrCo: $extshrCo, manageSttus: $manageSttus, hvofBgnde: $hvofBgnde, hvofEnddle: $hvofEnddle, trsagntNo: $trsagntNo, bizrno: $bizrno, facltDivNm: $facltDivNm, mangeDivNm: $mangeDivNm, mgcDiv: $mgcDiv, tourEraCl: $tourEraCl, lctCl: $lctCl, doNm: $doNm, sigunguNm: $sigunguNm, zipcode: $zipcode, addr1: $addr1, addr2: $addr2, mapX: $mapX, mapY: $mapY, direction: $direction, tel: $tel, homepage: $homepage, contentId: $contentId, swrmCo: $swrmCo, wtrplCo: $wtrplCo, brazierCl: $brazierCl, sbrsCl: $sbrsCl, sbrsEtc: $sbrsEtc, modifiedtime: $modifiedtime, facltNm: $facltNm, lineIntro: $lineIntro, intro: $intro, allar: $allar, insrncAt: $insrncAt, resveUrl: $resveUrl, resveCl: $resveCl, manageNmpr: $manageNmpr, gnrlSiteCo: $gnrlSiteCo, autoSiteCo: $autoSiteCo, glampSiteCo: $glampSiteCo, caravSiteCo: $caravSiteCo, indvdlCaravSiteCo: $indvdlCaravSiteCo, sitedStnc: $sitedStnc, siteMg1Width: $siteMg1Width, siteMg2Width: $siteMg2Width, siteMg3Width: $siteMg3Width, createdtime: $createdtime, posblFcltyCl: $posblFcltyCl, featureNm: $featureNm, siteBottomCl5: $siteBottomCl5)';
  }

  @override
  bool operator ==(covariant CampingResData other) {
    if (identical(this, other)) return true;

    return other.firstImageUrl == firstImageUrl &&
        other.siteMg3Vrticl == siteMg3Vrticl &&
        other.siteMg2Vrticl == siteMg2Vrticl &&
        other.siteMg1Co == siteMg1Co &&
        other.siteMg2Co == siteMg2Co &&
        other.siteMg3Co == siteMg3Co &&
        other.siteBottomCl1 == siteBottomCl1 &&
        other.siteBottomCl2 == siteBottomCl2 &&
        other.siteBottomCl3 == siteBottomCl3 &&
        other.siteBottomCl4 == siteBottomCl4 &&
        other.fireSensorCo == fireSensorCo &&
        other.themaEnvrnCl == themaEnvrnCl &&
        other.eqpmnLendCl == eqpmnLendCl &&
        other.animalCmgCl == animalCmgCl &&
        other.tooltip == tooltip &&
        other.glampInnerFclty == glampInnerFclty &&
        other.caravInnerFclty == caravInnerFclty &&
        other.prmisnDe == prmisnDe &&
        other.operPdCl == operPdCl &&
        other.operDeCl == operDeCl &&
        other.trlerAcmpnyAt == trlerAcmpnyAt &&
        other.caravAcmpnyAt == caravAcmpnyAt &&
        other.toiletCo == toiletCo &&
        other.frprvtWrppCo == frprvtWrppCo &&
        other.frprvtSandCo == frprvtSandCo &&
        other.induty == induty &&
        other.siteMg1Vrticl == siteMg1Vrticl &&
        other.posblFcltyEtc == posblFcltyEtc &&
        other.clturEventAt == clturEventAt &&
        other.clturEvent == clturEvent &&
        other.exprnProgrmAt == exprnProgrmAt &&
        other.exprnProgrm == exprnProgrm &&
        other.extshrCo == extshrCo &&
        other.manageSttus == manageSttus &&
        other.hvofBgnde == hvofBgnde &&
        other.hvofEnddle == hvofEnddle &&
        other.trsagntNo == trsagntNo &&
        other.bizrno == bizrno &&
        other.facltDivNm == facltDivNm &&
        other.mangeDivNm == mangeDivNm &&
        other.mgcDiv == mgcDiv &&
        other.tourEraCl == tourEraCl &&
        other.lctCl == lctCl &&
        other.doNm == doNm &&
        other.sigunguNm == sigunguNm &&
        other.zipcode == zipcode &&
        other.addr1 == addr1 &&
        other.addr2 == addr2 &&
        other.mapX == mapX &&
        other.mapY == mapY &&
        other.direction == direction &&
        other.tel == tel &&
        other.homepage == homepage &&
        other.contentId == contentId &&
        other.swrmCo == swrmCo &&
        other.wtrplCo == wtrplCo &&
        other.brazierCl == brazierCl &&
        other.sbrsCl == sbrsCl &&
        other.sbrsEtc == sbrsEtc &&
        other.modifiedtime == modifiedtime &&
        other.facltNm == facltNm &&
        other.lineIntro == lineIntro &&
        other.intro == intro &&
        other.allar == allar &&
        other.insrncAt == insrncAt &&
        other.resveUrl == resveUrl &&
        other.resveCl == resveCl &&
        other.manageNmpr == manageNmpr &&
        other.gnrlSiteCo == gnrlSiteCo &&
        other.autoSiteCo == autoSiteCo &&
        other.glampSiteCo == glampSiteCo &&
        other.caravSiteCo == caravSiteCo &&
        other.indvdlCaravSiteCo == indvdlCaravSiteCo &&
        other.sitedStnc == sitedStnc &&
        other.siteMg1Width == siteMg1Width &&
        other.siteMg2Width == siteMg2Width &&
        other.siteMg3Width == siteMg3Width &&
        other.createdtime == createdtime &&
        other.posblFcltyCl == posblFcltyCl &&
        other.featureNm == featureNm &&
        other.siteBottomCl5 == siteBottomCl5;
  }

  @override
  int get hashCode {
    return firstImageUrl.hashCode ^
        siteMg3Vrticl.hashCode ^
        siteMg2Vrticl.hashCode ^
        siteMg1Co.hashCode ^
        siteMg2Co.hashCode ^
        siteMg3Co.hashCode ^
        siteBottomCl1.hashCode ^
        siteBottomCl2.hashCode ^
        siteBottomCl3.hashCode ^
        siteBottomCl4.hashCode ^
        fireSensorCo.hashCode ^
        themaEnvrnCl.hashCode ^
        eqpmnLendCl.hashCode ^
        animalCmgCl.hashCode ^
        tooltip.hashCode ^
        glampInnerFclty.hashCode ^
        caravInnerFclty.hashCode ^
        prmisnDe.hashCode ^
        operPdCl.hashCode ^
        operDeCl.hashCode ^
        trlerAcmpnyAt.hashCode ^
        caravAcmpnyAt.hashCode ^
        toiletCo.hashCode ^
        frprvtWrppCo.hashCode ^
        frprvtSandCo.hashCode ^
        induty.hashCode ^
        siteMg1Vrticl.hashCode ^
        posblFcltyEtc.hashCode ^
        clturEventAt.hashCode ^
        clturEvent.hashCode ^
        exprnProgrmAt.hashCode ^
        exprnProgrm.hashCode ^
        extshrCo.hashCode ^
        manageSttus.hashCode ^
        hvofBgnde.hashCode ^
        hvofEnddle.hashCode ^
        trsagntNo.hashCode ^
        bizrno.hashCode ^
        facltDivNm.hashCode ^
        mangeDivNm.hashCode ^
        mgcDiv.hashCode ^
        tourEraCl.hashCode ^
        lctCl.hashCode ^
        doNm.hashCode ^
        sigunguNm.hashCode ^
        zipcode.hashCode ^
        addr1.hashCode ^
        addr2.hashCode ^
        mapX.hashCode ^
        mapY.hashCode ^
        direction.hashCode ^
        tel.hashCode ^
        homepage.hashCode ^
        contentId.hashCode ^
        swrmCo.hashCode ^
        wtrplCo.hashCode ^
        brazierCl.hashCode ^
        sbrsCl.hashCode ^
        sbrsEtc.hashCode ^
        modifiedtime.hashCode ^
        facltNm.hashCode ^
        lineIntro.hashCode ^
        intro.hashCode ^
        allar.hashCode ^
        insrncAt.hashCode ^
        resveUrl.hashCode ^
        resveCl.hashCode ^
        manageNmpr.hashCode ^
        gnrlSiteCo.hashCode ^
        autoSiteCo.hashCode ^
        glampSiteCo.hashCode ^
        caravSiteCo.hashCode ^
        indvdlCaravSiteCo.hashCode ^
        sitedStnc.hashCode ^
        siteMg1Width.hashCode ^
        siteMg2Width.hashCode ^
        siteMg3Width.hashCode ^
        createdtime.hashCode ^
        posblFcltyCl.hashCode ^
        featureNm.hashCode ^
        siteBottomCl5.hashCode;
  }
}
