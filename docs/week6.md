# Week 6: Vercel 배포 - Next.js 웹 애플리케이션

## 🎯 학습 목표

Next.js 웹 애플리케이션을 Vercel 플랫폼에 배포하고, 환경 변수 관리와 커스텀 도메인 설정을 학습합니다.

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