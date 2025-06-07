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
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('AI 맛집 추천'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: '예: 강남역 근처 회식하기 좋은 맛집 추천해줘',
                hintStyle: TextStyle(
                  color: Colors.grey.withOpacity(0.5), // 희미한 텍스트
                  fontSize: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: theme.cardColor,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _loading ? null : _getRecommendation,
                icon: Icon(Icons.smart_toy),
                label: Text('추천 받기'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (_loading) CircularProgressIndicator(),
            if (_response != null && !_loading)
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.withOpacity(0.2)),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      _response!,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
