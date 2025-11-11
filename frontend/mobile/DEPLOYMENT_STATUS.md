# 📱 Senior MHealth 모바일 앱 배포 설정 완료

> 배포 완료 날짜: 2025년 11월 11일
> Firebase 프로젝트: senior-mhealth-202373080
> Android 패키지명: com.seniorhealth.mhealth

## ✅ 완료된 설정

### 1. Firebase 프로젝트 설정
- **프로젝트 ID**: `senior-mhealth-202373080`
- **프로젝트 번호**: `739201926447`
- **위치**: asia-northeast3
- **상태**: ✅ 활성화

### 2. Firebase Android 앱
- **앱 ID**: `1:739201926447:android:b1d639c14ffd31f09a4dda`
- **패키지명**: `com.seniorhealth.mhealth`
- **앱 이름**: Senior MHealth Mobile
- **API Key**: `AIzaSyAFYJy4Vb05Aw-2owiyO8Cgn8fxsS_pnSs`

### 3. 생성된 파일

#### `google-services.json`
- 위치: `android/app/google-services.json`
- 상태: ✅ 생성 완료

#### `firebase_options.dart`
- 위치: `lib/firebase_options.dart`
- 플랫폼: Android, iOS, Web
- 상태: ✅ 생성 완료

#### `.env`
- 위치: `.env`
- 설정: Firebase Config, API URLs
- 상태: ✅ 생성 완료

#### `MainActivity.kt`
- 위치: `android/app/src/main/kotlin/com/seniorhealth/mhealth/MainActivity.kt`
- 패키지: `com.seniorhealth.mhealth`
- 상태: ✅ 생성 완료

### 4. Firebase 서비스 활성화 상태

| 서비스 | 상태 | 설명 |
|--------|------|------|
| **Authentication** | ✅ 활성화 | 4명의 사용자 등록됨 |
| **Firestore Database** | ✅ 활성화 | asia-northeast3, Free Tier |
| **Cloud Storage** | ✅ 활성화 | senior-mhealth-202373080.firebasestorage.app |
| **Cloud Functions** | ✅ 배포됨 | 5개 함수 활성화 |
| **Cloud Messaging (FCM)** | ✅ 활성화 | 알림 준비 완료 |

### 5. 백엔드 API 엔드포인트

```
주요 API:
- https://asia-northeast3-senior-mhealth-202373080.cloudfunctions.net/api

배포된 Functions:
- api (HTTP Trigger, 1st gen)
- helloWorld (HTTP Trigger, 2nd gen)
- processVoiceFile (Storage Trigger, 2nd gen)
- registerFCMToken (HTTP Trigger, 1st gen)
- testDB (HTTP Trigger, 2nd gen)
```

## 🚀 다음 단계: APK 빌드

### Flutter SDK 설치 (필수)

1. **Flutter SDK 다운로드**
   ```powershell
   # Windows용 Flutter SDK
   # https://docs.flutter.dev/get-started/install/windows
   ```

2. **환경 변수 설정**
   - `Path`에 `C:\flutter\bin` 추가
   - PowerShell 재시작

3. **Flutter 설치 확인**
   ```powershell
   flutter doctor
   ```

4. **Android SDK 설정**
   ```powershell
   flutter doctor --android-licenses
   ```

### APK 빌드 명령어

```powershell
# 1. 프로젝트 디렉토리로 이동
cd C:\senior_mhealth_lecture\frontend\mobile

# 2. 의존성 설치
flutter pub get

# 3. 디버그 APK 빌드 (테스트용)
flutter build apk --debug

# 4. 릴리즈 APK 빌드 (배포용)
flutter build apk --release

# 5. APK 위치
# build/app/outputs/flutter-apk/app-release.apk
```

### 기기 설치

```powershell
# USB 디버깅 연결
adb devices

# APK 설치
adb install build/app/outputs/flutter-apk/app-release.apk

# 또는 디버그 모드로 직접 실행
flutter run
```

## 📊 프로젝트 구조

```
frontend/mobile/
├── android/
│   ├── app/
│   │   ├── google-services.json ✅
│   │   ├── build.gradle ✅
│   │   └── src/main/
│   │       ├── AndroidManifest.xml ✅
│   │       └── kotlin/com/seniorhealth/mhealth/
│   │           └── MainActivity.kt ✅
│   └── build.gradle
├── lib/
│   ├── firebase_options.dart ✅
│   ├── main.dart
│   ├── screens/
│   ├── services/
│   └── widgets/
├── .env ✅
└── pubspec.yaml ✅
```

## 🔧 주요 설정 값

### Firebase Configuration
```dart
// Android
apiKey: "AIzaSyAFYJy4Vb05Aw-2owiyO8Cgn8fxsS_pnSs"
appId: "1:739201926447:android:b1d639c14ffd31f09a4dda"
projectId: "senior-mhealth-202373080"
storageBucket: "senior-mhealth-202373080.firebasestorage.app"
messagingSenderId: "739201926447"

// Web (참고용)
apiKey: "AIzaSyCMZ5G72UJR_Wtw5kHbkxE7u1ykWyE7PF4"
appId: "1:739201926447:web:7392cc28b672c1169a4dda"
```

### Package Configuration
```gradle
namespace = "com.seniorhealth.mhealth"
applicationId = "com.seniorhealth.mhealth"
```

## 📱 테스트 계정

모바일 앱 테스트를 위한 계정 (이미 등록됨):

```
계정 1 (환자):
- 이메일: test@example.com
- 비밀번호: [사용자 설정]

계정 2 (의사):
- 이메일: doctor@hospital.com
- 비밀번호: [사용자 설정]

계정 3 (관리자):
- 이메일: admin@example.com
- 비밀번호: [사용자 설정]
```

## ⚠️ 주의사항

1. **패키지명 변경 불가**: `com.seniorhealth.mhealth`로 고정됨
2. **google-services.json**: 절대 Git에 커밋하지 말 것 (이미 .gitignore에 포함)
3. **API Key 보안**: 프로덕션 배포 시 API Key 제한 설정 필요
4. **서명 키**: 릴리즈 빌드 시 앱 서명 키 필요 (Google Play 배포 시)

## 🎯 배포 체크리스트

- [x] Firebase 프로젝트 설정
- [x] Android 앱 등록
- [x] google-services.json 생성
- [x] firebase_options.dart 생성
- [x] .env 파일 생성
- [x] MainActivity.kt 패키지명 일치
- [x] build.gradle 설정
- [x] Firebase 서비스 활성화
- [ ] Flutter SDK 설치
- [ ] APK 빌드
- [ ] 기기 테스트
- [ ] Google Play 배포 (선택사항)

## 📚 참고 문서

- [Flutter 공식 문서](https://docs.flutter.dev)
- [Firebase Flutter 설정](https://firebase.google.com/docs/flutter/setup)
- [UNIVERSAL_SETUP.md](./UNIVERSAL_SETUP.md)
- [Week 7-1 가이드](../../docs/week7-1.md)

---

**🎉 설정 완료! Flutter 설치 후 APK 빌드 가능합니다.**
