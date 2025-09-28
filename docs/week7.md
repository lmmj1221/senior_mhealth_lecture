# Week 7: Mobile 앱 빌드 및 배포

## 🎯 학습 목표
- Flutter 프로젝트 구조 이해
- Android APK 빌드 프로세스 학습
- 디버그 및 릴리즈 빌드 차이 이해
- APK 파일 기기 설치 방법 습득
- 앱 서명 및 보안 설정

## 📋 사전 준비
- [ ] Flutter SDK 설치 (3.0 이상)
- [ ] Android Studio 또는 VS Code 설치
- [ ] Android SDK 설치
- [ ] Android 기기 또는 에뮬레이터
- [ ] Week 3-6 백엔드 서비스 준비

---

## 📱 Flutter 프로젝트 이해

### Flutter란?
**Google의 크로스 플랫폼 모바일 프레임워크**로 하나의 코드베이스로 Android와 iOS 앱을 동시 개발할 수 있습니다.

### 프로젝트 구조
```
frontend/mobile/
├── android/           # Android 플랫폼 설정
├── ios/              # iOS 플랫폼 설정
├── lib/              # Dart 소스 코드
│   ├── main.dart     # 앱 진입점
│   ├── screens/      # 화면 컴포넌트
│   ├── widgets/      # 재사용 위젯
│   └── services/     # API 서비스
├── pubspec.yaml      # 의존성 관리
└── .env              # 환경 변수
```

### 빌드 타입
1. **Debug 빌드**: 개발용, 디버깅 가능, 최적화 안됨
2. **Profile 빌드**: 성능 분석용
3. **Release 빌드**: 배포용, 최적화됨, 디버깅 불가

---

## Step 1: Flutter 환경 설정

### 1-1. Flutter SDK 설치 확인 🤖

```bash
# Flutter 버전 확인
flutter --version

# 예상 출력:
# Flutter 3.x.x • channel stable
# Dart 3.x.x
# DevTools 2.x.x

# Flutter 설치 상태 진단
flutter doctor

# 모든 항목이 체크되어야 함:
# [✓] Flutter
# [✓] Android toolchain
# [✓] Chrome (웹 개발용)
# [✓] VS Code 또는 Android Studio
# [✓] Connected device
```

### 1-2. 프로젝트 의존성 설치 🤖

```bash
# Mobile 디렉토리로 이동
cd frontend/mobile

# 의존성 설치
flutter pub get

# 설치 확인
flutter pub deps
```

### 1-3. 환경 변수 설정 👤

`.env` 파일 생성:

```bash
# Firebase 설정 (Week 3에서 생성)
FIREBASE_API_KEY=your_firebase_api_key_here
FIREBASE_AUTH_DOMAIN=your_project_id.firebaseapp.com
FIREBASE_PROJECT_ID=your_project_id
FIREBASE_STORAGE_BUCKET=your_project_id.firebasestorage.app
FIREBASE_MESSAGING_SENDER_ID=your_sender_id
FIREBASE_APP_ID=your_app_id

# API URLs (Week 4, 5에서 배포)
API_BASE_URL=https://asia-northeast3-your-project-id.cloudfunctions.net/api
AI_SERVICE_URL=https://your-ai-service-xxxxx-an.a.run.app
API_SERVICE_URL=https://your-api-service-xxxxx-an.a.run.app

# 환경 설정
ENVIRONMENT=production
DEBUG_MODE=false
```

---

## Step 2: Firebase 설정

### 2-1. Firebase 프로젝트 연결 🤖

```bash
# FlutterFire CLI 설치 (이미 있으면 건너뛰기)
dart pub global activate flutterfire_cli

# Firebase 프로젝트 구성
flutterfire configure \
  --project=your-project-id \
  --platforms=android,ios

# 자동으로 생성되는 파일들:
# - android/app/google-services.json
# - ios/Runner/GoogleService-Info.plist
# - lib/firebase_options.dart
```

### 2-2. google-services.json 확인 👤

`android/app/google-services.json` 파일이 생성되었는지 확인:

```json
{
  "project_info": {
    "project_number": "your-project-number",
    "project_id": "your-project-id",
    "storage_bucket": "your-project-id.firebasestorage.app"
  },
  "client": [
    {
      "client_info": {
        "mobilesdk_app_id": "1:your-project-number:android:xxxxx",
        "android_client_info": {
          "package_name": "com.example.senior_mhealth_mobile"
        }
      }
    }
  ]
}
```

### 2-3. Android 설정 확인 🤖

`android/app/build.gradle` 확인:

```gradle
android {
    compileSdkVersion 34

    defaultConfig {
        applicationId "com.example.senior_mhealth_mobile"
        minSdkVersion 21
        targetSdkVersion 34
        versionCode 1
        versionName "1.0.0"
        multiDexEnabled true
    }
}

dependencies {
    implementation platform('com.google.firebase:firebase-bom:32.0.0')
    implementation 'com.google.firebase:firebase-analytics'
}

// 맨 아래 추가
apply plugin: 'com.google.gms.google-services'
```

---

## Step 3: 앱 빌드

### 3-1. 디버그 APK 빌드 (테스트용) 🤖

```bash
# 디버그 빌드 (빠른 테스트용)
flutter build apk --debug

# 빌드 출력 위치:
# build/app/outputs/flutter-apk/app-debug.apk

# 파일 크기: 약 50-70MB
# 특징: 디버깅 가능, 최적화 안됨
```

### 3-2. 릴리즈 APK 빌드 (배포용) 🤖

#### Windows 사용자 (rebuild_clean.bat 사용):

```bash
# Windows PowerShell 또는 CMD
cd frontend/mobile

# 빌드 스크립트 실행
.\rebuild_clean.bat

# 또는 수동으로:
flutter clean
flutter pub get
flutter build apk --release
```

#### Mac/Linux 사용자:

```bash
#!/bin/bash
# rebuild_clean.sh 생성

echo "🧹 Flutter 클린 빌드 시작"

# 1. 캐시 삭제
flutter clean
rm -rf build/
rm -rf .dart_tool/
rm -rf .flutter-plugins*

# 2. Gradle 캐시 삭제
cd android
./gradlew clean
cd ..

# 3. 의존성 재설치
flutter pub get

# 4. 릴리즈 빌드
flutter build apk --release

echo "✅ 빌드 완료!"
echo "📱 APK 위치: build/app/outputs/flutter-apk/app-release.apk"
```

실행:

```bash
chmod +x rebuild_clean.sh
./rebuild_clean.sh
```

### 3-3. 빌드 옵션 설명 🤖

```bash
# 기본 릴리즈 빌드
flutter build apk --release

# 분할 APK 빌드 (크기 최적화)
flutter build apk --split-per-abi

# 생성되는 파일들:
# - app-armeabi-v7a-release.apk (32비트 ARM)
# - app-arm64-v8a-release.apk (64비트 ARM)
# - app-x86_64-release.apk (x86 64비트)

# App Bundle 빌드 (Google Play 업로드용)
flutter build appbundle --release
# 출력: build/app/outputs/bundle/release/app-release.aab
```

### 3-4. 빌드 성공 확인 🤖

```bash
# APK 파일 확인
ls -la build/app/outputs/flutter-apk/

# 예상 출력:
# app-release.apk (15-25MB)
# app-debug.apk (50-70MB, 디버그 빌드한 경우)

# APK 정보 확인
aapt dump badging build/app/outputs/flutter-apk/app-release.apk | head -10
```

---

## Step 4: APK 서명 (선택사항)

### 4-1. 키스토어 생성 👤

**프로덕션 배포를 위해 필요합니다:**

```bash
# 키스토어 생성 (한 번만)
keytool -genkey -v -keystore ~/senior-mhealth.keystore \
  -alias senior-mhealth \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000

# 입력 정보:
# 키스토어 비밀번호: (안전한 비밀번호 입력)
# 이름: Your Name
# 조직 단위: Development
# 조직: Senior MHealth
# 도시: Seoul
# 시/도: Seoul
# 국가 코드: KR
```

### 4-2. 서명 설정 🤖

`android/key.properties` 파일 생성:

```properties
storePassword=your-store-password
keyPassword=your-key-password
keyAlias=senior-mhealth
storeFile=/Users/username/senior-mhealth.keystore
```

`android/app/build.gradle` 수정:

```gradle
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
        }
    }
}
```

---

## Step 5: APK 기기 설치

### 5-1. ADB를 통한 설치 (개발자용) 🤖

```bash
# Android 기기 USB 디버깅 활성화
# 설정 → 개발자 옵션 → USB 디버깅 ON

# 연결된 기기 확인
adb devices

# 예상 출력:
# List of devices attached
# ABC123DEF456    device

# APK 설치
adb install build/app/outputs/flutter-apk/app-release.apk

# 기존 앱이 있으면 덮어쓰기
adb install -r build/app/outputs/flutter-apk/app-release.apk

# 설치 확인
adb shell pm list packages | grep senior_mhealth
```

### 5-2. 직접 설치 (일반 사용자용) 👤

#### 방법 1: USB 케이블 전송

1. **APK 파일을 휴대폰으로 복사**:
   - USB 케이블로 연결
   - 파일 전송 모드 선택
   - `app-release.apk`를 Downloads 폴더로 복사

2. **기기에서 설치**:
   - 파일 관리자 앱 실행
   - Downloads 폴더로 이동
   - `app-release.apk` 탭
   - "설치" 버튼 클릭
   - 출처를 알 수 없는 앱 허용 (첫 설치 시)

#### 방법 2: 클라우드 전송

```bash
# Google Drive 업로드
# 1. APK를 Google Drive에 업로드
# 2. 휴대폰에서 Google Drive 앱 실행
# 3. APK 다운로드 및 설치

# 이메일 전송 (25MB 이하)
# 1. APK를 이메일 첨부
# 2. 휴대폰에서 이메일 확인
# 3. 첨부 파일 다운로드 및 설치
```

#### 방법 3: QR 코드 사용

```bash
# 1. APK를 웹 서버에 업로드
# 2. QR 코드 생성 (https://qr-code-generator.com)
# 3. 휴대폰으로 QR 스캔
# 4. 다운로드 및 설치
```

### 5-3. 설치 전 기기 설정 👤

**Android 기기 설정**:

1. **출처를 알 수 없는 앱 허용**:
   - 설정 → 보안 → "출처를 알 수 없는 앱" 허용
   - 또는 설치 시 팝업에서 "설정" → 허용

2. **Play 프로텍트 임시 비활성화** (선택사항):
   - Google Play → 메뉴 → Play 프로텍트
   - "기기 보안 위협 검색" 비활성화
   - 설치 후 다시 활성화 권장

---

## Step 6: 앱 실행 및 테스트

### 6-1. 첫 실행 확인 👤

1. **앱 아이콘 확인**:
   - 앱 서랍에서 "Senior MHealth" 찾기
   - 홈 화면에 바로가기 추가

2. **권한 요청 수락**:
   - 인터넷 접근
   - 저장소 접근
   - 알림 권한
   - 위치 권한 (필요시)

3. **Firebase 연결 테스트**:
   - 로그인/회원가입 테스트
   - 데이터 동기화 확인

### 6-2. 로그 확인 (디버깅) 🤖

```bash
# 실시간 로그 보기
adb logcat | grep flutter

# 특정 태그만 필터링
adb logcat -s flutter

# 로그 파일로 저장
adb logcat > app_logs.txt

# 앱 충돌 시 스택 트레이스 확인
adb logcat *:E
```

### 6-3. 성능 모니터링 🤖

```bash
# Flutter DevTools 실행
flutter pub global activate devtools
flutter pub global run devtools

# 프로파일 모드로 실행
flutter run --profile

# 성능 오버레이 표시
# main.dart에 추가:
# MaterialApp(
#   showPerformanceOverlay: true,
#   ...
# )
```

---

## Step 7: 배포 준비

### 7-1. 앱 최적화 🤖

```dart
// main.dart 최적화 예시
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase 초기화
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 에러 핸들링
  FlutterError.onError = (details) {
    FirebaseCrashlytics.instance.recordFlutterError(details);
  };

  runApp(MyApp());
}
```

### 7-2. 버전 관리 🤖

`pubspec.yaml` 버전 업데이트:

```yaml
version: 1.0.1+2
# 형식: major.minor.patch+build
# 1.0.1 = 사용자에게 보이는 버전
# +2 = 빌드 번호 (내부 관리용)
```

### 7-3. Play Store 준비 (선택사항) 👤

**Google Play Console 업로드 준비**:

1. **App Bundle 생성**:
   ```bash
   flutter build appbundle --release
   ```

2. **스크린샷 준비**:
   - 휴대폰: 최소 2장
   - 태블릿: 최소 2장 (선택)
   - 각 1024x500 ~ 3840x2160

3. **앱 정보 준비**:
   - 앱 이름: Senior MHealth
   - 간단한 설명 (80자)
   - 자세한 설명 (4000자)
   - 카테고리: 건강 및 피트니스
   - 콘텐츠 등급: 전체 이용가

---

## 🔧 트러블슈팅

### 빌드 관련 문제

#### 1. Gradle 빌드 실패

```bash
# "Could not resolve all dependencies"
# 해결: Gradle 캐시 삭제
cd android
./gradlew clean
./gradlew build --refresh-dependencies

# "Minimum SDK version" 에러
# 해결: android/app/build.gradle에서
# minSdkVersion 21 이상으로 설정
```

#### 2. 메모리 부족

```bash
# "Out of memory" 에러
# 해결: android/gradle.properties에 추가
org.gradle.jvmargs=-Xmx4096m -XX:MaxPermSize=512m
```

#### 3. Multidex 에러

```gradle
// android/app/build.gradle
android {
    defaultConfig {
        multiDexEnabled true
    }
}

dependencies {
    implementation 'androidx.multidex:multidex:2.0.1'
}
```

### 설치 관련 문제

#### 1. "앱이 설치되지 않음"

```bash
# 원인: 서명 충돌
# 해결: 기존 앱 삭제 후 재설치
adb uninstall com.example.senior_mhealth_mobile
adb install app-release.apk

# 또는 기기에서 직접 삭제
# 설정 → 앱 → Senior MHealth → 제거
```

#### 2. "파일을 열 수 없음"

```bash
# 원인: APK 파일 손상
# 해결: 다시 빌드
flutter clean
flutter build apk --release

# 파일 무결성 확인
md5sum app-release.apk
```

#### 3. 권한 거부

```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
<uses-permission android:name="android.permission.WAKE_LOCK"/>
```

### 런타임 문제

#### 1. Firebase 연결 실패

```dart
// 해결: Firebase 초기화 확인
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
    print("Firebase initialized successfully");
  } catch (e) {
    print("Firebase initialization error: $e");
  }

  runApp(MyApp());
}
```

#### 2. API 호출 실패

```dart
// 해결: 네트워크 권한 및 URL 확인
// .env 파일 확인
// API_BASE_URL이 올바른지 확인
// HTTPS 사용 확인
```

---

## ✅ 완료 체크리스트

### 환경 설정
- [ ] Flutter SDK 설치 및 설정
- [ ] Firebase 프로젝트 연결
- [ ] google-services.json 구성
- [ ] 환경 변수 설정

### 빌드
- [ ] 디버그 APK 빌드 테스트
- [ ] 릴리즈 APK 빌드 성공
- [ ] APK 파일 생성 확인
- [ ] 파일 크기 최적화 (25MB 이하)

### 설치 및 테스트
- [ ] APK 기기 설치 성공
- [ ] 앱 정상 실행 확인
- [ ] Firebase 연결 테스트
- [ ] API 통신 확인

### 배포 준비
- [ ] 앱 서명 설정 (선택)
- [ ] 버전 정보 업데이트
- [ ] 최종 테스트 완료

---

## 💡 핵심 개념 정리

### APK vs App Bundle
```
APK:                       App Bundle:
모든 리소스 포함           동적 리소스 전달
즉시 설치 가능            Play Store 필요
크기가 큼                  크기 최적화
직접 배포 가능            스토어 전용
```

### 빌드 모드 비교
```
Debug:          Profile:        Release:
개발용          성능분석용       배포용
느림            중간            빠름
50-70MB         30-40MB         15-25MB
Hot Reload ✓    Hot Reload ✓    Hot Reload ✗
디버깅 ✓        디버깅 ✗        디버깅 ✗
```

### 배포 채널
1. **직접 배포**: APK 파일 전달
2. **Play Store**: Google Play Console
3. **기업 배포**: MDM 솔루션
4. **베타 테스트**: Firebase App Distribution

---

## 💰 비용 관리

### 무료 배포 옵션
- APK 직접 배포: 무료
- Firebase App Distribution: 무료
- GitHub Releases: 무료

### 유료 옵션
- Google Play Store: $25 (일회성)
- Apple App Store: $99/년
- 기업 배포: MDM 솔루션별 상이

---

## 🎯 학습 성과

이번 주차를 통해 완성한 내용:

1. **Flutter 앱 빌드**: 디버그/릴리즈 APK 생성
2. **Firebase 통합**: 백엔드 서비스 연결
3. **APK 배포**: 다양한 설치 방법 습득
4. **앱 최적화**: 크기 및 성능 최적화

---

## 📚 다음 주차 예고

**Week 8: 통합 테스트 및 최적화**
- 전체 시스템 통합 테스트
- 성능 모니터링 설정
- 사용자 피드백 수집
- 프로덕션 운영 준비

---

## 🔗 참고 자료

### 공식 문서
- [Flutter Build Documentation](https://docs.flutter.dev/deployment/android)
- [Firebase Flutter Setup](https://firebase.google.com/docs/flutter/setup)
- [Android App Bundle](https://developer.android.com/guide/app-bundle)
- [Google Play Console](https://play.google.com/console)

### 추가 학습 자료
- [Flutter 성능 최적화](https://docs.flutter.dev/perf)
- [APK 크기 줄이기](https://docs.flutter.dev/perf/app-size)
- [Flutter DevTools](https://docs.flutter.dev/development/tools/devtools)
- [배포 체크리스트](https://docs.flutter.dev/deployment/android#review-the-app-manifest)