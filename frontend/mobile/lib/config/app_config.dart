/// Flutter 앱 설정 로더 (Universal Configuration System)
/// project.config.json에서 설정을 읽어와 환경변수와 병합
library;

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;

class ProjectConfig {
  final ProjectInfo project;
  final FirebaseInfo firebase;
  final ServicesInfo services;
  final SecurityInfo? security;

  ProjectConfig({
    required this.project,
    required this.firebase,
    required this.services,
    this.security,
  });

  factory ProjectConfig.fromJson(Map<String, dynamic> json) {
    return ProjectConfig(
      project: ProjectInfo.fromJson(json['project'] ?? {}),
      firebase: FirebaseInfo.fromJson(json['firebase'] ?? {}),
      services: ServicesInfo.fromJson(json['services'] ?? {}),
      security: json['security'] != null
          ? SecurityInfo.fromJson(json['security'])
          : null,
    );
  }
}

class ProjectInfo {
  final String id;
  final String name;
  final String region;
  final String location;

  ProjectInfo({
    required this.id,
    required this.name,
    required this.region,
    required this.location,
  });

  factory ProjectInfo.fromJson(Map<String, dynamic> json) {
    return ProjectInfo(
      id: json['id'] ?? 'your-project-id',
      name: json['name'] ?? 'Your Project Name',
      region: json['region'] ?? 'asia-northeast3',
      location: json['location'] ?? 'asia-northeast3',
    );
  }
}

class FirebaseInfo {
  final String projectId;
  final String storageBucket;
  final String messagingSenderId;
  final String? appId;
  final String? apiKey;

  FirebaseInfo({
    required this.projectId,
    required this.storageBucket,
    required this.messagingSenderId,
    this.appId,
    this.apiKey,
  });

  factory FirebaseInfo.fromJson(Map<String, dynamic> json) {
    return FirebaseInfo(
      projectId: json['projectId'] ?? 'your-project-id',
      storageBucket: json['storageBucket'] ?? 'your-project-id.firebasestorage.app',
      messagingSenderId: json['messagingSenderId'] ?? 'your-messaging-sender-id',
      appId: json['appId'],
      apiKey: json['apiKey'],
    );
  }
}

class ServicesInfo {
  final ServiceInfo aiService;
  final ServiceInfo apiService;
  final ServiceInfo? webApp;

  ServicesInfo({
    required this.aiService,
    required this.apiService,
    this.webApp,
  });

  factory ServicesInfo.fromJson(Map<String, dynamic> json) {
    return ServicesInfo(
      aiService: ServiceInfo.fromJson(json['aiService'] ?? {}),
      apiService: ServiceInfo.fromJson(json['apiService'] ?? {}),
      webApp: json['webApp'] != null
          ? ServiceInfo.fromJson(json['webApp'])
          : null,
    );
  }
}

class ServiceInfo {
  final String name;
  final String url;

  ServiceInfo({
    required this.name,
    required this.url,
  });

  factory ServiceInfo.fromJson(Map<String, dynamic> json) {
    return ServiceInfo(
      name: json['name'] ?? '',
      url: json['url'] ?? '',
    );
  }
}

class SecurityInfo {
  final List<String> corsOrigins;
  final List<String> allowedDomains;

  SecurityInfo({
    required this.corsOrigins,
    required this.allowedDomains,
  });

  factory SecurityInfo.fromJson(Map<String, dynamic> json) {
    return SecurityInfo(
      corsOrigins: List<String>.from(json['corsOrigins'] ?? []),
      allowedDomains: List<String>.from(json['allowedDomains'] ?? []),
    );
  }
}

class AppConfig {
  static ProjectConfig? _cachedConfig;

  // 기본 설정 (fallback) - 환경변수로 덮어써야 합니다!
  // ⚠️ 경고: 이 기본값은 플레이스홀더입니다. 실제 프로젝트 설정은 project.config.json 또는 환경변수로 제공해야 합니다.
  static final ProjectConfig _defaultConfig = ProjectConfig(
    project: ProjectInfo(
      id: 'your-project-id',
      name: 'Your Project Name',
      region: 'asia-northeast3',
      location: 'asia-northeast3',
    ),
    firebase: FirebaseInfo(
      projectId: 'your-project-id',
      storageBucket: 'your-project-id.firebasestorage.app',
      messagingSenderId: 'your-messaging-sender-id',
      appId: 'your-firebase-app-id',
      apiKey: 'your-firebase-api-key',
    ),
    services: ServicesInfo(
      aiService: ServiceInfo(
        name: 'your-ai-service',
        url: 'https://your-ai-service.run.app',
      ),
      apiService: ServiceInfo(
        name: 'your-api-service',
        url: 'https://your-api-service.run.app',
      ),
      webApp: ServiceInfo(
        name: 'your-web-app',
        url: 'https://your-app.vercel.app',
      ),
    ),
    security: SecurityInfo(
      corsOrigins: [
        'http://localhost:3000',
        'http://localhost:3001',
      ],
      allowedDomains: [
        'localhost',
      ],
    ),
  );

  /// 프로젝트 설정 파일 로드
  static Future<ProjectConfig?> _loadProjectConfigFile() async {
    try {
      // assets에서 설정 파일 로드 시도
      try {
        final String configString = await rootBundle.loadString('assets/config/project.config.json');
        final Map<String, dynamic> configJson = jsonDecode(configString);
        if (kDebugMode) {
          print('✅ Flutter 프로젝트 설정 로드 성공: assets/config/project.config.json');
        }
        return ProjectConfig.fromJson(configJson);
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ Flutter assets 설정 파일 없음: assets/config/project.config.json');
        }
      }

      // 프로젝트 루트에서 설정 파일 로드 시도 (개발 환경용)
      if (kDebugMode && !kIsWeb) {
        try {
          final Directory current = Directory.current;
          String projectRoot = current.path;

          // Flutter 프로젝트에서 프로젝트 루트 찾기
          for (int i = 0; i < 5; i++) {
            final File configFile = File(path.join(projectRoot, 'project.config.json'));
            if (await configFile.exists()) {
              final String configContent = await configFile.readAsString();
              final Map<String, dynamic> configJson = jsonDecode(configContent);
              if (kDebugMode) {
                print('✅ 프로젝트 설정 로드 성공: ${configFile.path}');
              }
              return ProjectConfig.fromJson(configJson);
            }

            // 상위 디렉토리로 이동
            final String parentDir = path.dirname(projectRoot);
            if (parentDir == projectRoot) break;
            projectRoot = parentDir;
          }
        } catch (e) {
          if (kDebugMode) {
            print('⚠️ 프로젝트 루트 설정 파일 로드 실패: $e');
          }
        }
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        print('❌ 프로젝트 설정 파일 로드 실패: $e');
      }
      return null;
    }
  }

  /// 환경변수로 설정 덮어쓰기 (Flutter에서는 제한적)
  static ProjectConfig _applyEnvironmentOverrides(ProjectConfig config) {
    // Flutter에서는 환경변수 접근이 제한적이므로
    // 주로 컴파일 타임 환경변수나 flavor 설정을 사용

    // 예: Flutter flavor나 build 설정에서 전달된 값들
    // const String apiUrl = String.fromEnvironment('API_URL', defaultValue: '');
    // if (apiUrl.isNotEmpty) {
    //   config = ProjectConfig(...);  // 덮어쓰기
    // }

    return config;
  }

  /// 설정 로드 (캐시 포함)
  static Future<ProjectConfig> getConfig({bool forceReload = false}) async {
    if (_cachedConfig != null && !forceReload) {
      return _cachedConfig!;
    }

    // 1. 기본 설정으로 시작
    ProjectConfig config = _defaultConfig;

    // 2. 프로젝트 설정 파일로 덮어쓰기
    final ProjectConfig? fileConfig = await _loadProjectConfigFile();
    if (fileConfig != null) {
      config = fileConfig;
    }

    // 3. 환경변수로 최종 덮어쓰기
    config = _applyEnvironmentOverrides(config);

    _cachedConfig = config;

    if (kDebugMode) {
      print('🔧 Flutter 앱 설정 로드 완료');
      debugConfig();
    }

    return config;
  }

  /// 편의 함수들
  static Future<String> getProjectId() async {
    final config = await getConfig();
    return config.project.id;
  }

  static Future<String> getProjectRegion() async {
    final config = await getConfig();
    return config.project.region;
  }

  static Future<FirebaseInfo> getFirebaseConfig() async {
    final config = await getConfig();
    return config.firebase;
  }

  static Future<String> getApiServiceUrl() async {
    final config = await getConfig();
    return config.services.apiService.url;
  }

  static Future<String> getAiServiceUrl() async {
    final config = await getConfig();
    return config.services.aiService.url;
  }

  static Future<String> getWebAppUrl() async {
    final config = await getConfig();
    return config.services.webApp?.url ?? 'https://your-app.vercel.app';
  }

  /// 설정 다시 로드
  static Future<ProjectConfig> reloadConfig() async {
    _cachedConfig = null;
    return await getConfig(forceReload: true);
  }

  /// 개발 환경에서 설정 출력
  static Future<void> debugConfig() async {
    if (kDebugMode) {
      final config = await getConfig();
      print('🔧 Flutter 앱 설정:');
      print('  프로젝트 ID: ${config.project.id}');
      print('  Firebase 프로젝트: ${config.firebase.projectId}');
      print('  API URL: ${config.services.apiService.url}');
      print('  AI 서비스 URL: ${config.services.aiService.url}');
      print('  웹 앱 URL: ${await getWebAppUrl()}');
    }
  }

  /// 설정 검증
  static Future<bool> validateConfig() async {
    try {
      final config = await getConfig();

      // 필수 필드 확인
      if (config.project.id.isEmpty ||
          config.firebase.projectId.isEmpty ||
          config.services.apiService.url.isEmpty) {
        if (kDebugMode) {
          print('❌ Flutter 앱 설정 검증 실패: 필수 필드 누락');
        }
        return false;
      }

      if (kDebugMode) {
        print('✅ Flutter 앱 설정 검증 성공');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Flutter 앱 설정 검증 실패: $e');
      }
      return false;
    }
  }
}