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

### 🚀 4. Backend 서비스 배포 (선택사항, Week 4-5)

- [ ] **Cloud Functions 배포 완료** (선택사항)
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
   https://senior-mhealth.vercel.app

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

### 사전 준비 확인 🤖

```bash
# Node.js 버전 확인 (18 이상)
node --version

# npm 버전 확인
npm --version

# Vercel CLI 설치
npm install -g vercel

# Vercel 로그인
vercel login
```

---

## Step 1: Next.js 프로젝트 준비

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
NEXT_PUBLIC_FIREBASE_PROJECT_ID=senior-mhealth-lee
NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET=${FIREBASE_STORAGE_BUCKET}
NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID=${FIREBASE_MESSAGING_SENDER_ID}
NEXT_PUBLIC_FIREBASE_APP_ID=${FIREBASE_APP_ID}

# API URLs
NEXT_PUBLIC_API_URL=https://senior-mhealth-api-xxxxx-an.a.run.app
NEXT_PUBLIC_FUNCTIONS_URL=https://asia-northeast3-senior-mhealth-lee.cloudfunctions.net/api

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

## Step 3: Vercel 배포 (수동)

### 3.1 Vercel 계정 및 프로젝트 설정 👤

1. [Vercel Dashboard](https://vercel.com/dashboard) 접속
2. "New Project" 클릭
3. "Import Git Repository" 선택
4. GitHub 연동 및 저장소 선택

### 3.2 Vercel CLI로 배포 🤖

```bash
# Vercel CLI로 배포
vercel

# 프롬프트 응답:
# ? Set up and deploy "~/senior_mhealth_lecture/frontend"? [Y/n] Y
# ? Which scope do you want to deploy to? Your Account
# ? Link to existing project? [y/N] N
# ? What's your project's name? senior-mhealth
# ? In which directory is your code located? ./
# ? Want to override the settings? [y/N] N

# 배포 완료 후 URL 확인
# https://senior-mhealth-xxxxx.vercel.app
```

### 3.3 환경 변수 설정 (Vercel Dashboard) 👤

1. Vercel Dashboard > Project Settings
2. Environment Variables 메뉴
3. 각 환경 변수 추가:
   - Name: `NEXT_PUBLIC_FIREBASE_API_KEY`
   - Value: 실제 값 입력
   - Environment: Production, Preview, Development
4. 모든 환경 변수 추가 완료

### 3.4 재배포 트리거 🤖

```bash
# 환경 변수 적용을 위한 재배포
vercel --prod

# 또는 Git push로 자동 배포
git add .
git commit -m "Add environment variables"
git push origin main
```

---

## Step 4: 커스텀 도메인 설정

### 4.1 도메인 추가 (Vercel Dashboard) 👤

1. Project Settings > Domains
2. "Add Domain" 클릭
3. 도메인 입력: `mhealth.example.com`
4. DNS 설정 안내 확인

### 4.2 DNS 설정 🤖

```bash
# DNS 레코드 확인
nslookup mhealth.example.com

# Vercel이 제공하는 DNS 설정:
# Type: A
# Name: @
# Value: 76.76.21.21

# Type: CNAME
# Name: www
# Value: cname.vercel-dns.com
```

### 4.3 SSL 인증서 자동 발급 👤

1. DNS 설정 완료 후 자동으로 SSL 인증서 발급
2. 일반적으로 10-30분 소요
3. Dashboard에서 상태 확인

---

## Step 5: Preview Deployments

### 5.1 브랜치별 자동 배포 🤖

```bash
# 새 기능 브랜치 생성
git checkout -b feature/new-dashboard

# 변경사항 커밋
git add .
git commit -m "Add new dashboard feature"

# 브랜치 푸시 (자동 프리뷰 배포)
git push origin feature/new-dashboard

# Preview URL 생성됨:
# https://senior-mhealth-feature-new-dashboard.vercel.app
```

### 5.2 Pull Request 통합 👤

1. GitHub에서 Pull Request 생성
2. Vercel Bot이 자동으로 Preview URL 댓글 추가
3. 프리뷰에서 테스트 후 머지

---

## Step 6: 모니터링 및 분석

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