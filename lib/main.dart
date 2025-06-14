import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:sis_project/firebase_options.dart';
import 'package:provider/provider.dart';
import 'package:sis_project/screens/default_screen.dart';
import 'package:sis_project/services/global_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '/.env');
  runApp(ChangeNotifierProvider(create: (_) => GlobalState(), child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "IMA - WebHub",
      initialRoute: '/',
      routes: {'/': (context) => const DefaultWebScreen()},
    );
  }
}
