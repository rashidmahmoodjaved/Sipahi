import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'config/firebase_config.dart';
import 'services/auth_service.dart';
import 'services/call_service.dart';
import 'services/chat_service.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: FirebaseConfig.options);
  await NotificationService().initialize();
  runApp(const SipahiApp());
}

class SipahiApp extends StatelessWidget {
  const SipahiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => ChatService()),
        ChangeNotifierProvider(create: (_) => CallService()),
      ],
      child: MaterialApp(
        title: 'Sipahi',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.indigo,
          scaffoldBackgroundColor: Colors.white,
          appBarTheme: const AppBarTheme(
            elevation: 0,
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
          ),
        ),
        home: const App(),
      ),
    );
  }
}
