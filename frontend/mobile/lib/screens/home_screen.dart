import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:logging/logging.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/messaging_service.dart';
import '../services/simple_audio_service.dart';
import '../services/background_service.dart';
import '../services/samsung_call_detector.dart';
import '../services/fcm_service.dart';

import 'login_screen.dart';
import 'settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final Logger _logger = Logger('HomeScreen');
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();
  final MessagingService _messagingService = MessagingService();
  final SimpleAudioService _audioService = SimpleAudioService();
  final BackgroundService _backgroundService = BackgroundService();

  // 앱 상태 관련
  String _analysisResult = '';
  User? _currentUser;
  bool _isInitialized = false;
  bool _isMonitoring = false;
  final List<String> _detectedFiles = [];
  final Map<String, double> _uploadProgress = {};
  List<Map<String, dynamic>> _recentCalls = [];

  // 중복 업로드 방지를 위한 메서드들
  Future<String?> _getLastUploadedFileName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('last_uploaded_file');
  }

  Future<void> _setLastUploadedFileName(String fileName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_uploaded_file', fileName);
    await prefs.setString('last_upload_time', DateTime.now().toIso8601String());
    debugPrint("🔒 저장된 마지막 업로드 파일: $fileName");
  }

  Future<bool> _isAlreadyUploaded(File file) async {
    final fileName = file.path.split('/').last;
    final lastUploadedFile = await _getLastUploadedFileName();

    if (lastUploadedFile == fileName) {
      debugPrint("⏸️ 중복 업로드 방지: $fileName (이미 업로드됨)");
      return true;
    }
    return false;
  }

  /// 자동 모니터링 토글 기능
  void _toggleMonitoring() async {
    setState(() {
      _isMonitoring = !_isMonitoring;
    });

    if (_isMonitoring) {
      debugPrint("🔄 자동 모니터링 시작");
      await _startAutomaticMonitoring();
    } else {
      debugPrint("⏹️ 자동 모니터링 중지");
      await _stopAutomaticMonitoring();
    }
  }

  /// 자동 모니터링 시작
  Future<void> _startAutomaticMonitoring() async {
    try {
      // 1단계: 스트림 초기화
      debugPrint('📡 1단계: 스트림 초기화 중...');
      _audioService.initializeStream();
      debugPrint('✅ 1단계: 스트림 초기화 완료');

      // 2단계: 스트림 구독 설정
      debugPrint('📡 2단계: 스트림 구독 설정 중...');
      _audioService.fileStream?.listen((file) {
        debugPrint('📨 스트림에서 파일 수신: ${file.path}');
        setState(() {
          _detectedFiles.add(file.path);
        });

        debugPrint('📤 자동 업로드 시작: ${file.path}');
        // 자동 업로드
        _uploadFile(file);
      });
      debugPrint('✅ 2단계: 스트림 구독 설정 완료');

      // 3단계: 모니터링 시작 (스트림에 파일 추가)
      debugPrint('📡 3단계: 모니터링 시작 중...');
      await _audioService.startMonitoring();
      debugPrint('✅ 3단계: 모니터링 시작 완료');

      debugPrint("🎉 자동 모니터링 전체 시작 완료");
    } catch (e) {
      debugPrint("❌ 자동 모니터링 시작 실패: $e");
      setState(() {
        _isMonitoring = false;
      });
    }
  }

  /// 자동 모니터링 중지
  Future<void> _stopAutomaticMonitoring() async {
    try {
      _audioService.stopMonitoring();
      debugPrint("✅ 자동 모니터링 중지 완료");
    } catch (e) {
      debugPrint("❌ 자동 모니터링 중지 실패: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeApp();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _audioService.stopMonitoring();
    _backgroundService.stopBackground();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    try {
      // Firebase Auth 상태 확인 (즉시)
      _currentUser = _authService.currentUser;

      if (_currentUser != null) {
        // 사용자가 이미 로그인되어 있으면 즉시 UI 표시
        setState(() {
          _isInitialized = true;
        });

        // 백그라운드에서 서비스 초기화
        _initializeServicesInBackground();
        
        // 최근 통화 목록 로드
        _loadRecentCalls();
      } else {
        // 로그인되지 않은 경우에만 개발자 로그인 시도
        final success = await _authService.developmentLogin();
        if (success) {
          _currentUser = _authService.currentUser;
          setState(() {
            _isInitialized = true;
          });
          _initializeServicesInBackground();
        } else {
          _navigateToLogin();
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('앱 초기화 오류: $e');
      }
      _showErrorDialog('앱 초기화 중 오류가 발생했습니다: $e');
    }
  }

  /// 백그라운드에서 서비스 초기화
  void _initializeServicesInBackground() async {
    try {
      await _initializeServices();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('백그라운드 서비스 초기화 오류: $e');
      }
    }
  }

  /// 메시징 서비스 초기화
  Future<void> _initializeMessagingService() async {
    try {
      if (kDebugMode) {
        debugPrint('📱 FCM 서비스 초기화 시작...');
      }

      // 1. 사용자 로그인 상태 확인
      if (_currentUser == null) {
        if (kDebugMode) {
          debugPrint('❌ 사용자가 로그인되지 않음 - FCM 초기화 건너뜀');
        }
        return;
      }

      if (kDebugMode) {
        debugPrint('✅ 사용자 로그인 확인됨: ${_currentUser!.email}');
      }

      // 2. FCMService를 직접 사용하여 초기화
      final fcmService = FCMService();
      await fcmService.initialize();

      if (fcmService.token != null) {
        if (kDebugMode) {
          debugPrint('✅ FCMService로 토큰 획득 성공!');
          debugPrint('📱 FCM 토큰: ${fcmService.token!.substring(0, 50)}...');
        }
      } else {
        if (kDebugMode) {
          debugPrint('⚠️ FCMService 토큰이 null - 새로고침 시도');
        }
        await fcmService.refreshToken();
      }

      // 3. 메시징 서비스 초기화 (레거시 호환)
      final initialized = await _messagingService.initialize();

      if (kDebugMode) {
        debugPrint('📱 FCM 서비스 초기화 결과: $initialized');
        debugPrint('📱 FCM 토큰: ${_messagingService.fcmToken}');
        debugPrint('📱 FCM 토큰 길이: ${_messagingService.fcmToken?.length ?? 0}');
        if (_messagingService.fcmToken != null) {
          debugPrint(
            '📱 FCM 토큰 앞 20자: ${_messagingService.fcmToken!.substring(0, 20)}...',
          );
        }
      }

      // 3. 포그라운드 메시지 콜백 설정
      _messagingService.setOnForegroundMessageCallback((message) {
        _handleForegroundMessage(message);
      });

      // 4. FCM 토큰이 있으면 서버에 전송
      if (_messagingService.fcmToken != null) {
        if (kDebugMode) {
          debugPrint('📱 FCM 토큰을 서버에 전송 시도...');
          debugPrint(
              '📱 토큰: ${_messagingService.fcmToken!.substring(0, 20)}...');
        }

        final tokenSent = await _messagingService.sendTokenToServer();

        if (kDebugMode) {
          if (tokenSent) {
            debugPrint('✅ FCM 토큰이 서버에 성공적으로 등록되었습니다!');
          } else {
            debugPrint('❌ FCM 토큰 서버 전송 실패');
          }
        }
      } else {
        if (kDebugMode) {
          debugPrint('⚠️ FCM 토큰이 아직 준비되지 않음 - 잠시 후 재시도');
        }

        // 토큰이 준비되지 않은 경우 잠시 후 재시도
        Future.delayed(const Duration(seconds: 3), () async {
          if (_messagingService.fcmToken != null) {
            if (kDebugMode) {
              debugPrint('📱 지연된 FCM 토큰 서버 전송 시도...');
            }
            final tokenSent = await _messagingService.sendTokenToServer();
            if (kDebugMode) {
              if (tokenSent) {
                debugPrint('✅ 지연된 FCM 토큰 서버 전송 성공!');
              } else {
                debugPrint('❌ 지연된 FCM 토큰 서버 전송 실패');
              }
            }
          }
        });
      }

      if (kDebugMode) {
        debugPrint('📱 FCM 서비스 초기화 완료');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ FCM 서비스 초기화 실패: $e');
      }
    }
  }

  /// 포그라운드 메시지 처리 (간단한 스낵바 표시)
  void _handleForegroundMessage(RemoteMessage message) {
    try {
      if (kDebugMode) {
        debugPrint('📨 포그라운드 메시지 수신: ${message.notification?.title}');
      }

      final data = message.data;
      if (data['type'] == 'analysis_complete') {
        final webUrl = data['webUrl'];
        if (webUrl != null && webUrl.isNotEmpty) {
          // 간단한 스낵바로 메시지 표시
          _showSimpleAnalysisCompleteSnackBar(webUrl);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ 포그라운드 메시지 처리 실패: $e');
      }
    }
  }

  /// 간단한 분석 완료 스낵바 표시
  void _showSimpleAnalysisCompleteSnackBar(String webUrl) {
    if (!mounted) return;

    final message = '파일 업로드가 완료되었습니다. 분석 결과는 아래 주소에서 확인할 수 있습니다.\n$webUrl';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📁 업로드 완료',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(message, style: const TextStyle(fontSize: 14)),
          ],
        ),
        duration: const Duration(seconds: 10),
        backgroundColor: Colors.green,
        action: SnackBarAction(
          label: '웹에서 보기',
          textColor: Colors.white,
          onPressed: () => _openWebUrl(webUrl),
        ),
      ),
    );
  }

  /// 웹 URL 열기 (다단계 Fallback 전략)
  Future<void> _openWebUrl(String url) async {
    try {
      final uri = Uri.parse(url);

      // 1차 시도: 외부 브라우저로 열기
      if (await _tryLaunchUrl(uri, LaunchMode.externalApplication, '외부 브라우저')) {
        return;
      }

      // 2차 시도: 인앱 브라우저로 열기
      if (await _tryLaunchUrl(uri, LaunchMode.inAppWebView, '인앱 브라우저')) {
        return;
      }

      // 3차 시도: 플랫폼 기본 방식으로 열기
      if (await _tryLaunchUrl(uri, LaunchMode.platformDefault, '기본 브라우저')) {
        return;
      }

      // 4차 시도: Android Intent 직접 사용
      if (await _tryAndroidIntent(url)) {
        return;
      }

      // 최종 대안: URL 복사 후 안내
      await _copyUrlAndShowDialog(url);
    } catch (e) {
      await _copyUrlAndShowDialog(url, '링크 열기 실패: $e');
    }
  }

  /// URL 실행 시도 (로깅 포함)
  Future<bool> _tryLaunchUrl(Uri uri, LaunchMode mode, String modeName) async {
    try {
      // canLaunchUrl 체크 건너뛰고 바로 시도 (더 강력한 방법)
      await launchUrl(uri, mode: mode);
      _logger.info('✅ $modeName로 URL 열기 성공: ${uri.toString()}');
      return true;
    } catch (e) {
      _logger.warning('❌ $modeName 오류: $e');
      // 실패시 canLaunchUrl 체크하는 기존 방식으로 재시도
      try {
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: mode);
          _logger.info('✅ $modeName로 재시도 성공: ${uri.toString()}');
          return true;
        } else {
          _logger.warning('❌ $modeName canLaunchUrl 실패: ${uri.toString()}');
          return false;
        }
      } catch (e2) {
        _logger.severe('❌ $modeName 재시도 실패: $e2');
        return false;
      }
    }
  }

  /// Android Intent로 직접 브라우저 열기 시도
  Future<bool> _tryAndroidIntent(String url) async {
    try {
      if (Platform.isAndroid) {
        // Android Intent 방식으로 브라우저 열기 시도
        const platform = MethodChannel('flutter/platform');
        await platform.invokeMethod('openUrl', {'url': url});
        _logger.info('✅ Android Intent로 URL 열기 성공: $url');
        return true;
      }
      return false;
    } catch (e) {
      _logger.warning('❌ Android Intent 실패: $e');
      return false;
    }
  }

  /// URL 복사 후 사용자 안내
  Future<void> _copyUrlAndShowDialog(String url, [String? errorMessage]) async {
    try {
      // 클립보드에 URL 복사
      await Clipboard.setData(ClipboardData(text: url));

      final message = errorMessage != null
          ? '$errorMessage\n\n링크가 클립보드에 복사되었습니다.\n브라우저를 직접 열어서 붙여넣기 해주세요.'
          : '브라우저를 자동으로 열 수 없어 링크를 클립보드에 복사했습니다.\n브라우저를 직접 열어서 붙여넣기 해주세요.';

      _showInfoDialog('링크 복사됨', message);
    } catch (e) {
      _showErrorDialog('링크를 열 수 없습니다.\n수동으로 다음 주소를 브라우저에 입력해주세요:\n\n$url');
    }
  }

  /// 앱 생명주기 변경 처리
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (kDebugMode) {
      debugPrint('🔄 앱 생명주기 변경: $state');
    }

    switch (state) {
      case AppLifecycleState.paused:
        // 앱이 백그라운드로 갈 때
        if (kDebugMode) {
          debugPrint('📱 앱이 백그라운드로 이동');
        }
        break;
      case AppLifecycleState.resumed:
        // 앱이 포그라운드로 돌아올 때
        if (kDebugMode) {
          debugPrint('📱 앱이 포그라운드로 복귀');
        }
        break;
      case AppLifecycleState.inactive:
        // 앱이 비활성화될 때
        if (kDebugMode) {
          debugPrint('📱 앱이 비활성화됨');
        }
        break;
      case AppLifecycleState.detached:
        // 앱이 완전히 종료될 때
        if (kDebugMode) {
          debugPrint('📱 앱이 종료됨');
        }
        break;
      default:
        break;
    }
  }

  Future<void> _initializeServices() async {
    try {
      if (!kIsWeb) {
        // 메시징 서비스 초기화
        await _initializeMessagingService();

        // 전화 서비스 초기화 (삭제됨)
        // final phoneInitialized = await _phoneService.initialize();
        // if (phoneInitialized) {
        //   if (kDebugMode) {
        //     print('📞 전화 서비스 초기화 완료');
        //   }
        // } else {
        //   if (kDebugMode) {
        //     print('⚠️ 전화 서비스 초기화 실패 (권한 부족 또는 오류)');
        //   }
        // }

        if (kDebugMode) {
          debugPrint('📱 메시징 서비스 초기화 완료');
        }
      } else {
        if (kDebugMode) {
          debugPrint('🌐 웹 환경: 제한된 기능으로 초기화');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('서비스 초기화 오류: $e');
      }
      _showErrorDialog('서비스 초기화 실패: $e');
    }
  }

  void _navigateToLogin() {
    if (mounted) {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  void _showErrorDialog(String message) {
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('오류'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('확인'),
            ),
          ],
        ),
      );
    }
  }

  void _showInfoDialog(String title, String message) {
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('확인'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('앱을 초기화하는 중...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Monitor',
            style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.grey[800],
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.person), onPressed: _showUserInfo),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _authService.signOut();
              _navigateToLogin();
            },
          ),
        ],
      ),
      backgroundColor: Colors.grey[50],
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 사용자 정보 카드
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!, width: 1),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.blue[100],
                    child: Icon(Icons.person, color: Colors.blue[700]),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _currentUser?.displayName ?? '사용자',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _currentUser?.email ?? 'N/A',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 자동 모니터링 카드
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '자동 모니터링',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '통화 파일 자동 감지',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      Switch(
                        value: _isMonitoring,
                        onChanged: (_) => _toggleMonitoring(),
                        activeThumbColor: Colors.blue[600],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color:
                          _isMonitoring ? Colors.green[50] : Colors.orange[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _isMonitoring
                              ? Icons.check_circle
                              : Icons.pause_circle,
                          color: _isMonitoring
                              ? Colors.green[600]
                              : Colors.orange[600],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _isMonitoring
                                ? '녹음 파일을 실시간으로 감시하고 있습니다'
                                : '모니터링이 중지되었습니다 (수동 분석만 가능)',
                            style: TextStyle(
                              color: _isMonitoring
                                  ? Colors.green[700]
                                  : Colors.orange[700],
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 수동 분석 카드
            if (!kIsWeb)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.analytics,
                            color: Colors.blue[600],
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '수동 분석',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[800],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '최신 통화 녹음 파일 분석',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _analyzeSamsungCall,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.play_arrow, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              '분석 시작',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _pickAndUploadFile,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.blue[700],
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          side: BorderSide(color: Colors.blue[700]!, width: 2),
                        ),
                        icon: const Icon(Icons.file_upload, size: 20),
                        label: const Text(
                          '파일 선택하여 업로드',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            // 최근 통화 목록
            if (_recentCalls.isNotEmpty) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '최근 통화 분석',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton(
                            onPressed: _loadRecentCalls,
                            child: Text('새로고침'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...(_recentCalls.take(3).map((call) => _buildCallItem(call)).toList()),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // 분석 결과
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '분석 결과',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: SingleChildScrollView(
                          child: _analysisResult.isEmpty
                              ? Text(
                                  kIsWeb
                                      ? '🌐 웹 테스트 환경입니다.\n\n📱 실제 기능은 모바일 앱에서만 가능합니다.'
                                      : '📱 Samsung 분석 버튼을 눌러서\n통화 녹음 파일을 자동으로 찾고 AI 분석을 시작하세요.\n\n✅ Samsung 통화 녹음 → AI 자동 분석',
                                  style: const TextStyle(fontSize: 14),
                                )
                              : _buildAnalysisResult(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 통화 아이템 UI
  Widget _buildCallItem(Map<String, dynamic> call) {
    final callId = call['id'] ?? 'unknown';
    final fileName = call['fileName'] ?? '파일명 없음';
    final status = call['analysisStatus'] ?? 'pending';
    final result = call['analysisResult'];

    Color statusColor = Colors.grey;
    String statusText = '대기중';
    
    if (status == 'completed') {
      statusColor = Colors.green;
      statusText = '완료';
    } else if (status == 'processing') {
      statusColor = Colors.orange;
      statusText = '처리중';
    } else if (status == 'failed') {
      statusColor = Colors.red;
      statusText = '실패';
    }

    return Card(
      margin: EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          status == 'completed' ? Icons.check_circle : Icons.hourglass_empty,
          color: statusColor,
        ),
        title: Text(
          fileName.length > 30 ? '${fileName.substring(0, 30)}...' : fileName,
          style: TextStyle(fontSize: 14),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            Text('상태: $statusText', style: TextStyle(color: statusColor)),
            if (result != null && result['summary'] != null)
              Text(
                result['summary'].toString().length > 50
                    ? '${result['summary'].toString().substring(0, 50)}...'
                    : result['summary'].toString(),
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
          ],
        ),
        trailing: status == 'completed'
            ? Icon(Icons.arrow_forward_ios, size: 16)
            : null,
        onTap: status == 'completed'
            ? () {
                // 결과 표시
                setState(() {
                  _analysisResult = jsonEncode(result);
                });
              }
            : null,
      ),
    );
  }

  /// 분석 결과를 파싱하여 UI로 표시
  Widget _buildAnalysisResult() {
    try {
      // JSON 파싱 시도
      final Map<String, dynamic> result = jsonDecode(_analysisResult);

      // 웹 URL이 있는지 확인
      final String? webUrl = result['webUrl'];
      final String summary = result['summary'] ?? _analysisResult;
      final List<dynamic> recommendations = result['recommendations'] ?? [];
      final int score = result['score'] ?? 0;
      
      // 정신건강 점수 추출
      final int? depressionScore = result['depression_score'];
      final int? anxietyScore = result['anxiety_score'];
      final int? cognitiveScore = result['cognitive_score'];
      final String? emotionalState = result['emotional_state'];

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 정신건강 점수 카드
          if (depressionScore != null || anxietyScore != null || cognitiveScore != null) ...[
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📊 정신건강 분석 결과',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (cognitiveScore != null)
                      _buildScoreBar('🧠 인지 점수', cognitiveScore, Colors.green, isReversed: false),
                    if (cognitiveScore != null) const SizedBox(height: 12),
                    if (depressionScore != null)
                      _buildScoreBar('😔 우울 점수', depressionScore, Colors.orange, isReversed: true),
                    if (depressionScore != null) const SizedBox(height: 12),
                    if (anxietyScore != null)
                      _buildScoreBar('😰 불안 점수', anxietyScore, Colors.red, isReversed: true),
                    if (emotionalState != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        '💭 감정 상태: $emotionalState',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (score > 0) ...[
            Text(
              '📊 종합 점수: $score/100',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
          ],
          Text(
            '📋 요약',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(summary, style: const TextStyle(fontSize: 14)),
          if (recommendations.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              '💡 권장사항',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...recommendations.map(
              (rec) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('• $rec', style: const TextStyle(fontSize: 14)),
              ),
            ),
          ],
          if (webUrl != null) ...[
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: () => _openWebAnalysis(webUrl),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.open_in_browser, size: 18),
                    const SizedBox(width: 8),
                    const Text(
                      '🌐 상세 분석 보기',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      );
    } catch (e) {
      // JSON 파싱 실패 시 원본 텍스트 표시
      return Text(_analysisResult, style: const TextStyle(fontSize: 14));
    }
  }

  /// 점수 바 위젯 생성 (0-100점)
  Widget _buildScoreBar(String label, int score, Color color, {bool isReversed = false}) {
    // isReversed: true면 낮을수록 좋음 (우울, 불안), false면 높을수록 좋음 (인지)
    Color barColor;
    String statusText;
    
    if (isReversed) {
      // 우울/불안 점수: 낮을수록 좋음
      if (score <= 30) {
        barColor = Colors.green;
        statusText = '정상';
      } else if (score <= 50) {
        barColor = Colors.orange;
        statusText = '경증';
      } else if (score <= 70) {
        barColor = Colors.deepOrange;
        statusText = '중등도';
      } else {
        barColor = Colors.red;
        statusText = '주의';
      }
    } else {
      // 인지 점수: 높을수록 좋음
      if (score >= 80) {
        barColor = Colors.green;
        statusText = '정상';
      } else if (score >= 60) {
        barColor = Colors.orange;
        statusText = '경증';
      } else if (score >= 40) {
        barColor = Colors.deepOrange;
        statusText = '중등도';
      } else {
        barColor = Colors.red;
        statusText = '주의';
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '$score점 ($statusText)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: barColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: score / 100,
            backgroundColor: Colors.grey.shade300,
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
            minHeight: 10,
          ),
        ),
      ],
    );
  }

  /// 웹 분석 결과 페이지 열기
  Future<void> _openWebAnalysis(String url) async {
    try {
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showErrorDialog('웹 브라우저를 열 수 없습니다.');
      }
    } catch (e) {
      _showErrorDialog('링크 열기 실패: $e');
    }
  }

  void _showUserInfo() {
    if (_currentUser != null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('사용자 정보'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('이름: ${_currentUser!.displayName ?? 'N/A'}'),
              Text('이메일: ${_currentUser!.email ?? 'N/A'}'),
              Text('UID: ${_currentUser!.uid}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('닫기'),
            ),
          ],
        ),
      );
    }
  }

  /// Samsung 통화 분석 설정 상태 확인
  Future<void> _checkSamsungSetupStatus() async {
    try {
      final detector = SamsungCallDetector();

      // 권한 체크
      final hasPermissions = await detector.requestStoragePermissions();
      if (!hasPermissions) {
        _showSetupDialog(
          '통화 분석 설정 미완료',
          '파일 접근 권한이 필요합니다.\n\n'
              '설정 → 앱 → Senior Health Monitor → 권한에서\n'
              '"모든 파일 관리" 권한을 허용해주세요.',
        );
        return;
      }

      // Samsung 폴더 접근 체크
      final hasSamsungAccess = await detector.checkCallRecordingFolder();
      if (!hasSamsungAccess) {
        _showSetupDialog(
          '통화 녹음 설정 미완료',
          '통화 녹음이 활성화되지 않았거나\n'
              '통화 녹음 파일이 존재하지 않습니다.\n\n'
              '전화 앱 → 설정 → 통화 녹음을 활성화해주세요.',
        );
        return;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Samsung 설정 체크 실패: $e');
      }
    }
  }

  /// 설정 안내 대화상자 표시
  void _showSetupDialog(String title, String message) {
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushNamed(context, '/setup');
              },
              child: const Text('설정 진행'),
            ),
          ],
        ),
      );
    }
  }

  /// 최근 통화 목록 불러오기 (Firestore에서 직접)
  Future<void> _loadRecentCalls() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      debugPrint('📋 최근 통화 목록 로드 중...');

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('calls')
          .orderBy('uploadedAt', descending: true)
          .limit(10)
          .get();

      final calls = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();

      setState(() {
        _recentCalls = calls;
      });

      debugPrint('✅ 통화 목록 로드 완료: ${calls.length}개');
    } catch (e) {
      debugPrint('❌ 통화 목록 로드 실패: $e');
    }
  }

  /// 파일 업로드 (자동 모니터링용)
  Future<void> _uploadFile(File file) async {
    // 중복 체크 먼저 수행
    if (await _isAlreadyUploaded(file)) {
      return; // 이미 업로드된 파일이면 처리 중단
    }

    final fileName = file.path.split('/').last;
    debugPrint("📤 새 파일 업로드 시작: $fileName");

    setState(() {
      _uploadProgress[fileName] = 0.0;
    });

    try {
      // ✅ ApiService를 사용하여 업로드 (시니어 정보 포함)
      debugPrint("🔍 ApiService를 통한 업로드 시작...");
      final result = await _apiService.uploadAndAnalyzeAudio(file);

      debugPrint("✅ 업로드 및 분석 요청 성공: $fileName");

      // 성공시에만 마지막 업로드 파일로 기록
      await _setLastUploadedFileName(fileName);

      setState(() {
        _uploadProgress[fileName] = 1.0;
        _analysisResult = result; // 분석 결과 표시
      });

      _showSnackBar('📁 업로드 완료: $fileName (AI 분석 시작됨)');
    } catch (e) {
      debugPrint("❌ 업로드 에러: $e");
      setState(() {
        _uploadProgress[fileName] = 0.0;
      });

      _showSnackBar('❌ 업로드 실패: ${e.toString()}');
    }
  }

  /// 📁 수동으로 파일을 선택하여 업로드 및 분석
  Future<void> _pickAndUploadFile() async {
    try {
      _showSnackBar('파일을 선택하세요...');

      // FilePicker로 오디오 파일 선택
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        _showSnackBar('파일 선택이 취소되었습니다');
        return;
      }

      final pickedFile = result.files.first;
      final filePath = pickedFile.path;

      if (filePath == null) {
        _showSnackBar('파일 경로를 가져올 수 없습니다');
        return;
      }

      final file = File(filePath);
      if (!await file.exists()) {
        _showSnackBar('파일이 존재하지 않습니다');
        return;
      }

      final fileName = pickedFile.name;
      final fileSize = pickedFile.size;

      _showSnackBar('파일 업로드 중: $fileName (${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB)');

      setState(() {
        _analysisResult = '📤 파일 업로드 중...\n\n파일: $fileName\n크기: ${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB\n\n⏳ 잠시만 기다려주세요...';
      });

      // API 서비스를 사용하여 업로드 및 분석
      final uploadResult = await _apiService.uploadAndAnalyzeAudio(file);

      setState(() {
        _analysisResult = uploadResult;
      });

      _showSnackBar('✅ 파일 업로드 완료!\nAI 분석이 시작되었습니다.');

    } catch (e) {
      debugPrint('❌ 파일 선택/업로드 오류: $e');
      setState(() {
        _analysisResult = '❌ 파일 업로드 실패\n\n오류: ${e.toString()}';
      });
      _showSnackBar('❌ 파일 업로드 실패: ${e.toString()}');
    }
  }

  /// Samsung 통화 녹음을 찾아서 AI 분석 요청
  void _analyzeSamsungCall() async {
    try {
      // 먼저 설정 상태 확인
      await _checkSamsungSetupStatus();

      _showSnackBar('시니어 정보 및 통화 녹음을 찾는 중...');

      // 🎯 현재 사용자의 시니어 정보 조회
      final currentSenior = await _apiService.getCurrentSenior();
      if (currentSenior == null) {
        _showErrorDialog(
          '시니어 정보를 찾을 수 없습니다.\n\n'
          '• 시니어 등록이 완료되었는지 확인하세요\n'
          '• 인터넷 연결을 확인하세요',
        );
        return;
      }

      final seniorName = currentSenior['name'] as String;
      _showSnackBar('시니어: $seniorName\n통화 녹음을 찾는 중...');

      final detector = SamsungCallDetector();
      // 🎯 시니어 이름으로 필터링하여 통화 파일 검색
      final latestFile = await detector.findLatestCallRecording(
        seniorName: seniorName,
      );

      if (latestFile == null) {
        _showErrorDialog(
          '\'$seniorName\'님의 통화 녹음 파일을 찾을 수 없습니다.\n\n'
          '• 통화 녹음 기능이 활성화되어 있는지 확인하세요\n'
          '• \'$seniorName\'님과의 최근 통화 녹음이 있는지 확인하세요\n'
          '• 시니어 이름이 전화번호부 이름과 정확히 일치하는지 확인하세요',
        );
        return;
      }

      final fileName = latestFile.path.split('/').last;
      _showSnackBar('파일 발견: $fileName\nAI 분석을 요청하는 중...');

      setState(() {
        _analysisResult = '📤 AI 분석 요청 중...\n\n파일: $fileName\n⏳ 잠시만 기다려주세요...';
      });

      // 기존 API 서비스를 사용하여 업로드 및 분석
      final result = await _apiService.uploadAndAnalyzeAudio(latestFile);

      setState(() {
        _analysisResult = result;
      });

      _showSnackBar('📁 파일 업로드 완료! AI 분석 결과는 알림으로 확인하세요');
    } catch (e) {
      setState(() {
        _analysisResult = '''
❌ 통화 분석 실패

오류 내용:
$e

💡 해결 방법:
• 인터넷 연결을 확인하세요
• 시니어 이름이 전화번호부와 정확히 일치하는지 확인하세요
• 앱을 재시작해보세요
        ''';
      });
      _showErrorDialog('통화 분석 중 오류가 발생했습니다:\n$e');
    }
  }
}
