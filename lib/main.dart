import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../views/auth/login_screen.dart'; // Import màn hình login vào đây

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Bỏ SystemUiMode.edgeToEdge để tránh việc giao diện đè lên thanh hệ thống (Status Bar)
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Color(0xFF10B981), // Màu chủ đạo xanh lá
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
  ));
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quản Lý Phòng Trọ',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF10B981),
          primary: const Color(0xFF10B981),
        ),
        useMaterial3: true,
      ),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const LoginScreen(), // Gọi màn hình đăng nhập làm màn hình chính
    );
  }
}