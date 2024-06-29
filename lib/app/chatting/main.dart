import 'package:flutter/material.dart';
import 'package:flutter_supabase_chat_core/flutter_supabase_chat_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'color_schemes.g.dart';
import 'chat_main_page.dart';
import 'supabase_options.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await Supabase.initialize(
//     url: supabaseOptions.url,
//     anonKey: supabaseOptions.anonKey,
//   );

//   runApp(const ChatMainApp());
// }

class ChatMainApp1 extends StatelessWidget {
  const ChatMainApp1({
    super.key,
  });

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Firebase Chat',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: lightColorScheme,
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          colorScheme: darkColorScheme,
        ),
        themeMode: ThemeMode.light,
        //  home: const RoomsPage(),
        // home: const UserOnlineStateObserver(
        //   child: RoomsPage(),
        // ),
      );
}
