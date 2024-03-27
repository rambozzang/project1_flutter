import 'package:flutter/material.dart';
import 'package:hashtagable_v3/hashtagable.dart';

class MainView2 extends StatefulWidget {
  final String title;

  const MainView2({Key? key, required this.title}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MainView2> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                /// Tagged text only to be shown
                HashTagText(
                  text: "#Welcome to #hashtagable\n This is #ReadOnlyText",
                  basicStyle: const TextStyle(fontSize: 22, color: Colors.black),
                  decoratedStyle: const TextStyle(fontSize: 22, color: Colors.red),
                  textAlign: TextAlign.center,
                  onTap: (text) {
                    print(text);
                  },
                ),
                HashTagTextField(
                  basicStyle: const TextStyle(fontSize: 15, color: Colors.black, decorationThickness: 0),
                  decoratedStyle: const TextStyle(fontSize: 15, color: Colors.blue),
                  keyboardType: TextInputType.multiline,
                  maxLines: 5,

                  decoration: InputDecoration(
                    //   hintText: "Type something here...",
                    //   hintStyle: TextStyle(fontSize: 15, color: Colors.grey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),

                  /// Called when detection (word starts with #, or # and @) is being typed
                  onDetectionTyped: (text) {
                    print(text);
                  },

                  /// Called when detection is fully typed
                  onDetectionFinished: () {
                    print("detection finished");
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
