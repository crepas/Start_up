import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("홈 화면")),
      body: Center(child: Text("홈 화면입니다.")),
    );
  }
}
