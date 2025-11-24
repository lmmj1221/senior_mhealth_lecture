import 'dart:convert';
import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'notification_channel_manager.dart';

class MessagingService {
  static final MessagingService _instance = MessagingService._internal();
  factory MessagingService() => _instance;
  MessagingService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final Logger _logger = Logger('MessagingService');
  final Connectivity _connectivity = Connectivity();

  bool _isInitialized = false;
  String? _fcmToken;
  bool _notificationEnabled = true;
  Timer? _retryTimer;
  int _retryCount = 0;
  static const int _maxRetryCount = 2;  // 재시도 횟수 감소
  static const Duration _retryDelay = Duration(seconds: 5);  // 재시도 간격 단축

  // 추가된 오류 추적 변수들
  DateTime? _lastTokenUpdate;
  String? _lastError;
  int _totalErrorCount = 0;

  // 포그라운드 알림 콜백
  Function(RemoteMessage)? _onForegroundMessage;

  /// 포그라운드 메시지 콜백 설정
  void setOnForegroundMessageCallback(Function(RemoteMessage) callback) {
    _onForegroundMessage = callback;
    _logger.info('포그라운드 메시지 콜백 설정됨');
  }

  /// Android Notification Channel 생성
  Future<void> _createNotificationChannels() async {
    try {
      if (kIsWeb) return; // 웹에서는 채널 생성 불필요

      // NotificationChannelManager를 통해 모든 채널 생성
      await NotificationChannelManager.initialize();
      _logger.info('NotificationChannelManager 초기화 완료');

      // 포그라운드 알림 설정
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      _logger.info('포그라운드 알림 설정 완료');
    } catch (e) {
      _logger.severe('Android 알림 설정 실패: $e');
    }
  }

  /// FCM 서비스 초기화 (최적화된 버전)
  Future<bool> initialize() async {
    if (_isInitialized) {
      _logger.info('MessagingService 이미 초기화됨');
      return true;
    }

    try {
      _logger.info('MessagingService 초기화 시작');

      // 1. Android Notification Channel 생성
      await _createNotificationChannels();
      _logger.info('알림 채널 생성 완료');

      // 2. 즉시 메시지 리스너 설정 (앱 시작을 차단하지 않음)
      _setupMessageListeners();
      _logger.info('메시지 리스너 설정 완료');

      // 3. 백그라운드에서 나머지 초기화 진행
      _initializeInBackground();

      _isInitialized = true;
      _logger.info('MessagingService 초기화 완료 (백그라운드에서 계속 진행)');
      return true;
    } catch (e, stackTrace) {
      _logger.severe('MessagingService 초기화 실패: $e');
      _logger.severe('스택 트레이스: $stackTrace');
      _recordError('초기화 실패: $e');
      return false;
    }
  }

  /// 백그라운드에서 초기화 진행
  void _initializeInBackground() async {
    try {
      _logSystemInfo();

      // 1. 저장된 설정 로드
      await _loadSettings();
      _logger.info('설정 로드 완료 - 알림 활성화: $_notificationEnabled');

      // 2. 권한 요청 (동기적으로 처리)
      final hasPermission = await _requestPermissions();
      if (!hasPermission) {
        _logger.warning('FCM 권한이 거부되었습니다');
        _recordError('FCM 권한 거부');
        return; // 권한이 없으면 초기화 중단
      }

      // 3. FCM 토큰 가져오기 (동기적으로 처리)
      await _getFCMToken();

      // 4. 네트워크 연결 상태 모니터링 시작
      _setupConnectivityListener();
      _logger.info('네트워크 모니터링 시작');

      _logger.info('MessagingService 백그라운드 초기화 완료');
    } catch (e) {
      _logger.severe('MessagingService 백그라운드 초기화 실패: $e');
      if (kDebugMode) {
        print('❌ MessagingService 백그라운드 초기화 실패: $e');
      }
    }
  }

  /// 권한 요청 (개선된 버전)
  Future<bool> _requestPermissions() async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
        criticalAlert: false,
        carPlay: false,
        announcement: false,
      );

      _logger.info('FCM 권한 상태: ${settings.authorizationStatus}');

      final isAuthorized =
          settings.authorizationStatus == AuthorizationStatus.authorized ||
              settings.authorizationStatus == AuthorizationStatus.provisional;

      if (!isAuthorized) {
        _logger.warning('FCM 권한이 거부되었습니다');
        _notificationEnabled = false;
        await _saveSettings();
      }

      return isAuthorized;
    } catch (e) {
      _logger.severe('FCM 권한 요청 실패: $e');
      return false;
    }
  }

  /// FCM 토큰 가져오기 (개선된 버전)
  Future<void> _getFCMToken() async {
    try {
      _logger.info('FCM 토큰 획득 시도 시작');
      if (kDebugMode) {
        print('🔑 === FCM 토큰 획득 프로세스 시작 ===');
      }

      // Firebase 초기화 상태 확인
      try {
        final apps = Firebase.apps;
        if (kDebugMode) {
          print('🔑 Firebase 앱 개수: ${apps.length}');
          for (var app in apps) {
            print(
                '🔑 Firebase 앱: ${app.name}, options: ${app.options.projectId}');
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('❌ Firebase 앱 확인 실패: $e');
        }
      }

      // 사용자 로그인 상태 확인 제거 - 토큰은 로그인 전에도 생성 가능해야 함
      // final user = FirebaseAuth.instance.currentUser;
      // if (user == null) {
      //   _logger.warning('사용자가 로그인되지 않음 - FCM 토큰 획득 건너뜀');
      //   return;
      // }

      if (kDebugMode) {
        print('🔑 FCM 토큰 요청 중...');
      }

      _fcmToken = await _messaging.getToken();

      if (_fcmToken != null) {
        _logger.info('FCM 토큰 획득 성공: ${_fcmToken!.substring(0, 20)}...');
        if (kDebugMode) {
          print('🔑 FCM 토큰 획득 성공!');
          print('🔑 토큰 길이: ${_fcmToken!.length}');
          print('🔑 토큰 앞 20자: ${_fcmToken!.substring(0, 20)}...');
          print('🔑 토큰 전체: $_fcmToken');
        }
        _recordTokenUpdate();

        // 토큰 변경 리스너 설정
        _messaging.onTokenRefresh.listen((token) {
          _fcmToken = token;
          _logger.info('FCM 토큰 갱신: ${token.substring(0, 20)}...');
          _recordTokenUpdate();
          _handleTokenRefresh(token);
        });

        // 서버에 토큰 전송 (강화된 재시도)
        if (_notificationEnabled) {
          _logger.info('서버에 FCM 토큰 전송 시작');
          await _sendTokenToServerWithRetry(_fcmToken!);
        } else {
          _logger.info('알림이 비활성화되어 토큰 전송 건너뜀');
        }
      } else {
        _logger.warning('FCM 토큰이 null입니다');
        if (kDebugMode) {
          print('❌ FCM 토큰이 null입니다!');
          print('❌ 가능한 원인:');
          print('   1. Google Play Services가 최신 버전이 아님');
          print('   2. 인터넷 연결 문제');
          print('   3. Firebase 프로젝트 설정 문제');
          print('   4. google-services.json 파일 문제');
          print('   5. 에뮬레이터에서 실행 중 (Google Play Services 없음)');
        }
        _recordError('FCM 토큰 null');
        _scheduleTokenRetry();
      }
    } catch (e, stackTrace) {
      _logger.severe('FCM 토큰 가져오기 실패: $e');
      _logger.severe('스택 트레이스: $stackTrace');
      if (kDebugMode) {
        print('❌ FCM 토큰 획득 실패!');
        print('❌ 오류 타입: ${e.runtimeType}');
        print('❌ 오류 메시지: $e');

        // 특정 오류 타입에 따른 안내
        if (e.toString().contains('MissingPluginException')) {
          print('❌ Firebase Messaging 플러그인이 제대로 설치되지 않았습니다.');
          print('   해결방법: flutter clean && flutter pub get');
        } else if (e.toString().contains('PERMISSION_DENIED')) {
          print('❌ 알림 권한이 거부되었습니다.');
          print('   해결방법: 앱 설정에서 알림 권한을 허용하세요.');
        } else if (e.toString().contains('SENDER_ID_MISMATCH')) {
          print('❌ Firebase 프로젝트 설정이 일치하지 않습니다.');
          print('   해결방법: google-services.json 파일을 다시 다운로드하세요.');
        }
      }
      _recordError('토큰 획득 실패: $e');
      // 토큰 획득 실패 시 재시도 스케줄링
      _scheduleTokenRetry();
    }
  }

  /// 메시지 리스너 설정 (개선된 버전)
  void _setupMessageListeners() {
    // 앱이 포그라운드에 있을 때
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _logger.info('포그라운드 메시지 수신: ${message.notification?.title}');
      _handleForegroundMessage(message);
    });

    // 앱이 백그라운드에서 탭될 때
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _logger.info('백그라운드 메시지 탭: ${message.notification?.title}');
      _handleMessage(message);
    });

    // 앱이 종료된 상태에서 탭될 때
    _messaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        _logger.info('앱 종료 상태에서 메시지 탭: ${message.notification?.title}');
        _handleMessage(message);
      }
    });
  }

  /// 메시지 처리 (개선된 오류 처리)
  void _handleMessage(RemoteMessage message) {
    try {
      _logger.info('=== 메시지 처리 시작 ===');
      _logger.info('메시지 ID: ${message.messageId}');
      _logger.info('발신자: ${message.from}');
      _logger.info('제목: ${message.notification?.title}');
      _logger.info('내용: ${message.notification?.body}');
      _logger.info('데이터: ${message.data}');

      final data = message.data;

      if (data.isEmpty) {
        _logger.warning('메시지 데이터가 비어있습니다');
        _recordError('빈 메시지 데이터');
        return;
      }

      if (data['type'] == 'analysis_complete') {
        final webUrl = data['webUrl'];
        if (webUrl != null && webUrl.isNotEmpty) {
          _logger.info('분석 완료 메시지 - 간단한 알림 표시: $webUrl');
          _showSimpleAnalysisCompleteMessage(webUrl);
        } else {
          final errorMsg = '웹 URL이 비어있거나 null입니다';
          _logger.warning(errorMsg);
          _recordError(errorMsg);
        }
      } else {
        final errorMsg = '알 수 없는 메시지 타입: ${data['type']}';
        _logger.info(errorMsg);
        _recordError(errorMsg);
      }

      _logger.info('=== 메시지 처리 완료 ===');
    } catch (e, stackTrace) {
      final errorMsg = '메시지 처리 실패: $e';
      _logger.severe(errorMsg);
      _logger.severe('스택 트레이스: $stackTrace');
      _recordError(errorMsg);
    }
  }

  /// 간단한 분석 완료 메시지 표시
  void _showSimpleAnalysisCompleteMessage(String webUrl) {
    try {
      _logger.info('간단한 업로드 완료 메시지 표시: $webUrl');

      // 전역 스낵바 표시를 위한 콜백 호출
      if (_onForegroundMessage != null) {
        final message = '파일 업로드가 완료되었습니다. 분석 결과는 아래 주소에서 확인할 수 있습니다.\n$webUrl';
        _onForegroundMessage!(RemoteMessage(
          data: {'type': 'analysis_complete', 'webUrl': webUrl},
          notification: RemoteNotification(
            title: '업로드 완료',
            body: message,
          ),
        ));
      } else {
        _logger.warning('포그라운드 메시지 콜백이 설정되지 않음');
      }
    } catch (e) {
      _logger.severe('간단한 메시지 표시 실패: $e');
    }
  }

  /// 서버에 FCM 토큰 전송 (재시도 로직 포함)
  Future<bool> _sendTokenToServerWithRetry(String token) async {
    _logger.info('FCM 토큰 서버 전송 시작 - 토큰: ${token.substring(0, 20)}...');

    for (int attempt = 1; attempt <= _maxRetryCount; attempt++) {
      try {
        _logger.info('FCM 토큰 서버 전송 시도 $attempt/$_maxRetryCount');

        final success = await _sendTokenToServer(token);
        if (success) {
          _retryCount = 0; // 성공 시 재시도 카운트 리셋
          _logger.info('FCM 토큰 서버 전송 성공 (시도 $attempt)');
          return true;
        }

        if (attempt < _maxRetryCount) {
          _logger.warning(
              'FCM 토큰 전송 실패, ${_retryDelay.inSeconds}초 후 재시도... (시도 $attempt/$_maxRetryCount)');
          await Future.delayed(_retryDelay);
        }
      } catch (e, stackTrace) {
        _logger.severe('FCM 토큰 서버 전송 오류 (시도 $attempt): $e');
        _logger.severe('스택 트레이스: $stackTrace');
        _recordError('토큰 전송 실패 (시도 $attempt): $e');

        if (attempt < _maxRetryCount) {
          await Future.delayed(_retryDelay);
        }
      }
    }

    final errorMsg = 'FCM 토큰 서버 전송 최종 실패 (모든 재시도 소진)';
    _logger.severe(errorMsg);
    _recordError(errorMsg);
    return false;
  }

  /// 서버에 FCM 토큰 전송
  Future<bool> _sendTokenToServer(String token) async {
    try {
      _logger.info('서버 토큰 전송 시작');

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _logger.warning('사용자가 로그인되지 않음 - FCM 토큰 전송 건너뜀');
        _recordError('사용자 미로그인');
        return false;
      }

      // 네트워크 연결 확인
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        _logger.warning('네트워크 연결 없음 - FCM 토큰 전송 실패');
        _recordError('네트워크 연결 없음');
        return false;
      }
      _logger.info('네트워크 연결 확인됨: $connectivityResult');

      final idToken = await user.getIdToken();
      _logger.info('Firebase ID 토큰 획득 완료');

      // 백엔드 API 엔드포인트 (Cloud Run) - 통일된 경로
      final apiUrl = dotenv.env['API_BASE_URL'] != null 
          ? '${dotenv.env['API_BASE_URL']}/api/v1/users/fcm-token'
          : 'https://your-api-service.run.app/api/v1/users/fcm-token';

      _logger.info('API 호출 시작: $apiUrl');
      if (kDebugMode) {
        print('🌐 API 호출 상세 정보:');
        print('   URL: $apiUrl');
        print('   Token: ${token.substring(0, 20)}...');
        print('   ID Token: ${idToken?.substring(0, 20) ?? 'null'}...');
      }

      final response = await http
          .post(
            Uri.parse(apiUrl),
            headers: {
              'Authorization': 'Bearer $idToken',
              'Content-Type': 'application/json',
            },
            body: json.encode({
              'fcmToken': token,
              'deviceType': 'android',
            }),
          )
          .timeout(const Duration(seconds: 5));  // 타임아웃 단축

      _logger.info('API 응답 수신: HTTP ${response.statusCode}');
      if (kDebugMode) {
        print('🌐 API 응답 상세 정보:');
        print('   Status Code: ${response.statusCode}');
        print('   Response Body: ${response.body}');
        print('   Response Headers: ${response.headers}');
      }

      if (response.statusCode == 200) {
        _logger.info('FCM 토큰 서버 전송 성공');
        if (kDebugMode) {
          print('✅ FCM 토큰 서버 전송 성공!');
        }
        return true;
      } else {
        final errorMsg =
            'FCM 토큰 서버 전송 실패: HTTP ${response.statusCode}, Body: ${response.body}';
        _logger.warning(errorMsg);
        _recordError(errorMsg);
        if (kDebugMode) {
          print('❌ FCM 토큰 서버 전송 실패: $errorMsg');
        }
        return false;
      }
    } catch (e, stackTrace) {
      final errorMsg = 'FCM 토큰 서버 전송 오류: $e';
      _logger.severe(errorMsg);
      _logger.severe('스택 트레이스: $stackTrace');
      _recordError(errorMsg);
      return false;
    }
  }

  /// 토큰 갱신 처리
  Future<void> _handleTokenRefresh(String newToken) async {
    try {
      _logger.info('=== FCM 토큰 갱신 처리 시작 ===');
      _logger.info('이전 토큰: ${_fcmToken?.substring(0, 20)}...');
      _logger.info('새 토큰: ${newToken.substring(0, 20)}...');

      if (_notificationEnabled) {
        _logger.info('알림이 활성화되어 있어 서버에 새 토큰 전송');
        await _sendTokenToServerWithRetry(newToken);
      } else {
        _logger.info('알림이 비활성화되어 토큰 전송 건너뜀');
      }

      _logger.info('=== FCM 토큰 갱신 처리 완료 ===');
    } catch (e, stackTrace) {
      final errorMsg = '토큰 갱신 처리 실패: $e';
      _logger.severe(errorMsg);
      _logger.severe('스택 트레이스: $stackTrace');
      _recordError(errorMsg);
    }
  }

  /// 토큰 획득 재시도 스케줄링
  void _scheduleTokenRetry() {
    _retryTimer?.cancel();
    _retryCount++;

    if (_retryCount <= _maxRetryCount) {
      _logger.info('FCM 토큰 재시도 스케줄링 ($_retryCount/$_maxRetryCount)');
      _retryTimer = Timer(_retryDelay, () async {
        try {
          await _getFCMToken();
        } catch (e) {
          _logger.severe('FCM 토큰 재시도 실패: $e');
        }
      });
    } else {
      _logger.severe('FCM 토큰 획득 최종 실패 (모든 재시도 소진)');
    }
  }

  /// 네트워크 연결 상태 모니터링
  void _setupConnectivityListener() {
    _connectivity.onConnectivityChanged.listen((ConnectivityResult result) {
      _logger.info('네트워크 연결 상태 변경: $result');

      if (result != ConnectivityResult.none &&
          _fcmToken != null &&
          _notificationEnabled) {
        // 네트워크가 복구되면 토큰 전송 재시도
        _logger.info('네트워크 복구 - FCM 토큰 재전송 시도');
        _sendTokenToServerWithRetry(_fcmToken!);
      }
    });
  }

  /// 포그라운드 메시지 처리
  void _handleForegroundMessage(RemoteMessage message) {
    try {
      _logger.info('포그라운드 메시지 처리: ${message.notification?.title}');

      // 분석 완료 메시지인 경우 로컬 알림 표시
      if (message.data['type'] == 'analysis_complete') {
        final title = message.notification?.title ?? '분석 완료';
        final body = message.notification?.body ?? '음성 분석이 완료되었습니다.';
        final webUrl = message.data['webUrl'];
        
        // 로컬 알림 표시 (포그라운드에서도 보이도록)
        NotificationChannelManager.showAnalysisCompleteNotification(
          title: title,
          body: body,
          payload: webUrl,
        );
        
        _logger.info('포그라운드에서 분석 완료 알림 표시: $title');
      }

      // 콜백이 설정되어 있으면 호출
      if (_onForegroundMessage != null) {
        _onForegroundMessage!(message);
      }

      // 기본 처리
      _handleMessage(message);
    } catch (e) {
      _logger.severe('포그라운드 메시지 처리 실패: $e');
    }
  }

  /// 설정 로드
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _notificationEnabled = prefs.getBool('notification_enabled') ?? true;
      _logger.info('알림 설정 로드: $_notificationEnabled');
    } catch (e) {
      _logger.severe('설정 로드 실패: $e');
      _notificationEnabled = true; // 기본값으로 설정
    }
  }

  /// 설정 저장
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notification_enabled', _notificationEnabled);
      _logger.info('알림 설정 저장: $_notificationEnabled');
    } catch (e) {
      _logger.severe('설정 저장 실패: $e');
    }
  }

  /// 알림 활성화 상태 확인
  Future<bool> isNotificationEnabled() async {
    await _loadSettings();
    return _notificationEnabled;
  }

  /// 알림 활성화/비활성화 설정
  Future<void> setNotificationEnabled(bool enabled) async {
    try {
      _logger.info('=== 알림 설정 변경 시작 ===');
      _logger.info('이전 설정: $_notificationEnabled');
      _logger.info('새 설정: $enabled');

      _notificationEnabled = enabled;
      await _saveSettings();
      _logger.info('설정 저장 완료');

      if (enabled && _fcmToken != null) {
        // 알림이 활성화되면 토큰을 서버에 전송
        _logger.info('알림 활성화 - FCM 토큰 서버 전송 시작');
        await _sendTokenToServerWithRetry(_fcmToken!);
      } else if (enabled && _fcmToken == null) {
        _logger.warning('알림은 활성화되었지만 FCM 토큰이 없음 - 토큰 재획득 시도');
        await _getFCMToken();
      } else {
        _logger.info('알림 비활성화 또는 토큰 없음 - 서버 전송 건너뜀');
      }

      _logger.info('=== 알림 설정 변경 완료 ===');
    } catch (e, stackTrace) {
      final errorMsg = '알림 설정 변경 실패: $e';
      _logger.severe(errorMsg);
      _logger.severe('스택 트레이스: $stackTrace');
      _recordError(errorMsg);
    }
  }

  /// 포그라운드 메시지 콜백 설정
  void setForegroundMessageCallback(Function(RemoteMessage) callback) {
    _onForegroundMessage = callback;
  }

  /// FCM 토큰 가져오기
  String? get fcmToken => _fcmToken;

  /// 초기화 상태 확인
  bool get isInitialized => _isInitialized;

  /// 로그인 후 FCM 토큰을 서버에 수동으로 전송
  Future<bool> sendTokenToServer() async {
    if (_fcmToken == null) {
      _logger.warning('FCM 토큰이 없습니다');
      return false;
    }

    _logger.info('수동 FCM 토큰 서버 전송 시작');
    return await _sendTokenToServerWithRetry(_fcmToken!);
  }

  /// 서비스 해제
  Future<void> dispose() async {
    try {
      _logger.info('MessagingService 해제 시작');
      _retryTimer?.cancel();
      _isInitialized = false;
      _logger.info('MessagingService 해제 완료');
    } catch (e) {
      _logger.severe('MessagingService 해제 실패: $e');
    }
  }

  /// 시스템 정보 로깅
  void _logSystemInfo() {
    try {
      _logger.info('=== MessagingService 시스템 정보 ===');
      _logger.info('초기화 시간: ${DateTime.now()}');
      _logger.info('총 오류 횟수: $_totalErrorCount');
      _logger.info('마지막 토큰 업데이트: $_lastTokenUpdate');
      _logger.info('마지막 오류: $_lastError');
      _logger.info('=====================================');
    } catch (e) {
      _logger.warning('시스템 정보 로깅 실패: $e');
    }
  }

  /// 오류 기록
  void _recordError(String error) {
    try {
      _totalErrorCount++;
      _lastError = error;
      _logger.warning('오류 기록 - 총 $_totalErrorCount회: $error');
    } catch (e) {
      _logger.severe('오류 기록 실패: $e');
    }
  }

  /// 토큰 업데이트 기록
  void _recordTokenUpdate() {
    try {
      _lastTokenUpdate = DateTime.now();
      _logger.info('토큰 업데이트 기록: $_lastTokenUpdate');
    } catch (e) {
      _logger.warning('토큰 업데이트 기록 실패: $e');
    }
  }

  /// 서비스 상태 정보 가져오기
  Map<String, dynamic> getServiceStatus() {
    return {
      'isInitialized': _isInitialized,
      'hasToken': _fcmToken != null,
      'notificationEnabled': _notificationEnabled,
      'totalErrorCount': _totalErrorCount,
      'lastError': _lastError,
      'lastTokenUpdate': _lastTokenUpdate?.toIso8601String(),
      'retryCount': _retryCount,
    };
  }

  /// FCM 토큰 직접 테스트 및 서버 전송
  Future<void> testFCMTokenDirectly() async {
    try {
      _logger.info('🔍 === FCM 토큰 직접 테스트 시작 ===');
      if (kDebugMode) {
        print('🔍 === FCM 토큰 직접 테스트 시작 ===');
      }

      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        _logger.info('✅ FCM 토큰 직접 획득 성공!');
        _logger.info('📏 토큰 길이: ${token.length}');
        _logger.info('🔑 토큰 앞 20자: ${token.substring(0, 20)}...');
        if (kDebugMode) {
          print('✅ FCM 토큰 직접 획득 성공!');
          print('📏 토큰 길이: ${token.length}');
          print('🔑 토큰 앞 20자: ${token.substring(0, 20)}...');
          print('🔑 토큰 전체: $token');
        }

        // 토큰을 서버에 즉시 전송
        _logger.info('🚀 토큰을 서버에 즉시 전송 시도...');
        if (kDebugMode) {
          print('🚀 토큰을 서버에 즉시 전송 시도...');
        }

        final success = await _sendTokenToServerWithRetry(token);
        if (success) {
          _logger.info('✅ 토큰 서버 전송 성공!');
          if (kDebugMode) {
            print('✅ 토큰 서버 전송 성공!');
          }
        } else {
          _logger.warning('❌ 토큰 서버 전송 실패');
          if (kDebugMode) {
            print('❌ 토큰 서버 전송 실패');
          }
        }
      } else {
        _logger.warning('❌ FCM 토큰 직접 획득 실패');
        if (kDebugMode) {
          print('❌ FCM 토큰 직접 획득 실패');
        }
      }
    } catch (e) {
      _logger.severe('❌ FCM 토큰 직접 테스트 오류: $e');
      if (kDebugMode) {
        print('❌ FCM 토큰 직접 테스트 오류: $e');
      }
    }
  }
}
