// ai_recommendation_screen.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:start_up/utils/api_config.dart';

class AIRecommendationScreen extends StatefulWidget {
  @override
  _AIRecommendationScreenState createState() => _AIRecommendationScreenState();
}

class _AIRecommendationScreenState extends State<AIRecommendationScreen> {
  final TextEditingController _controller = TextEditingController();
  String? _response;
  bool _loading = false;

  Future<void> _getRecommendation() async {
    setState(() => _loading = true);

    final prompt = _controller.text;
    final url = Uri.parse('${getServerUrl()}/api/gpt-recommend');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'prompt': prompt}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        _response = data['reply'];
        _loading = false;
      });
    } else {
      setState(() {
        _response = '추천에 실패했습니다.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('AI 맛집 추천')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: '예: 강남역 근처 회식하기 좋은 맛집 추천해줘',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            SizedBox(height: 12),
            ElevatedButton(
              onPressed: _getRecommendation,
              child: Text('추천 받기'),
            ),
            SizedBox(height: 24),
            _loading
                ? CircularProgressIndicator()
                : _response != null
                ? Expanded(
              child: SingleChildScrollView(
                child: Text(_response ?? '', style: TextStyle(fontSize: 16)),
              ),
            )
                : Container(),
          ],
        ),
      ),
    );
  }
}
