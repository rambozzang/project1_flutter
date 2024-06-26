import 'package:flutter/material.dart';
import 'package:flutter_supabase_chat_core/flutter_supabase_chat_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'color_schemes.g.dart';
import 'rooms.dart';
import 'supabase_options.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await Supabase.initialize(
//     url: supabaseOptions.url,
//     anonKey: supabaseOptions.anonKey,
//   );

//   runApp(const ChatMainApp());
// }

class ChatMainApp extends StatelessWidget {
  const ChatMainApp({
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
        themeMode: ThemeMode.dark,
        home: const UserOnlineStateObserver(
          child: RoomsPage(),
        ),
      );
}
