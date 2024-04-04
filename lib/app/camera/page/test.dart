import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:project1/widget/custom_indicator_offstage.dart';

class TestPage extends StatefulWidget {
  const TestPage({super.key});

  @override
  State<TestPage> createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> {
  final ValueNotifier<bool> isUploading = ValueNotifier<bool>(false);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
          backgroundColor: Colors.white, centerTitle: false, forceMaterialTransparency: false, elevation: 0, scrolledUnderElevation: 0),
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Gap(40),
                  const Text('data'),
                  const Gap(40),
                  Container(
                    height: 100,
                    //   width: 100,
                    color: Colors.red,
                  ),
                  Container(
                    height: 100,
                    //  width: 100,
                    color: Colors.yellow,
                  ),
                  Container(
                    height: 100,
                    //    width: 100,
                    color: Colors.black,
                  ),
                  const TextField(
                    decoration: InputDecoration(
                      hintText: 'data',
                      hintStyle: TextStyle(color: Colors.grey),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          ValueListenableBuilder<bool>(
              valueListenable: isUploading,
              builder: (context, value, child) {
                return CustomIndicatorOffstage(isLoading: !value, color: const Color(0xFFEA3799), opacity: 0.5);
              })
        ],
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
            height: 50,
            color: Colors.blue,
            child: ElevatedButton(
              onPressed: () => isUploading.value = !isUploading.value,
              child: const Text('data'),
            )),
      ),
    );
  }
}
