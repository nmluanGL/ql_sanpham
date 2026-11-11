import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'login_screen.dart';
import 'products_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  String? setupError;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (_) {
    setupError = 'Chưa kết nối được Firebase. Kiểm tra cấu hình theo README.';
  }

  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Quản lý sản phẩm',
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF305BE0),
        scaffoldBackgroundColor: const Color(0xFFF3F6FC),
        appBarTheme: const AppBarTheme(backgroundColor: Colors.white),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF8FAFF),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
        ),
      ),
      home: setupError == null
          ? const SessionScreen()
          : Scaffold(body: Center(child: Text(setupError))),
    ),
  );
}

class SessionScreen extends StatelessWidget {
  const SessionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(child: Text('Không đọc được phiên đăng nhập.')),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return snapshot.data == null
            ? const LoginScreen()
            : const ProductsScreen();
      },
    );
  }
}
