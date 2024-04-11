// import 'package:flutter/material.dart';
// import 'package:korea_weather_api/korea_weather_api.dart';

// class FctPage extends StatefulWidget {
//   const FctPage({
//     Key? key,
//     required this.apiKey,
//   }) : super(key: key);
//   final String apiKey;

//   @override
//   State<FctPage> createState() => _FctPageState();
// }

// class _FctPageState extends State<FctPage> {
//   late Future<List<ItemFct>> items1;
//   late Future<List<ItemFct>> items2;
//   late Future<List<ItemFct>> items3;
//   late Future<List<ItemFct>> items4;

//   Future<List<ItemFct>> getFctListJson({isLog = true}) async {
//     final weather = Weather(
//       serviceKey: widget.apiKey,
//       pageNo: 1,
//       numOfRows: 10,
//     );
//     final List<ItemFct> items = [];
//     final json = await FctRepositoryImp(isLog: isLog).getItemListJSON(weather);

//     json.map((e) => setState(() => items.add(e))).toList();

//     return items;
//   }

//   Future<List<ItemFct>> getFctListXML({isLog = false}) async {
//     final weather = Weather(
//       serviceKey: widget.apiKey,
//       pageNo: 1,
//       numOfRows: 10,
//     );
//     final List<ItemFct> items = [];
//     final json = await FctRepositoryImp(isLog: isLog).getItemListXML(weather);

//     json.map((e) => setState(() => items.add(e))).toList();

//     return items;
//   }

//   Future<List<ItemFct>> getFctJson(int index, {isLog = false}) async {
//     final List<ItemFct> list = [];

//     final weather = Weather(
//       serviceKey: widget.apiKey,
//       pageNo: 1,
//       numOfRows: index,
//     );

//     for (int i = 0; i < index; i++) {
//       FctRepositoryImp(isLog: isLog).getItemJSON(weather, i).then((v) {
//         setState(() => list.add(v));
//       });
//     }

//     return list;
//   }

//   Future<List<ItemFct>> getFctXML(int index, {isLog = false}) async {
//     final List<ItemFct> list = [];

//     final weather = Weather(
//       serviceKey: widget.apiKey,
//       pageNo: 1,
//       numOfRows: index,
//     );

//     for (int i = 0; i < index; i++) {
//       FctRepositoryImp(isLog: isLog).getItemXML(weather, i).then((v) {
//         setState(() => list.add(v));
//       });
//     }

//     return list;
//   }

//   @override
//   void initState() {
//     super.initState();

//     items1 = getFctListJson();
//     items2 = getFctListXML();
//     items3 = getFctJson(10);
//     items4 = getFctXML(10);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Fct 단기 예보'),
//       ),
//       body: ex1List(),
//     );
//   }

//   Widget card(ItemFct item) {
//     const textStyle = TextStyle(fontSize: 24);
//     return Card(
//       margin: const EdgeInsets.all(8),
//       color: Colors.green,
//       child: Padding(
//         padding: const EdgeInsets.all(12.0),
//         child: Wrap(
//           direction: Axis.vertical,
//           spacing: 10,
//           runSpacing: 10,
//           children: [
//             Text('baseDate: ${item.baseDate}', style: textStyle),
//             Text('baseTime: ${item.baseTime}', style: textStyle),
//             Text('nx: ${item.nx}', style: textStyle),
//             Text('ny: ${item.ny}', style: textStyle),
//             Text('fcstTime: ${item.fcstTime}', style: textStyle),
//             Text('fcstDate: ${item.fcstDate}', style: textStyle),
//             Text('fcstValue: ${item.fcstValue}', style: textStyle),
//             Text('category: ${item.category}', style: textStyle),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget loadingWidget() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: const [
//           SizedBox(
//             height: 120,
//             width: 120,
//             child: CircularProgressIndicator(
//               strokeWidth: 10,
//             ),
//           ),
//           SizedBox(height: 20),
//           Center(
//             child: Text(
//               '⌛ Loading...',
//               style: TextStyle(fontSize: 20),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   /// getFctListJson
//   Widget ex1List() {
//     return FutureBuilder<List<ItemFct>>(
//       future: items1,
//       builder: (context, snapshot) {
//         final error = snapshot.error;
//         if (snapshot.hasData) {
//           return ListView.builder(
//             itemCount: snapshot.data?.length,
//             itemBuilder: (context, index) {
//               final item = snapshot.data![index];

//               return card(item);
//             },
//           );
//         } else if (snapshot.hasError) {
//           return Center(child: Text('Error: $error'));
//         } else {
//           return loadingWidget();
//         }
//       },
//     );
//   }

//   /// getFctListXML
//   Widget ex2List() {
//     return FutureBuilder<List<ItemFct>>(
//       future: items2,
//       builder: (context, snapshot) {
//         final error = snapshot.error;
//         if (snapshot.hasData) {
//           return ListView.builder(
//             itemCount: snapshot.data?.length,
//             itemBuilder: (context, index) {
//               final item = snapshot.data![index];

//               return card(item);
//             },
//           );
//         } else if (snapshot.hasError) {
//           return Center(child: Text('Error: $error'));
//         } else {
//           return loadingWidget();
//         }
//       },
//     );
//   }

//   /// getFctJson
//   Widget ex3List() {
//     return FutureBuilder<List<ItemFct>>(
//       future: items3,
//       builder: (context, snapshot) {
//         final error = snapshot.error;
//         if (snapshot.hasData) {
//           return ListView.builder(
//             itemCount: snapshot.data?.length,
//             itemBuilder: (context, index) {
//               final item = snapshot.data![index];

//               return card(item);
//             },
//           );
//         } else if (snapshot.hasError) {
//           return Center(child: Text('Error: $error'));
//         } else {
//           return loadingWidget();
//         }
//       },
//     );
//   }

//   /// getFctXML
//   Widget ex4List() {
//     return FutureBuilder<List<ItemFct>>(
//       future: items4,
//       builder: (context, snapshot) {
//         final error = snapshot.error;

//         if (snapshot.hasData) {
//           return ListView.builder(
//             itemCount: snapshot.data?.length,
//             itemBuilder: (context, index) {
//               final item = snapshot.data![index];

//               return card(item);
//             },
//           );
//         } else if (snapshot.hasError) {
//           return Center(child: Text('Error: $error'));
//         } else {
//           return loadingWidget();
//         }
//       },
//     );
//   }
// }
