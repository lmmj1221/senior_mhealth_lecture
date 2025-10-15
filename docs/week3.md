## 🎯 학습 목표

Google Cloud Platform과 Firebase의 기본 개념을 이해하고, 클라우드 컴퓨팅의 핵심 원리를 학습합니다.

## 📚 핵심 개념

### 1. 클라우드 컴퓨팅 기초

### 클라우드 서비스 모델

- **IaaS** (Infrastructure as a Service): 가상 서버, 스토리지, 네트워크
- **PaaS** (Platform as a Service): 개발 플랫폼, 데이터베이스
- **SaaS** (Software as a Service): 완성된 애플리케이션
- **BaaS** (Backend as a Service): Firebase 같은 백엔드 서비스

### 클라우드 배포 모델

- **Public Cloud**: GCP, AWS, Azure
- **Private Cloud**: 기업 전용 클라우드
- **Hybrid Cloud**: Public + Private 조합
- **Multi-Cloud**: 여러 클라우드 제공업체 활용

### 2. Google Cloud Platform (GCP) 개요

### GCP 핵심 서비스

```
Compute
├── Compute Engine (IaaS, 가상 머신)
├── App Engine (PaaS)
├── Cloud Run (컨테이너 기반 서버리스)
└── Cloud Functions (이벤트 기반 서버리스)

Storage & Database
├── Cloud Storage
├── Firebase Firestore (NoSQL)
--- Firebase storage 
├── Cloud SQL (관계형 DB)
└── BigQuery (데이터 웨어하우스)

AI & ML
├── Vertex AI (통합 ML 플랫폼)
├── Vision API
├── Natural Language API
└── Translation API

```

### GCP 리전과 존

- **리전**: 지리적 위치 (예: asia-northeast3 = 서울)
- **존(Zone)**: 리전 내의 독립된 데이터센터
- **멀티리전**: 여러 리전에 걸친 고가용성

### 3. Firebase 플랫폼

### Firebase = BaaS (Backend as a Service)

모바일과 웹 앱 개발을 위한 Google의 통합 플랫폼

### 핵심 서비스

```
개발 (Develop)
├── Authentication (인증)
├── Firestore (실시간 DB)
├── Storage (파일 저장)
├── Functions (서버리스)
└── Hosting (웹 호스팅)

품질 (Quality)
├── Crashlytics (충돌 보고)
├── Performance (성능 모니터링)
└── Test Lab (자동 테스트)

성장 (Grow)
├── Analytics (분석)
├── Cloud Messaging (푸시 알림)
└── Remote Config (원격 설정)

```

### 4. 프로젝트 구조와 IAM

### GCP 프로젝트 계층

```
Organization (조직)
└── Folders (폴더)
    └── Projects (프로젝트)
        └── Resources (리소스)

```

### IAM (Identity and Access Management)

- **Principal**: 누가 (사용자, 서비스 계정)
- **Role**: 무엇을 (권한 집합)
- **Resource**: 어디에 (프로젝트, 서비스)

### 주요 역할

- **Owner**: 모든 권한 + 결제
- **Editor**: 리소스 생성/수정/삭제
- **Viewer**: 읽기 전용
- **Custom Roles**: 맞춤 권한

### 5. 서버리스 컴퓨팅 상세

### Cloud Functions vs Cloud Run 비교

**Cloud Functions (함수 기반 서버리스)**

```jsx
// 단일 함수 단위 배포
exports.helloWorld = (req, res) => {
  res.send('Hello from Cloud Functions!');
};

```

- **특징**:
    - 단일 함수 단위로 배포
    - 이벤트 트리거 (HTTP, Pub/Sub, Firestore 변경 등)
    - 최대 실행 시간: 9분
    - 자동 확장: 0 → 1000+ 인스턴스
    - 언어: Node.js, Python, Go, Java, .NET 등
- **사용 사례**: Webhook, 데이터 변환, 실시간 파일 처리, 경량 API
- **과금**: 호출 횟수 + 실행 시간 + 메모리 사용량

**Cloud Run (컨테이너 기반 서버리스)**

```docker
# 컨테이너 이미지 배포
FROM node:18
COPY . .
RUN npm install
CMD ["node", "server.js"]
```

- **특징**:
    - Docker 컨테이너 실행
    - 모든 언어/프레임워크 지원
    - 최대 실행 시간: 60분
    - 자동 확장: 0 → 1000 인스턴스
    - HTTP/gRPC 엔드포인트
- **사용 사례**: 마이크로서비스, REST API, 웹 애플리케이션, 배치 처리
- **과금**: 요청 수 + CPU/메모리 사용 시간

### 서버리스의 장점

1. **자동 확장**: 트래픽에 따라 자동 스케일링
2. **비용 효율**: 사용한 만큼만 과금 (0 사용 = 0 비용)
3. **운영 부담 감소**: 서버 관리 불필요
4. **빠른 개발**: 비즈니스 로직에 집중
5. **고가용성**: 자동 장애 복구

### 6. NoSQL vs SQL

### Firestore (NoSQL) 특징

```jsx
// 문서 기반 구조
{
  users: {
    user1: {
      name: "홍길동",
      age: 30,
      hobbies: ["독서", "운동"]
    }
  }
}

```

**장점**:

- 유연한 스키마
- 수평적 확장 용이
- 실시간 동기화

**단점**:

- 복잡한 쿼리 제한
- 트랜잭션 제약

### SQL 데이터베이스

```sql
-- 테이블 기반 구조
CREATE TABLE users (
  id INT PRIMARY KEY,
  name VARCHAR(100),
  age INT
);

```

**장점**:

- 트랜잭션
- 복잡한 조인 쿼리
- 데이터 무결성

**단점**:

- 스키마 변경 어려움
- 수직적 확장 위주

### 7. 보안

### 최소 권한 원칙

- 필요한 최소한의 권한만 부여
- 서비스 계정 세분화
- 정기적인 권한 검토

### API 키 관리

```jsx
// ❌ 하드코딩
const apiKey = "AIzaSyDxxxxx";

// ✅ 환경 변수
const apiKey = process.env.API_KEY;

```

### 보안 규칙 설정

```jsx
// Firestore 보안 규칙
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null
        && request.auth.uid == userId;
    }
  }
}

```

### 8. 개발 워크플로우

### CI/CD with Firebase

```yaml
# GitHub Actions 예시
deploy:
  steps:
    - uses: actions/checkout@v2
    - run: npm ci
    - run: npm test
    - run: firebase deploy --token $FIREBASE_TOKEN

```

### 환경 분리

- **Development**: 개발용 프로젝트
- **Staging**: 테스트용 프로젝트
- **Production**: 실제 서비스용 프로젝트

### 9. 성능 최적화

### Cloud CDN 활용

- 정적 콘텐츠 캐싱
- 글로벌 엣지 로케이션
- 자동 압축 및 최적화

### 데이터베이스 최적화

```jsx
// ❌ N+1 쿼리 문제
users.forEach(user => {
  getPosts(user.id); // N번 쿼리
});

// ✅ 배치 조회
const posts = await db.collectionGroup('posts')
  .where('userId', 'in', userIds)
  .get();

```

## 🏗️ Senior MHealth 프로젝트 아키텍처 선택

### 왜 Cloud Functions를 선택했나?

본 프로젝트에서는 **Cloud Functions**를 주요 백엔드 서비스로 선택했습니다:

1. **Firebase와의 완벽한 통합**
    - Firebase SDK와 네이티브 통합
    - Firestore, Auth, Storage 트리거 지원
    - 단일 CLI로 전체 스택 관리 (`firebase deploy`)
2. **교육적 가치**
    - 서버리스 패러다임 학습
    - 이벤트 기반 아키텍처 이해
    - 최신 클라우드 개발 트렌드
3. **개발 편의성**
    
    ```jsx
    // Firebase Functions - 간단한 구조
    const { onRequest } = require('firebase-functions/v2/https');
    exports.api = onRequest((req, res) => {
      res.send('API Response');
    });
    
    ```
    
4. **비용 효율성**
    - 학생 프로젝트에 충분한 무료 할당량
    - 월 200만 호출, 400,000 GB-초 무료
    - 사용하지 않으면 비용 0원

### Cloud Run은 언제 사용하나?

프로젝트에서 Cloud Run을 보조적으로 사용하는 경우:

- **AI 서비스**: 무거운 ML 모델 실행
- **배치 처리**: 장시간 실행되는 작업
- **레거시 통합**: 기존 컨테이너 애플리케이션

```bash
# Cloud Run 배포 예시 (선택적)
cd backend/ai-service
gcloud run deploy ai-service \\
  --source . \\
  --region asia-northeast3 \\
  --allow-unauthenticated

```

## 🎓 핵심 요약

### 기억해야 할 5가지

1. **클라우드 = 탄력성**: 필요에 따라 확장/축소
2. **서버리스 = 효율성**: 관리 부담 없이 개발
3. **Firebase = 통합 플랫폼**: 모바일/웹 개발 All-in-One
4. **보안 = 기본**: 처음부터 보안 고려
5. **비용 = 모니터링**: 지속적인 비용 관리

### 프로젝트 기술 스택

- **백엔드**: Cloud Functions (서버리스)
- **데이터베이스**: Firestore (NoSQL)
- **인증**: Firebase Authentication
- **AI/ML**: Vertex AI (Gemini API)
- **스토리지**: Cloud Storage
- **호스팅**: Firebase Hosting / Vercel

## 실습

## 🎯 실습 목표

Google Cloud Platform 계정을 생성하고, Firebase 프로젝트를 설정하여 Senior MHealth의 클라우드 인프라를 구축합니다.

## 🔍 작업 구분

- **👤 사용자 직접 작업**: GCP Console에서 수동으로 진행
- **🤖 AI 프롬프트**: AI에게 코드 작성을 요청하여 자동화

---

## Step 1: 개발 도구 설치

### 1-1. 개발 도구 설치 🤖

> 🤖 AI에게 요청:
"Node.js가 설치되어 있는지 확인하고, 없으면 바로 설치해줘. Firebase CLI와 Google Cloud SDK도 설치가 필요하면 자동으로 설치해줘. 내 OS는 [Windows/Mac]야."
> 

**Windows 설치 코드 (관리자 권한 CMD에서 실행)**:

```bash
# Google Cloud SDK 설치 프로그램 다운로드
curl -o "%TEMP%\\GoogleCloudSDKInstaller.exe" <https://dl.google.com/dl/cloudsdk/channels/rapid/GoogleCloudSDKInstaller.exe>

# 설치 프로그램 실행 (자동 설치 모드)
"%TEMP%\\GoogleCloudSDKInstaller.exe"

# 설치 확인
gcloud --version

# Firebase CLI 설치
npm install -g firebase-tools

# 로그인 및 프로젝트 설정
gcloud auth login
gcloud config set project YOUR_PROJECT_ID

```

**macOS 설치 코드**:

```bash
# Homebrew로 설치 (PATH 자동 설정됨)
brew install --cask google-cloud-sdk

# PATH 설정
source "$(brew --prefix)/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/path.zsh.inc"
source "$(brew --prefix)/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/completion.zsh.inc"

# 설치 확인
gcloud --version

# Firebase CLI 설치
npm install -g firebase-tools

# 로그인 및 프로젝트 설정
gcloud auth login
gcloud config set project YOUR_PROJECT_ID

```

- -

## Step 2: GCP 계정 및 프로젝트 설정

### 2-1. GCP 무료 평가판 가입 👤

**목표**: Google Cloud Platform에 가입하고 무료 크레딧을 받습니다.

1. **GCP 콘솔 접속**
    - [https://console.cloud.google.com](https://console.cloud.google.com/) 접속
    - Google 계정으로 로그인
2. **무료 평가판 시작**
    - "무료로 시작하기" 버튼 클릭
    - 국가: 대한민국 선택
    - 계정 유형: 개인 선택
    - 결제 정보 입력 (무료 평가판 종료 후 자동 결제 안 됨)
3. **무료 크레딧 확인**
    - $300 무료 크레딧 제공 (90일간 유효)
    - 교육 목적으로 충분한 금액

### 2-2. 새 프로젝트 생성 👤

**목표**: 개인 학습용 GCP 프로젝트를 생성합니다.

1. **프로젝트 생성**
    
    ```
    GCP Console > 상단 프로젝트 드롭다운 > "새 프로젝트"
    
    ```
    
2. **프로젝트 정보 입력**
    - 프로젝트 이름: `senior-mhealth-your-name` (예: senior-mhealth-홍길동)
    - 프로젝트 ID: 자동 생성 또는 커스텀 (전역 고유해야 함)
    - 위치: "조직 없음" 선택
3. **프로젝트 ID 저장**

    ```
    ⚠️ 중요: 프로젝트 ID를 메모해두세요!
    예: senior-mhealth-your-name-a1b2c3

    ```
    

### 2-3. 프로젝트 선택 및 확인 👤

**목표**: 생성한 프로젝트가 활성화되었는지 확인합니다.

1. **프로젝트 선택**
    - 상단 드롭다운에서 방금 생성한 프로젝트 선택
    - 대시보드에서 프로젝트 정보 확인
2. **프로젝트 ID 확인**
    
    ```bash
    # Cloud Shell에서 확인 (Console 우측 상단 터미널 아이콘 클릭)
    gcloud config get-value project
    
    ```
    

### 2-4. 결제 설정 👤

**목표**: 무료 크레딧을 사용할 수 있도록 결제 계정을 연결합니다.

1. **결제 페이지 접속**
    - 왼쪽 메뉴 → "결제"
    - 또는 https://console.cloud.google.com/billing
2. **결제 계정 연결**
    - "이 프로젝트에 결제 계정 연결" 클릭
    - 무료 평가판 계정 선택
    - "계정 설정" 클릭
3. **예산 알림 설정 (선택사항)**
    - 결제 > 예산 및 알림
    - 월 $50 예산 설정
    - 50%, 90%, 100% 도달 시 이메일 알림

---

## Step 3: 개발 환경 설정

### 3-1. 환경 변수 파일 준비 👤

**목표**: 프로젝트 설정을 위한 환경 변수 파일을 생성합니다.

VSCode에서:

```
.env.example -> .env로 복사

```

`.env` 파일 내용 수정:

```
GCP_PROJECT_ID=your-project-id  # 자신의 프로젝트 ID로 변경!
GCP_REGION=asia-northeast3
FIREBASE_PROJECT_ID=your-project-id

```

## Step 4: 권한 및 서비스 계정 설정

### 4-1. IAM 권한 자동 설정 🤖

> 🤖 AI에게 요청:
"GCP 프로젝트의 IAM 권한을 설정해줘:
> 
> 1. 현재 로그인 상태 확인:
>     
>     ```bash
>     gcloud auth list --filter=status:ACTIVE
>     
>     ```
>     
> 2. 현재 사용자에게 Owner 권한 부여:
>     
>     ```bash
>     # .env에서 GCP_PROJECT_ID 읽기
>     # 현재 계정 이메일 가져오기
>     gcloud config get-value account
>     # Owner 권한 부여
>     gcloud projects add-iam-policy-binding [GCP_PROJECT_ID] \\
>       --member="user:[YOUR_EMAIL]" \\
>       --role="roles/owner"
>     
>     ```
>     
> 3. 권한 부여 확인:
>     
>     ```bash
>     gcloud projects get-iam-policy [GCP_PROJECT_ID] \\
>       --flatten="bindings[].members" \\
>       --filter="bindings.members:user:[YOUR_EMAIL]"
>     
>     ```
>     
> 4. 문제 발생 시 수동 설정 안내 제공"

### 4-2. 서비스 계정 생성 및 키 설정 🤖

> 🤖 AI에게 요청:
"GCP 서비스 계정을 생성하고 필요한 모든 권한을 설정해줘:
> 
> 1. **서비스 계정 생성**:
>     
>     ```bash
>     # .env에서 GCP_PROJECT_ID 읽기
>     # 서비스 계정 생성
>     gcloud iam service-accounts create automation-sa \\
>       --display-name="Automation Service Account" \\
>       --project=[GCP_PROJECT_ID]
>     
>     ```
>     
> 2. **필수 IAM 역할 부여** (모든 역할 자동 적용):
>     
>     ```bash
>     # 서비스 계정 이메일 설정
>     SERVICE_ACCOUNT=automation-sa@[GCP_PROJECT_ID].iam.gserviceaccount.com
>     
>     # Owner 역할 (전체 권한)
>     gcloud projects add-iam-policy-binding [GCP_PROJECT_ID] \\
>       --member="serviceAccount:${SERVICE_ACCOUNT}" \\
>       --role="roles/owner"
>     
>     # Firebase Admin 역할
>     gcloud projects add-iam-policy-binding [GCP_PROJECT_ID] \\
>       --member="serviceAccount:${SERVICE_ACCOUNT}" \\
>       --role="roles/firebase.admin"
>     
>     # 추가 필수 역할들
>     - roles/serviceusage.serviceUsageAdmin (API 관리)
>     - roles/iam.serviceAccountUser (서비스 계정 사용)
>     - roles/storage.admin (Cloud Storage 관리)
>     - roles/cloudsql.admin (Cloud SQL 관리)
>     - roles/secretmanager.admin (Secret Manager)
>     - roles/datastore.owner (Firestore 관리)
>     - roles/bigquery.admin (BigQuery 관리)
>     - roles/run.admin (Cloud Run 관리)
>     - roles/compute.admin (Compute Engine 관리)
>     
>     ```
>     
> 3. **서비스 계정 키 생성**:
>     
>     ```bash
>     # 기존 키 확인 및 정리 (최대 10개 제한)
>     gcloud iam service-accounts keys list \\
>       --iam-account=${SERVICE_ACCOUNT} \\
>       --filter="keyType:USER_MANAGED"
>     
>     # 새 키 생성 및 저장
>     gcloud iam service-accounts keys create ./serviceAccountKey.json \\
>       --iam-account=${SERVICE_ACCOUNT} \\
>       --project=[GCP_PROJECT_ID]
>     
>     ```
>     
> 4. **키 파일 검증**:
>     
>     ```bash
>     # 키 파일 크기 확인 (100 bytes 이상)
>     # JSON 구조 검증
>     # client_email 필드 추출 및 확인
>     
>     ```
>     
> 5. **환경 변수 설정**:
>     
>     ```bash
>     export GOOGLE_APPLICATION_CREDENTIALS="./serviceAccountKey.json"
>     
>     ```
>     
> 6. **권한 테스트**:
>     
>     ```bash
>     # 서비스 계정으로 인증
>     gcloud auth activate-service-account --key-file=serviceAccountKey.json
>     
>     # 프로젝트 접근 테스트
>     gcloud projects describe [GCP_PROJECT_ID]
>     
>     # 원래 계정으로 복귀
>     gcloud config set account [ORIGINAL_ACCOUNT]
>     
>     ```
>     
> 7. **보안 설정 확인**:
>     - serviceAccountKey.json이 .gitignore에 포함되어 있는지 확인
>     - 파일 권한 설정 (읽기 전용)
>     - 키 파일 백업 위치 안내
> 
> 실패 시 다음 스크립트 직접 실행:
> 
> - Windows: `setup/scripts/utils/create-service-account.bat`
> - macOS/Linux: `setup/scripts/utils/create-service-account.sh`"

---

## Step 5: Firebase 프로젝트 연결 및 초기 설정

### 5-1. Firebase 프로젝트 연결 준비 🤖

> 🤖 AI에게 요청:
"Firebase 프로젝트 연결을 위한 사전 준비 작업을 수행해줘:
> 
> 1. 서비스 계정 키 파일 확인:
>     - serviceAccountKey.json 파일이 프로젝트 루트에 있는지 확인
>     - 없으면 Step 4-2에서 생성한 키 파일 위치 알려줘
> 2. Firebase CLI 로그인 상태 확인:
>     - firebase login:list 명령으로 현재 로그인 계정 확인
>     - 로그인 안 되어있으면 firebase login 실행
> 3. .firebaserc 파일 자동 생성:
>     - GCP_PROJECT_ID를 사용해서 Firebase 프로젝트 설정 파일 생성
>     - 기존 파일 있으면 백업 후 수정"

### 5-2. Firebase 프로젝트 추가 및 연결 🤖

> 🤖 AI에게 요청:
"GCP 프로젝트에 Firebase를 추가하고 연결해줘:
> 
> 1. Firebase 프로젝트 추가:
>     
>     ```bash
>     firebase projects:addfirebase [GCP_PROJECT_ID]
>     
>     ```
>     
>     - 이미 추가된 경우 스킵하고 다음 단계 진행
>     - 실패 시 에러 메시지와 해결 방법 제시
> 2. Firebase 프로젝트 설정:
>     
>     ```bash
>     firebase use --add [GCP_PROJECT_ID] --alias default
>     
>     ```
>     
> 3. 서비스 계정 연결:
>     - GOOGLE_APPLICATION_CREDENTIALS 환경변수 설정
>     - serviceAccountKey.json 경로 자동 설정
> 4. 프로젝트 연결 확인:
>     - firebase projects:list로 연결 상태 확인
>     - 프로젝트 ID와 상태 출력"

### 5-3. Firestore Database 초기 설정 👤/🤖

**⚠️ 중요: Firestore는 최초 1회 수동 설정 필요**

> 👤 사용자 직접 작업:
> 
> 1. [Firebase Console](https://console.firebase.google.com/) 접속
> 2. 프로젝트 선택 → Firestore Database 클릭
> 3. "데이터베이스 만들기" 클릭
> 4. 다음 설정으로 생성:
>     - 모드: **테스트 모드에서 시작** (30일간 읽기/쓰기 허용)
>     - 위치: **asia-northeast3 (Seoul)** 선택
>     - "사용 설정" 클릭

> 🤖 AI에게 요청 (Firestore 생성 후):
"Firestore가 생성되었는지 확인하고 초기 컬렉션을 설정해줘:
> 
> 1. Firestore 초기 데이터 설정:
>     
>     ```jsx
>     // setup/scripts/init-firestore.js
>     const db = admin.firestore();
>     
>     // 초기 컬렉션 생성 예시
>     await db.collection("users").doc("sample_user").set({
>       email: "test@example.com",
>       name: "Test User",
>       role: "patient",
>     });
>     
>     ```
>     
> 2. 보안 규칙 설정:
>     
>     ```jsx
>     // setup/scripts/firestore.rules
>     rules_version = '2';
>     service cloud.firestore {
>       match /databases/{database}/documents {
>         match /users/{userId} {
>           allow read: if request.auth != null;
>           allow write: if request.auth != null && request.auth.uid == userId;
>         }
>         // 다른 컬렉션들도 유사한 방식으로 설정
>       }
>     }
>     
>     ```
>     
> 3. 인덱스 설정:
>     
>     ```json
>     // setup/scripts/firestore.indexes.json
>     {
>       "indexes": [
>         {
>           "collectionId": "users",
>           "fields": [
>             { "fieldPath": "role", "mode": "ASCENDING" },
>             { "fieldPath": "createdAt", "mode": "DESCENDING" }
>           ]
>         }
>       ]
>     }
>     
>     ```
>     
> 4. 설정 배포:
>     
>     ```bash
>     firebase deploy --only firestore:rules
>     firebase deploy --only firestore:indexes
>     ```"
>     
>     ```
>     

### 5-4. Authentication 설정 🤖

> 🤖 AI에게 요청:
"Firebase Authentication을 설정하고 테스트 사용자를 생성해줘:
> 
> 1. Firebase Console에서 Authentication 활성화 확인
> 2. 이메일/비밀번호 공급자 활성화:
>     
>     ```jsx
>     // Firebase Admin SDK 사용
>     const auth = admin.auth();
>     // 설정 확인 및 필요시 수동 안내
>     
>     ```
>     
> 3. 테스트 사용자 생성:
>     - [test@example.com](mailto:test@example.com) / Test123!
>     - [admin@example.com](mailto:admin@example.com) / Admin123!
> 4. 사용자 생성 확인:
>     - 생성된 사용자 UID 출력
>     - 로그인 테스트 수행"

### 5-5. Cloud Storage 설정 🤖

> 🤖 AI에게 요청:
"Cloud Storage를 설정하고 버킷을 구성해줘:
> 
> 1. Storage 버킷 확인:
>     - 기본 버킷: [project-id].appspot.com
>     - 추가 버킷: [project-id].firebasestorage.app
> 2. Storage 보안 규칙 설정:
>     - setup/scripts/storage.rules 파일 내용 확인
>     - 테스트 모드 규칙으로 임시 설정 (개발용)
> 3. firebase.json 수정:
>     
>     ```json
>     {
>       "storage": [
>         {
>           "bucket": "[실제-버킷-이름]",
>           "rules": "setup/scripts/storage.rules"
>         }
>       ]
>     }
>     
>     ```
>     
> 4. Storage 규칙 배포:
>     
>     ```bash
>     firebase deploy --only storage
>     
>     ```
>     
>     - 실패 시 수동 설정 방법 안내"

### 5-6. Cloud Functions 환경 설정 🤖

> 🤖 AI에게 요청:
"Cloud Functions 환경을 설정해줘:
> 
> 1. Functions 디렉토리 확인:
>     - backend/functions 디렉토리 존재 확인
>     - package.json 의존성 설치 상태 확인
> 2. Functions 환경 변수 설정:
>     
>     ```bash
>     firebase functions:config:set app.env="development" app.project_id="[GCP_PROJECT_ID]"
>     
>     ```
>     
> 3. Cloud Functions API 활성화:
>     
>     ```bash
>     # 필수 API 활성화
>     gcloud services enable cloudfunctions.googleapis.com cloudbuild.googleapis.com artifactregistry.googleapis.com
>     
>     ```
>     
> 4. IAM 권한 확인:
>     - Cloud Functions Admin (roles/cloudfunctions.admin)
>     - Cloud Build Editor (roles/cloudbuild.builds.editor)
>     - Service Account User (roles/iam.serviceAccountUser)
> 5. Functions 배포 테스트:
>     
>     ```bash
>     cd backend/functions
>     npm run deploy
>     
>     ```
>     

### 5-7. Firebase 프로젝트 전체 초기화 🤖

영상에서는 진행하고 있으나 여러분들은 하지 않습니다.

## Step 6: 프로젝트 의존성 설치

### 6-1. 프론트엔드/백엔드 패키지 설치 🤖

> 🤖 AI에게 요청:
"Frontend와 Backend의 npm 패키지를 직접 설치해줘.
> 
> - frontend/web 디렉토리의 package.json
> - backend/functions 디렉토리의 package.json
> - 각 디렉토리에서 npm install 자동 실행
> - 실시간으로 설치 진행 상황 보여줘"

### 6-2. 환경 변수 검증 🤖

> 🤖 AI에게 요청:
".env 파일이 올바르게 설정되었는지 직접 검증하고 결과를 보여줘.
> 
> - 필수 변수 자동 확인: GCP_PROJECT_ID, GCP_REGION, FIREBASE_PROJECT_ID
> - serviceAccountKey.json 파일 존재 여부 즉시 체크
> - .gitignore에 보안 파일들이 등록되어 있는지 검사하고 없으면 추가해줘"

## 실습 검증

### 설정 확인 테스트 🤖

> 🤖 AI에게 요청:
"다음 항목들이 모두 올바르게 설정되었는지 직접 테스트하고 결과를 보여줘:
> 
> - GCP 프로젝트 ID와 로그인 상태 즉시 확인
> - Firebase 프로젝트 연결 상태 자동 검증
> - 모든 Firebase 서비스 활성화 여부 체크
> - 환경 변수 파일 존재 및 내용 검사
> - serviceAccountKey.json 파일 존재 확인
> - 프론트엔드/백엔드 의존성 설치 상태 검증
> 문제가 발견되면 자동으로 수정해줘."

---

## 실습 완료

---

### ✅ 체크리스트

- [x]  GCP 계정 생성 및 프로젝트 설정
- [x]  $300 무료 크레딧 활성화
- [x]  결제 계정 연결 및 예산 설정
- [x]  Firebase 프로젝트 연결
- [x]  Firebase 서비스 활성화 (Firestore, Auth, Storage, FCM)
- [x]  개발 도구 설치 (Node.js, gcloud, Firebase CLI)
- [x]  프로젝트 권한 (IAM) 설정
- [x]  서비스 계정 생성 및 키 발급
- [x]  환경 변수 설정
- [x]  프로젝트 의존성 설치

### 💰 비용 관리 팁

1. **무료 할당량 활용**: Firebase 무료 티어 한도 확인
2. **일일 한도 설정**: Firebase Console에서 일일 사용량 제한
3. **사용량 모니터링**: GCP Console > 결제 > 보고서 정기 확인
4. **리소스 정리**: 사용하지 않는 Functions, Storage 파일 삭제
5. **예산 알림**: 월 $50 예산 설정 및 알림 활성화

### 🔒 보안 주의사항

- **serviceAccountKey.json**: 절대 Git에 커밋하지 마세요!
- **.env 파일**: 민감한 정보 포함, Git 제외 필수
- **Firebase 규칙**: 프로덕션 전 반드시 보안 규칙 강화
- **API 키 관리**: 환경 변수로 관리, 하드코딩 금지

### **9월 22일 과제**

1. GCP 설정한 캡처 아무거나 1장
2. Firebase의 인증, firestore, storage, funcitons 설정한 캡처 각 1장 총 3장