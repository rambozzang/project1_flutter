import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import 'package:material_floating_search_bar_2/material_floating_search_bar_2.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:project1/app/weather/models/geocode.dart';
import 'package:project1/app/weather/provider/weatherProvider.dart';
import 'package:project1/app/weather/theme/colors.dart';
import 'package:project1/app/weather/provider/weather_cntr.dart';
import 'package:project1/root/cntr/root_cntr.dart';
import 'package:project1/utils/log_utils.dart';
import 'package:project1/utils/utils.dart';
import 'package:provider/provider.dart';

class NiceApiService {
  //  Rest API key 로 입력
  static const String apiKey = '1025c933440c41d7a66397edbf7bf83d';

  Future<List<Map<String, dynamic>>> getCoordinates(String query) async {
    final url = 'https://open.neis.go.kr/hub/schoolInfo?'
        'Key=$apiKey'
        '&Type=json'
        '&pIndex=1'
        '&pSize=30'
        '&SCHUL_NM=$query';
    lo.g('url : $url');
    final response = await http.get(
      Uri.parse(url),
      // headers: {
      //   'Authorization': 'KakaoAK $_apiKey',
      // },
    );

    Lo.g('response : ${response.body} ');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data['schoolInfo'][1]['row'].isNotEmpty && data['schoolInfo'][1]['row'] != null) {
        lo.g("11");
        return List<Map<String, dynamic>>.from(data['schoolInfo'][1]['row']);
      } else {
        throw Exception('No results found');
      }
    } else {
      throw Exception('Failed to load data');
    }
  }
}

class SchoolSearchPage extends StatefulWidget {
  const SchoolSearchPage({super.key});

  @override
  State<SchoolSearchPage> createState() => _SchoolSearchPageState();
}

class _SchoolSearchPageState extends State<SchoolSearchPage> {
  FloatingSearchBarController fsc = FloatingSearchBarController();

  final StreamController<List<Map<String, dynamic>>> _streamController = StreamController<List<Map<String, dynamic>>>();

  final NiceApiService _apiService = NiceApiService();
  List<Map<String, dynamic>> _results = [];
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
  }

  void _search() async {
    try {
      final data = await _apiService.getCoordinates(fsc.query);
      _streamController.sink.add(data);
      // setState(() {
      //   _results = data;
      //   _errorMessage = '';
      // });
    } catch (e) {
      _streamController.sink.addError(e);
      // setState(() {
      //   _results = [];
      //   _errorMessage = '에러: $e';
      // });
    }
  }

  _selectClick(Map<String, dynamic> data) async {
    Utils.alert("msg : ${data['SCHUL_NM']}");
  }

  @override
  void dispose() {
    _streamController.sink.close();

    _streamController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FloatingSearchBar(
      // backgroundColor: Colors.grey.shade400,
      controller: fsc,
      hint: '국내 지명, 주소를 검색해주세요.',
      clearQueryOnClose: false,
      scrollPadding: const EdgeInsets.only(top: 8.0, bottom: 56.0, left: 10.0, right: 10.0),
      margins: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 3),
      transitionDuration: const Duration(milliseconds: 100),
      borderRadius: BorderRadius.circular(14.0),
      transitionCurve: Curves.easeInOut,
      accentColor: primaryBlue,
      hintStyle: const TextStyle(color: Colors.black), //regularText,
      queryStyle: const TextStyle(color: Colors.black), //regularText,
      physics: const BouncingScrollPhysics(),
      elevation: 20.0,
      debounceDelay: const Duration(milliseconds: 300),
      onFocusChanged: (isFocused) {
        // if (!isFocused) {
        //   fsc.clear();
        // }
        RootCntr.to.bottomBarStreamController.sink.add(false);
      },
      onQueryChanged: (query) {
        _search();
      },
      onSubmitted: (query) async {
        fsc.close();
        _search();
      },
      transition: CircularFloatingSearchBarTransition(),
      automaticallyImplyBackButton: false,
      actions: [
        const FloatingSearchBarAction(
          showIfOpened: false,
          child: PhosphorIcon(
            PhosphorIconsBold.magnifyingGlass,
            color: primaryBlue,
          ),
        ),
        FloatingSearchBarAction.icon(
          showIfClosed: false,
          showIfOpened: true,
          icon: const PhosphorIcon(
            PhosphorIconsBold.x,
            color: primaryBlue,
          ),
          onTap: () {
            if (fsc.query.isEmpty) {
              fsc.close();
            } else {
              fsc.clear();
            }
          },
        ),
      ],
      builder: (context, transition) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(4.0),
          child: Material(
            color: Colors.white,
            elevation: 1.0,
            child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _streamController.stream,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const SizedBox.shrink();
                  }
                  if (snapshot.data == []) {
                    return const SizedBox.shrink();
                  }
                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.zero,
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      final _data = snapshot.data![index];
                      return InkWell(
                        onTap: () async {
                          fsc.query = _data['SCHUL_NM'];
                          fsc.close();
                          _selectClick(_data);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            children: [
                              const PhosphorIcon(PhosphorIconsFill.mapPin),
                              const SizedBox(width: 15.0),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(_data['SCHUL_NM'],
                                        style: GoogleFonts.openSans(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        )),
                                    Text(_data['ORG_RDNMA'],
                                        style: GoogleFonts.openSans(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w400,
                                          color: Colors.black,
                                        )),
                                    _data['SCHUL_KND_SC_NM'] == null
                                        ? Text(_data['SCHUL_KND_SC'],
                                            style: GoogleFonts.openSans(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w400,
                                              color: Colors.black,
                                            ))
                                        : const SizedBox.shrink(),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    separatorBuilder: (context, index) => const Divider(
                      thickness: 1.0,
                      height: 0.0,
                    ),
                  );
                }),
          ),
        );
      },
    );
  }
}


// {
//    "schoolInfo":[
//       {
//          "head":[
//             {
//                "list_total_count":201
//             },
//             {
//                "RESULT":{
//                   "CODE":"INFO-000",
//                   "MESSAGE":"정상 처리되었습니다."
//                }
//             }
//          ]
//       },
//       {
//          "row":[
//             {
//                "ATPT_OFCDC_SC_CODE":"T10",
//                "ATPT_OFCDC_SC_NM":"제주특별자치도교육청",
//                "SD_SCHUL_CODE":"9299048",
//                "SCHUL_NM":"가마초등학교",
//                "ENG_SCHUL_NM":"GAMA ELEMENTARY SCHOOL",
//                "SCHUL_KND_SC_NM":"초등학교",
//                "LCTN_SC_NM":"제주특별자치도",
//                "JU_ORG_NM":"서귀포시교육지원청",
//                "FOND_SC_NM":"공립",
//                "ORG_RDNZC":"63625 ",
//                "ORG_RDNMA":"제주특별자치도 서귀포시 표선면 일주동로6285번길 8",
//                "ORG_RDNDA":"/ 가마초등학교 (표선면)",
//                "ORG_TELNO":"064-780-9500",
//                "HMPG_ADRES":"http://gama.jje.es.kr",
//                "COEDU_SC_NM":"남여공학",
//                "ORG_FAXNO":"064-780-9580",
//                "HS_SC_NM":null,
//                "INDST_SPECL_CCCCL_EXST_YN":"N",
//                "HS_GNRL_BUSNS_SC_NM":"해당없음",
//                "SPCLY_PURPS_HS_ORD_NM":null,
//                "ENE_BFE_SEHF_SC_NM":"전기",
//                "DGHT_SC_NM":"주간",
//                "FOND_YMD":"19680301",
//                "FOAS_MEMRD":"19730316",
//                "LOAD_DTM":"20230615"
//             },
//          ]
//       }
//    ]
// }