import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:my_store/screens/Home.dart';
import 'package:my_store/screens/profile_screen.dart';
import 'package:my_store/screens/register_screen.dart';
import '../services/firebase/firebase_options.dart';
import 'package:my_store/screens/test.dart';
import 'package:my_store/screens/CartPage.dart';
import 'screens/login_screen.dart';

bool isTesting = true;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Store',
      debugShowCheckedModeBanner: false,
      initialRoute: '/login', // Giữ trang mặc định là /login
      routes: {
        '/test': (_) => AddToCartScreen(),
        '/login': (_) => LoginScreen(),
        '/register': (_) => RegisterScreen(),
        '/home': (_) => HomeScreen(),
        '/profile': (_) => ProfileScreen(),
        '/cart': (_) => CartPage(),
      },
    );
  }
}
