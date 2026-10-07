import 'package:flutter/material.dart';

import 'pages/home_page.dart';

class ReplaimApp extends StatelessWidget {
  const ReplaimApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Replaim 客服邮件助手',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2F6FED)),
        fontFamily: 'PingFang SC',
      ),
      locale: const Locale('zh', 'CN'),
      supportedLocales: const [Locale('zh', 'CN'), Locale('en', 'US')],
      home: const HomePage(),
    );
  }
}
