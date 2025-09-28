# Week 8: 통합 테스트 및 프로덕션 최적화

## 🎯 학습 목표
- 전체 시스템 통합 테스트 수행
- 성능 모니터링 및 최적화
- 프로덕션 환경 설정 및 배포
- CI/CD 파이프라인 구축 기초
- 비용 관리 및 스케일링 전략

## 📋 사전 준비
- [ ] Week 3-7 모든 서비스 배포 완료
- [ ] GCP, Firebase, Vercel 계정 활성화
- [ ] 모바일 앱 빌드 성공
- [ ] 테스트 기기 또는 에뮬레이터 준비

---

## 🏗️ 시스템 아키텍처 검증

### 전체 아키텍처 구성
```
┌─────────────────┐     ┌─────────────────┐
│  Mobile App     │────▶│  Web App        │
│  (Flutter)      │     │  (Next.js)      │
└────────┬────────┘     └────────┬────────┘
         │                       │
         ▼                       ▼
┌─────────────────────────────────────────┐
│         Cloud Functions API             │
│         (Express.js)                    │
└─────────┬───────────────────┬───────────┘
          │                   │
          ▼                   ▼
┌──────────────────┐ ┌──────────────────┐
│  Cloud Run       │ │  Firestore       │
│  AI Service      │ │  Database        │
└──────────────────┘ └──────────────────┘
```

### 서비스 체크리스트
- [ ] Cloud Run AI Service (Week 4)
- [ ] Cloud Run API Service (Week 4)
- [ ] Cloud Functions (Week 5)
- [ ] Firestore Database (Week 5)
- [ ] Vercel Web App (Week 6)
- [ ] Mobile App (Week 7)

---

## Step 1: 통합 테스트 환경 준비

### 1-1. 서비스 URL 확인 🤖

```bash
# 프로젝트 설정 확인
export PROJECT_ID=senior-mhealth-lee
gcloud config set project $PROJECT_ID

# Cloud Run 서비스 URL 가져오기
export AI_SERVICE_URL=$(gcloud run services describe senior-mhealth-ai \
  --region asia-northeast3 --format 'value(status.url)')

export API_SERVICE_URL=$(gcloud run services describe senior-mhealth-api \
  --region asia-northeast3 --format 'value(status.url)')

# Cloud Functions URL
export FUNCTIONS_URL=https://asia-northeast3-$PROJECT_ID.cloudfunctions.net/api

# Vercel Web App URL
export WEB_APP_URL=https://senior-mhealth-lee.vercel.app

echo "=== 서비스 URL 목록 ==="
echo "AI Service: $AI_SERVICE_URL"
echo "API Service: $API_SERVICE_URL"
echo "Functions: $FUNCTIONS_URL"
echo "Web App: $WEB_APP_URL"
```

### 1-2. 테스트 데이터 준비 🤖

`test-data.json` 생성:

```json
{
  "testUser": {
    "email": "test@example.com",
    "password": "Test123!@#",
    "name": "테스트 사용자",
    "age": 75,
    "phone": "010-1234-5678"
  },
  "testHealthData": {
    "bloodPressure": {
      "type": "bloodPressure",
      "value": { "systolic": 120, "diastolic": 80 },
      "notes": "정상 혈압"
    },
    "heartRate": {
      "type": "heartRate",
      "value": 72,
      "notes": "안정시 심박수"
    }
  },
  "testAIInput": {
    "text": "오늘 아침에 일어났을 때 어지러움을 느꼈습니다. 혈압약을 먹어야 할까요?",
    "analysisType": "health"
  }
}
```

### 1-3. 테스트 스크립트 설정 🤖

`integration-test.sh` 생성:

```bash
#!/bin/bash

# 색상 설정
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}🧪 Senior MHealth 통합 테스트 시작${NC}"
echo "=================================="

# 테스트 결과 카운터
PASSED=0
FAILED=0

# 테스트 함수
run_test() {
    local test_name=$1
    local command=$2

    echo -n "Testing: $test_name ... "

    if eval $command > /dev/null 2>&1; then
        echo -e "${GREEN}PASSED${NC}"
        ((PASSED++))
    else
        echo -e "${RED}FAILED${NC}"
        ((FAILED++))
    fi
}

# 1. Cloud Run 헬스체크
run_test "AI Service Health" \
  "curl -s $AI_SERVICE_URL/health | grep healthy"

run_test "API Service Health" \
  "curl -s $API_SERVICE_URL/health | grep healthy"

# 2. Cloud Functions 헬스체크
run_test "Functions Health" \
  "curl -s $FUNCTIONS_URL/health | grep healthy"

# 3. Vercel 웹앱 확인
run_test "Web App Loading" \
  "curl -s $WEB_APP_URL | grep '<title>'"

# 결과 출력
echo "=================================="
echo -e "Results: ${GREEN}$PASSED passed${NC}, ${RED}$FAILED failed${NC}"

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}✅ 모든 테스트 통과!${NC}"
    exit 0
else
    echo -e "${RED}❌ 일부 테스트 실패${NC}"
    exit 1
fi
```

---

## Step 2: End-to-End (E2E) 테스트

### 2-1. 사용자 시나리오 테스트 👤

**시나리오 1: 신규 사용자 가입 및 설정**

1. **웹앱에서 회원가입**:
   - https://senior-mhealth-lee.vercel.app 접속
   - "회원가입" 클릭
   - 이메일, 비밀번호, 기본 정보 입력
   - 이메일 인증 완료

2. **프로필 설정**:
   - 나이, 건강 정보 입력
   - 복약 정보 추가
   - 알림 설정 활성화

3. **Firebase 확인**:
   ```bash
   # Firestore에서 사용자 데이터 확인
   firebase firestore:get users/[USER_ID]
   ```

**시나리오 2: 건강 데이터 입력 및 AI 분석**

1. **모바일 앱에서 건강 데이터 입력**:
   - 혈압 측정값 입력
   - 심박수 입력
   - 증상 메모 작성

2. **AI 분석 요청**:
   ```bash
   # API 테스트
   curl -X POST $FUNCTIONS_URL/api/ai/analyze/text \
     -H "Content-Type: application/json" \
     -H "Authorization: Bearer [TOKEN]" \
     -d '{
       "text": "어지러움이 있고 두통이 있습니다",
       "analysisType": "health"
     }'
   ```

3. **결과 확인**:
   - 분석 결과 표시
   - Firestore 저장 확인
   - 알림 수신 확인

### 2-2. API 통합 테스트 🤖

`api-test.js` 생성:

```javascript
const axios = require('axios');
const assert = require('assert');

// 테스트 설정
const BASE_URL = process.env.FUNCTIONS_URL;
const AI_SERVICE_URL = process.env.AI_SERVICE_URL;

// 테스트 스위트
describe('API Integration Tests', () => {
  let authToken;
  let userId;

  // 1. 사용자 등록 테스트
  it('should register a new user', async () => {
    const response = await axios.post(`${BASE_URL}/api/users/register`, {
      email: `test${Date.now()}@example.com`,
      password: 'Test123!@#',
      name: '테스트 사용자',
      age: 75
    });

    assert.equal(response.status, 201);
    assert.ok(response.data.userId);
    userId = response.data.userId;
  });

  // 2. 로그인 테스트
  it('should login user', async () => {
    // Firebase Auth 로그인 구현
    // authToken 획득
  });

  // 3. 건강 데이터 CRUD 테스트
  it('should create health record', async () => {
    const response = await axios.post(
      `${BASE_URL}/api/health/records`,
      {
        type: 'bloodPressure',
        value: { systolic: 120, diastolic: 80 },
        notes: '정상'
      },
      {
        headers: { Authorization: `Bearer ${authToken}` }
      }
    );

    assert.equal(response.status, 201);
    assert.ok(response.data.recordId);
  });

  // 4. AI 서비스 연동 테스트
  it('should analyze text with AI', async () => {
    const response = await axios.post(
      `${BASE_URL}/api/ai/analyze/text`,
      {
        text: '혈압이 높은 것 같습니다',
        analysisType: 'health'
      },
      {
        headers: { Authorization: `Bearer ${authToken}` }
      }
    );

    assert.equal(response.status, 200);
    assert.ok(response.data.result);
  });
});

// 테스트 실행
npm test
```

### 2-3. 부하 테스트 🤖

```bash
# autocannon 설치
npm install -g autocannon

# Cloud Functions 부하 테스트
autocannon \
  -c 100 \
  -d 30 \
  -p 10 \
  $FUNCTIONS_URL/health

# 예상 결과:
# - Req/Sec: 500+
# - Latency: <500ms (p99)
# - Errors: 0%
```

---

## Step 3: 성능 모니터링 설정

### 3-1. Google Cloud Monitoring 설정 🤖

```bash
# 모니터링 대시보드 생성
gcloud monitoring dashboards create \
  --config-from-file=monitoring-dashboard.json

# 알림 정책 설정
gcloud alpha monitoring policies create \
  --notification-channels=[CHANNEL_ID] \
  --display-name="High Error Rate Alert" \
  --condition="rate(compute.googleapis.com/instance/cpu/utilization) > 0.8"
```

`monitoring-dashboard.json`:

```json
{
  "displayName": "Senior MHealth Dashboard",
  "mosaicLayout": {
    "columns": 12,
    "tiles": [
      {
        "widget": {
          "title": "Cloud Run Request Count",
          "xyChart": {
            "dataSets": [{
              "timeSeriesQuery": {
                "timeSeriesFilter": {
                  "filter": "resource.type=\"cloud_run_revision\""
                }
              }
            }]
          }
        }
      },
      {
        "widget": {
          "title": "Firestore Operations",
          "scorecard": {
            "timeSeriesQuery": {
              "timeSeriesFilter": {
                "filter": "resource.type=\"firestore_database\""
              }
            }
          }
        }
      }
    ]
  }
}
```

### 3-2. Firebase Performance Monitoring 👤

**웹앱 설정**:

```javascript
// frontend/web/lib/firebase.js
import { getPerformance } from 'firebase/performance';

// Performance Monitoring 초기화
const perf = getPerformance(app);

// 커스텀 트레이스
const trace = perf.trace('api_call');
trace.start();

// API 호출
const response = await fetch('/api/data');

trace.stop();
```

**모바일 앱 설정**:

```dart
// frontend/mobile/lib/main.dart
import 'package:firebase_performance/firebase_performance.dart';

void main() async {
  // Performance Monitoring 활성화
  FirebasePerformance performance = FirebasePerformance.instance;

  // 커스텀 트레이스
  Trace trace = performance.newTrace('api_call');
  await trace.start();

  // API 호출
  final response = await http.get(apiUrl);

  await trace.stop();
}
```

### 3-3. Lighthouse CI 설정 🤖

`.github/workflows/lighthouse.yml`:

```yaml
name: Lighthouse CI
on: [push]

jobs:
  lighthouse:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
      - run: npm install -g @lhci/cli
      - run: lhci autorun --config=lighthouserc.json
```

`lighthouserc.json`:

```json
{
  "ci": {
    "collect": {
      "url": ["https://senior-mhealth-lee.vercel.app/"],
      "numberOfRuns": 3
    },
    "assert": {
      "assertions": {
        "categories:performance": ["warn", {"minScore": 0.75}],
        "categories:accessibility": ["error", {"minScore": 0.9}],
        "categories:seo": ["warn", {"minScore": 0.9}]
      }
    },
    "upload": {
      "target": "temporary-public-storage"
    }
  }
}
```

---

## Step 4: 프로덕션 최적화

### 4-1. 코드 최적화 🤖

**Cloud Functions 최적화**:

```javascript
// backend/functions/src/middleware/cache.js
const NodeCache = require('node-cache');
const cache = new NodeCache({ stdTTL: 600 });

const cacheMiddleware = (req, res, next) => {
  const key = req.originalUrl;
  const cachedResponse = cache.get(key);

  if (cachedResponse) {
    return res.json(cachedResponse);
  }

  res.originalJson = res.json;
  res.json = (body) => {
    cache.set(key, body);
    res.originalJson(body);
  };

  next();
};

// 사용
app.get('/api/data', cacheMiddleware, handler);
```

**Next.js 최적화**:

```javascript
// next.config.js
module.exports = {
  images: {
    domains: ['firebasestorage.googleapis.com'],
    formats: ['image/avif', 'image/webp']
  },
  compress: true,
  poweredByHeader: false,
  reactStrictMode: true,
  swcMinify: true,

  // 정적 페이지 생성
  experimental: {
    optimizeFonts: true,
    optimizeImages: true
  }
};
```

### 4-2. 데이터베이스 최적화 🤖

**Firestore 인덱스 최적화**:

```json
// firestore.indexes.json
{
  "indexes": [
    {
      "collectionGroup": "healthRecords",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "userId", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    }
  ],
  "fieldOverrides": [
    {
      "collectionGroup": "users",
      "fieldPath": "email",
      "indexes": [
        { "order": "ASCENDING", "queryScope": "COLLECTION" },
        { "arrayConfig": "CONTAINS", "queryScope": "COLLECTION_GROUP" }
      ]
    }
  ]
}
```

**쿼리 최적화**:

```javascript
// 비효율적
const allRecords = await db.collection('healthRecords').get();
const userRecords = allRecords.docs.filter(doc =>
  doc.data().userId === userId
);

// 효율적
const userRecords = await db.collection('healthRecords')
  .where('userId', '==', userId)
  .orderBy('createdAt', 'desc')
  .limit(10)
  .get();
```

### 4-3. 이미지 및 에셋 최적화 🤖

```bash
# 이미지 최적화 도구 설치
npm install -g imagemin-cli

# 이미지 압축
imagemin public/images/* --out-dir=public/images/optimized

# WebP 변환
for file in public/images/*.{jpg,png}; do
  cwebp -q 80 "$file" -o "${file%.*}.webp"
done
```

---

## Step 5: CI/CD 파이프라인

### 5-1. GitHub Actions 설정 🤖

`.github/workflows/deploy.yml`:

```yaml
name: Deploy Pipeline

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'

      - name: Install dependencies
        run: |
          npm ci
          cd backend/functions && npm ci
          cd ../../frontend/web && npm ci

      - name: Run tests
        run: |
          npm test
          cd backend/functions && npm test

      - name: Check code quality
        run: |
          npm run lint
          npm run type-check

  deploy-functions:
    needs: test
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Setup Firebase
        uses: w9jds/firebase-action@master
        with:
          args: deploy --only functions
        env:
          FIREBASE_TOKEN: ${{ secrets.FIREBASE_TOKEN }}

  deploy-web:
    needs: test
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Deploy to Vercel
        uses: amondnet/vercel-action@v20
        with:
          vercel-token: ${{ secrets.VERCEL_TOKEN }}
          vercel-org-id: ${{ secrets.VERCEL_ORG_ID }}
          vercel-project-id: ${{ secrets.VERCEL_PROJECT_ID }}
```

### 5-2. 자동 테스트 설정 🤖

`package.json` 스크립트:

```json
{
  "scripts": {
    "test": "mocha test/**/*.test.js",
    "test:coverage": "nyc npm test",
    "test:integration": "mocha test/integration/**/*.js",
    "test:e2e": "cypress run",
    "lint": "eslint .",
    "type-check": "tsc --noEmit",
    "pre-commit": "npm run lint && npm run type-check && npm test"
  }
}
```

---

## Step 6: 비용 관리

### 6-1. 리소스 사용량 모니터링 🤖

```bash
# 현재 월 비용 확인
gcloud billing accounts list
gcloud alpha billing budgets list

# Cloud Run 비용 확인
gcloud run services list --format="table(
  SERVICE,
  REGION,
  URL,
  LAST_DEPLOYED_BY,
  LAST_DEPLOYED_AT
)"

# Firestore 사용량 확인
firebase firestore:databases:list
```

### 6-2. 비용 최적화 전략 👤

**Cloud Run 최적화**:
```yaml
# 최소 인스턴스 0으로 설정 (콜드 스타트 허용)
gcloud run services update senior-mhealth-ai \
  --min-instances=0 \
  --max-instances=3 \
  --concurrency=80 \
  --cpu=1 \
  --memory=512Mi
```

**Firestore 최적화**:
- 불필요한 읽기 줄이기 (캐싱 활용)
- 배치 쓰기 사용
- 적절한 인덱스 설정
- 큰 문서 분할

**Functions 최적화**:
```javascript
// 콜드 스타트 최소화
const functions = require('firebase-functions');

// 메모리 및 타임아웃 최적화
exports.api = functions
  .region('asia-northeast3')
  .runWith({
    timeoutSeconds: 60,
    memory: '256MB',
    minInstances: 0,
    maxInstances: 10
  })
  .https.onRequest(app);
```

### 6-3. 예산 알림 설정 👤

```bash
# 예산 생성
gcloud billing budgets create \
  --billing-account=BILLING_ACCOUNT_ID \
  --display-name="Senior MHealth Monthly Budget" \
  --budget-amount=50 \
  --threshold-rule=percent=50,basis=current-spend \
  --threshold-rule=percent=90,basis=current-spend \
  --threshold-rule=percent=100,basis=current-spend
```

---

## Step 7: 보안 강화

### 7-1. 보안 체크리스트 👤

- [ ] API 키 환경 변수화
- [ ] HTTPS 강제 사용
- [ ] CORS 설정 최소화
- [ ] SQL Injection 방지
- [ ] XSS 방지
- [ ] Rate Limiting 설정
- [ ] 민감 정보 로깅 금지

### 7-2. 보안 설정 구현 🤖

**API 보안**:
```javascript
// Rate Limiting
const rateLimit = require('express-rate-limit');

const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15분
  max: 100, // 최대 요청 수
  message: 'Too many requests'
});

app.use('/api/', limiter);

// Helmet으로 보안 헤더 설정
const helmet = require('helmet');
app.use(helmet());

// Input Validation
const { body, validationResult } = require('express-validator');

app.post('/api/user',
  body('email').isEmail().normalizeEmail(),
  body('age').isInt({ min: 0, max: 120 }),
  (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }
  }
);
```

---

## 🔧 트러블슈팅

### 통합 문제

#### 1. 서비스 간 통신 실패
```bash
# CORS 에러
# 해결: Cloud Run 서비스에 CORS 헤더 추가
app.use(cors({
  origin: ['https://senior-mhealth-lee.vercel.app'],
  credentials: true
}));

# 타임아웃 에러
# 해결: 타임아웃 설정 증가
gcloud run services update SERVICE_NAME --timeout=300
```

#### 2. 인증 토큰 문제
```javascript
// Firebase ID Token 갱신
firebase.auth().currentUser.getIdToken(true)
  .then(token => {
    // 새 토큰 사용
  });
```

### 성능 문제

#### 1. 느린 응답 시간
```bash
# Cloud Run 콜드 스타트
# 해결: 최소 인스턴스 설정
gcloud run services update SERVICE_NAME --min-instances=1

# Firestore 느린 쿼리
# 해결: 인덱스 생성 및 쿼리 최적화
```

#### 2. 높은 메모리 사용
```javascript
// 메모리 누수 방지
// 이벤트 리스너 정리
componentWillUnmount() {
  this.unsubscribe();
}

// 캐시 크기 제한
const cache = new NodeCache({
  stdTTL: 600,
  maxKeys: 1000
});
```

---

## ✅ 완료 체크리스트

### 통합 테스트
- [ ] 모든 서비스 헬스체크 통과
- [ ] E2E 시나리오 테스트 완료
- [ ] API 통합 테스트 성공
- [ ] 부하 테스트 목표 달성

### 모니터링
- [ ] Cloud Monitoring 대시보드 설정
- [ ] Firebase Performance 설정
- [ ] 알림 정책 구성
- [ ] Lighthouse CI 설정

### 최적화
- [ ] 코드 최적화 적용
- [ ] 데이터베이스 인덱스 최적화
- [ ] 이미지/에셋 압축
- [ ] 캐싱 전략 구현

### CI/CD
- [ ] GitHub Actions 설정
- [ ] 자동 테스트 구성
- [ ] 자동 배포 파이프라인

### 보안
- [ ] API 키 보안 관리
- [ ] Rate Limiting 설정
- [ ] 입력 검증 구현
- [ ] 보안 헤더 설정

---

## 💡 핵심 개념 정리

### 테스트 피라미드
```
         /\
        /E2E\       적음/느림/비쌈
       /------\
      /통합테스트\   중간
     /----------\
    / 단위 테스트  \  많음/빠름/저렴
   /--------------\
```

### 성능 메트릭
- **TTFB** (Time to First Byte): <200ms
- **FCP** (First Contentful Paint): <1.8s
- **LCP** (Largest Contentful Paint): <2.5s
- **TTI** (Time to Interactive): <3.8s
- **CLS** (Cumulative Layout Shift): <0.1

### 모니터링 레벨
1. **인프라**: CPU, 메모리, 네트워크
2. **애플리케이션**: 에러율, 응답시간
3. **비즈니스**: 사용자 수, 전환율

---

## 🎯 프로젝트 완성

### 완성된 시스템
1. **클라우드 인프라**: GCP + Firebase 기반
2. **백엔드 서비스**: Cloud Run + Functions
3. **프론트엔드**: Next.js 웹 + Flutter 모바일
4. **AI 통합**: Gemini API 활용
5. **모니터링**: 실시간 성능 추적
6. **CI/CD**: 자동화된 배포

### 학습 성과
- ✅ 풀스택 개발 경험
- ✅ 클라우드 네이티브 아키텍처
- ✅ 마이크로서비스 구현
- ✅ DevOps 실무 경험
- ✅ AI 서비스 통합

---

## 📚 참고 자료

### 공식 문서
- [Google Cloud Monitoring](https://cloud.google.com/monitoring/docs)
- [Firebase Performance](https://firebase.google.com/docs/perf-mon)
- [GitHub Actions](https://docs.github.com/en/actions)
- [Lighthouse CI](https://github.com/GoogleChrome/lighthouse-ci)

### 추가 학습
- [SRE Book](https://sre.google/sre-book/table-of-contents/)
- [Web Vitals](https://web.dev/vitals/)
- [12 Factor App](https://12factor.net/)
- [Cloud Native Patterns](https://www.cloudnativepatterns.org/)

---

## 🎉 축하합니다!

8주간의 여정을 통해 완전한 Senior MHealth 시스템을 구축했습니다!

### 다음 단계 제안
1. **기능 확장**: 음성 인식, 비디오 상담
2. **ML 모델**: 맞춤형 건강 예측 모델
3. **국제화**: 다국어 지원
4. **의료 기관 연동**: HL7 FHIR 표준
5. **웨어러블 연동**: Fitbit, Apple Watch

### 포트폴리오 활용
- GitHub에 전체 코드 업로드
- README 작성 및 문서화
- 데모 영상 제작
- 기술 블로그 작성

---

**Senior MHealth 프로젝트 완료! 🚀**