# 🚀 모바일 앱 빌드 가이드

## 빠른 시작

### 1. Flutter 설치 확인
```powershell
flutter --version
```

없다면: https://docs.flutter.dev/get-started/install/windows

### 2. 프로젝트 디렉토리로 이동
```powershell
cd C:\senior_mhealth_lecture\frontend\mobile
```

### 3. 의존성 설치
```powershell
flutter pub get
```

### 4. Android 기기 연결 확인
```powershell
flutter devices
```

### 5. 앱 실행 (디버그 모드)
```powershell
flutter run
```

### 6. APK 빌드 (릴리즈)
```powershell
flutter build apk --release
```

빌드된 APK 위치:
```
build/app/outputs/flutter-apk/app-release.apk
```

## 🔧 문제 해결

### Flutter 명령어를 찾을 수 없음
```powershell
# Flutter SDK 설치 필요
# https://docs.flutter.dev/get-started/install/windows
```

### Gradle 빌드 실패
```powershell
cd android
.\gradlew clean
cd ..
flutter clean
flutter pub get
flutter build apk
```

### 기기를 찾을 수 없음
```powershell
# USB 디버깅 활성화 필요
# Android 설정 > 개발자 옵션 > USB 디버깅

adb devices
```

## 📱 APK 설치

```powershell
# USB로 연결된 기기에 설치
adb install build/app/outputs/flutter-apk/app-release.apk

# 또는 파일 직접 전송
# APK 파일을 휴대폰으로 전송 후 설치
```

## ✅ 모든 설정 완료!

Firebase, Android 앱, 설정 파일 모두 준비되었습니다.
Flutter만 설치하면 바로 빌드 가능합니다! 🎉
