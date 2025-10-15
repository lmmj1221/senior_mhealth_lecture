# Week 5: Cloud Functions & Firestore - 서버리스 백엔드

## 🎯 학습 목표

Cloud Functions로 서버리스 API를 개발하고 Firestore NoSQL 데이터베이스를 설계하여 실시간 데이터 처리 시스템을 구축합니다.

## 📚 핵심 개념

### 1. 서버리스 아키텍처

### 서버리스의 진화

```
Traditional → Virtual Machines → Containers → Serverless
    ↓              ↓                ↓            ↓
서버 관리       OS 관리         컨테이너 관리    코드만 관리
```

### 서버리스의 특징

- **No Server Management**: 인프라 관리 불필요
- **Auto-scaling**: 자동 확장/축소
- **Pay-per-use**: 실행 시간만큼만 과금
- **Event-driven**: 이벤트 기반 실행

### 2. Cloud Functions 이해

### Cloud Functions = FaaS (Function as a Service)

```
이벤트 트리거 종류:
├── HTTP 요청
├── Cloud Storage 변경
├── Firestore 문서 변경
├── Pub/Sub 메시지
├── Firebase 이벤트
└── 스케줄 (Cloud Scheduler)
```

### Functions 실행 모델

```
Cold Start (첫 실행)
┌─────────────────────────────────┐
│ 1. 컨테이너 생성 (100-700ms)     │
│ 2. 런타임 초기화                 │
│ 3. 코드 로드                     │
│ 4. 함수 실행                     │
└─────────────────────────────────┘

Warm Start (재사용)
┌─────────────────────────────────┐
│ 1. 기존 컨테이너 사용 (0ms)       │
│ 2. 함수 실행                     │
└─────────────────────────────────┘
```

### 3. Firestore NoSQL 데이터베이스

### Firestore vs Realtime Database

| 특징 | Firestore | Realtime Database |
|-----|-----------|-------------------|
| 데이터 모델 | 문서-컬렉션 | JSON 트리 |
| 쿼리 | 복잡한 쿼리 지원 | 단순 쿼리 |
| 확장성 | 자동 확장 | 수동 샤딩 |
| 오프라인 | 모바일/웹 지원 | 모바일만 |

### Firestore 데이터 구조

```
Firestore Database
└── Collections (컬렉션)
    └── Documents (문서)
        ├── Fields (필드)
        └── Subcollections (하위 컬렉션)

예시:
/users/{userId}
    ├── name: "홍길동"
    ├── email: "hong@example.com"
    └── /activities/{activityId}
        ├── type: "exercise"
        ├── duration: 30
        └── timestamp: 2024-09-28
```

### 4. 실시간 데이터 동기화

### Firestore 실시간 리스너

```javascript
// 실시간 구독 패턴
firestore.collection('messages')
  .where('userId', '==', currentUser.id)
  .onSnapshot((snapshot) => {
    snapshot.docChanges().forEach((change) => {
      if (change.type === 'added') {
        // 새 메시지
      }
      if (change.type === 'modified') {
        // 수정된 메시지
      }
      if (change.type === 'removed') {
        // 삭제된 메시지
      }
    });
  });
```

### 보안 규칙 (Security Rules)

```javascript
// Firestore 보안 규칙 예시
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // 사용자 본인 데이터만 읽기/쓰기
    match /users/{userId} {
      allow read, write: if request.auth != null
        && request.auth.uid == userId;
    }

    // 인증된 사용자만 읽기, 본인 것만 쓰기
    match /posts/{postId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null
        && request.auth.uid == resource.data.authorId;
    }
  }
}
```

---

## 🚀 실습: Functions & Firestore 구축

### 사전 준비 확인 🤖

```bash
# Firebase CLI 설치 확인
firebase --version

# 설치 필요시
npm install -g firebase-tools

# Firebase 로그인
firebase login

# 프로젝트 확인
firebase projects:list

# 필요한 API 활성화
gcloud services enable cloudfunctions.googleapis.com
gcloud services enable firestore.googleapis.com
gcloud services enable cloudbuild.googleapis.com
```

---

## Step 1: Firestore 데이터베이스 설정

### 1.1 Firestore 초기화 👤

1. [Firebase Console](https://console.firebase.google.com) 접속
2. 프로젝트 선택: your-project-id
3. Firestore Database 메뉴 클릭
4. "데이터베이스 만들기" 클릭
5. 위치 선택: asia-northeast3 (서울)
6. 보안 규칙: 테스트 모드로 시작

### 1.2 데이터 구조 설계 🤖

```bash
# 프로젝트 루트에서
cat > firestore-structure.md << 'EOF'
# Firestore 데이터 구조

## Collections

### users
- userId (document ID)
  - email: string
  - name: string
  - profileImage: string
  - createdAt: timestamp
  - lastActive: timestamp
  - settings: map
    - notifications: boolean
    - language: string

### healthData
- dataId (document ID)
  - userId: string (reference)
  - type: string (heartRate, steps, sleep, mood)
  - value: number/string
  - unit: string
  - timestamp: timestamp
  - metadata: map

### aiAnalysis
- analysisId (document ID)
  - userId: string (reference)
  - dataId: string (reference)
  - analysisType: string
  - results: map
  - confidence: number
  - createdAt: timestamp
  - processedBy: string

### conversations
- conversationId (document ID)
  - userId: string
  - messages: array
    - role: string (user/assistant)
    - content: string
    - timestamp: timestamp
  - context: map
  - lastMessageAt: timestamp
EOF

echo "데이터 구조 설계 완료"
```

### 1.3 보안 규칙 설정 🤖

```bash
# firestore.rules 파일 생성
cat > firestore.rules << 'EOF'
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Helper functions
    function isAuthenticated() {
      return request.auth != null;
    }

    function isOwner(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }

    function isValidHealthData() {
      return request.resource.data.keys().hasAll(['type', 'value', 'timestamp']) &&
             request.resource.data.type in ['heartRate', 'steps', 'sleep', 'mood'];
    }

    // Users collection
    match /users/{userId} {
      allow read: if isAuthenticated();
      allow create: if isOwner(userId);
      allow update: if isOwner(userId);
      allow delete: if false; // 삭제 금지
    }

    // Health data collection
    match /healthData/{dataId} {
      allow read: if isAuthenticated() &&
        (isOwner(resource.data.userId) ||
         request.auth.token.role == 'admin');
      allow create: if isAuthenticated() &&
        isOwner(request.resource.data.userId) &&
        isValidHealthData();
      allow update: if isOwner(resource.data.userId);
      allow delete: if isOwner(resource.data.userId);
    }

    // AI Analysis collection (읽기 전용)
    match /aiAnalysis/{analysisId} {
      allow read: if isAuthenticated() &&
        isOwner(resource.data.userId);
      allow write: if false; // Functions만 쓰기 가능
    }

    // Conversations collection
    match /conversations/{conversationId} {
      allow read, write: if isOwner(resource.data.userId);
    }
  }
}
EOF

# 보안 규칙 배포
firebase deploy --only firestore:rules
```

### 1.4 인덱스 설정 🤖

```bash
# firestore.indexes.json 생성
cat > firestore.indexes.json << 'EOF'
{
  "indexes": [
    {
      "collectionGroup": "healthData",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "userId", "order": "ASCENDING" },
        { "fieldPath": "type", "order": "ASCENDING" },
        { "fieldPath": "timestamp", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "aiAnalysis",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "userId", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "conversations",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "userId", "order": "ASCENDING" },
        { "fieldPath": "lastMessageAt", "order": "DESCENDING" }
      ]
    }
  ],
  "fieldOverrides": []
}
EOF

# 인덱스 배포
firebase deploy --only firestore:indexes
```

---

## Step 2: Cloud Functions 개발

### 2.1 Functions 프로젝트 초기화 🤖

```bash
# backend/functions 디렉토리로 이동
cd backend/functions

# Firebase Functions 초기화 (이미 있으면 스킵)
firebase init functions

# 선택 옵션:
# - Use an existing project
# - JavaScript
# - ESLint: Yes
# - Install dependencies: Yes

# 필요한 패키지 설치
npm install express cors dotenv firebase-admin axios
npm install --save-dev @types/express @types/cors
```

### 2.2 Express 앱 설정 🤖

```bash
# index.js 생성
cat > index.js << 'EOF'
const functions = require('firebase-functions');
const admin = require('firebase-admin');
const express = require('express');
const cors = require('cors');

// Firebase Admin 초기화
admin.initializeApp();

const db = admin.firestore();
const auth = admin.auth();

// Express 앱 생성
const app = express();

// Middleware
app.use(cors({ origin: true }));
app.use(express.json());

// 인증 미들웨어
const authenticate = async (req, res, next) => {
  const token = req.headers.authorization?.split('Bearer ')[1];

  if (!token) {
    return res.status(401).json({ error: 'No token provided' });
  }

  try {
    const decodedToken = await auth.verifyIdToken(token);
    req.user = decodedToken;
    next();
  } catch (error) {
    return res.status(401).json({ error: 'Invalid token' });
  }
};

// Health check
app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    service: 'cloud-functions',
    timestamp: new Date().toISOString()
  });
});

// API Routes
app.use('/api/health', authenticate, require('./routes/health'));
app.use('/api/analysis', authenticate, require('./routes/analysis'));
app.use('/api/users', authenticate, require('./routes/users'));

// Export Express app as Cloud Function
exports.api = functions
  .region('asia-northeast3')
  .runWith({
    timeoutSeconds: 60,
    memory: '512MB'
  })
  .https.onRequest(app);

// Firestore 트리거 함수들
exports.onHealthDataCreated = require('./triggers/onHealthDataCreated');
exports.onUserCreated = require('./triggers/onUserCreated');
exports.scheduledAnalysis = require('./triggers/scheduledAnalysis');

// Storage 트리거 함수
exports.processVoiceFile = require('./triggers/processVoiceFile');
EOF
```

### 2.3 API 라우트 구현 🤖

```bash
# routes 디렉토리 생성
mkdir -p routes

# Health 데이터 라우트
cat > routes/health.js << 'EOF'
const express = require('express');
const admin = require('firebase-admin');
const router = express.Router();

const db = admin.firestore();

// 건강 데이터 저장
router.post('/', async (req, res) => {
  try {
    const { type, value, unit, metadata } = req.body;
    const userId = req.user.uid;

    const healthData = {
      userId,
      type,
      value,
      unit,
      metadata: metadata || {},
      timestamp: admin.firestore.FieldValue.serverTimestamp()
    };

    const docRef = await db.collection('healthData').add(healthData);

    res.json({
      success: true,
      id: docRef.id,
      message: 'Health data saved successfully'
    });
  } catch (error) {
    console.error('Error saving health data:', error);
    res.status(500).json({ error: error.message });
  }
});

// 건강 데이터 조회
router.get('/', async (req, res) => {
  try {
    const userId = req.user.uid;
    const { type, limit = 100, startDate, endDate } = req.query;

    let query = db.collection('healthData')
      .where('userId', '==', userId)
      .orderBy('timestamp', 'desc')
      .limit(parseInt(limit));

    if (type) {
      query = query.where('type', '==', type);
    }

    if (startDate) {
      query = query.where('timestamp', '>=', new Date(startDate));
    }

    if (endDate) {
      query = query.where('timestamp', '<=', new Date(endDate));
    }

    const snapshot = await query.get();
    const data = snapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data()
    }));

    res.json({ data });
  } catch (error) {
    console.error('Error fetching health data:', error);
    res.status(500).json({ error: error.message });
  }
});

// 특정 데이터 삭제
router.delete('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user.uid;

    const doc = await db.collection('healthData').doc(id).get();

    if (!doc.exists) {
      return res.status(404).json({ error: 'Data not found' });
    }

    if (doc.data().userId !== userId) {
      return res.status(403).json({ error: 'Unauthorized' });
    }

    await db.collection('healthData').doc(id).delete();

    res.json({
      success: true,
      message: 'Data deleted successfully'
    });
  } catch (error) {
    console.error('Error deleting health data:', error);
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
EOF
```

### 2.4 Firestore 트리거 함수 🤖

```bash
# triggers 디렉토리 생성
mkdir -p triggers

# 건강 데이터 생성 시 트리거
cat > triggers/onHealthDataCreated.js << 'EOF'
const functions = require('firebase-functions');
const admin = require('firebase-admin');
const axios = require('axios');

const db = admin.firestore();

module.exports = functions
  .region('asia-northeast3')
  .firestore
  .document('healthData/{dataId}')
  .onCreate(async (snapshot, context) => {
    const data = snapshot.data();
    const dataId = context.params.dataId;

    console.log('New health data created:', dataId);

    try {
      // AI 분석 요청 (Cloud Run AI Service 호출)
      const aiServiceUrl = process.env.AI_SERVICE_URL || functions.config().services?.ai_url;

      if (!aiServiceUrl) {
        console.warn('AI Service URL not configured');
        return null;
      }

      const analysisRequest = {
        dataType: data.type,
        value: data.value,
        timestamp: data.timestamp,
        metadata: data.metadata
      };

      const response = await axios.post(
        `${aiServiceUrl}/analyze`,
        analysisRequest,
        { timeout: 30000 }
      );

      // 분석 결과 저장
      const analysisResult = {
        userId: data.userId,
        dataId: dataId,
        analysisType: 'automated',
        results: response.data,
        confidence: response.data.confidence || 0,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        processedBy: 'onHealthDataCreated'
      };

      await db.collection('aiAnalysis').add(analysisResult);

      console.log('AI analysis completed and saved');

      // 알림 전송 (필요시)
      if (response.data.alert) {
        // FCM 또는 이메일 알림 전송 로직
        console.log('Alert triggered:', response.data.alert);
      }

    } catch (error) {
      console.error('Error processing health data:', error);
    }
  });
EOF

# 사용자 생성 시 트리거
cat > triggers/onUserCreated.js << 'EOF'
const functions = require('firebase-functions');
const admin = require('firebase-admin');

const db = admin.firestore();

module.exports = functions
  .region('asia-northeast3')
  .auth
  .user()
  .onCreate(async (user) => {
    console.log('New user created:', user.uid);

    try {
      // Firestore에 사용자 프로필 생성
      const userProfile = {
        email: user.email,
        name: user.displayName || 'Unknown',
        profileImage: user.photoURL || '',
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        lastActive: admin.firestore.FieldValue.serverTimestamp(),
        settings: {
          notifications: true,
          language: 'ko'
        }
      };

      await db.collection('users').doc(user.uid).set(userProfile);

      // 환영 메시지 생성
      const welcomeConversation = {
        userId: user.uid,
        messages: [{
          role: 'assistant',
          content: '안녕하세요! mHealth 서비스에 오신 것을 환영합니다.',
          timestamp: admin.firestore.FieldValue.serverTimestamp()
        }],
        context: {},
        lastMessageAt: admin.firestore.FieldValue.serverTimestamp()
      };

      await db.collection('conversations').add(welcomeConversation);

      console.log('User profile and welcome message created');

    } catch (error) {
      console.error('Error creating user profile:', error);
    }
  });
EOF

# 스케줄 함수 (일일 분석)
cat > triggers/scheduledAnalysis.js << 'EOF'
const functions = require('firebase-functions');
const admin = require('firebase-admin');

const db = admin.firestore();

module.exports = functions
  .region('asia-northeast3')
  .pubsub
  .schedule('every day 09:00')
  .timeZone('Asia/Seoul')
  .onRun(async (context) => {
    console.log('Running daily analysis at:', context.timestamp);

    try {
      // 모든 활성 사용자 가져오기
      const oneDayAgo = new Date(Date.now() - 24 * 60 * 60 * 1000);
      const usersSnapshot = await db.collection('users')
        .where('lastActive', '>=', oneDayAgo)
        .get();

      const analysisPromises = usersSnapshot.docs.map(async (userDoc) => {
        const userId = userDoc.id;

        // 사용자의 최근 24시간 데이터 가져오기
        const healthDataSnapshot = await db.collection('healthData')
          .where('userId', '==', userId)
          .where('timestamp', '>=', oneDayAgo)
          .get();

        if (healthDataSnapshot.empty) {
          return null;
        }

        // 데이터 집계
        const summary = {
          userId,
          date: new Date().toISOString().split('T')[0],
          dataCount: healthDataSnapshot.size,
          types: {},
          createdAt: admin.firestore.FieldValue.serverTimestamp()
        };

        healthDataSnapshot.docs.forEach(doc => {
          const data = doc.data();
          if (!summary.types[data.type]) {
            summary.types[data.type] = {
              count: 0,
              values: []
            };
          }
          summary.types[data.type].count++;
          summary.types[data.type].values.push(data.value);
        });

        // 일일 요약 저장
        await db.collection('dailySummaries').add(summary);

        console.log(`Daily summary created for user: ${userId}`);
      });

      await Promise.all(analysisPromises);

      console.log('Daily analysis completed');

    } catch (error) {
      console.error('Error in scheduled analysis:', error);
    }
  });
EOF

# Storage 트리거 - 음성 파일 자동 처리
cat > triggers/processVoiceFile.js << 'EOF'
const functions = require('firebase-functions');
const admin = require('firebase-admin');
const axios = require('axios');

const db = admin.firestore();

module.exports = functions
  .region('asia-northeast3')
  .storage
  .object()
  .onFinalize(async (object) => {
    const filePath = object.name;
    const metadata = object.metadata || {};
    
    console.log('🔔 Storage 트리거 발생:', filePath);
    
    // 음성 파일 경로인지 확인 (calls/{userId}/{seniorId}/{callId}/filename)
    if (!filePath.startsWith('calls/')) {
      console.log('❌ 음성 파일이 아님:', filePath);
      return null;
    }
    
    try {
      // 1. 파일 경로에서 정보 추출
      const pathParts = filePath.split('/');
      if (pathParts.length < 4) {
        console.log('❌ 잘못된 경로 구조:', filePath);
        return null;
      }
      
      const userId = pathParts[1];
      const seniorId = pathParts[2];
      const callId = pathParts[3];
      const fileName = pathParts[4] || 'unknown';
      
      console.log('📋 파일 정보:', { userId, seniorId, callId, fileName });
      
      // 2. Firestore에서 해당 통화 문서 찾기
      const callDocRef = db.collection('users').doc(userId).collection('calls').doc(callId);
      const callDoc = await callDocRef.get();
      
      if (!callDoc.exists) {
        console.log('❌ 통화 문서를 찾을 수 없음:', callId);
        return null;
      }
      
      // 3. Firestore 문서 상태 업데이트
      await callDocRef.update({
        status: 'uploaded',
        analysisStatus: 'processing',
        filePath: filePath,
        uploadedAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });
      
      console.log('✅ Firestore 업데이트 완료:', callId);
      
      // 4. AI 분석 서비스 호출
      const aiServiceUrl = process.env.CLOUD_RUN_AI_URL || functions.config().services?.ai_url;
      
      if (aiServiceUrl) {
        console.log('🤖 AI 분석 요청 시작:', aiServiceUrl);
        
        // AI 분석 요청 페이로드
        const analysisRequest = {
          call_id: callId,
          user_id: userId,
          senior_id: seniorId,
          audio_url: filePath,
          analysis_type: 'comprehensive',
          metadata: {
            fileName: fileName,
            uploadedAt: new Date().toISOString(),
            ...metadata
          }
        };
        
        // HTTP 요청으로 AI 서비스 호출
        try {
          const response = await axios.post(
            `${aiServiceUrl}/analyze`,
            analysisRequest,
            {
              timeout: 30000,
              headers: {
                'Content-Type': 'application/json'
              }
            }
          );
          
          console.log('🎉 AI 분석 요청 성공:', response.data);
          
          // 분석 요청 성공시 상태 업데이트
          await callDocRef.update({
            analysisStatus: 'ai_processing',
            aiRequestId: response.data.analysis_id || callId,
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
          });
          
        } catch (aiError) {
          console.error('❌ AI 분석 요청 실패:', aiError.message);
          
          // 분석 요청 실패시 상태 업데이트
          await callDocRef.update({
            analysisStatus: 'failed',
            errorMessage: aiError.message,
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
          });
        }
      } else {
        console.log('⚠️ AI 서비스 URL이 설정되지 않음');
        
        // AI 서비스 URL이 없을 때 상태 업데이트
        await callDocRef.update({
          analysisStatus: 'pending_config',
          errorMessage: 'AI service URL not configured',
          updatedAt: admin.firestore.FieldValue.serverTimestamp()
        });
      }
      
      return { success: true, callId, status: 'processed' };
      
    } catch (error) {
      console.error('❌ processVoiceFile 오류:', error);
      return { success: false, error: error.message };
    }
  });
EOF
```

### 2.5 환경 변수 설정 🤖

```bash
# .env 파일 생성 (Functions용)
cat > .env << EOF
# Cloud Run Services - Storage 트리거에서 사용
CLOUD_RUN_AI_URL=https://your-ai-service-xxxxx-an.a.run.app
CLOUD_RUN_API_URL=https://your-api-service-xxxxx-an.a.run.app

# Firebase 설정
FIREBASE_PROJECT_ID=your-project-id
EOF

# Firebase Functions 환경 변수 설정
firebase functions:config:set \
  services.ai_url="${CLOUD_RUN_AI_URL}" \
  services.api_url="${CLOUD_RUN_API_URL}"

# 현재 설정된 환경 변수 확인
firebase functions:config:get
```

### 2.6 package.json 의존성 추가 🤖

```bash
# Storage 트리거에 필요한 axios 의존성이 이미 포함되어 있는지 확인
cd functions
cat package.json | grep axios

# 없다면 추가 설치
npm install axios

# 전체 의존성 재설치
npm install
```

---

## Step 3: Functions 배포 및 테스트

### 3.1 로컬 에뮬레이터 테스트 🤖

```bash
# 에뮬레이터 시작
firebase emulators:start --only functions,firestore

# 다른 터미널에서 테스트
# Health check (your-project-id를 실제 프로젝트 ID로 변경)
curl http://localhost:5001/your-project-id/asia-northeast3/api/health

# 테스트 데이터 추가 (인증 필요)
# 먼저 테스트 토큰 생성 필요
```

### 3.2 Functions 배포 🤖

```bash
# ✅ Storage 트리거 포함하여 Functions 배포
firebase deploy --only functions

# 특정 함수만 배포하려면
firebase deploy --only functions:processVoiceFile
firebase deploy --only functions:onHealthDataCreated

# 배포 확인
firebase functions:list

# 예상 결과:
# ✅ api (HTTP Trigger)
# ✅ processVoiceFile (Storage Trigger) ⭐
# ✅ onHealthDataCreated (Firestore Trigger)  
# ✅ onUserCreated (Auth Trigger)
# ✅ scheduledAnalysis (Scheduled Function)
```
firebase deploy --only functions

# 배포 확인
firebase functions:list

# 배포된 URL 확인
# https://asia-northeast3-your-project-id.cloudfunctions.net/api
```

### 3.3 배포 검증 👤

1. [Firebase Console](https://console.firebase.google.com) 접속
2. Functions 메뉴에서 배포 상태 확인
3. Logs에서 실행 로그 확인

### 3.4 API 테스트 🤖

```bash
# Functions URL 설정 (your-project-id를 실제 프로젝트 ID로 변경)
export FUNCTIONS_URL="https://asia-northeast3-your-project-id.cloudfunctions.net/api"

# Health check
curl ${FUNCTIONS_URL}/health

# Firestore 데이터 테스트 (Firebase Console에서)
# 1. Firestore 메뉴 접속
# 2. 컬렉션 생성 및 테스트 데이터 추가
# 3. 트리거 함수 동작 확인
```

### 3.5 Storage 트리거 테스트 🆕

```bash
# ⭐ Storage 트리거 테스트 방법

# 1. Firebase Console에서 Storage 메뉴 접속
# 2. 테스트 파일 업로드: calls/test_user/test_senior/test_call/audio.m4a
# 3. Functions 로그에서 트리거 실행 확인:

firebase functions:log --only processVoiceFile

# 예상 로그:
# 🔔 Storage 트리거 발생: calls/test_user/test_senior/test_call/audio.m4a
# 📋 파일 정보: {userId: test_user, seniorId: test_senior, callId: test_call}
# ✅ Firestore 업데이트 완료: test_call
# 🤖 AI 분석 요청 시작: https://...
# 🎉 AI 분석 요청 성공: {...}

# 4. Firestore에서 통화 문서 상태 확인:
# - analysisStatus: 'ai_processing'
# - filePath: 'calls/test_user/test_senior/test_call/audio.m4a'
# - uploadedAt: [timestamp]
```

---

## Step 4: 통합 및 모니터링

### 4.1 Cloud Run과 Functions 통합 🤖

```bash
# Cloud Run 서비스 환경 변수 업데이트
# (API_SERVICE_NAME은 week4에서 정의한 환경변수)
gcloud run services update ${API_SERVICE_NAME} \
  --platform managed \
  --region asia-northeast3 \
  --update-env-vars="FUNCTIONS_URL=${FUNCTIONS_URL}"

# 통합 테스트
curl -X POST ${API_SERVICE_URL}/api/integrated-test \
  -H "Content-Type: application/json" \
  -d '{"test": true}'
```

### 4.2 모니터링 설정 👤

1. [Cloud Console](https://console.cloud.google.com) 접속
2. Monitoring > Dashboards 메뉴
3. "Create Dashboard" 클릭
4. 다음 메트릭 추가:
   - Cloud Functions 실행 횟수
   - Cloud Functions 오류율
   - Firestore 읽기/쓰기 작업
   - Cloud Run 요청 수

### 4.3 로그 확인 🤖

```bash
# Functions 로그 확인
firebase functions:log --only api

# Firestore 트리거 로그
firebase functions:log --only onHealthDataCreated

# Cloud Logging으로 통합 로그 확인
gcloud logging read "resource.type=cloud_function" --limit 50
```

---

## 🔧 트러블슈팅

### Functions 관련 문제

#### 배포 실패
```bash
# 문제: "Permission denied"
# 해결: 권한 확인
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:${PROJECT_ID}@appspot.gserviceaccount.com" \
  --role="roles/cloudfunctions.developer"

# 문제: "Quota exceeded"
# 해결: 할당량 확인
gcloud compute project-info describe
```

#### 콜드 스타트 개선
```javascript
// 전역 변수로 재사용
const db = admin.firestore();
let aiServiceClient = null;

exports.api = functions.https.onRequest(async (req, res) => {
  // 클라이언트 재사용
  if (!aiServiceClient) {
    aiServiceClient = new AIServiceClient();
  }
  // ...
});
```

### Firestore 관련 문제

#### 인덱스 오류
```bash
# 문제: "The query requires an index"
# 해결: 오류 메시지의 링크 클릭하여 인덱스 생성

# 또는 수동으로 인덱스 추가
firebase deploy --only firestore:indexes
```

#### 보안 규칙 문제
```bash
# 문제: "Missing or insufficient permissions"
# 해결: 보안 규칙 확인 및 수정
firebase deploy --only firestore:rules

# 규칙 테스트
firebase emulators:start --only firestore
```

---

## 💰 비용 최적화

### Cloud Functions 무료 티어
- 월 200만 호출 무료
- 월 400,000 GB-초, 200,000 GHz-초 무료

### Firestore 무료 티어
- 일 5만 읽기, 2만 쓰기, 2만 삭제 무료
- 1GB 저장 무료

### 비용 절감 팁

```javascript
// 1. 배치 작업 사용
const batch = db.batch();
docs.forEach(doc => batch.set(doc.ref, doc.data));
await batch.commit();

// 2. 필드 선택적 가져오기
db.collection('users')
  .select('name', 'email')  // 필요한 필드만
  .get();

// 3. 캐싱 활용
const cache = new Map();
if (cache.has(key)) {
  return cache.get(key);
}
```

---

## ✅ 완료 체크리스트

- [x] Firestore 데이터베이스 생성
- [x] 데이터 구조 설계
- [x] 보안 규칙 설정
- [x] Cloud Functions 프로젝트 초기화
- [x] Express API 구현
- [x] Firestore 트리거 함수 작성
- [x] **Storage 트리거 함수 구현** ⭐
- [ ] Functions 배포
- [x] Storage 트리거와 Cloud Run AI 서비스 통합
- [ ] 모니터링 설정
- [x] 비용 최적화 적용

### 🆕 **새로 구현된 기능들**

#### **Firebase Storage 트리거 자동화** ⭐
- **위치**: `backend/functions/index.js`
- **기능**: 파일 업로드 완료 시 자동으로 AI 분석 시작
- **트리거**: `onFinalize` 이벤트
- **처리 경로**: `calls/{userId}/{seniorId}/{callId}/filename`

#### **완전한 워크플로우 구현**
```javascript
Firebase Storage 업로드 
    ↓ (onFinalize 이벤트)
Storage 트리거 실행
    ↓
Firestore 상태 업데이트 (pending → processing)
    ↓
AI 서비스 호출 (Cloud Run)
    ↓
결과에 따른 최종 상태 업데이트
```

#### **AI 서비스 연동**
- HTTP 요청으로 Cloud Run AI 서비스 호출
- 환경변수로 AI 서비스 URL 설정
- 상태별 에러 처리 및 재시도 로직

#### **Firestore 상태 관리**
- `pending` → `processing` → `ai_processing` → `completed`
- 실패 시 `failed` 상태로 업데이트
- 상세한 에러 메시지 저장

---

## 🎯 학습 성과

이번 주차를 완료하면:
- ✅ 서버리스 아키텍처 이해
- ✅ Cloud Functions 개발 능력
- ✅ Firestore NoSQL 데이터베이스 설계
- ✅ 실시간 데이터 동기화 구현
- ✅ 트리거 기반 자동화
- ✅ 마이크로서비스 통합

---

## 📚 다음 주차 예고

**Week 6: Vercel 배포**
- Next.js 웹 애플리케이션
- Vercel 플랫폼 이해
- 환경 변수 관리
- 커스텀 도메인 설정

---

## 🔗 참고 자료

- [Cloud Functions 문서](https://firebase.google.com/docs/functions)
- [Firestore 문서](https://firebase.google.com/docs/firestore)
- [Firebase Admin SDK](https://firebase.google.com/docs/admin/setup)
- [Firestore 보안 규칙](https://firebase.google.com/docs/firestore/security/get-started)