// import 'package:flutter/material.dart';
// import 'package:korea_weather_api/korea_weather_api.dart';

// class SuperFctPage extends StatefulWidget {
//   const SuperFctPage({
//     Key? key,
//     required this.apiKey,
//   }) : super(key: key);
//   final String apiKey;

//   @override
//   State<SuperFctPage> createState() => _SuperFctPageState();
// }

// class _SuperFctPageState extends State<SuperFctPage> {
//   late Future<List<ItemSuperFct>> items1;
//   late Future<List<ItemSuperFct>> items2;
//   late Future<List<ItemSuperFct>> items3;
//   late Future<List<ItemSuperFct>> items4;

//   Future<List<ItemSuperFct>> getSuperFctListJson({isLog = false}) async {
//     final weather = Weather(
//       serviceKey: widget.apiKey,
//     );

//     final List<ItemSuperFct> items = [];

//     final json =
//         await SuperFctRepositoryImp(isLog: isLog).getItemListJSON(weather);

//     json.map((e) => setState(() => items.add(e))).toList();

//     return items;
//   }

//   Future<List<ItemSuperFct>> getSuperFctListXML({isLog = false}) async {
//     final weather = Weather(
//       serviceKey: widget.apiKey,
//     );
//     final List<ItemSuperFct> items = [];

//     final json =
//         await SuperFctRepositoryImp(isLog: isLog).getItemListXML(weather);

//     json.map((e) => setState(() => items.add(e))).toList();

//     return items;
//   }

//   Future<List<ItemSuperFct>> getSuperFctJson(int index, {isLog = false}) async {
//     final List<ItemSuperFct> list = [];

//     final weather = Weather(
//       serviceKey: widget.apiKey,
//       pageNo: 1,
//       numOfRows: index,
//     );

//     for (int i = 0; i < index; i++) {
//       SuperFctRepositoryImp(isLog: isLog).getItemJSON(weather, i).then((v) {
//         setState(() => list.add(v));
//       });
//     }

//     return list;
//   }

//   Future<List<ItemSuperFct>> getSuperFctXML(int index, {isLog = false}) async {
//     final List<ItemSuperFct> list = [];

//     final weather = Weather(
//       serviceKey: widget.apiKey,
//       pageNo: 1,
//       numOfRows: index,
//     );

//     for (int i = 0; i < index; i++) {
//       SuperFctRepositoryImp(isLog: isLog).getItemXML(weather, i).then((v) {
//         setState(() => list.add(v));
//       });
//     }

//     return list;
//   }

//   @override
//   void initState() {
//     super.initState();

//     items1 = getSuperFctListJson();
//     items2 = getSuperFctListXML();
//     items3 = getSuperFctJson(10);
//     items4 = getSuperFctXML(10);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Super Fct 초단기 예보'),
//       ),
//       body: ex1List(),
//     );
//   }

//   Widget card(ItemSuperFct item) {
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

//   /// getSuperFctListJson
//   Widget ex1List() {
//     return FutureBuilder<List<ItemSuperFct>>(
//       future: items1,
//       builder: (context, snapshot) {
//         final error = snapshot.error;
//         if (snapshot.hasData) {
//           return ListView.builder(
//             itemCount: snapshot.data!.length,
//             itemBuilder: (context, index) {
//               final item = snapshot.data![index];

//               return card(item);
//             },
//           );
//         } else if (snapshot.hasError) {
//           return Center(child: Text('Error: \n$error'));
//         } else {
//           return loadingWidget();
//         }
//       },
//     );
//   }

//   /// getSuperFctListXML
//   Widget ex2List() {
//     return FutureBuilder<List<ItemSuperFct>>(
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

//   /// getSuperFctJson
//   Widget ex3List() {
//     return FutureBuilder<List<ItemSuperFct>>(
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

//   /// getSuperFctXML
//   Widget ex4List() {
//     return FutureBuilder<List<ItemSuperFct>>(
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