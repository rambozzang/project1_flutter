// import 'package:flutter/material.dart';
// import 'package:korea_weather_api/korea_weather_api.dart';
// import 'package:pretty_dio_logger/pretty_dio_logger.dart';

// class FctVersionPage extends StatefulWidget {
//   const FctVersionPage({
//     Key? key,
//     required this.apiKey,
//   }) : super(key: key);
//   final String apiKey;

//   @override
//   State<FctVersionPage> createState() => _FctVersionPageState();
// }

// class _FctVersionPageState extends State<FctVersionPage> {
//   late Future<List<ItemFctVersion>> items1;
//   late Future<List<ItemFctVersion>> items2;

//   final logger = PrettyDioLogger(
//     requestHeader: true,
//     requestBody: true,
//     responseHeader: true,
//     responseBody: true,
//   );

//   Future<List<ItemFctVersion>> getFctVersionJson({isLog = true}) async {
//     final List<ItemFctVersion> items = [];

//     final weather = WeatherVersion(
//       serviceKey: widget.apiKey,
//       pageNo: 1,
//       numOfRows: 100,
//     );

//     FctVersionRepositoryImp(isLog: isLog, customLogger: logger).getItemJSON(weather).then((value) => setState(() => items.add(value)));

//     return items;
//   }

//   Future<List<ItemFctVersion>> getFctVersionXML({isLog = true}) async {
//     final List<ItemFctVersion> items = [];

//     final weather = WeatherVersion(
//       serviceKey: widget.apiKey,
//       pageNo: 1,
//       numOfRows: 100,
//     );

//     FctVersionRepositoryImp(isLog: isLog, customLogger: logger).getItemXML(weather).then((value) => setState(() => items.add(value)));

//     return items;
//   }

//   @override
//   void initState() {
//     super.initState();
//     items1 = getFctVersionJson();
//     items2 = getFctVersionXML();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Fct Version 예보 버전'),
//       ),
//       // body: itemJson(),
//       body: itemXML(),
//     );
//   }

//   Widget card(ItemFctVersion item) {
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
//             Text('version: ${item.version}', style: textStyle),
//             Text('filetype: ${item.filetype}', style: textStyle),
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

//   /// getFctVersionJson
//   Widget itemJson() {
//     return FutureBuilder<List<ItemFctVersion>>(
//       future: items1,
//       builder: (context, snapshot) {
//         final error = snapshot.error;
//         if (snapshot.hasData) {
//           return ListView.builder(
//             itemCount: snapshot.data?.length,
//             itemBuilder: (context, index) {
//               final item = snapshot.data![0];

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

//   /// getFctVersionXML
//   Widget itemXML() {
//     return FutureBuilder<List<ItemFctVersion>>(
//       future: items2,
//       builder: (context, snapshot) {
//         final error = snapshot.error;

//         if (snapshot.hasData) {
//           return ListView.builder(
//             itemCount: snapshot.data?.length,
//             itemBuilder: (context, index) {
//               final item = snapshot.data![0];

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
