# Week 6: Vercel 배포 - Next.js 웹 애플리케이션

## 🎯 학습 목표

Next.js 웹 애플리케이션을 Vercel 플랫폼에 배포하고, 환경 변수 관리와 커스텀 도메인 설정을 학습합니다.

---

## ✅ 배포 사전 체크리스트 (Pre-deployment Checklist)

Vercel 배포를 시작하기 전에 아래 항목들이 완료되었는지 확인하세요.

### 🔐 1. Firebase 설정 완료 여부

```bash
# 확인 명령어
ls -la .firebaserc
ls -la backend/service-account-key.json
cat .env | grep FIREBASE
```

- [ ] **Firebase 프로젝트 생성 완료**
  - 프로젝트 ID:
  - 프로젝트 번호:
  - 리전: `asia-northeast3` (서울)

- [ ] **Firebase 서비스 활성화 완료**
  - Authentication (이메일/비밀번호 로그인)
  - Firestore Database (Native 모드)
  - Cloud Storage
  - Cloud Functions
  - Firebase Hosting (선택사항)

- [ ] **Service Account Key 생성 및 저장**
  - 파일 위치: `backend/service-account-key.json`
  - 권한 설정: `600` (읽기 전용)
  - 프로젝트 ID 일치 확인

  > 참고: 저장소에는 서비스 계정 키(JSON)가 여러 이름/위치로 등장할 수 있습니다.
  > 일반적으로는 하나의 Google 서비스 계정 키를 생성해 여러 컴포넌트에서 "복사해서" 사용합니다.
  > 레포에서 자주 보는 이름/위치 예:
  > - `backend/service-account-key.json` (백엔드 개발/로컬 실행용)
  > - `serviceAccountKey.json` (프로덕션 빌드/Docker 컨텍스트에서 루트 위치로 기대됨)
  > - `firebase-service-account.json` (CI/CD에서 임시로 생성 후 사용)
  >
  > 실제로는 위 파일들 중 하나만 올바른 권한을 가진 키 파일이면 되고, 민감 정보이므로 절대 Git에 커밋하지 마세요. 운영 환경에서는 `GOOGLE_APPLICATION_CREDENTIALS` 환경변수로 경로를 지정하거나, CI 비밀(Secrets)로 키 내용을 안전하게 주입하는 방식을 권장합니다.

- [ ] **Firebase Web App 설정 완료**
  - Firebase Console에서 웹 앱 등록
  - Firebase Config 정보 확인:
    ```
    FIREBASE_API_KEY
    FIREBASE_AUTH_DOMAIN
    FIREBASE_PROJECT_ID
    FIREBASE_STORAGE_BUCKET
    FIREBASE_MESSAGING_SENDER_ID
    FIREBASE_APP_ID
    ```

### 🗄️ 2. Firestore 데이터베이스 설정

- [ ] **Firestore Rules 배포 완료**
  ```bash
  firebase deploy --only firestore:rules
  ```
  - 확인: [Firestore Rules Console](https://console.firebase.google.com/project/my-project-54928-b9704/firestore/rules)

- [ ] **Firestore Indexes 배포 완료**
  ```bash
  firebase deploy --only firestore:indexes
  ```
  - 확인: [Firestore Indexes Console](https://console.firebase.google.com/project/my-project-54928-b9704/firestore/indexes)
  - 필수 인덱스:
    - `healthData`: `userId + createdAt`
    - `healthData`: `seniorId + timestamp`

- [ ] **Storage Rules 배포 완료**
  ```bash
  firebase deploy --only storage
  ```
  - 확인: [Storage Rules Console](https://console.firebase.google.com/project/my-project-54928-b9704/storage/rules)

### ⚙️ 3. 환경 변수 파일 준비

- [ ] **루트 .env 파일 존재 및 설정 완료**
  ```bash
  cat .env
  ```
  - GCP 프로젝트 정보
  - Firebase 설정
  - JWT Secret

- [ ] **Backend 환경 변수 설정 완료**
  - `backend/.env`
  - `backend/functions/.env`
  - `backend/ai-service/.env`
  - `backend/api-service/.env`

- [ ] **Frontend Web 환경 변수 설정 완료**
  - `frontend/web/.env.local`
  - 모든 Firebase Config 포함
  - API URL 설정 완료

### 🚀 4. Backend 서비스 배포

- [ ] **Cloud Functions 배포 완료**
  ```bash
  firebase deploy --only functions
  ```
  - API Functions URL 확인
  - Storage Trigger 작동 확인
  - Firestore Trigger 작동 확인

- [ ] **Cloud Run AI Service 배포 완료**
  ```bash
  gcloud run services list
  ```
  - AI Service URL 확인
  - Health Check 통과

- [ ] **Cloud Run API Service 배포 완료**
  ```bash
  gcloud run services list
  ```
  - API Service URL 확인
  - Health Check 통과

### 💻 5. Frontend Web App 로컬 테스트

- [ ] **의존성 설치 완료**
  ```bash
  cd frontend/web
  npm install
  ```

- [ ] **로컬 개발 서버 실행 성공**
  ```bash
  npm run dev
  # http://localhost:3000 접속 가능
  ```

- [ ] **Firebase 연결 테스트**
  - Firebase Authentication 로그인 작동
  - Firestore 데이터 읽기/쓰기 작동
  - Storage 파일 업로드/다운로드 작동

- [ ] **프로덕션 빌드 테스트**
  ```bash
  npm run build
  npm start
  # 빌드 에러 없음
  ```

- [ ] **테스트 데이터 생성 완료** ⭐ **중요!**
  - Web App에서 표시할 데이터를 Firebase에 생성
  - 테스트 사용자, Firestore 문서, Storage 파일 업로드
  - **📖 [테스트 데이터 생성 가이드](./SETUP_TEST_DATA.md) 참조**
  - 최소 요구사항:
    - [ ] Authentication: `test@test.com` 사용자 생성
    - [ ] Firestore: `users/{userId}/calls/{callId}` 문서 생성
    - [ ] Storage: 음성 파일 업로드
    - [ ] 데이터 확인: Firebase Console에서 검증

### 🔑 6. Vercel 계정 및 CLI 준비

- [ ] **Vercel 계정 생성**
  - [Vercel 가입](https://vercel.com/signup)
  - GitHub 계정 연동 (권장)

- [ ] **Vercel CLI 설치**
  ```bash
  npm install -g vercel
  vercel --version
  ```

- [ ] **Vercel 로그인 완료**
  ```bash
  vercel login
  # 이메일 인증 완료
  ```

### 📋 7. Git Repository 준비 (자동 배포용)

- [ ] **Git 저장소 초기화 완료**
  ```bash
  git status
  # 현재 브랜치 확인
  ```

- [ ] **GitHub Repository 생성 (권장)**
  - Public 또는 Private 저장소
  - Vercel과 연동 예정

- [ ] **.gitignore 설정 확인**
  ```bash
  cat .gitignore
  ```
  - `.env`, `.env.local` 포함 확인
  - `service-account-key.json` 포함 확인
  - `node_modules/` 포함 확인

### 🔍 8. 최종 점검

- [ ] **모든 민감한 정보 보호**
  - Service Account Key는 Git에 커밋하지 않음
  - .env 파일은 Git에 커밋하지 않음
  - API Key는 환경 변수로만 관리

- [ ] **Firebase 프로젝트 권한 확인**
  - Firebase Console 접근 가능
  - 프로젝트 편집 권한 보유

- [ ] **네트워크 및 API 접근 테스트**
  ```bash
  # Firebase 접속 테스트
  curl https://firestore.googleapis.com/

  # Cloud Run 접속 테스트 (배포된 경우)
  curl YOUR_CLOUD_RUN_URL/health
  ```

---

## 🚨 체크리스트 미완료 시 대응

각 섹션에서 체크되지 않은 항목이 있다면 해당 Week로 돌아가서 완료하세요:

- **Firebase 설정**: Week 3 참조
- **Firestore 설정**: Week 5 참조
- **환경 변수**: `SETUP_GUIDE.md` 참조
- **Backend 배포**: Week 4-5 참조
- **Frontend 준비**: 아래 Step 1부터 진행

---

## ⚡ 빠른 확인 스크립트

모든 설정을 빠르게 확인하려면:

```bash
# 프로젝트 루트에서 실행
echo "=== Firebase 설정 확인 ==="
test -f .firebaserc && echo "✅ .firebaserc 존재" || echo "❌ .firebaserc 없음"
test -f backend/service-account-key.json && echo "✅ Service Account Key 존재" || echo "❌ Service Account Key 없음"

echo -e "\n=== 환경 변수 확인 ==="
test -f .env && echo "✅ 루트 .env 존재" || echo "❌ 루트 .env 없음"
test -f frontend/web/.env.local && echo "✅ Web .env.local 존재" || echo "❌ Web .env.local 없음"

echo -e "\n=== Firebase 배포 확인 ==="
firebase deploy --only firestore:rules --dry-run 2>/dev/null && echo "✅ Firestore Rules 유효" || echo "❌ Firestore Rules 문제"

echo -e "\n=== 테스트 데이터 확인 ==="
test -f create_test_call.js && echo "✅ 테스트 스크립트 존재" || echo "⚠️  테스트 스크립트 없음 (SETUP_TEST_DATA.md 참조)"
test -f auth_users.json && echo "✅ 테스트 사용자 확인됨" || echo "⚠️  테스트 사용자 미확인"

echo -e "\n=== Frontend 빌드 테스트 ==="
cd frontend/web && npm run build 2>/dev/null && echo "✅ 빌드 성공" || echo "❌ 빌드 실패"

echo -e "\n=== Vercel CLI 확인 ==="
which vercel >/dev/null 2>&1 && echo "✅ Vercel CLI 설치됨" || echo "❌ Vercel CLI 미설치"
```

**모든 항목이 ✅로 표시되면 Vercel 배포를 시작할 수 있습니다!**

---

## 📝 테스트 데이터 생성 (필수!)

Web App을 배포하기 전에 **반드시** 테스트 데이터를 생성해야 합니다.

### 왜 필요한가?

Vercel에 배포한 Web App은 Firebase에서 데이터를 읽어와 화면에 표시합니다.
테스트 데이터가 없으면 **빈 화면만 보이게 됩니다!**

### 생성 방법

**📖 [테스트 데이터 생성 가이드](./SETUP_TEST_DATA.md)**를 따라 진행하세요.

### 생성할 데이터

1. **Authentication**: `test@test.com` / `test1234`
2. **Firestore**: 통화 기록 문서 (calls collection)
3. **Storage**: 음성 파일 (1.59 MB)

### 예상 소요 시간

약 10-15분 (스크립트 작성 및 실행)

---

## 🌐 Web App이란? (배포하기 전에 이해하기)

### 프로젝트의 전체 구조

```
Senior MHealth 프로젝트
├─────────────────────────────────────────────────┐
│                                                 │
│  📱 Mobile App (Flutter)                        │
│  ┌───────────────────────────────────┐          │
│  │ 노인/보호자가 스마트폰에서 사용      │          │
│  │ • 음성 통화 녹음                   │          │
│  │ • 건강 데이터 입력                 │          │
│  │ • 알림 수신                        │          │
│  │ • 실시간 모니터링                  │          │
│  └───────────────────────────────────┘          │
│                    ↓ 데이터 전송                 │
│             [Firebase Backend]                  │
│         (Firestore, Storage, Functions)         │
│                    ↓ 데이터 조회                 │
│  💻 Web App (Next.js) ← 이번 Week에 배포!       │
│  ┌───────────────────────────────────┐          │
│  │ 의료진/관리자가 브라우저에서 사용   │          │
│  │ • 📊 대시보드 (환자 현황)          │          │
│  │ • 📈 데이터 시각화 (차트/그래프)   │          │
│  │ • 👥 환자 관리                     │          │
│  │ • 📝 리포트 생성 (PDF 다운로드)    │          │
│  │ • ⚙️ 시스템 설정                   │          │
│  │ • 🔔 알림 관리                     │          │
│  └───────────────────────────────────┘          │
│                                                 │
└─────────────────────────────────────────────────┘
```

### Web App vs Mobile App 비교

| 구분 | Mobile App | Web App |
|------|-----------|---------|
| **플랫폼** | Android/iOS | 브라우저 (Chrome, Safari 등) |
| **사용자** | 노인, 보호자 | 의료진, 관리자 |
| **주요 기능** | 데이터 입력, 통화 | 데이터 분석, 관리 |
| **화면 크기** | 작음 (스마트폰) | 큼 (PC, 노트북) |
| **설치** | 필요 (앱스토어) | 불필요 (URL 접속) |
| **사용 장소** | 이동 중, 집 | 병원, 사무실 |
| **데이터** | 생성/입력 | 조회/분석 |
| **배포** | 앱스토어 | **Vercel** ← 이번 주차! |

### Web App의 핵심 역할

```
┌─────────────────────────────────────────────────────┐
│            Web App = 관리자 대시보드                  │
├─────────────────────────────────────────────────────┤
│                                                     │
│  1. 📊 실시간 현황 모니터링                          │
│     ┌──────────────────────────────────┐           │
│     │ 오늘의 통화: 15건                │           │
│     │ AI 분석 완료: 12건               │           │
│     │ 긴급 알림: 0건                   │           │
│     └──────────────────────────────────┘           │
│                                                     │
│  2. 👥 환자 관리                                     │
│     • 환자 목록 조회                                │
│     • 개인별 건강 기록 확인                         │
│     • 통화 히스토리 분석                            │
│                                                     │
│  3. 📈 데이터 시각화                                 │
│     • 건강 지표 차트                                │
│     • 트렌드 분석 그래프                            │
│     • AI 분석 결과 표시                             │
│                                                     │
│  4. 📝 리포트 생성                                   │
│     • 월간 통계 리포트                              │
│     • PDF 다운로드                                  │
│     • 보고서 자동 생성                              │
│                                                     │
└─────────────────────────────────────────────────────┘
```

### 실제 사용 시나리오

**시나리오 1: 일상 모니터링**
```
09:00 - 노인이 Mobile App으로 "안부 통화" 📱
        → 음성 녹음 자동 업로드
        → AI가 감정/건강 상태 분석

09:30 - 의료진이 Web App으로 확인 💻
        → 브라우저에서 http://your-app.vercel.app 접속
        → 대시보드에서 "홍길동님 통화 완료 ✅" 확인
        → AI 분석 결과: "정상 범위"
```

**시나리오 2: 이상 신호 감지**
```
14:30 - Mobile App이 이상 신호 감지 📱
        → "목소리 톤이 평소와 다름"
        → 자동 알림 발송

14:35 - Web App에 긴급 알림 표시 💻 🔔
        → 의료진이 브라우저에서 즉시 확인
        → 상세 차트 분석
        → 최근 일주일 데이터 비교
        → 필요시 즉시 연락
```

**시나리오 3: 월간 리포트**
```
매월 말 - 관리자가 Web App에서 💻
         → "리포트 생성" 버튼 클릭
         → 모든 환자 통계 자동 집계
         → PDF 다운로드
         → 보건소/병원에 제출
```

---

## 🚀 왜 Vercel로 배포하는가?

### Vercel = Web App을 인터넷에 올리는 플랫폼

```
로컬 개발 환경                       Vercel 배포
────────────────                    ──────────────
http://localhost:3000      →        https://your-app.vercel.app

• 본인 컴퓨터에서만 접속             • 전 세계 어디서든 접속 가능
• 개발/테스트용                      • 실제 서비스용
• 컴퓨터 꺼지면 안됨                 • 24시간 작동
```

### Vercel 배포의 장점

```
┌─────────────────────────────────────────────┐
│  Vercel이 자동으로 해주는 것들             │
├─────────────────────────────────────────────┤
│  ✅ 서버 관리 (자동)                        │
│  ✅ HTTPS 보안 인증서 (무료)               │
│  ✅ 전 세계 CDN (빠른 속도)                │
│  ✅ 자동 스케일링 (사용자 많아져도 OK)     │
│  ✅ Git 연동 (코드 푸시하면 자동 배포)     │
│  ✅ 프리뷰 URL (테스트용 주소 자동 생성)   │
└─────────────────────────────────────────────┘
```

### 배포 프로세스

```
1. 로컬에서 개발
   frontend/web/
   ├── .env.local  ← Firebase 설정
   ├── src/
   └── package.json

2. Vercel 연결
   vercel login
   vercel --prod

3. 환경 변수 설정 (Vercel Dashboard)
   NEXT_PUBLIC_FIREBASE_API_KEY=...
   NEXT_PUBLIC_FIREBASE_PROJECT_ID=...

4. 배포 완료! 🎉
   https://your-project-name.vercel.app

5. 전 세계 어디서든 접속 가능
   의료진이 병원에서
   관리자가 사무실에서
   → 브라우저로 접속하여 환자 데이터 확인
```

---

## 📚 핵심 개념

### 1. Vercel 플랫폼 이해

### Vercel = Frontend Cloud

```
Vercel 특징:
├── Zero-config 배포
├── Global Edge Network (CDN)
├── Serverless Functions
├── 자동 HTTPS
├── Preview Deployments
└── Analytics & Web Vitals
```

### 배포 워크플로우

```
Git Push → Vercel Build → Deploy → Global CDN
    ↓           ↓            ↓          ↓
코드 변경    빌드 시스템    프리뷰 URL   전 세계 배포
```

### 2. Next.js Framework

### Next.js 핵심 기능

```
Pages & Routing
├── pages/          # 파일 기반 라우팅
├── app/            # App Router (Next.js 13+)
└── api/            # API Routes

Rendering Methods
├── SSG (Static Site Generation)
├── SSR (Server-Side Rendering)
├── ISR (Incremental Static Regeneration)
└── CSR (Client-Side Rendering)
```

### 프로젝트 구조

```
frontend/
├── pages/
│   ├── index.js         # 홈페이지
│   ├── dashboard.js     # 대시보드
│   └── api/            # API 엔드포인트
├── components/
│   ├── Layout.js
│   └── HealthChart.js
├── lib/
│   ├── firebase.js     # Firebase 설정
│   └── api.js         # API 클라이언트
├── public/            # 정적 파일
└── styles/           # CSS/SCSS
```

### 3. 환경 변수 관리

### Vercel 환경 변수 타입

| 타입 | 설명 | 사용 위치 |
|-----|-----|----------|
| `NEXT_PUBLIC_*` | 브라우저 노출 | 클라이언트 |
| 일반 변수 | 서버만 접근 | 서버/빌드 |

### 환경 변수 우선순위

```
1. .env.local (로컬 개발)
2. .env.development (개발 환경)
3. .env.production (프로덕션)
4. Vercel Dashboard (최종 우선)
```

### 4. Edge Functions & Middleware

### Edge Functions

```javascript
// Edge에서 실행되는 함수
export const config = {
  runtime: 'edge',
  regions: ['icn1'], // 서울 리전
};

export default function handler(req) {
  // 10ms 이내 응답
  return new Response('Hello from Edge!');
}
```

### Middleware 패턴

```javascript
// middleware.js
export function middleware(request) {
  // 인증 체크
  if (!request.cookies.get('token')) {
    return NextResponse.redirect('/login');
  }
}

export const config = {
  matcher: '/dashboard/:path*',
};
```

---

## 🚀 실습: Vercel 배포

> **배포 방식 구분**
> - 🤖 **자동화**: CLI 명령어로 자동 실행
> - 👤 **수동 설정**: Vercel Dashboard에서 직접 클릭/입력

---

## 배포 전 필수 확인

### ✅ 사전 준비 체크리스트

```bash
# 1. Node.js 버전 확인 (18 이상 필수)
node --version
# v18.0.0 이상이어야 함

# 2. npm 버전 확인
npm --version

# 3. Git 저장소 상태 확인
git status
# 커밋되지 않은 변경사항이 있으면 커밋 필요

# 4. Firebase 설정 확인
cat frontend/web/.env.local | grep FIREBASE
# 모든 FIREBASE 환경 변수가 설정되어 있어야 함
```

### 🔧 필수 도구 설치 (🤖 자동화)

```bash
# Vercel CLI 전역 설치
npm install -g vercel

# 설치 확인
vercel --version
# Vercel CLI 33.0.0 (또는 최신 버전)
```

### 🔐 Vercel 계정 로그인 (👤 수동 설정)

```bash
# Vercel 로그인 시작
vercel login
```

**화면 출력:**
```
Vercel CLI 33.0.0
? Log in to Vercel
  Continue with GitHub
  Continue with GitLab
  Continue with Bitbucket
❯ Continue with Email
```

**단계별 진행:**

1. **이메일 로그인 선택**
   - 화살표 키로 "Continue with Email" 선택
   - Enter 키 입력

2. **이메일 주소 입력**
   ```
   ? Enter your email address: your-email@example.com
   ```
   - Vercel 계정 이메일 입력
   - Enter 키 입력

3. **이메일 확인**
   ```
   We sent an email to your-email@example.com.
   Please follow the steps provided inside it and make sure the security code matches XXX XXX.
   ```
   - 이메일 받은 편지함 확인
   - Vercel에서 온 이메일 열기
   - "Verify" 버튼 클릭
   - 또는 이메일의 6자리 코드가 터미널 코드와 일치하는지 확인

4. **로그인 완료 확인**
   ```
   > Success! Email authentication complete for your-email@example.com
   Congratulations! You are now logged in.
   ```

---

## Step 1: Next.js 프로젝트 준비 (🤖 자동화)

### 1.1 프로젝트 구조 확인 🤖

```bash
# frontend 디렉토리로 이동
cd frontend

# 의존성 설치
npm install

# 프로젝트 구조 확인
ls -la

# package.json 확인
cat package.json | grep scripts
```

### 1.2 환경 변수 설정 🤖

```bash
# .env.local 파일 생성 (로컬 개발용)
cat > .env.local << EOF
# Firebase Config (Public)
NEXT_PUBLIC_FIREBASE_API_KEY=${FIREBASE_API_KEY}
NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN=${FIREBASE_AUTH_DOMAIN}
NEXT_PUBLIC_FIREBASE_PROJECT_ID=${PROJECT_ID}
NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET=${FIREBASE_STORAGE_BUCKET}
NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID=${FIREBASE_MESSAGING_SENDER_ID}
NEXT_PUBLIC_FIREBASE_APP_ID=${FIREBASE_APP_ID}

# API URLs
NEXT_PUBLIC_API_URL=https://your-api-service-xxxxx-an.a.run.app
NEXT_PUBLIC_FUNCTIONS_URL=https://asia-northeast3-${PROJECT_ID}.cloudfunctions.net/api

# Server-only variables
FIREBASE_SERVICE_ACCOUNT_KEY='${SERVICE_ACCOUNT_KEY_JSON}'
EOF

echo "환경 변수 파일 생성 완료"
```

### 1.3 Firebase 초기화 설정 🤖

```bash
# lib/firebase.js 생성
cat > lib/firebase.js << 'EOF'
import { initializeApp, getApps } from 'firebase/app';
import { getAuth } from 'firebase/auth';
import { getFirestore } from 'firebase/firestore';
import { getStorage } from 'firebase/storage';

const firebaseConfig = {
  apiKey: process.env.NEXT_PUBLIC_FIREBASE_API_KEY,
  authDomain: process.env.NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN,
  projectId: process.env.NEXT_PUBLIC_FIREBASE_PROJECT_ID,
  storageBucket: process.env.NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET,
  messagingSenderId: process.env.NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID,
  appId: process.env.NEXT_PUBLIC_FIREBASE_APP_ID,
};

// 싱글톤 패턴으로 초기화
const app = getApps().length === 0
  ? initializeApp(firebaseConfig)
  : getApps()[0];

export const auth = getAuth(app);
export const db = getFirestore(app);
export const storage = getStorage(app);
export default app;
EOF
```

### 1.4 API 클라이언트 설정 🤖

```bash
# lib/api.js 생성
cat > lib/api.js << 'EOF'
const API_URL = process.env.NEXT_PUBLIC_API_URL;
const FUNCTIONS_URL = process.env.NEXT_PUBLIC_FUNCTIONS_URL;

class APIClient {
  constructor() {
    this.apiUrl = API_URL;
    this.functionsUrl = FUNCTIONS_URL;
  }

  async getAuthToken() {
    const { auth } = await import('./firebase');
    const user = auth.currentUser;
    if (!user) throw new Error('Not authenticated');
    return user.getIdToken();
  }

  async request(endpoint, options = {}) {
    const token = await this.getAuthToken();

    const response = await fetch(`${this.apiUrl}${endpoint}`, {
      ...options,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${token}`,
        ...options.headers,
      },
    });

    if (!response.ok) {
      throw new Error(`API Error: ${response.statusText}`);
    }

    return response.json();
  }

  // Health Data API
  async saveHealthData(data) {
    return this.request('/api/health', {
      method: 'POST',
      body: JSON.stringify(data),
    });
  }

  async getHealthData(params = {}) {
    const query = new URLSearchParams(params).toString();
    return this.request(`/api/health?${query}`);
  }

  // AI Analysis API
  async requestAnalysis(data) {
    return this.request('/api/analysis', {
      method: 'POST',
      body: JSON.stringify(data),
    });
  }
}

export default new APIClient();
EOF
```

---

## Step 2: 로컬 개발 및 테스트

### 2.1 개발 서버 실행 🤖

```bash
# 개발 서버 시작
npm run dev

# 브라우저에서 확인
# http://localhost:3000
```

### 2.2 빌드 테스트 🤖

```bash
# 프로덕션 빌드
npm run build

# 빌드 결과 확인
ls -la .next/

# 빌드된 앱 실행
npm start

# http://localhost:3000에서 테스트
```

### 2.3 성능 최적화 확인 🤖

```bash
# Lighthouse CI 설치 (선택사항)
npm install -g @lhci/cli

# 성능 측정
lhci autorun

# Bundle 분석
npm run analyze
```

---

## Step 3: Vercel 첫 배포 (🤖 자동화 + 👤 수동 설정)

> **🚨 중요: 프로젝트 경로 확인!**
>
> 이 프로젝트는 모노레포 구조로 **`frontend/web`** 서브디렉토리에 Next.js 앱이 있습니다.
> **반드시 `frontend/web` 디렉토리에서 배포 명령어를 실행해야 합니다!**
>
> ```
> senior_mhealth_lecture/        ← 프로젝트 루트 (여기서 실행 ❌)
> ├── backend/
> ├── frontend/
> │   └── web/                   ← Next.js 앱 (여기서 실행 ✅)
> │       ├── pages/
> │       ├── package.json
> │       └── next.config.js
> └── docs/
> ```
>
> **잘못된 경로에서 실행하면 배포 실패합니다!**

### 3.1 첫 배포 시작 (🤖 자동화)

**🔍 현재 위치 확인 (필수!)**

```bash
# 1. 현재 위치 확인
pwd
# 출력 예상: /Users/yourname/senior_mhealth_lecture

# 2. frontend/web 디렉토리로 이동
cd frontend/web

# 3. 다시 위치 확인
pwd
# 출력 예상: /Users/yourname/senior_mhealth_lecture/frontend/web

# 4. package.json 존재 확인
ls package.json
# 출력: package.json (파일이 보여야 함)

# 5. Next.js 프로젝트인지 확인
cat package.json | grep next
# "next": "^13.x.x" 또는 "next": "^14.x.x" 출력되어야 함
```

**✅ 위치 확인 완료 후 배포 시작**

```bash
# Vercel 배포 시작
vercel
```

### 3.2 CLI 대화형 설정 (👤 수동 응답)

**질문 1: 프로젝트 설정 및 배포**
```
Vercel CLI 33.0.0
? Set up and deploy "~/senior_mhealth_lecture/frontend/web"? [Y/n]
```
➡️ **입력**: `Y` (Enter)

**질문 2: 배포 스코프 선택**
```
? Which scope do you want to deploy to?
❯ Your Personal Account (your-username)
  Add New Team
```
➡️ **입력**: Enter (개인 계정 선택)

**질문 3: 기존 프로젝트 연결 여부**
```
? Link to existing project? [y/N]
```
➡️ **입력**: `N` (새 프로젝트 생성)

**질문 4: 프로젝트 이름 설정**
```
? What's your project's name? (frontend)
```
➡️ **입력**: `your-project-name` (원하는 이름 입력)

**질문 5: 코드 디렉토리 확인** ⚠️ **중요!**
```
? In which directory is your code located? ./
```

**⚠️ 경고: 이 질문이 가장 중요합니다!**

현재 위치가 `frontend/web`이므로:
- ✅ **올바른 답변**: `./` (Enter만 누름)
- ❌ **잘못된 답변**: `frontend/web` (이미 여기 있으므로 틀림)

**📝 설명:**
- Vercel은 **현재 디렉토리**를 기준으로 물어봅니다
- 이미 `cd frontend/web`로 이동했으므로 `./`가 정답입니다
- 만약 프로젝트 루트에서 실행했다면 `frontend/web`를 입력해야 하지만,
  **우리는 이미 `frontend/web`에 있으므로 `./`를 입력합니다**

➡️ **입력**: Enter (현재 디렉토리 = `./`)

**질문 6: 빌드 설정 오버라이드**
```
Auto-detected Project Settings (Next.js):
- Build Command: next build
- Development Command: next dev --port 3000
- Install Command: npm install
- Output Directory: Next.js default
? Want to modify these settings? [y/N]
```
➡️ **입력**: `N` (자동 감지 설정 사용)

### 3.3 첫 배포 완료 확인 (🤖 자동화)

**배포 진행 중 출력:**
```
🔗  Linked to your-username/your-project-name (created .vercel)
🔍  Inspect: https://vercel.com/your-username/your-project-name/xxxxx
✅  Production: https://your-project-name.vercel.app [2s]
```

**중요 정보 저장:**
- ✅ Production URL: `https://your-project-name.vercel.app`
- ✅ Project 이름: `your-project-name`
- ✅ `.vercel` 폴더 생성됨 (Git에 커밋하지 말것!)

---

## Step 4: 환경 변수 설정 (👤 수동 설정 필수!)

> **⚠️ 중요**: 첫 배포는 환경 변수 없이 진행되므로 앱이 정상 작동하지 않습니다!
> 반드시 이 단계를 완료해야 합니다.

### 4.1 Vercel Dashboard 접속 (👤 수동 설정)

**1단계: Dashboard 열기**
```
브라우저에서 접속: https://vercel.com/dashboard
```

**2단계: 프로젝트 선택**
- Dashboard 화면에서 방금 생성한 프로젝트 찾기
- 프로젝트 이름: `your-project-name` 클릭

**3단계: Settings 메뉴 이동**
- 상단 탭에서 "Settings" 클릭
- 왼쪽 사이드바에서 "Environment Variables" 클릭

### 4.2 환경 변수 추가하기 (👤 수동 설정 - 매우 중요!)

**화면 구성:**
```
┌─────────────────────────────────────────────────┐
│  Environment Variables                          │
├─────────────────────────────────────────────────┤
│  ⚙️ Add New                                     │
├─────────────────────────────────────────────────┤
│  Name  |  Value  |  Environment                │
│  (비어있음)                                     │
└─────────────────────────────────────────────────┘
```

**각 환경 변수를 하나씩 추가합니다:**

---

#### 📝 환경 변수 #1: Firebase API Key

1. **"Add New" 버튼 클릭**

2. **Name 입력란:**
   ```
   NEXT_PUBLIC_FIREBASE_API_KEY
   ```

3. **Value 입력란:**
   ```
   # .env.local 파일에서 복사
   cat frontend/web/.env.local | grep FIREBASE_API_KEY

   # 출력 예시:
   NEXT_PUBLIC_FIREBASE_API_KEY=AIzaSyDxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
   ```
   - 위 명령어 출력에서 `=` 뒤의 값만 복사
   - Value 입력란에 붙여넣기

4. **Environment 선택:**
   - ✅ **Production** (체크)
   - ✅ **Preview** (체크)
   - ✅ **Development** (체크)
   - 💡 모든 환경에 적용하려면 3개 모두 체크

5. **"Save" 버튼 클릭**

---

#### 📝 환경 변수 #2: Firebase Auth Domain

1. **다시 "Add New" 버튼 클릭**

2. **Name:**
   ```
   NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN
   ```

3. **Value:**
   ```bash
   # .env.local에서 확인
   cat frontend/web/.env.local | grep AUTH_DOMAIN

   # 예시: your-project-id.firebaseapp.com
   ```

4. **Environment: Production, Preview, Development 모두 체크**

5. **"Save" 클릭**

---

#### 📝 환경 변수 #3-7: 나머지 Firebase 변수들

**같은 방식으로 다음 변수들을 추가합니다:**

| Name | Value 확인 명령어 |
|------|------------------|
| `NEXT_PUBLIC_FIREBASE_PROJECT_ID` | `grep PROJECT_ID .env.local` |
| `NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET` | `grep STORAGE_BUCKET .env.local` |
| `NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID` | `grep SENDER_ID .env.local` |
| `NEXT_PUBLIC_FIREBASE_APP_ID` | `grep APP_ID .env.local` |

**각 변수마다:**
- Name 입력
- Value 입력 (`.env.local`에서 복사)
- Environment 3개 모두 체크
- Save 클릭
- **다음 변수로 이동 전 저장 확인**

---

#### 📝 환경 변수 #8-9: API URLs (선택사항)

**Cloud Run 서비스를 배포한 경우만 추가:**

| Name | Value 예시 |
|------|-----------|
| `NEXT_PUBLIC_API_URL` | `https://your-api-xxxxx.run.app` |
| `NEXT_PUBLIC_FUNCTIONS_URL` | `https://region-project.cloudfunctions.net/api` |

---

### 4.3 환경 변수 설정 완료 확인 (👤 수동 설정)

**Environment Variables 화면에서 확인:**

```
┌──────────────────────────────────────────────────────────────┐
│  Name                                    | Environments       │
├──────────────────────────────────────────────────────────────┤
│  NEXT_PUBLIC_FIREBASE_API_KEY           | Prod, Prev, Dev   │
│  NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN       | Prod, Prev, Dev   │
│  NEXT_PUBLIC_FIREBASE_PROJECT_ID        | Prod, Prev, Dev   │
│  NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET    | Prod, Prev, Dev   │
│  NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID | Prod, Prev, Dev │
│  NEXT_PUBLIC_FIREBASE_APP_ID            | Prod, Prev, Dev   │
│  NEXT_PUBLIC_API_URL                    | Prod, Prev, Dev   │
│  NEXT_PUBLIC_FUNCTIONS_URL              | Prod, Prev, Dev   │
└──────────────────────────────────────────────────────────────┘

총 8개 변수 (최소 6개 필수)
```

**✅ 체크리스트:**
- [ ] 모든 `NEXT_PUBLIC_FIREBASE_*` 변수 6개 추가됨
- [ ] 각 변수의 Environment에 3개 모두 체크됨
- [ ] Value에 실제 값 입력됨 (플레이스홀더 아님)
- [ ] "Save" 버튼을 각각 클릭함

---

## Step 5: 환경 변수 적용을 위한 재배포 (🤖 자동화)

> **중요**: 환경 변수를 추가한 후 반드시 재배포해야 적용됩니다!

### 5.1 프로덕션 재배포 (🤖 자동화)

**🔍 현재 위치 다시 확인 (필수!)**

```bash
# 1. 현재 위치 확인
pwd
# 출력이 ...../frontend/web 이어야 함

# 2. 만약 다른 곳에 있다면 이동
cd frontend/web

# 3. 프로덕션 환경으로 재배포
vercel --prod

# 출력:
🔍  Inspect: https://vercel.com/your-username/your-project-name/xxxxx
✅  Production: https://your-project-name.vercel.app [deployed]
```

**💡 Tip:**
모든 `vercel` 명령어는 반드시 `frontend/web` 디렉토리에서 실행하세요!
- `vercel` - Preview 배포
- `vercel --prod` - Production 배포
- `vercel ls` - 배포 목록 확인
- `vercel inspect` - 배포 상세 정보

### 5.2 배포 완료 확인 (👤 수동 설정)

**1단계: Production URL 접속**
```
브라우저에서 열기:
https://your-project-name.vercel.app
```

**2단계: 정상 작동 확인**
- ✅ 페이지가 로드됨 (빈 화면 아님)
- ✅ Firebase 로그인 화면 표시됨
- ✅ 콘솔에 Firebase 에러 없음

**3단계: 개발자 도구로 환경 변수 확인**
```javascript
// 브라우저 콘솔에서 실행
console.log(process.env.NEXT_PUBLIC_FIREBASE_PROJECT_ID)
// 출력: "your-project-id" (실제 프로젝트 ID)
```

**❌ 문제 발생 시:**
- 빈 화면: 환경 변수 누락 → Step 4로 돌아가기
- Firebase 에러: API Key 잘못됨 → 값 재확인
- 빌드 에러: Vercel Dashboard > Deployments > 로그 확인

---

## Step 6: GitHub 연동 자동 배포 (👤 수동 설정 + 🤖 자동화)

> **선택사항**: GitHub과 연동하면 코드를 푸시할 때마다 자동으로 배포됩니다.

### 6.1 GitHub Repository 준비 (🤖 자동화)

```bash
# Git 저장소가 없다면 초기화
git init

# .gitignore 확인 (.vercel 폴더는 제외되어야 함)
cat .gitignore | grep .vercel
# .vercel 있어야 함

# 변경사항 커밋
git add .
git commit -m "Initial commit for Vercel deployment"

# GitHub에 푸시 (저장소가 이미 있다고 가정)
git push origin main
```

### 6.2 Vercel에서 GitHub 연동 (👤 수동 설정)

**1단계: Vercel Dashboard 접속**
```
https://vercel.com/dashboard
```

**2단계: 프로젝트 Settings 이동**
- 프로젝트 선택: `your-project-name`
- 상단 탭: "Settings" 클릭
- 왼쪽 사이드바: "Git" 클릭

**3단계: Git Repository 연결**

화면 구성:
```
┌─────────────────────────────────────────┐
│  Git Repository                         │
├─────────────────────────────────────────┤
│  No Git repository connected            │
│                                         │
│  [Connect Git Repository]              │
└─────────────────────────────────────────┘
```

**진행 순서:**

1. **"Connect Git Repository" 버튼 클릭**

2. **Git Provider 선택 화면:**
   ```
   Connect Git Provider
   ┌─────────────────────────┐
   │  🐙 GitHub             │
   │  🦊 GitLab             │
   │  🪣 Bitbucket          │
   └─────────────────────────┘
   ```
   - "GitHub" 선택

3. **GitHub 인증:**
   - 새 창이 열리면서 GitHub 로그인 요청
   - GitHub 계정으로 로그인
   - Vercel 앱 권한 승인

4. **Repository 선택:**
   ```
   Select Repository
   ┌─────────────────────────────────────┐
   │  🔍 Search repositories...          │
   ├─────────────────────────────────────┤
   │  □ your-username/senior_mhealth_lecture │
   │  □ your-username/other-repo         │
   └─────────────────────────────────────┘
   ```
   - 검색창에 프로젝트 이름 입력
   - 해당 저장소 선택
   - "Connect" 버튼 클릭

5. **Root Directory 설정:** ⚠️ **매우 중요!**

   **🚨 이 단계를 반드시 정확히 입력해야 합니다!**

   ```
   Root Directory
   ┌─────────────────────────────────────┐
   │  frontend/web                       │
   └─────────────────────────────────────┘
   ```

   **입력 방법:**
   - 입력란에 정확히: `frontend/web`
   - ✅ **올바른 예**: `frontend/web`
   - ❌ **잘못된 예**: `/frontend/web` (앞에 슬래시 있음)
   - ❌ **잘못된 예**: `./frontend/web` (상대 경로)
   - ❌ **잘못된 예**: `web` (상위 디렉토리 누락)

   **📝 왜 중요한가?**
   - GitHub 저장소 루트에서 Next.js 앱까지의 상대 경로입니다
   - 이 경로가 틀리면 Vercel이 package.json을 찾지 못해 빌드 실패합니다

   **입력 완료 후:**
   - "Continue" 버튼 클릭
   - Vercel이 `frontend/web/package.json`을 자동 감지하는지 확인

### 6.3 자동 배포 테스트 (🤖 자동화)

**1단계: 코드 변경하기**
```bash
# 간단한 변경사항 추가
cd frontend/web
echo "// Auto-deploy test" >> pages/index.js

# 커밋 및 푸시
git add .
git commit -m "Test auto-deploy"
git push origin main
```

**2단계: Vercel Dashboard에서 확인 (👤 수동 설정)**
```
https://vercel.com/your-username/your-project-name
```

**Deployments 탭에서 확인:**
```
┌──────────────────────────────────────────────────┐
│  Recent Deployments                              │
├──────────────────────────────────────────────────┤
│  🚀 Building... (main)                           │
│     Commit: Test auto-deploy                     │
│     by your-username                             │
│     Started 10s ago                              │
├──────────────────────────────────────────────────┤
│  ✅ Ready (main)                                 │
│     Commit: Initial commit                       │
│     by your-username                             │
│     2 minutes ago                                │
└──────────────────────────────────────────────────┘
```

**3단계: 배포 완료 확인**
- Building → Ready로 상태 변경 (약 1-2분 소요)
- Production URL 자동 업데이트
- GitHub 커밋에 Vercel 체크 표시 추가됨

---

## Step 7: Preview Deployments (🤖 자동화)

> **Preview Deployments**: 브랜치별로 독립된 테스트 URL 자동 생성

### 7.1 Feature 브랜치 생성 및 배포 (🤖 자동화)

```bash
# 새 기능 브랜치 생성
git checkout -b feature/new-dashboard

# 코드 변경
echo "// New feature" >> pages/dashboard.js

# 커밋 및 푸시
git add .
git commit -m "Add new dashboard feature"
git push origin feature/new-dashboard

# ✅ Vercel이 자동으로 Preview 배포 시작!
```

**자동 생성되는 Preview URL:**
```
https://your-project-name-git-feature-new-dashboard-your-username.vercel.app
```

### 7.2 Pull Request와 Preview (👤 수동 설정 + 🤖 자동화)

**1단계: GitHub에서 PR 생성 (👤 수동 설정)**
```
1. GitHub 저장소 접속
2. "Pull requests" 탭 클릭
3. "New pull request" 버튼
4. Base: main ← Compare: feature/new-dashboard
5. "Create pull request" 클릭
```

**2단계: Vercel Bot 댓글 확인 (🤖 자동화)**

PR에 자동으로 Vercel Bot이 댓글을 남깁니다:

```
┌─────────────────────────────────────────────────┐
│  vercel bot commented                           │
├─────────────────────────────────────────────────┤
│  ✅ Successfully deployed to the following URLs:│
│                                                 │
│  🔍 Preview:                                    │
│  https://your-project-name-git-feature-...     │
│                                                 │
│  📝 Inspect:                                    │
│  https://vercel.com/.../deployments/...        │
└─────────────────────────────────────────────────┘
```

**3단계: Preview 테스트**
- Preview URL 클릭
- 변경사항 확인
- 문제 없으면 PR Merge
- Merge 시 자동으로 Production 배포!

---

## Step 8: 커스텀 도메인 설정 (👤 수동 설정 - 선택사항)

> **선택사항**: 자체 도메인을 사용하려면 이 단계를 진행하세요.

### 8.1 Vercel에서 도메인 추가 (👤 수동 설정)

**1단계: Settings > Domains 이동**
```
Vercel Dashboard > 프로젝트 선택 > Settings > Domains
```

**2단계: 도메인 추가**

화면 구성:
```
┌─────────────────────────────────────────────────┐
│  Domains                                        │
├─────────────────────────────────────────────────┤
│  Production: your-project-name.vercel.app       │
│                                                 │
│  Add a domain you own:                          │
│  ┌───────────────────────────────────────────┐ │
│  │ mhealth.example.com                       │ │
│  └───────────────────────────────────────────┘ │
│  [Add]                                          │
└─────────────────────────────────────────────────┘
```

진행 순서:
1. 입력란에 도메인 입력: `mhealth.example.com`
2. "Add" 버튼 클릭

**3단계: DNS 설정 안내 확인**

Vercel이 제공하는 DNS 레코드:

```
┌─────────────────────────────────────────────────┐
│  Configure DNS Records                          │
├─────────────────────────────────────────────────┤
│  Add the following records to your DNS:        │
│                                                 │
│  Type: A                                        │
│  Name: @                                        │
│  Value: 76.76.21.21                             │
│                                                 │
│  Type: CNAME                                    │
│  Name: www                                      │
│  Value: cname.vercel-dns.com                    │
└─────────────────────────────────────────────────┘
```

### 8.2 DNS Provider에서 레코드 설정 (👤 수동 설정)

**예시: Cloudflare / Google Domains / GoDaddy**

**1단계: DNS Provider 접속**
- 도메인 등록 업체 사이트 로그인
- DNS 설정 페이지 이동

**2단계: A 레코드 추가**
```
Type: A
Name: @ (또는 비워두기)
Value: 76.76.21.21
TTL: Auto (또는 3600)
```

**3단계: CNAME 레코드 추가 (www 서브도메인)**
```
Type: CNAME
Name: www
Value: cname.vercel-dns.com
TTL: Auto (또는 3600)
```

**4단계: 저장 및 대기**
- DNS 변경사항 저장
- 전파 대기 (10분 ~ 48시간, 보통 10-30분)

### 8.3 SSL 인증서 확인 (🤖 자동화)

**Vercel Dashboard에서 상태 확인:**

```
┌─────────────────────────────────────────────────┐
│  Domains                                        │
├─────────────────────────────────────────────────┤
│  ⏳ Pending                                     │
│     mhealth.example.com                         │
│     Waiting for DNS propagation...              │
│                                                 │
│  ↓ (10-30분 후)                                 │
│                                                 │
│  ✅ Active                                      │
│     mhealth.example.com                         │
│     SSL Certificate: Valid                      │
└─────────────────────────────────────────────────┘
```

**DNS 전파 확인 (🤖 자동화):**
```bash
# DNS 레코드 확인
nslookup mhealth.example.com

# 출력 예시:
# Name: mhealth.example.com
# Address: 76.76.21.21
```

**SSL 인증서 확인:**
- 브라우저에서 `https://mhealth.example.com` 접속
- 주소창 자물쇠 아이콘 확인
- 인증서 유효성 확인

---

## 📋 배포 프로세스 전체 요약

### 자동화 vs 수동 설정 한눈에 보기

| 단계 | 작업 | 방식 | 소요 시간 |
|------|------|------|-----------|
| **사전 준비** | Vercel CLI 설치 | 🤖 자동화 | 1분 |
| **로그인** | Vercel 계정 인증 | 👤 수동 설정 | 2분 |
| **Step 1** | 프로젝트 준비 | 🤖 자동화 | 5분 |
| **Step 2** | 로컬 테스트 | 🤖 자동화 | 3분 |
| **Step 3** | 첫 배포 실행 | 🤖 자동화 + 👤 수동 응답 | 3분 |
| **Step 4** | **환경 변수 설정** | 👤 **수동 설정 (필수!)** | **10-15분** |
| **Step 5** | 재배포 (환경 변수 적용) | 🤖 자동화 | 2분 |
| **Step 6** | GitHub 연동 (선택) | 👤 수동 설정 + 🤖 자동화 | 5분 |
| **Step 7** | Preview 배포 (선택) | 🤖 자동화 | 자동 |
| **Step 8** | 커스텀 도메인 (선택) | 👤 수동 설정 | 20-30분 |

**총 소요 시간 (필수만):** 약 30분
**총 소요 시간 (전체):** 약 60분

### 필수 수동 설정 체크리스트

반드시 사람이 직접 해야 하는 작업:

#### ✅ Step 0: Vercel 로그인
- [ ] `vercel login` 실행
- [ ] 이메일 선택
- [ ] 이메일 주소 입력
- [ ] 받은 이메일에서 "Verify" 클릭

#### ✅ Step 3: CLI 대화형 설정
- [ ] **현재 디렉토리 확인**: `pwd`로 `frontend/web`에 있는지 확인
- [ ] **package.json 존재 확인**: `ls package.json`
- [ ] 프로젝트 설정: `Y` 입력
- [ ] 개인 계정 선택: Enter
- [ ] 새 프로젝트: `N` 입력
- [ ] 프로젝트 이름: `your-project-name` 입력
- [ ] **코드 디렉토리 (중요!)**: `./` 입력 (Enter만 누름)
- [ ] 빌드 설정: `N` 입력

#### ✅ Step 4: 환경 변수 설정 (가장 중요!)
- [ ] Vercel Dashboard 접속
- [ ] 프로젝트 선택
- [ ] Settings > Environment Variables
- [ ] **각 환경 변수 개별 추가** (8개):
  - [ ] `NEXT_PUBLIC_FIREBASE_API_KEY`
  - [ ] `NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN`
  - [ ] `NEXT_PUBLIC_FIREBASE_PROJECT_ID`
  - [ ] `NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET`
  - [ ] `NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID`
  - [ ] `NEXT_PUBLIC_FIREBASE_APP_ID`
  - [ ] `NEXT_PUBLIC_API_URL` (선택)
  - [ ] `NEXT_PUBLIC_FUNCTIONS_URL` (선택)
- [ ] **각 변수마다 Environment 3개 체크**
- [ ] **각 변수마다 Save 클릭**

#### ✅ Step 5: 배포 확인
- [ ] Production URL 접속
- [ ] 페이지 정상 로드 확인
- [ ] Firebase 로그인 테스트
- [ ] 콘솔 에러 없는지 확인

### 선택 수동 설정

#### 🔄 Step 6: GitHub 연동 (권장)
- [ ] Vercel Dashboard > Settings > Git
- [ ] "Connect Git Repository" 클릭
- [ ] GitHub 선택 및 로그인
- [ ] Repository 선택
- [ ] Root Directory 설정: `frontend/web`

#### 🌐 Step 8: 커스텀 도메인 (선택)
- [ ] Vercel Dashboard > Settings > Domains
- [ ] "Add Domain" 클릭
- [ ] 도메인 입력
- [ ] DNS Provider에서 A/CNAME 레코드 추가
- [ ] DNS 전파 대기 (10-30분)

### 자동화되는 작업들

다음 작업들은 CLI 명령어 한 줄로 자동 처리됩니다:

- ✅ 의존성 설치 (`npm install`)
- ✅ 프로젝트 빌드 (`npm run build`)
- ✅ 빌드 파일 업로드
- ✅ CDN 배포
- ✅ HTTPS 인증서 발급
- ✅ Production URL 생성
- ✅ Git push 시 자동 재배포 (GitHub 연동 후)
- ✅ Preview URL 생성 (브랜치별)

---

## ⚠️ 주의사항 및 자주 하는 실수

### 1. 환경 변수 관련 실수

**❌ 실수 1: 환경 변수를 추가했지만 재배포하지 않음**
```
문제: 환경 변수를 추가했는데도 앱이 작동하지 않음
해결: vercel --prod 명령어로 재배포 필수!
```

**❌ 실수 2: Environment 체크박스를 누락**
```
문제: Production에만 체크하고 Preview는 안 함
결과: Preview 배포가 작동하지 않음
해결: Production, Preview, Development 3개 모두 체크
```

**❌ 실수 3: NEXT_PUBLIC_ 접두사 누락**
```
문제: FIREBASE_API_KEY로 설정 (접두사 없음)
결과: 클라이언트에서 undefined
해결: NEXT_PUBLIC_FIREBASE_API_KEY로 수정
```

**❌ 실수 4: Value에 따옴표 포함**
```
❌ 잘못된 예: "AIzaSyD..." (따옴표 포함)
✅ 올바른 예: AIzaSyD... (따옴표 없이 값만)
```

### 2. 배포 관련 실수

**❌ 실수 5: 잘못된 디렉토리에서 배포 명령어 실행** 🚨 **가장 흔한 실수!**
```
문제: 프로젝트 루트에서 vercel 명령어 실행
결과: "Could not find package.json" 에러 또는 빌드 실패

❌ 잘못된 예:
$ pwd
/Users/yourname/senior_mhealth_lecture  ← 프로젝트 루트
$ vercel  ← 여기서 실행하면 실패!

✅ 올바른 예:
$ cd frontend/web  ← 반드시 이동
$ pwd
/Users/yourname/senior_mhealth_lecture/frontend/web
$ vercel  ← 여기서 실행!
```

**해결 방법:**
```bash
# 항상 현재 위치 확인
pwd

# frontend/web로 이동
cd frontend/web

# package.json 확인
ls package.json  # 파일이 보여야 함

# 그 다음 배포
vercel
```

**❌ 실수 6: CLI 질문 5번에서 잘못된 경로 입력**
```
상황: "In which directory is your code located?" 질문

❌ 잘못된 답변:
? In which directory is your code located? frontend/web
→ 이미 frontend/web에 있는데 또 입력하면 틀림!
→ Vercel이 frontend/web/frontend/web을 찾으려고 함

✅ 올바른 답변:
? In which directory is your code located? ./
→ 현재 디렉토리(frontend/web)가 맞다는 의미
```

**❌ 실수 7: .vercel 폴더를 Git에 커밋**
```
문제: .vercel 폴더가 Git에 추적됨
해결: .gitignore에 .vercel 추가
```

**❌ 실수 8: GitHub 연동 시 Root Directory 설정 오류** 🚨 **두 번째로 흔한 실수!**
```
GitHub 연동 시 Root Directory 입력란:

❌ 잘못된 예: /frontend/web (맨 앞에 / 있음)
❌ 잘못된 예: ./frontend/web (. 있음)
❌ 잘못된 예: web (상위 폴더 누락)
❌ 잘못된 예: 비워둠 (입력 안 함)
✅ 올바른 예: frontend/web

결과:
- 잘못 입력 시 "Error: Cannot find module 'next'"
- 빌드 로그에 "package.json not found"
```

**해결 방법:**
```
1. Vercel Dashboard > Settings > Git > Root Directory
2. 정확히 입력: frontend/web (앞뒤 공백 없이)
3. Save 클릭
4. 다시 배포 시도
```

**❌ 실수 9: 빌드 에러를 무시하고 배포**
```
문제: 로컬에서 npm run build 실패했는데 배포 시도
결과: Vercel 배포 실패
해결: 로컬 빌드 성공 확인 후 배포
```

### 3. 확인 방법

**환경 변수가 제대로 적용되었는지 확인:**
```javascript
// 브라우저 콘솔에서 실행
console.log({
  apiKey: process.env.NEXT_PUBLIC_FIREBASE_API_KEY,
  projectId: process.env.NEXT_PUBLIC_FIREBASE_PROJECT_ID,
})

// ✅ 정상: 실제 값이 출력됨
// ❌ 오류: undefined가 출력됨 → 환경 변수 재확인
```

**배포 상태 확인:**
```bash
# Vercel CLI로 현재 프로젝트 정보 확인
vercel ls

# 최근 배포 목록 확인
vercel inspect
```

---

## Step 9: 모니터링 및 분석 (👤 수동 설정 - 선택사항)

### 6.1 Vercel Analytics 설정 👤

1. Dashboard > Analytics 탭
2. "Enable Analytics" 클릭
3. 스크립트 자동 삽입됨

### 6.2 Web Vitals 모니터링 🤖

```javascript
// pages/_app.js에 추가
export function reportWebVitals(metric) {
  // Vercel Analytics로 자동 전송
  console.log(metric);

  // 커스텀 모니터링 추가 가능
  if (metric.label === 'web-vital') {
    // Google Analytics나 다른 서비스로 전송
    gtag('event', metric.name, {
      value: Math.round(metric.value),
      metric_id: metric.id,
      metric_value: metric.value,
      metric_delta: metric.delta,
    });
  }
}
```

### 6.3 에러 모니터링 🤖

```bash
# Sentry 통합 (선택사항)
npm install @sentry/nextjs

# sentry.client.config.js
cat > sentry.client.config.js << 'EOF'
import * as Sentry from '@sentry/nextjs';

Sentry.init({
  dsn: process.env.NEXT_PUBLIC_SENTRY_DSN,
  environment: process.env.NODE_ENV,
  tracesSampleRate: 1.0,
});
EOF
```

---

## 🔧 트러블슈팅

### 빌드 관련 문제

#### 빌드 실패
```bash
# 문제: "Module not found"
# 해결: 의존성 확인
npm install
npm run build

# 문제: "Build exceeded maximum size"
# 해결: 번들 최적화
npm run analyze
# 불필요한 의존성 제거
```

#### 환경 변수 문제
```bash
# 문제: "undefined environment variable"
# 해결: NEXT_PUBLIC_ 접두사 확인
# 클라이언트에서 사용하는 변수는 NEXT_PUBLIC_ 필수

# 재배포 필요
vercel --prod --force
```

### 401 Unauthorized 에러

#### Deployment Protection 해제 방법
```
1. Vercel Dashboard 접속
2. Project Settings > Deployment Protection
3. "Vercel Authentication" OFF로 변경
4. Standard Protection 선택
5. Save 클릭
```

### 성능 관련 문제

#### 느린 초기 로딩
```javascript
// Dynamic Import 사용
const HeavyComponent = dynamic(
  () => import('../components/HeavyComponent'),
  {
    loading: () => <p>Loading...</p>,
    ssr: false
  }
);

// Image 최적화
import Image from 'next/image';

<Image
  src="/hero.jpg"
  width={1200}
  height={600}
  priority
  alt="Hero"
/>
```

---

## 💰 비용 최적화

### Vercel 무료 티어
- 월 100GB 대역폭
- 무제한 배포
- 자동 HTTPS
- 3명 팀 멤버

### 비용 절감 팁

```javascript
// 1. Static Generation 우선 사용
export async function getStaticProps() {
  // 빌드 시점에 데이터 페칭
  return {
    props: { data },
    revalidate: 3600, // ISR: 1시간마다 재생성
  };
}

// 2. 이미지 최적화
// next.config.js
module.exports = {
  images: {
    domains: ['firebasestorage.googleapis.com'],
    formats: ['image/avif', 'image/webp'],
  },
};

// 3. Edge Functions 활용
export const config = {
  runtime: 'edge', // Node.js 대신 Edge Runtime
};
```

---

## ✅ 완료 체크리스트

- [ ] Next.js 프로젝트 준비
- [ ] 환경 변수 설정
- [ ] Firebase 통합
- [ ] 로컬 개발 테스트
- [ ] Vercel CLI 배포
- [ ] Dashboard 환경 변수 설정
- [ ] 커스텀 도메인 설정
- [ ] Preview Deployments 테스트
- [ ] Analytics 설정
- [ ] 성능 최적화 적용

---

## 🎯 학습 성과

이번 주차를 완료하면:
- ✅ Vercel 플랫폼 이해
- ✅ Next.js 배포 프로세스
- ✅ 환경 변수 관리 능력
- ✅ Preview Deployments 활용
- ✅ 커스텀 도메인 설정
- ✅ 웹 성능 모니터링

---

## 📚 다음 주차 예고

**Week 7: 모바일 앱 배포**
- Flutter APK 빌드
- 앱 서명 및 릴리스
- 디바이스 설치 방법
- Google Play Console 준비

---

## 🔗 참고 자료

- [Vercel 문서](https://vercel.com/docs)
- [Next.js 문서](https://nextjs.org/docs)
- [Vercel CLI](https://vercel.com/docs/cli)
- [Web Vitals](https://web.dev/vitals/)
