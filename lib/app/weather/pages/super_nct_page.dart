// import 'package:flutter/material.dart';
// import 'package:korea_weather_api/korea_weather_api.dart';

// class SuperNctPage extends StatefulWidget {
//   const SuperNctPage({Key? key, required this.apiKey}) : super(key: key);
//   final String apiKey;

//   @override
//   State<SuperNctPage> createState() => _SuperNctPageState();
// }

// class _SuperNctPageState extends State<SuperNctPage> {
//   late Future<List<ItemSuperNct>> items1;
//   late Future<List<ItemSuperNct>> items2;
//   late Future<List<ItemSuperNct>> items3;
//   late Future<List<ItemSuperNct>> items4;

//   Future<List<ItemSuperNct>> getSuperNctListJson({isLog = false}) async {
//     final weather = Weather(
//       serviceKey: widget.apiKey,
//       pageNo: 1,
//       numOfRows: 100,
//     );
//     final List<ItemSuperNct> items = [];
//     final json =
//         await SuperNctRepositoryImp(isLog: isLog).getItemListJSON(weather);

//     json.map((e) => setState(() => items.add(e))).toList();

//     return items;
//   }

//   Future<List<ItemSuperNct>> getSuperNctListXML({isLog = false}) async {
//     final weather = Weather(
//       serviceKey: widget.apiKey,
//       pageNo: 1,
//       numOfRows: 100,
//     );
//     final List<ItemSuperNct> items = [];
//     final json = await SuperNctRepositoryImp(
//       isLog: isLog,
//     ).getItemListXML(weather);

//     json.map((e) => setState(() => items.add(e))).toList();

//     return items;
//   }

//   Future<List<ItemSuperNct>> getSuperNctJson(int index, {isLog = false}) async {
//     final List<ItemSuperNct> list = [];

//     final weather = Weather(
//       serviceKey: widget.apiKey,
//       pageNo: 1,
//       numOfRows: index,
//     );

//     for (int i = 0; i < index; i++) {
//       SuperNctRepositoryImp(isLog: isLog).getItemJSON(weather, i).then((v) {
//         setState(() => list.add(v));
//       });
//     }

//     return list;
//   }

//   Future<List<ItemSuperNct>> getSuperNctXML(int index, {isLog = false}) async {
//     final List<ItemSuperNct> list = [];

//     final weather = Weather(
//       serviceKey: widget.apiKey,
//       pageNo: 1,
//       numOfRows: index,
//     );

//     for (int i = 0; i < index; i++) {
//       SuperNctRepositoryImp(isLog: isLog).getItemXML(weather, i).then((v) {
//         setState(() => list.add(v));
//       });
//     }

//     return list;
//   }

//   @override
//   void initState() {
//     super.initState();

//     items1 = getSuperNctListJson();
//     items2 = getSuperNctListXML();
//     items3 = getSuperNctJson(5);
//     items4 = getSuperNctXML(5);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Super Nct 초단기 실황'),
//       ),
//       body: ex1List(),
//     );
//   }

//   Widget card(ItemSuperNct item) {
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
//             Text('category: ${item.category}', style: textStyle),
//             Text('obsrValue: ${item.obsrValue}', style: textStyle),
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

//   /// getItemFctListJson
//   Widget ex1List() {
//     return FutureBuilder<List<ItemSuperNct>>(
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

//   /// getItemFctListXML
//   Widget ex2List() {
//     return FutureBuilder<List<ItemSuperNct>>(
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

//   /// getItemFctJson
//   Widget ex3List() {
//     return FutureBuilder<List<ItemSuperNct>>(
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

//   /// getItemFctXML
//   Widget ex4List() {
//     return FutureBuilder<List<ItemSuperNct>>(
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