# 🚀 Universal Mobile App Setup Guide

이 가이드는 다른 프로젝트에서 이 모바일 앱을 사용하기 위한 설정 방법을 설명합니다.

## 📋 사전 준비

1. **Flutter SDK** (3.0 이상)
2. **Android Studio** 또는 **VS Code** (Flutter 확장 프로그램 포함)
3. **Firebase 프로젝트** 생성 완료
4. **백엔드 API 서비스** 배포 완료

## 🔧 1단계: 프로젝트 설정

### 1-1. 패키지명 변경

`android/app/build.gradle` 파일에서 패키지명을 변경하세요:

```gradle
android {
    namespace = "com.yourcompany.yourapp"  // 여기를 변경
    // ...
    defaultConfig {
        applicationId = "com.yourcompany.yourapp"  // 여기를 변경
    }
}
```

### 1-2. 앱 이름 변경

`pubspec.yaml` 파일에서 앱 정보를 변경하세요:

```yaml
name: your_app_name  # 패키지명도 함께 변경
description: "Your Project Name - Mobile Application"
```

## 🔥 2단계: Firebase 설정

### 2-1. Firebase 프로젝트 연결

```bash
# FlutterFire CLI 설치
dart pub global activate flutterfire_cli

# Firebase 프로젝트 연결
flutterfire configure --project=your-project-id --platforms=android,ios
```

### 2-2. 환경 변수 설정

`.env` 파일을 생성하고 다음 내용을 입력하세요:

```bash
# Firebase 설정
FIREBASE_API_KEY=your_firebase_api_key
FIREBASE_AUTH_DOMAIN=your-project-id.firebaseapp.com
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_STORAGE_BUCKET=your-project-id.firebasestorage.app
FIREBASE_MESSAGING_SENDER_ID=your_messaging_sender_id
FIREBASE_APP_ID=your_firebase_app_id

# API URLs
API_BASE_URL=https://your-api-service.run.app
AI_SERVICE_URL=https://your-ai-service.run.app
API_SERVICE_URL=https://your-api-service.run.app

# 환경 설정
ENVIRONMENT=production
DEBUG_MODE=false
```

## 🏗️ 3단계: 앱 빌드

### 3-1. 의존성 설치

```bash
flutter pub get
```

### 3-2. APK 빌드

```bash
# 디버그 빌드
flutter build apk --debug

# 릴리즈 빌드
flutter build apk --release
```

## 📱 4단계: 기기 설치

### 4-1. Android 기기 연결

```bash
# USB 연결
adb devices

# 무선 연결 (선택사항)
adb tcpip 5555
adb connect YOUR_DEVICE_IP:5555
```

### 4-2. APK 설치

```bash
adb install build/app/outputs/flutter-apk/app-release.apk
```

## 🔧 고급 설정

### 프로젝트 설정 파일 (선택사항)

`project.config.json` 파일을 생성하여 더 세밀한 설정을 할 수 있습니다:

```json
{
  "project": {
    "id": "your-project-id",
    "name": "Your Project Name",
    "region": "asia-northeast3",
    "location": "asia-northeast3"
  },
  "firebase": {
    "projectId": "your-project-id",
    "storageBucket": "your-project-id.firebasestorage.app",
    "messagingSenderId": "your-messaging-sender-id",
    "appId": "your-firebase-app-id",
    "apiKey": "your-firebase-api-key"
  },
  "services": {
    "aiService": {
      "name": "your-ai-service",
      "url": "https://your-ai-service.run.app"
    },
    "apiService": {
      "name": "your-api-service", 
      "url": "https://your-api-service.run.app"
    },
    "webApp": {
      "name": "your-web-app",
      "url": "https://your-app.vercel.app"
    }
  }
}
```

## 🚨 주의사항

1. **패키지명 중복**: Google Play Store에 업로드할 때는 고유한 패키지명을 사용해야 합니다.
2. **Firebase 설정**: `google-services.json` 파일이 올바르게 생성되었는지 확인하세요.
3. **API URL**: 백엔드 서비스가 정상적으로 배포되어 있는지 확인하세요.
4. **권한 설정**: Android 권한이 올바르게 설정되어 있는지 확인하세요.

## 🔍 문제 해결

### 빌드 실패
```bash
flutter clean
flutter pub get
flutter build apk --release
```

### Firebase 연결 실패
```bash
flutterfire configure --project=your-project-id
```

### APK 설치 실패
```bash
adb uninstall com.yourcompany.yourapp
adb install app-release.apk
```

## 📚 추가 자료

- [Flutter 공식 문서](https://docs.flutter.dev)
- [Firebase Flutter 설정](https://firebase.google.com/docs/flutter/setup)
- [Android 앱 서명](https://developer.android.com/studio/publish/app-signing)

---

**🎉 설정이 완료되면 이제 다른 프로젝트에서도 이 모바일 앱을 사용할 수 있습니다!**
