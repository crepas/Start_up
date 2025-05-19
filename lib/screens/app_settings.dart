import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/TopAppbar.dart';
import '../main.dart';

class AppSettingsTab extends StatefulWidget {
  @override
  _AppSettingsTabState createState() => _AppSettingsTabState();
}

class _AppSettingsTabState extends State<AppSettingsTab> {
  bool _isLoading = true;
  Map<String, dynamic> _settings = {
    'darkMode': false,
    'language': '한국어',
    'distanceUnit': 'km',
    'autoUpdateLocation': true,
    'searchHistory': true,
    'dataCollection': true,
    'privacyPolicy': '개인정보 처리방침 버전 1.0',
    'termsOfService': '서비스 이용약관 버전 1.0',
  };

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  // 앱 설정 불러오기
  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 로컬에 저장된 설정 불러오기
      final prefs = await SharedPreferences.getInstance();
      
      setState(() {
        _settings = {
          'darkMode': prefs.getBool('darkMode') ?? false,
          'language': prefs.getString('language') ?? '한국어',
          'distanceUnit': prefs.getString('distanceUnit') ?? 'km',
          'autoUpdateLocation': prefs.getBool('autoUpdateLocation') ?? true,
          'searchHistory': prefs.getBool('searchHistory') ?? true,
          'dataCollection': prefs.getBool('dataCollection') ?? true,
          'privacyPolicy': prefs.getString('privacyPolicy') ?? '개인정보 처리방침 버전 1.0',
          'termsOfService': prefs.getString('termsOfService') ?? '서비스 이용약관 버전 1.0',
        };
      });
      
      // 서버에서 최신 설정 가져오기 (필요한 경우)
      final token = prefs.getString('token');
      if (token != null) {
        await _fetchSettingsFromServer(token);
      }
    } catch (e) {
      print('설정 로드 오류: $e');
      _showErrorSnackBar('설정을 불러오는 중 오류가 발생했습니다');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 서버에서 설정 가져오기
  Future<void> _fetchSettingsFromServer(String token) async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:8081/settings'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final serverSettings = responseData['settings'];
        
        if (serverSettings != null) {
          // 로컬 설정과 서버 설정 병합
          setState(() {
            _settings = {
              ..._settings,
              ...serverSettings,
            };
          });
          
          // 로컬 저장소 업데이트
          final prefs = await SharedPreferences.getInstance();
          serverSettings.forEach((key, value) {
            if (value is bool) {
              prefs.setBool(key, value);
            } else if (value is String) {
              prefs.setString(key, value);
            }
          });
        }
      } else {
        print('서버 응답 오류: ${response.statusCode}');
      }
    } catch (e) {
      print('서버 연결 오류: $e');
    }
  }

  // 설정 변경 처리
  Future<void> _updateSetting(String key, dynamic value) async {
    try {
      setState(() {
        _settings[key] = value;
      });
      
      // 로컬 저장소 업데이트
      final prefs = await SharedPreferences.getInstance();
      if (value is bool) {
        await prefs.setBool(key, value);
      } else if (value is String) {
        await prefs.setString(key, value);
      }
      
      // 다크 모드 설정이 변경된 경우 테마 업데이트
      if (key == 'darkMode') {
        final MyAppState? appState = context.findAncestorStateOfType<MyAppState>();
        if (appState != null) {
          appState.updateThemeMode(value ? ThemeMode.dark : ThemeMode.light);
        }
      }
      
      // 서버에 설정 업데이트 요청 (필요한 경우)
      final token = prefs.getString('token');
      if (token != null) {
        await http.post(
          Uri.parse('http://localhost:8081/settings/update'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'key': key,
            'value': value,
          }),
        );
      }
    } catch (e) {
      print('설정 업데이트 오류: $e');
      _showErrorSnackBar('설정을 저장하는 중 오류가 발생했습니다');
      
      // 오류 발생 시 원래 설정으로 복구
      _loadSettings();
    }
  }

  // 오류 메시지 표시
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // 언어 선택 다이얼로그
  Future<void> _showLanguageDialog() async {
    final List<String> languages = ['한국어', '영어', '일본어', '중국어'];
    
    final String? selectedLanguage = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('언어 선택'),
          content: Container(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: languages.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(languages[index]),
                  trailing: languages[index] == _settings['language']
                      ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
                      : null,
                  onTap: () {
                    Navigator.of(context).pop(languages[index]);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              child: Text('취소'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
    
    if (selectedLanguage != null && selectedLanguage != _settings['language']) {
      await _updateSetting('language', selectedLanguage);
    }
  }

  // 거리 단위 선택 다이얼로그
  Future<void> _showDistanceUnitDialog() async {
    final List<String> units = ['km', 'm', 'mi'];
    
    final String? selectedUnit = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('거리 단위'),
          content: Container(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: units.length,
              itemBuilder: (context, index) {
                String unitName;
                switch (units[index]) {
                  case 'km': unitName = '킬로미터 (km)'; break;
                  case 'm': unitName = '미터 (m)'; break;
                  case 'mi': unitName = '마일 (mi)'; break;
                  default: unitName = units[index];
                }
                
                return ListTile(
                  title: Text(unitName),
                  trailing: units[index] == _settings['distanceUnit']
                      ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
                      : null,
                  onTap: () {
                    Navigator.of(context).pop(units[index]);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              child: Text('취소'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
    
    if (selectedUnit != null && selectedUnit != _settings['distanceUnit']) {
      await _updateSetting('distanceUnit', selectedUnit);
    }
  }

  // 법적 정보 표시 다이얼로그
  void _showLegalInfoDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: Text(content.isNotEmpty ? content : '정보를 불러올 수 없습니다'),
          ),
          actions: [
            TextButton(
              child: Text('확인'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // 설정 섹션 헤더 위젯
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    // 스위치 스타일 정의
    final _switchTheme = SwitchThemeData(
      thumbColor: MaterialStateProperty.resolveWith<Color>((Set<MaterialState> states) {
        if (states.contains(MaterialState.selected)) {
          return Theme.of(context).colorScheme.primary;
        }
        return Theme.of(context).colorScheme.onSurface.withOpacity(0.5);
      }),
      trackColor: MaterialStateProperty.resolveWith<Color>((Set<MaterialState> states) {
        if (states.contains(MaterialState.selected)) {
          return Theme.of(context).colorScheme.primary.withOpacity(0.5);
        }
        return Theme.of(context).colorScheme.onSurface.withOpacity(0.3);
      }),
    );

    return Theme(
      data: Theme.of(context).copyWith(
        switchTheme: _switchTheme,
      ),
      child: Scaffold(
        appBar: CommonAppBar(
          title: '앱 설정',
        ),
        body: ListView(
          children: [
            // 일반 설정
            _buildSectionHeader('일반'),
            SwitchListTile(
              title: Text('다크 모드'),
              value: _settings['darkMode'],
              onChanged: (bool value) {
                _updateSetting('darkMode', value);
              },
              secondary: Icon(Icons.dark_mode),
            ),
            ListTile(
              title: Text('언어'),
              subtitle: Text(_settings['language']),
              leading: Icon(Icons.language),
              trailing: Icon(Icons.chevron_right),
              onTap: _showLanguageDialog,
            ),
            ListTile(
              title: Text('거리 단위'),
              subtitle: Text(_settings['distanceUnit']),
              leading: Icon(Icons.straighten),
              trailing: Icon(Icons.chevron_right),
              onTap: _showDistanceUnitDialog,
            ),
            
            // 위치 설정
            _buildSectionHeader('위치'),
            SwitchListTile(
              title: Text('자동 위치 업데이트'),
              subtitle: Text('현재 위치를 자동으로 업데이트합니다'),
              value: _settings['autoUpdateLocation'],
              onChanged: (bool value) {
                _updateSetting('autoUpdateLocation', value);
              },
              secondary: Icon(Icons.location_on),
            ),
            
            // 데이터 및 개인 정보
            _buildSectionHeader('데이터 및 개인 정보'),
            SwitchListTile(
              title: Text('검색 기록 저장'),
              subtitle: Text('검색 기록을 저장하여 더 나은 추천을 제공합니다'),
              value: _settings['searchHistory'],
              onChanged: (bool value) {
                _updateSetting('searchHistory', value);
              },
              secondary: Icon(Icons.history),
            ),
            SwitchListTile(
              title: Text('사용 데이터 수집'),
              subtitle: Text('앱 개선을 위한 익명 데이터를 수집합니다'),
              value: _settings['dataCollection'],
              onChanged: (bool value) {
                _updateSetting('dataCollection', value);
              },
              secondary: Icon(Icons.data_usage),
            ),
            
            // 법적 정보
            _buildSectionHeader('법적 정보'),
            ListTile(
              title: Text('개인정보 처리방침'),
              subtitle: Text(_settings['privacyPolicy']),
              leading: Icon(Icons.privacy_tip),
              trailing: Icon(Icons.chevron_right),
              onTap: () {
                _showLegalInfoDialog('개인정보 처리방침', '''
나루나루 앱은 사용자의 개인정보를 중요하게 생각하며 관련 법규를 준수합니다.

1. 수집하는 개인정보
- 필수 정보: 이메일, 이름
- 선택 정보: 위치 정보, 음식 선호도

2. 개인정보 이용 목적
- 서비스 제공 및 개선
- 맞춤형 추천 서비스 제공
- 서비스 이용 통계 수집

3. 개인정보 보유 기간
회원 탈퇴 시 또는 법령에서 정한 기간까지 보관

4. 개인정보 보호를 위한 노력
암호화 기술 적용, 접근 제한 등의 보안 조치를 취함

5. 문의처
개인정보 관련 문의: privacy@narunaru.com
                ''');
              },
            ),
            ListTile(
              title: Text('서비스 이용약관'),
              subtitle: Text(_settings['termsOfService']),
              leading: Icon(Icons.description),
              trailing: Icon(Icons.chevron_right),
              onTap: () {
                _showLegalInfoDialog('서비스 이용약관', '''
나루나루 앱 서비스 이용약관

1. 서비스 소개
나루나루는 맛집 정보 공유 및 추천 서비스를 제공합니다.

2. 서비스 이용 조건
- 만 14세 이상 이용 가능
- 회원가입 및 본인 인증 필요

3. 사용자 의무
- 타인의 권리를 침해하는 콘텐츠 게시 금지
- 허위 정보 제공 금지
- 계정 보안 유지

4. 서비스 제공자 의무
- 안전한 서비스 제공
- 개인정보 보호
- 서비스 개선 노력

5. 게시물 관련 규정
사용자가 작성한 게시물의 저작권은 작성자에게 있으나, 서비스 내에서 활용할 권리를 당사에 부여함

6. 서비스 변경 및 중단
기술적 문제, 운영상 필요 등의 사유로 서비스가 변경되거나 중단될 수 있음

7. 준거법 및 분쟁 해결
본 약관은 대한민국 법률에 따라 규율되며, 분쟁 발생 시 협의 후 소비자분쟁해결기준에 따름
                ''');
              },
            ),
            
            ListTile(
              title: Text('앱 정보'),
              subtitle: Text('버전 1.0.0'),
              leading: Icon(Icons.info),
              onTap: () {
                // 앱 정보 화면으로 이동
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('앱 정보 화면은 준비 중입니다')),
                );
              },
            ),
            
            ListTile(
              title: Text('캐시 지우기'),
              subtitle: Text('로컬에 저장된 임시 데이터를 삭제합니다'),
              leading: Icon(Icons.cleaning_services),
              onTap: () {
                // 캐시 지우기 기능
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text('캐시 지우기'),
                      content: Text('저장된 임시 데이터를 모두 삭제하시겠습니까?'),
                      actions: [
                        TextButton(
                          child: Text('취소'),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                        TextButton(
                          child: Text('삭제'),
                          onPressed: () {
                            Navigator.of(context).pop();
                            // 실제 캐시 삭제 로직 구현
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('캐시가 삭제되었습니다')),
                            );
                          },
                        ),
                      ],
                    );
                  },
                );
              },
            ),
            
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}