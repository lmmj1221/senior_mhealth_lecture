# Week 7: Mobile 앱 빌드 및 배포 🚀

> **🎯 실습 목표**: Flutter 앱을 실제 Android 기기에 설치할 수 있는 APK 파일 만들기

## 🎮 Vibe 코딩 시작!

**이번 주차는 실습 중심으로 진행됩니다. 각 단계를 따라하며 실제로 APK를 만들어보세요!**

### 📋 사전 체크리스트
다음 항목들이 준비되었는지 확인하세요:

- [ ] **Flutter SDK 설치** (3.0 이상)
- [ ] **VS Code 설치** (Flutter 확장 프로그램 포함)
- [ ] **Android SDK 설치** (Android Studio 또는 독립 설치)
- [ ] **Android 기기 또는 에뮬레이터** 준비
- [ ] **Week 3-6 백엔드 서비스** 배포 완료
- [ ] **.env 파일 준비** (프로젝트 루트에 Firebase, API 설정값 포함)

### 🎯 최종 목표
이 실습을 완료하면:
- ✅ **APK 파일 생성**: 실제 Android 기기에 설치 가능한 파일
- ✅ **앱 테스트**: 백엔드 서버와 정상 통신 확인
- ✅ **배포 준비**: 다른 사람들과 공유할 수 있는 상태

---

## 🚀 실습 시작!

### Phase 1: 환경 준비 (10분)
### Phase 2: Firebase 연결 (15분)  
### Phase 3: 앱 빌드 (20분)
### Phase 4: 기기 설치 (10분)
### Phase 5: 테스트 및 배포 (15분)

**총 예상 시간: 약 70분**

---

## Phase 1: 환경 준비 🔧

**목표**: Flutter 개발 환경이 제대로 설정되었는지 확인하고 프로젝트를 준비합니다.

**💡 중요**: 이 실습에서는 기존에 생성된 `.env` 파일의 환경변수들을 활용합니다. Week 3-6에서 설정한 Firebase 프로젝트 ID, API URL 등을 그대로 사용하므로 별도로 설정할 필요가 없습니다.

### Step 1-1: Flutter 설치 확인 ✅

**실행할 명령어:**
```bash
flutter --version
```

**✅ 성공 기준:**
다음과 같은 출력이 나와야 합니다:
```
Flutter 3.16.0 • channel stable • https://github.com/flutter/flutter.git
Framework • revision 4b6b4b5b8b (2 weeks ago) • 2023-12-06 10:30:23 -0800
Engine • revision 1a65fd409c
Tools • Dart 3.2.0 • DevTools 2.28.4
```

**❌ 만약 "command not found" 에러가 나면:**
1. Flutter가 설치되지 않았거나 PATH 설정이 안됨
2. [Flutter 공식 설치 가이드](https://docs.flutter.dev/get-started/install) 참고

**🔍 체크포인트:**
- [ ] Flutter 버전이 3.0 이상인가요?
- [ ] 명령어가 정상적으로 실행되나요?

---

### Step 1-2: Flutter Doctor 실행 🔍

**실행할 명령어:**
```bash
flutter doctor
```

**✅ 성공 기준:**
모든 항목이 체크되어야 합니다:
```
[✓] Flutter (Channel stable, 3.16.0)
[✓] Android toolchain - develop for Android devices
[✓] Chrome - develop for the web
[✓] VS Code (version 1.85.0)
[✓] Connected device (1 available)
```

**❌ 체크되지 않은 항목이 있다면:**
- **Android toolchain**: Android Studio 설치 필요
- **VS Code**: Flutter 확장 프로그램 설치 필요
- **Connected device**: Android 기기 연결 또는 에뮬레이터 실행 필요

**🔍 체크포인트:**
- [ ] 모든 항목이 체크되었나요?
- [ ] 문제가 있다면 해결했나요?

---

### Step 1-3: 프로젝트 폴더로 이동 📁

**실행할 명령어:**
```bash
cd frontend/mobile
pwd
```

**✅ 성공 기준:**
출력이 다음과 같아야 합니다:
```
/Users/yourname/Documents/senior_mhealth_lecture/frontend/mobile
```

**🔍 체크포인트:**
- [ ] 올바른 폴더에 있나요?
- [ ] `pubspec.yaml` 파일이 보이나요?

---

### Step 1-4: 의존성 설치 📦

**실행할 명령어:**
```bash
flutter pub get
```

**✅ 성공 기준:**
다음과 같은 출력이 나와야 합니다:
```
Running "flutter pub get" in mobile...
Resolving dependencies...
Got dependencies!
```

**🔍 체크포인트:**
- [ ] 의존성 설치가 성공했나요?
- [ ] 에러 메시지가 없나요?

---

### Step 1-5: 환경 변수 설정 ⚙️

**실행할 명령어:**
```bash
ls -la .env
```

**✅ .env 파일이 이미 있다면:**
```bash
# 기존 .env 파일 내용 확인
cat .env
```

**❌ .env 파일이 없다면:**
```bash
# 프로젝트 루트에서 .env 파일 복사
cp ../.env .env

# 또는 직접 생성
touch .env
```

**📝 .env 파일 내용 확인/입력:**
기존 `.env` 파일에서 다음 값들을 확인하세요:

```bash
# Firebase 설정 (Week 3에서 생성한 값들)
FIREBASE_API_KEY=your_firebase_api_key
FIREBASE_AUTH_DOMAIN=your_project_id.firebaseapp.com
FIREBASE_PROJECT_ID=your_project_id
FIREBASE_STORAGE_BUCKET=your_project_id.firebasestorage.app
FIREBASE_MESSAGING_SENDER_ID=your_sender_id
FIREBASE_APP_ID=your_app_id

# API URLs (Week 4, 5에서 배포한 주소들)
API_BASE_URL=https://asia-northeast3-your-project-id.cloudfunctions.net/api
AI_SERVICE_URL=https://your-ai-service-xxxxx-an.a.run.app
API_SERVICE_URL=https://your-api-service-xxxxx-an.a.run.app

# 환경 설정
ENVIRONMENT=production
DEBUG_MODE=false
```

**💡 기존 .env 파일에서 복사하는 방법:**
```bash
# 프로젝트 루트의 .env 파일 내용을 mobile 폴더로 복사
cp ../.env .env

# 복사된 내용 확인
cat .env
```

**🔍 체크포인트:**
- [ ] .env 파일이 있나요? (기존 파일 복사 또는 새로 생성)
- [ ] Firebase 설정값들이 올바른가요?
- [ ] API URL들이 올바른가요?

---

## 🎉 Phase 1 완료!


**다음 단계**: Phase 2에서 Firebase와 연결하겠습니다.

---

## Phase 2: Firebase 연결 🔥

**목표**: Flutter 앱을 Firebase 프로젝트와 연결하여 인증과 데이터베이스 기능을 사용할 수 있게 합니다.

### Step 2-1: FlutterFire CLI 설치 🛠️

**실행할 명령어:**
```bash
dart pub global activate flutterfire_cli
```

**✅ 성공 기준:**
다음과 같은 출력이 나와야 합니다:
```
Installing executables...
Installed flutterfire_cli 0.2.0.
```

**설치 확인:**
```bash
flutterfire --version
```

**🔍 체크포인트:**
- [ ] FlutterFire CLI가 설치되었나요?
- [ ] 버전이 표시되나요?

---

### Step 2-2: Firebase 프로젝트 연결 🔗

**먼저 .env 파일에서 프로젝트 ID 확인:**
```bash
# .env 파일에서 FIREBASE_PROJECT_ID 값 확인
grep FIREBASE_PROJECT_ID .env
```

**실행할 명령어:**
```bash
# .env 파일의 프로젝트 ID를 사용하여 연결
flutterfire configure --project=$(grep FIREBASE_PROJECT_ID .env | cut -d'=' -f2) --platforms=android,ios
```

**또는 수동으로 프로젝트 ID 입력:**
```bash
flutterfire configure --platforms=android,ios
```

**✅ 성공 기준:**
다음과 같은 출력이 나와야 합니다:
```
? Which Firebase project do you want to use? senior-mhealth-lecture
? Which platforms should your configuration support? android,ios
✓ Created android/app/google-services.json
✓ Created ios/Runner/GoogleService-Info.plist
✓ Created lib/firebase_options.dart
```

**💡 프로젝트 ID를 .env에서 자동으로 가져오는 방법:**
```bash
# .env 파일에서 프로젝트 ID 추출하여 사용
PROJECT_ID=$(grep FIREBASE_PROJECT_ID .env | cut -d'=' -f2)
flutterfire configure --project=$PROJECT_ID --platforms=android,ios
```

**🔍 체크포인트:**
- [ ] .env 파일에서 프로젝트 ID를 찾았나요?
- [ ] 프로젝트 선택이 성공했나요?
- [ ] 3개 파일이 생성되었나요?

---

### Step 2-3: 생성된 파일 확인 📁

**실행할 명령어:**
```bash
ls -la android/app/google-services.json
ls -la lib/firebase_options.dart
```

**✅ 성공 기준:**
두 파일 모두 존재해야 합니다:
```
-rw-r--r-- 1 user staff 1234 Dec 19 23:30 android/app/google-services.json
-rw-r--r-- 1 user staff 5678 Dec 19 23:30 lib/firebase_options.dart
```

**🔍 체크포인트:**
- [ ] google-services.json 파일이 있나요?
- [ ] firebase_options.dart 파일이 있나요?

---

## 🎉 Phase 2 완료!

**축하합니다! Firebase 연결이 완료되었습니다.**

**다음 단계**: Phase 3에서 앱을 빌드하겠습니다.

---

## 📱 Flutter 프로젝트 이해

### 프로젝트 구조 상세 설명

Flutter 프로젝트는 여러 폴더로 구성되어 있습니다. 각 폴더의 역할을 자세히 알아보겠습니다:

```
frontend/mobile/
├── android/           # Android 플랫폼 설정
│   ├── app/          # Android 앱 설정 파일들
│   │   ├── build.gradle  # Android 빌드 설정
│   │   └── src/main/     # Android 네이티브 코드
│   └── gradle/       # Gradle 빌드 도구 설정
├── ios/              # iOS 플랫폼 설정 (이번 주차에서는 사용 안함)
├── lib/              # Dart 소스 코드 (우리가 주로 작업하는 곳)
│   ├── main.dart     # 앱의 시작점 (앱이 처음 실행될 때 여기부터 시작)
│   ├── screens/      # 각 화면들 (로그인, 홈, 설정 등)
│   ├── widgets/      # 재사용 가능한 UI 컴포넌트들
│   ├── services/     # API 호출, 데이터베이스 연결 등
│   └── models/       # 데이터 구조 정의
├── pubspec.yaml      # 앱 설정 및 라이브러리 관리 (중요!)
├── .env              # 환경 변수 (API 주소, 키 등)
└── test/             # 테스트 코드
```

### 각 폴더의 역할

**📁 android/ 폴더**
- Android 앱으로 변환할 때 필요한 설정들
- 앱 이름, 아이콘, 권한 설정 등
- 우리가 직접 수정할 일은 거의 없음

**📁 lib/ 폴더 (가장 중요!)**
- 실제 앱 코드가 들어있는 곳
- `main.dart`: 앱이 시작되는 곳
- `screens/`: 각 화면 (로그인 화면, 홈 화면 등)
- `widgets/`: 버튼, 입력창 등 재사용 가능한 UI 요소들
- `services/`: 백엔드 서버와 통신하는 코드

**📄 pubspec.yaml**
- 앱의 기본 정보 (이름, 버전 등)
- 사용할 라이브러리 목록
- 앱 아이콘, 이름 등 설정

### 빌드 타입 상세 설명

Flutter에서는 3가지 빌드 타입이 있습니다:

#### 1. **Debug 빌드** (개발용)
```
특징:
- 개발자가 코드를 수정하면서 테스트할 때 사용
- 디버깅 정보가 포함되어 있어 문제를 찾기 쉬움
- 파일 크기가 큼 (50-70MB)
- 실행 속도가 느림
- Hot Reload 가능 (코드 수정 시 즉시 반영)
```

#### 2. **Profile 빌드** (성능 분석용)
```
특징:
- 앱의 성능을 측정할 때 사용
- 실제 사용자와 비슷한 환경에서 테스트
- 파일 크기 중간 (30-40MB)
- 성능 측정 도구 사용 가능
```

#### 3. **Release 빌드** (배포용)
```
특징:
- 실제 사용자에게 배포할 때 사용
- 최적화되어 있어 빠르고 작음
- 파일 크기 작음 (15-25MB)
- 디버깅 정보 없음
- 최종 배포용
```

**💡 초보자를 위한 팁:**
- 처음에는 **Debug 빌드**로 시작하세요
- 문제없이 작동하면 **Release 빌드**로 최종 APK를 만드세요

---

## Phase 3: 앱 빌드 🏗️

**목표**: Flutter 앱을 Android APK 파일로 빌드하여 실제 기기에 설치할 수 있게 만듭니다.

### Step 3-1: 디버그 APK 빌드 (테스트용) 🧪

**실행할 명령어:**
```bash
flutter build apk --debug
```

**✅ 성공 기준:**
다음과 같은 출력이 나와야 합니다:
```
Running Gradle task 'assembleDebug'...
✓ Built build/app/outputs/flutter-apk/app-debug.apk (50.2MB).
```

**빌드 파일 확인:**
```bash
ls -la build/app/outputs/flutter-apk/
```

**✅ 성공 기준:**
`app-debug.apk` 파일이 생성되어야 합니다:
```
-rw-r--r-- 1 user staff 52428800 Dec 19 23:45 app-debug.apk
```

**🔍 체크포인트:**
- [ ] 빌드가 성공했나요?
- [ ] app-debug.apk 파일이 생성되었나요?
- [ ] 파일 크기가 50-70MB 정도인가요?

---

### Step 3-2: 릴리즈 APK 빌드 (배포용) 🚀

**실행할 명령어:**
```bash
flutter build apk --release
```

**✅ 성공 기준:**
다음과 같은 출력이 나와야 합니다:
```
Running Gradle task 'assembleRelease'...
✓ Built build/app/outputs/flutter-apk/app-release.apk (18.5MB).
```

**빌드 파일 확인:**
```bash
ls -la build/app/outputs/flutter-apk/
```

**✅ 성공 기준:**
`app-release.apk` 파일이 생성되어야 합니다:
```
-rw-r--r-- 1 user staff 19415040 Dec 19 23:50 app-release.apk
```

**🔍 체크포인트:**
- [ ] 릴리즈 빌드가 성공했나요?
- [ ] app-release.apk 파일이 생성되었나요?
- [ ] 파일 크기가 15-25MB 정도인가요?

---

### Step 3-3: APK 정보 확인 📊

**실행할 명령어:**
```bash
aapt dump badging build/app/outputs/flutter-apk/app-release.apk | head -10
```

**✅ 성공 기준:**
다음과 같은 정보가 표시되어야 합니다:
```
package: name='com.example.senior_mhealth_mobile' versionCode='1' versionName='1.0.0'
sdkVersion:'21'
targetSdkVersion:'34'
uses-permission: name='android.permission.INTERNET'
uses-permission: name='android.permission.ACCESS_NETWORK_STATE'
```

**🔍 체크포인트:**
- [ ] 패키지 이름이 올바른가요?
- [ ] 버전 정보가 표시되나요?
- [ ] 권한이 설정되어 있나요?

---

## 🎉 Phase 3 완료!

**축하합니다! APK 빌드가 완료되었습니다.**

**다음 단계**: Phase 4에서 Android 기기에 설치하겠습니다.

---

## Step 1: Flutter 환경 설정

### 1-1. Flutter SDK 설치 확인 🤖

**Flutter가 제대로 설치되었는지 확인해보겠습니다.**

```bash
# 터미널을 열고 다음 명령어 실행
flutter --version
```

**예상되는 출력:**
```
Flutter 3.16.0 • channel stable • https://github.com/flutter/flutter.git
Framework • revision 4b6b4b5b8b (2 weeks ago) • 2023-12-06 10:30:23 -0800
Engine • revision 1a65fd409c
Tools • Dart 3.2.0 • DevTools 2.28.4
```

**만약 "command not found" 에러가 나면:**
- Flutter가 설치되지 않았거나 PATH 설정이 안됨
- [Flutter 공식 설치 가이드](https://docs.flutter.dev/get-started/install) 참고

**Flutter 설치 상태 진단:**
```bash
flutter doctor
```

**모든 항목이 체크되어야 합니다:**
```
[✓] Flutter (Channel stable, 3.16.0)
[✓] Android toolchain - develop for Android devices
[✓] Chrome - develop for the web
[✓] VS Code (version 1.85.0)
[✓] Connected device (1 available)
```

**❌ 만약 체크되지 않은 항목이 있다면:**
- Android toolchain: Android Studio 설치 필요
- VS Code: Flutter 확장 프로그램 설치 필요
- Connected device: Android 기기 연결 또는 에뮬레이터 실행 필요

### 1-2. 프로젝트 의존성 설치 🤖

**프로젝트에 필요한 라이브러리들을 다운로드합니다.**

```bash
# 1. 프로젝트 폴더로 이동
cd frontend/mobile

# 2. 현재 위치 확인 (중요!)
pwd
# 출력: /Users/yourname/Documents/senior_mhealth_lecture/frontend/mobile

# 3. 의존성 설치
flutter pub get
```

**예상되는 출력:**
```
Running "flutter pub get" in mobile...
Resolving dependencies...
Got dependencies!
```

**설치된 라이브러리 확인:**
```bash
flutter pub deps
```

**💡 초보자를 위한 설명:**
- `flutter pub get`: pubspec.yaml에 적힌 라이브러리들을 다운로드
- `flutter pub deps`: 설치된 라이브러리 목록을 보여줌
- 이 과정은 앱을 실행하기 전에 반드시 해야 함

### 1-3. 환경 변수 설정 👤

**앱이 백엔드 서버와 연결하기 위해 필요한 설정들을 저장합니다.**

**`.env` 파일 생성:**
```bash
# .env 파일이 있는지 확인
ls -la .env

# 없다면 새로 생성
touch .env
```

**`.env` 파일 내용 (Week 3-6에서 만든 값들로 교체):**
```bash
# Firebase 설정 (Week 3에서 생성한 값들)
FIREBASE_API_KEY=AIzaSyC...your_actual_key_here
FIREBASE_AUTH_DOMAIN=your-project-id.firebaseapp.com
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_STORAGE_BUCKET=your-project-id.firebasestorage.app
FIREBASE_MESSAGING_SENDER_ID=123456789012
FIREBASE_APP_ID=1:123456789012:android:abcdef123456

# API URLs (Week 4, 5에서 배포한 주소들)
API_BASE_URL=https://asia-northeast3-your-project-id.cloudfunctions.net/api
AI_SERVICE_URL=https://your-ai-service-xxxxx-an.a.run.app
API_SERVICE_URL=https://your-api-service-xxxxx-an.a.run.app

# 환경 설정
ENVIRONMENT=production
DEBUG_MODE=false
```

**🔍 실제 값 찾는 방법:**

1. **Firebase 설정값 찾기:**
   - Firebase Console → 프로젝트 설정 → 일반 탭
   - "내 앱" 섹션에서 Android 앱 선택
   - `google-services.json` 파일에서 값 복사

2. **API URL 찾기:**
   - Week 4, 5에서 배포한 Cloud Run 서비스 URL
   - Google Cloud Console → Cloud Run에서 확인

**💡 초보자를 위한 팁:**
- `.env` 파일은 절대 Git에 올리지 마세요 (보안상 중요!)
- 값에 공백이나 특수문자가 있으면 따옴표로 감싸세요
- 모든 값이 정확해야 앱이 제대로 작동합니다

---

## Phase 4: 기기 설치 📱

**목표**: 빌드한 APK 파일을 Android 기기에 설치하여 실제로 실행해봅니다.

### Step 4-1: Android 기기 연결 🔌📶

**Android 기기 설정:**
1. **개발자 옵션 활성화**:
   - 설정 → 휴대전화 정보 → 빌드 번호를 7번 연속 탭
   - "개발자가 되었습니다!" 메시지 확인

2. **USB 디버깅 활성화**:
   - 설정 → 개발자 옵션 → USB 디버깅 ON

---

## 🔌 방법 1: USB 케이블 연결 (권장)

**연결 방법:**
1. **USB 케이블로 컴퓨터와 기기 연결**
2. **기기에서 "USB 디버깅 허용" 팝업에서 "허용" 선택**

**실행할 명령어:**
```bash
adb devices
```

**✅ 성공 기준:**
다음과 같은 출력이 나와야 합니다:
```
List of devices attached
ABC123DEF456    device
```

---

## 📶 방법 2: 무선 연결 (WiFi)

**무선 연결 설정 (USB 케이블이 필요한 초기 설정):**

**1단계: USB로 초기 연결**
```bash
# USB 케이블로 기기 연결
adb devices

# 기기가 연결되었는지 확인
# ABC123DEF456    device
```

**2단계: 무선 연결 활성화**
```bash
# 기기의 IP 주소와 포트로 연결 (기기마다 다름)
adb tcpip 5555

# 기기에서 WiFi IP 주소 확인
# 설정 → WiFi → 연결된 네트워크 → IP 주소 확인
# 예: 192.168.1.100
```

**3단계: USB 케이블 제거 후 무선 연결**
```bash
# USB 케이블 제거 후 무선으로 연결
adb connect 192.168.1.100:5555

# 연결 확인
adb devices
```

**✅ 성공 기준:**
```
List of devices attached
192.168.1.100:5555    device
```

**💡 무선 연결 팁:**
- 기기와 컴퓨터가 같은 WiFi 네트워크에 있어야 함
- 일부 기기에서는 "무선 디버깅" 옵션을 별도로 활성화해야 함
- 연결이 끊어지면 `adb connect IP주소:5555`로 다시 연결

**❌ 무선 연결 문제 해결:**
```bash
# 연결이 안 될 때
adb kill-server
adb start-server
adb connect 192.168.1.100:5555

# 기기 IP 주소 다시 확인
adb devices
```

**🔧 Android 11+ 무선 디버깅 (더 쉬운 방법):**
1. 설정 → 개발자 옵션 → "무선 디버깅" ON
2. "무선 디버깅" 탭 → "QR 코드로 페어링" 또는 "페어링 코드로 페어링"
3. 컴퓨터에서 `adb pair IP주소:포트` 실행

---

## 🔍 연결 확인

**실행할 명령어:**
```bash
adb devices
```

**✅ 성공 기준:**
다음과 같은 출력이 나와야 합니다:
```
List of devices attached
ABC123DEF456    device
# 또는
192.168.1.100:5555    device
```

**🔍 체크포인트:**
- [ ] 기기가 "device" 상태로 표시되나요?
- [ ] 기기 ID 또는 IP 주소가 표시되나요?
- [ ] USB 또는 무선 연결 중 하나는 성공했나요?

---

### Step 4-2: APK 설치 📦

**실행할 명령어:**
```bash
adb install build/app/outputs/flutter-apk/app-release.apk
```

**✅ 성공 기준:**
다음과 같은 출력이 나와야 합니다:
```
Performing Streamed Install
Success
```

**만약 기존 앱이 있다면:**
```bash
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

**🔍 체크포인트:**
- [ ] 설치가 성공했나요?
- [ ] "Success" 메시지가 나왔나요?

---

### Step 4-3: 앱 실행 확인 🚀

**기기에서 확인:**
1. **앱 서랍에서 "Senior MHealth" 아이콘 찾기**
2. **앱 아이콘 탭하여 실행**
3. **첫 화면이 정상적으로 표시되는지 확인**

**실행할 명령어 (로그 확인):**
```bash
adb logcat | grep flutter
```

**✅ 성공 기준:**
- 앱이 정상적으로 실행됨
- 첫 화면이 표시됨
- 에러 메시지가 없음

**🔍 체크포인트:**
- [ ] 앱 아이콘이 보이나요?
- [ ] 앱이 정상적으로 실행되나요?
- [ ] 첫 화면이 표시되나요?

---

## 🎉 Phase 4 완료!

**축하합니다! 앱 설치가 완료되었습니다.**

**다음 단계**: Phase 5에서 앱을 테스트하고 배포를 준비하겠습니다.

---

## Phase 5: 테스트 및 배포 🧪

**목표**: 설치된 앱이 정상적으로 작동하는지 테스트하고 배포를 준비합니다.

### Step 5-1: Firebase 연결 테스트 🔥

**앱에서 테스트:**
1. **로그인/회원가입 기능 테스트**
2. **Firebase 인증이 정상 작동하는지 확인**

**실행할 명령어 (로그 확인):**
```bash
adb logcat | grep -i firebase
```

**✅ 성공 기준:**
- 로그인/회원가입이 정상 작동
- Firebase 관련 에러가 없음

**🔍 체크포인트:**
- [ ] 로그인이 정상 작동하나요?
- [ ] Firebase 에러가 없나요?

---

### Step 5-2: API 통신 테스트 🌐

**앱에서 테스트:**
1. **백엔드 서버와 데이터 주고받기 테스트**
2. **네트워크 연결 상태 확인**

**실행할 명령어 (네트워크 로그 확인):**
```bash
adb logcat | grep -i "http\|api"
```

**✅ 성공 기준:**
- API 호출이 정상 작동
- 서버와 통신 성공

**🔍 체크포인트:**
- [ ] API 호출이 성공하나요?
- [ ] 서버와 통신이 되나요?

---

### Step 5-3: 성능 테스트 📊

**실행할 명령어:**
```bash
adb shell dumpsys meminfo com.example.senior_mhealth_mobile
```

**✅ 성공 기준:**
- 메모리 사용량이 적절함
- 앱이 안정적으로 실행됨

**🔍 체크포인트:**
- [ ] 앱이 안정적으로 실행되나요?
- [ ] 메모리 사용량이 적절한가요?

---

### Step 5-4: 배포 준비 📦

**APK 파일 복사:**
```bash
cp build/app/outputs/flutter-apk/app-release.apk ~/Desktop/SeniorMHealth-v1.0.apk
```

**파일 정보 확인:**
```bash
ls -la ~/Desktop/SeniorMHealth-v1.0.apk
```

**✅ 성공 기준:**
- APK 파일이 데스크톱에 복사됨
- 파일 크기가 적절함 (15-25MB)

**🔍 체크포인트:**
- [ ] APK 파일이 데스크톱에 있나요?
- [ ] 파일 크기가 적절한가요?

---

## 🎉 Phase 5 완료!

**축하합니다! 모든 테스트가 완료되었습니다.**

**최종 결과물:**
- ✅ **APK 파일**: `~/Desktop/SeniorMHealth-v1.0.apk`
- ✅ **앱 설치**: Android 기기에 정상 설치됨
- ✅ **기능 테스트**: Firebase, API 통신 정상 작동
- ✅ **배포 준비**: 다른 사람들과 공유 가능

---

## Step 2: Firebase 설정

### 2-1. Firebase 프로젝트 연결 🤖

**Firebase와 Flutter 앱을 연결하는 과정입니다. 이 과정을 통해 앱이 Firebase 서비스를 사용할 수 있게 됩니다.**

**FlutterFire CLI 설치:**
```bash
# FlutterFire CLI 설치 (처음 한 번만)
dart pub global activate flutterfire_cli

# 설치 확인
flutterfire --version
```

**Firebase 프로젝트 구성:**
```bash
# Firebase 프로젝트와 연결
flutterfire configure \
  --project=your-project-id \
  --platforms=android,ios
```

**💡 초보자를 위한 설명:**
- `your-project-id`: Week 3에서 만든 Firebase 프로젝트 ID
- 이 명령어를 실행하면 자동으로 필요한 파일들이 생성됩니다

**자동으로 생성되는 파일들:**
```
frontend/mobile/
├── android/app/google-services.json    # Android용 Firebase 설정
├── ios/Runner/GoogleService-Info.plist # iOS용 Firebase 설정 (사용 안함)
└── lib/firebase_options.dart           # Flutter에서 사용할 Firebase 설정
```

**실행 과정 예시:**
```
? Which Firebase project do you want to use? senior-mhealth-lecture
? Which platforms should your configuration support? android,ios
✓ Created android/app/google-services.json
✓ Created ios/Runner/GoogleService-Info.plist
✓ Created lib/firebase_options.dart
```

### 2-2. google-services.json 확인 👤

**Android용 Firebase 설정 파일이 제대로 생성되었는지 확인합니다.**

**파일 위치 확인:**
```bash
# 파일이 있는지 확인
ls -la android/app/google-services.json

# 파일 내용 확인 (처음 몇 줄만)
head -20 android/app/google-services.json
```

**올바른 파일 구조:**
```json
{
  "project_info": {
    "project_number": "123456789012",
    "project_id": "senior-mhealth-lecture",
    "storage_bucket": "senior-mhealth-lecture.firebasestorage.app"
  },
  "client": [
    {
      "client_info": {
        "mobilesdk_app_id": "1:123456789012:android:abcdef123456",
        "android_client_info": {
          "package_name": "com.example.senior_mhealth_mobile"
        }
      }
    }
  ]
}
```

**❌ 만약 파일이 없다면:**
1. Firebase Console에서 Android 앱이 등록되어 있는지 확인
2. `flutterfire configure` 명령어를 다시 실행
3. 프로젝트 ID가 정확한지 확인

### 2-3. Android 설정 확인 🤖

**Android 앱이 Firebase를 사용할 수 있도록 설정을 확인합니다.**

**`android/app/build.gradle` 파일 확인:**
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

// 맨 아래에 이 줄이 있어야 함
apply plugin: 'com.google.gms.google-services'
```

**💡 초보자를 위한 설명:**
- `applicationId`: 앱의 고유 식별자 (Play Store에서 구분하는 ID)
- `minSdkVersion 21`: Android 5.0 이상에서만 실행
- `multiDexEnabled true`: 앱이 클 때 필요한 설정
- `apply plugin`: Firebase 플러그인 활성화

**❌ 만약 설정이 다르다면:**
1. VS Code에서 `android/app/build.gradle` 파일 열기
2. 위의 내용과 비교하여 수정
3. 저장 후 다시 빌드 시도

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
keytool -genkey -v -keystore ~/your-app-name.keystore \
  -alias your-app-alias \
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
keyAlias=your-app-alias
storeFile=/Users/username/your-app-name.keystore
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

**초보자들이 자주 겪는 문제들과 해결 방법을 정리했습니다.**

### 🚨 빌드 관련 문제

#### 1. Gradle 빌드 실패

**❌ 문제: "Could not resolve all dependencies" 에러**

**원인:** 라이브러리 다운로드 실패 또는 캐시 문제

**해결 방법:**
```bash
# 1단계: Gradle 캐시 삭제
cd android
./gradlew clean

# 2단계: 의존성 새로고침
./gradlew build --refresh-dependencies

# 3단계: Flutter 캐시도 삭제
cd ..
flutter clean
flutter pub get
```

**❌ 문제: "Minimum SDK version" 에러**

**원인:** Android 버전이 너무 낮음

**해결 방법:**
1. `android/app/build.gradle` 파일 열기
2. 다음 부분 찾기:
```gradle
defaultConfig {
    minSdkVersion 16  // 이 숫자를 21로 변경
}
```
3. 21로 변경 후 저장:
```gradle
defaultConfig {
    minSdkVersion 21  // Android 5.0 이상
}
```

#### 2. 메모리 부족 에러

**❌ 문제: "Out of memory" 또는 "Java heap space" 에러**

**원인:** 컴퓨터 메모리가 부족하거나 Gradle이 너무 적은 메모리 사용

**해결 방법:**
1. `android/gradle.properties` 파일 열기
2. 다음 내용 추가:
```properties
org.gradle.jvmargs=-Xmx4096m -XX:MaxPermSize=512m
org.gradle.daemon=true
org.gradle.parallel=true
```

**💡 추가 팁:**
- 다른 프로그램들을 종료하여 메모리 확보
- 컴퓨터 재시작 후 다시 시도

#### 3. Multidex 에러

**❌ 문제: "Cannot fit requested classes in a single dex file"**

**원인:** 앱이 너무 커서 하나의 파일에 들어가지 않음

**해결 방법:**
1. `android/app/build.gradle` 파일 열기
2. 다음 내용 추가:
```gradle
android {
    defaultConfig {
        multiDexEnabled true  // 이 줄 추가
    }
}

dependencies {
    implementation 'androidx.multidex:multidex:2.0.1'  // 이 줄 추가
}
```

### 📱 설치 관련 문제

#### 1. "앱이 설치되지 않음"

**❌ 문제: APK 설치 시 "앱이 설치되지 않음" 메시지**

**원인:** 기존에 같은 앱이 설치되어 있거나 서명이 다름

**해결 방법:**
```bash
# 방법 1: 기존 앱 삭제 후 재설치
adb uninstall com.example.senior_mhealth_mobile
adb install build/app/outputs/flutter-apk/app-release.apk
```

**또는 기기에서 직접:**
1. 설정 → 앱 → Senior MHealth 찾기
2. 제거 버튼 클릭
3. APK 파일 다시 설치

#### 2. "파일을 열 수 없음"

**❌ 문제: APK 파일을 탭해도 아무 반응 없음**

**원인:** APK 파일이 손상되었거나 기기 설정 문제

**해결 방법:**
```bash
# 1단계: 새로 빌드
flutter clean
flutter build apk --release

# 2단계: 파일 크기 확인 (정상: 15-25MB)
ls -la build/app/outputs/flutter-apk/app-release.apk
```

**기기 설정 확인:**
1. 설정 → 보안 → "출처를 알 수 없는 앱" 허용
2. 파일 관리자 앱에서 APK 파일 찾기
3. 파일을 탭하여 설치

#### 3. 권한 거부

**❌ 문제: 앱이 인터넷에 연결되지 않음**

**원인:** Android 권한 설정 누락

**해결 방법:**
1. `android/app/src/main/AndroidManifest.xml` 파일 열기
2. 다음 권한들이 있는지 확인:
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
<uses-permission android:name="android.permission.WAKE_LOCK"/>
```

### 🔥 런타임 문제

#### 1. Firebase 연결 실패

**❌ 문제: 앱 실행 시 Firebase 관련 에러**

**원인:** Firebase 설정 파일 누락 또는 잘못된 설정

**해결 방법:**
1. `google-services.json` 파일이 있는지 확인:
```bash
ls -la android/app/google-services.json
```

2. Firebase 초기화 코드 확인:
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
    print("✅ Firebase initialized successfully");
  } catch (e) {
    print("❌ Firebase initialization error: $e");
  }

  runApp(MyApp());
}
```

3. `.env` 파일의 Firebase 설정값 확인

#### 2. API 호출 실패

**❌ 문제: 백엔드 서버와 연결되지 않음**

**원인:** API URL이 잘못되었거나 서버가 실행되지 않음

**해결 방법:**
1. `.env` 파일의 API URL 확인:
```bash
cat .env | grep API
```

2. 브라우저에서 API URL 접속 테스트:
```
https://your-api-service-xxxxx-an.a.run.app/health
```

3. Week 4, 5에서 배포한 서비스가 실행 중인지 확인

#### 3. 앱이 갑자기 종료됨 (크래시)

**❌ 문제: 앱 실행 중 갑자기 꺼짐**

**해결 방법:**
```bash
# 실시간 로그 확인
adb logcat | grep flutter

# 에러 로그만 보기
adb logcat *:E

# 로그를 파일로 저장
adb logcat > crash_log.txt
```

**일반적인 원인:**
- 메모리 부족
- 잘못된 API 호출
- Firebase 설정 오류
- 권한 문제

### 🆘 도움이 필요할 때

**문제가 해결되지 않으면:**

1. **에러 메시지 전체 복사**하여 검색
2. **Flutter 공식 문서** 확인: https://docs.flutter.dev
3. **Stack Overflow**에서 비슷한 문제 검색
4. **GitHub Issues**에서 해결책 찾기

**💡 디버깅 팁:**
- 항상 에러 메시지를 자세히 읽어보세요
- 한 번에 하나씩 문제를 해결하세요
- 문제가 생기면 이전 단계로 돌아가서 확인하세요

---

## 🎯 Vibe 코딩 완료 체크리스트

**각 Phase를 완료할 때마다 체크박스를 표시하세요!**

### Phase 1: 환경 준비 ✅
- [ ] **Step 1-1**: Flutter 설치 확인 (`flutter --version`)
- [ ] **Step 1-2**: Flutter Doctor 실행 (`flutter doctor`)
- [ ] **Step 1-3**: 프로젝트 폴더 이동 (`cd frontend/mobile`)
- [ ] **Step 1-4**: 의존성 설치 (`flutter pub get`)
- [ ] **Step 1-5**: 환경 변수 설정 (`.env` 파일 생성)

### Phase 2: Firebase 연결 🔥
- [ ] **Step 2-1**: FlutterFire CLI 설치 (`dart pub global activate flutterfire_cli`)
- [ ] **Step 2-2**: Firebase 프로젝트 연결 (`flutterfire configure`)
- [ ] **Step 2-3**: 생성된 파일 확인 (`google-services.json`, `firebase_options.dart`)

### Phase 3: 앱 빌드 🏗️
- [ ] **Step 3-1**: 디버그 APK 빌드 (`flutter build apk --debug`)
- [ ] **Step 3-2**: 릴리즈 APK 빌드 (`flutter build apk --release`)
- [ ] **Step 3-3**: APK 정보 확인 (`aapt dump badging`)

### Phase 4: 기기 설치 📱
- [ ] **Step 4-1**: Android 기기 연결 (`adb devices`)
- [ ] **Step 4-2**: APK 설치 (`adb install app-release.apk`)
- [ ] **Step 4-3**: 앱 실행 확인 (기기에서 앱 실행)

### Phase 5: 테스트 및 배포 🧪
- [ ] **Step 5-1**: Firebase 연결 테스트 (로그인/회원가입)
- [ ] **Step 5-2**: API 통신 테스트 (백엔드 서버 연결)
- [ ] **Step 5-3**: 성능 테스트 (`adb shell dumpsys meminfo`)
- [ ] **Step 5-4**: 배포 준비 (APK 파일 복사)

---

## 🎉 최종 성공 기준

**모든 Phase를 완료하면 다음을 달성합니다:**

### ✅ 기술적 성과
- **APK 파일 생성**: `~/Desktop/SeniorMHealth-v1.0.apk`
- **앱 설치**: Android 기기에 정상 설치됨
- **Firebase 연결**: 인증 및 데이터베이스 정상 작동
- **API 통신**: 백엔드 서버와 정상 통신

### ✅ 학습 성과
- **Flutter 빌드 프로세스** 이해
- **Android 앱 배포** 경험
- **모바일 앱 테스트** 방법 습득
- **실제 기기에서 앱 실행** 경험

### 🚀 다음 단계
- **Week 8**: 전체 시스템 통합 테스트
- **사용자 피드백** 수집 및 개선
- **Google Play Store** 배포 (선택사항)
- **앱 최적화** 및 성능 개선

---

## 💡 추가 도전 과제

**실습을 완료한 후 시도해보세요:**

1. **다른 기기에서 테스트**: 친구나 가족의 Android 기기에서 APK 설치
2. **앱 아이콘 변경**: `android/app/src/main/res/` 폴더에서 아이콘 수정
3. **버전 업데이트**: `pubspec.yaml`에서 버전 번호 변경 후 새 APK 빌드
4. **Firebase App Distribution**: 베타 테스터들에게 앱 배포

**🎯 축하합니다! 모바일 앱 개발의 핵심 과정을 모두 완료했습니다!**

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