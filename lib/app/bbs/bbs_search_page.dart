import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BbsSearchPage extends StatefulWidget {
  const BbsSearchPage({super.key});

  @override
  State<BbsSearchPage> createState() => _BbsSearchPageState();
}

class _BbsSearchPageState extends State<BbsSearchPage> {
  TextEditingController searchController = TextEditingController();
  FocusNode textFocus = FocusNode();

  ValueNotifier<bool> isAdLoading = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildSearchBar(),
      backgroundColor: Colors.white,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return Column(
      children: <Widget>[
        _buildSearchBar(),
        const Spacer(),
        _buildSearchResult(),
      ],
    );
  }

  AppBar _buildSearchBar() {
    return AppBar(
      forceMaterialTransparency: true,
      automaticallyImplyLeading: false,
      //titleSpacing: 0,
      title: Container(
        margin: const EdgeInsets.only(left: 0, right: 0),
        padding: const EdgeInsets.only(top: 5),
        // color: Colors.red,
        //  height: 54,
        child: TextFormField(
          controller: searchController,
          focusNode: textFocus,
          maxLines: 1,
          style: const TextStyle(decorationThickness: 0), // 한글밑줄제거
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
            filled: true,
            fillColor: Colors.grey[100],
            suffixIcon: const Icon(Icons.search, color: Colors.grey),
            enabledBorder: OutlineInputBorder(
              // width: 0.0 produces a thin "hairline" border
              borderSide: const BorderSide(color: Colors.grey, width: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            border: OutlineInputBorder(
              // width: 0.0 produces a thin "hairline" border
              //  borderSide: const BorderSide(color: Colors.grey, width: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.grey, width: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            label: const Text("검색어를 입력해주세요"),
            labelStyle: const TextStyle(color: Colors.black38),
          ),
          onFieldSubmitted: (searchWord) {
            // Perform search searchWord
            // Get.toNamed('/MainView1/$searchWord');
            // goSearchPage(searchWord);
          },
        ),
      ),
      centerTitle: false,
      //  backgroundColor: Colors.transparent,
      elevation: 0,
      actions: [
        IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(Icons.close),
        ),
      ],
    );
  }

  Widget _buildSearchResult() {
    return Container(
      color: Colors.orange,
    );
  }
}
