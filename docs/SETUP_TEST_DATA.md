# 테스트 데이터 생성 가이드

> **목적**: Week 6 Vercel 배포 전에 Web App에서 표시할 테스트 데이터를 Firebase에 생성합니다.

---

## 📋 사전 요구사항

- Firebase 프로젝트 설정 완료
- Service Account Key 파일 준비 (`backend/service-account-key.json`)
- Node.js 설치
- 테스트용 음성 파일 (`data/` 폴더)

---

## 🚀 테스트 데이터 생성 프로세스

### 전체 워크플로우

```
1. Firebase Authentication에 테스트 사용자 생성
   ↓
2. Firestore에 calls 문서 생성
   ↓
3. Firebase Storage에 음성 파일 업로드
   ↓
4. Firestore 업데이트 확인
   ↓
5. Web App에서 데이터 표시
```

---

## Step 1: 테스트 사용자 생성

### 1.1 Firebase Console에서 생성 (권장)

1. [Firebase Console](https://console.firebase.google.com/project/my-project-54928-b9704/authentication/users) 접속
2. Authentication > Users 메뉴
3. "Add user" 클릭
4. 사용자 정보 입력:
   - Email: `test@test.com`
   - Password: `test1234`
5. "Add user" 클릭

### 1.2 사용자 UID 확인

```bash
# 프로젝트 루트에서 실행
firebase auth:export auth_users.json --project my-project-54928-b9704

# UID 확인
cat auth_users.json | jq '.users[] | select(.email == "test@test.com") | {uid: .localId, email: .email}'
```

**예상 출력:**
```json
{
  "uid": "7wll6D15YZgVrL7jEO1dJhyCUKG3",
  "email": "test@test.com"
}
```

**중요**: 이 UID를 다음 단계에서 사용합니다.

---

## Step 2: Firebase Admin SDK 설치

```bash
# 프로젝트 루트에서 실행
npm install firebase-admin
```

---

## Step 3: Firestore에 Call 문서 생성

### 3.1 스크립트 작성

`create_test_call.js` 파일을 생성합니다:

```javascript
const admin = require('firebase-admin');
const serviceAccount = require('./backend/service-account-key.json');

// Firebase Admin 초기화
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  storageBucket: 'my-project-54928-b9704.firebasestorage.app'
});

const db = admin.firestore();

async function createTestCall() {
  // Step 1에서 확인한 UID로 변경
  const userId = '7wll6D15YZgVrL7jEO1dJhyCUKG3';
  const seniorId = 'test_senior_001';
  const callId = 'test_call_' + Date.now();

  const callData = {
    userId: userId,
    seniorId: seniorId,
    fileName: '통화 녹음 어머니_250505_122325.m4a',
    status: 'pending',
    analysisStatus: 'pending',
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    recordedAt: admin.firestore.FieldValue.serverTimestamp(),
    metadata: {
      device: 'test',
      version: '1.0.0'
    }
  };

  try {
    console.log('📝 Creating test call document...');
    console.log('   User ID:', userId);
    console.log('   Senior ID:', seniorId);
    console.log('   Call ID:', callId);

    // Firestore에 문서 생성
    await db.collection('users').doc(userId).collection('calls').doc(callId).set(callData);

    console.log('✅ Call document created successfully!');
    console.log('   Path: users/' + userId + '/calls/' + callId);
    console.log('\n📤 Now you can upload the file to Storage at:');
    console.log('   calls/' + userId + '/' + seniorId + '/' + callId + '/통화 녹음 어머니_250505_122325.m4a');

    return { userId, seniorId, callId };
  } catch (error) {
    console.error('❌ Error creating call document:', error);
    throw error;
  }
}

createTestCall()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
```

### 3.2 스크립트 실행

```bash
node create_test_call.js
```

**예상 출력:**
```
📝 Creating test call document...
   User ID: 7wll6D15YZgVrL7jEO1dJhyCUKG3
   Senior ID: test_senior_001
   Call ID: test_call_1760506267900
✅ Call document created successfully!
   Path: users/7wll6D15YZgVrL7jEO1dJhyCUKG3/calls/test_call_1760506267900

📤 Now you can upload the file to Storage at:
   calls/7wll6D15YZgVrL7jEO1dJhyCUKG3/test_senior_001/test_call_1760506267900/통화 녹음 어머니_250505_122325.m4a
```

**중요**: Call ID를 기록해두세요. 다음 단계에서 사용합니다.

---

## Step 4: Storage에 음성 파일 업로드

### 4.1 스크립트 작성

`upload_test_file.js` 파일을 생성합니다:

```javascript
const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');
const serviceAccount = require('./backend/service-account-key.json');

// Firebase Admin 초기화
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  storageBucket: 'my-project-54928-b9704.firebasestorage.app'
});

const bucket = admin.storage().bucket();

async function uploadTestFile() {
  // Step 1과 Step 3의 값으로 변경
  const userId = '7wll6D15YZgVrL7jEO1dJhyCUKG3';
  const seniorId = 'test_senior_001';
  const callId = 'test_call_1760506267900'; // Step 3에서 생성된 Call ID
  const fileName = '통화 녹음 어머니_250505_122325.m4a';

  const localFilePath = path.join(__dirname, 'data', fileName);
  const storagePath = `calls/${userId}/${seniorId}/${callId}/${fileName}`;

  try {
    console.log('📤 Uploading test file to Firebase Storage...');
    console.log('   Local file:', localFilePath);
    console.log('   Storage path:', storagePath);

    // 파일 존재 확인
    if (!fs.existsSync(localFilePath)) {
      throw new Error(`File not found: ${localFilePath}`);
    }

    const fileStats = fs.statSync(localFilePath);
    console.log('   File size:', (fileStats.size / 1024 / 1024).toFixed(2), 'MB');

    // Storage에 업로드
    await bucket.upload(localFilePath, {
      destination: storagePath,
      metadata: {
        contentType: 'audio/m4a',
        metadata: {
          userId: userId,
          seniorId: seniorId,
          callId: callId,
          uploadedBy: 'test_script'
        }
      }
    });

    console.log('✅ File uploaded successfully!');
    console.log('   Storage path:', storagePath);
    console.log('\n🔔 Storage trigger should fire now...');
    console.log('   Check Firebase Functions logs:');
    console.log('   firebase functions:log --project my-project-54928-b9704');

    console.log('\n📊 Check Firestore for updates:');
    console.log('   Path: users/' + userId + '/calls/' + callId);

  } catch (error) {
    console.error('❌ Error uploading file:', error);
    throw error;
  }
}

uploadTestFile()
  .then(() => {
    console.log('\n✨ Upload complete! Waiting 5 seconds before exiting...');
    setTimeout(() => process.exit(0), 5000);
  })
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
```

### 4.2 스크립트 실행

```bash
node upload_test_file.js
```

**예상 출력:**
```
📤 Uploading test file to Firebase Storage...
   Local file: /Users/callii/Documents/senior_mhealth_lecture/data/통화 녹음 어머니_250505_122325.m4a
   Storage path: calls/7wll6D15YZgVrL7jEO1dJhyCUKG3/test_senior_001/test_call_1760506267900/통화 녹음 어머니_250505_122325.m4a
   File size: 1.59 MB
✅ File uploaded successfully!
   Storage path: calls/7wll6D15YZgVrL7jEO1dJhyCUKG3/test_senior_001/test_call_1760506267900/통화 녹음 어머니_250505_122325.m4a

🔔 Storage trigger should fire now...
   Check Firebase Functions logs:
   firebase functions:log --project my-project-54928-b9704

📊 Check Firestore for updates:
   Path: users/7wll6D15YZgVrL7jEO1dJhyCUKG3/calls/test_call_1760506267900

✨ Upload complete!
```

---

## Step 5: Firestore 데이터 확인

### 5.1 스크립트 작성

`check_firestore.js` 파일을 생성합니다:

```javascript
const admin = require('firebase-admin');
const serviceAccount = require('./backend/service-account-key.json');

// Firebase Admin 초기화
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  storageBucket: 'my-project-54928-b9704.firebasestorage.app'
});

const db = admin.firestore();

async function checkFirestore() {
  // Step 1과 Step 3의 값으로 변경
  const userId = '7wll6D15YZgVrL7jEO1dJhyCUKG3';
  const callId = 'test_call_1760506267900';

  try {
    console.log('📊 Checking Firestore for call document...');
    console.log('   Path: users/' + userId + '/calls/' + callId);

    const docRef = db.collection('users').doc(userId).collection('calls').doc(callId);
    const doc = await docRef.get();

    if (!doc.exists) {
      console.log('❌ Document not found!');
      return;
    }

    console.log('\n✅ Document found!');
    console.log('\n📄 Document data:');
    const data = doc.data();

    // Pretty print
    console.log(JSON.stringify(data, null, 2));

    console.log('\n🔍 Key fields:');
    console.log('   status:', data.status);
    console.log('   analysisStatus:', data.analysisStatus);
    console.log('   fileName:', data.fileName);
    console.log('   filePath:', data.filePath);
    console.log('   updatedAt:', data.updatedAt?.toDate?.());

  } catch (error) {
    console.error('❌ Error checking Firestore:', error);
    throw error;
  }
}

checkFirestore()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
```

### 5.2 스크립트 실행

```bash
node check_firestore.js
```

**예상 출력:**
```
📊 Checking Firestore for call document...
   Path: users/7wll6D15YZgVrL7jEO1dJhyCUKG3/calls/test_call_1760506267900

✅ Document found!

📄 Document data:
{
  "userId": "7wll6D15YZgVrL7jEO1dJhyCUKG3",
  "seniorId": "test_senior_001",
  "fileName": "통화 녹음 어머니_250505_122325.m4a",
  "status": "pending",
  "analysisStatus": "pending",
  "metadata": {
    "device": "test",
    "version": "1.0.0"
  },
  "createdAt": { "_seconds": 1760506269, "_nanoseconds": 91000000 },
  "recordedAt": { "_seconds": 1760506269, "_nanoseconds": 91000000 },
  "updatedAt": { "_seconds": 1760506269, "_nanoseconds": 91000000 }
}

🔍 Key fields:
   status: pending
   analysisStatus: pending
   fileName: 통화 녹음 어머니_250505_122325.m4a
   filePath: undefined
   updatedAt: 2025-10-15T05:31:09.091Z
```

---

## Step 6: Firebase Console에서 확인

### 6.1 Authentication

1. [Authentication Console](https://console.firebase.google.com/project/my-project-54928-b9704/authentication/users)
2. `test@test.com` 사용자 확인

### 6.2 Firestore

1. [Firestore Console](https://console.firebase.google.com/project/my-project-54928-b9704/firestore/databases/-default-/data)
2. 경로 확인: `users/{userId}/calls/{callId}`
3. 문서 데이터 확인

### 6.3 Storage

1. [Storage Console](https://console.firebase.google.com/project/my-project-54928-b9704/storage)
2. 경로 확인: `calls/{userId}/{seniorId}/{callId}/{fileName}`
3. 파일 존재 확인 (1.59 MB)

---

## 📊 생성된 테스트 데이터 요약

### Firebase Authentication
```
Email: test@test.com
Password: test1234
UID: 7wll6D15YZgVrL7jEO1dJhyCUKG3
```

### Firestore
```
Collection: users
Document: 7wll6D15YZgVrL7jEO1dJhyCUKG3
Sub-collection: calls
Document: test_call_1760506267900

Data:
- userId: 7wll6D15YZgVrL7jEO1dJhyCUKG3
- seniorId: test_senior_001
- fileName: 통화 녹음 어머니_250505_122325.m4a
- status: pending
- analysisStatus: pending
- createdAt: [timestamp]
- updatedAt: [timestamp]
```

### Storage
```
Bucket: my-project-54928-b9704.firebasestorage.app
Path: calls/7wll6D15YZgVrL7jEO1dJhyCUKG3/test_senior_001/test_call_1760506267900/통화 녹음 어머니_250505_122325.m4a
Size: 1.59 MB
Content-Type: audio/m4a
```

---

## 🎯 Web App에서 표시될 데이터

### 로그인 정보
```
Email: test@test.com
Password: test1234
```

### 대시보드에 표시될 내용
- 총 통화 수: 1건
- 최근 통화: 통화 녹음 어머니_250505_122325.m4a
- 분석 상태: pending
- 업로드 시간: [timestamp]

### Calls 페이지
| Call ID | Senior ID | File Name | Status | Created At |
|---------|-----------|-----------|--------|------------|
| test_call_... | test_senior_001 | 통화 녹음 어머니... | pending | 2025-10-15 |

---

## 🔧 추가 테스트 데이터 생성

더 많은 테스트 데이터가 필요한 경우:

### 1. 여러 통화 기록 생성

```javascript
// create_multiple_calls.js
async function createMultipleCalls() {
  const userId = '7wll6D15YZgVrL7jEO1dJhyCUKG3';
  const seniorIds = ['senior_001', 'senior_002', 'senior_003'];
  const fileNames = [
    '통화 녹음 어머니_250505_122325.m4a',
    '통화 녹음 어머니_250512_122325.m4a',
    '통화 녹음 어머니_250519_122325.m4a'
  ];

  for (let i = 0; i < 3; i++) {
    const callId = `test_call_${Date.now()}_${i}`;
    const callData = {
      userId: userId,
      seniorId: seniorIds[i],
      fileName: fileNames[i],
      status: i === 0 ? 'completed' : 'pending',
      analysisStatus: i === 0 ? 'completed' : 'pending',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      recordedAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    await db.collection('users').doc(userId).collection('calls').doc(callId).set(callData);
    console.log(`✅ Created call ${i + 1}: ${callId}`);

    // 1초 대기 (Timestamp 구분)
    await new Promise(resolve => setTimeout(resolve, 1000));
  }
}
```

### 2. Senior 프로필 생성

```javascript
// create_senior_profiles.js
async function createSeniorProfiles() {
  const userId = '7wll6D15YZgVrL7jEO1dJhyCUKG3';
  const seniors = [
    {
      seniorId: 'test_senior_001',
      name: '김영희',
      age: 75,
      phone: '010-1234-5678'
    },
    {
      seniorId: 'test_senior_002',
      name: '이철수',
      age: 80,
      phone: '010-2345-6789'
    }
  ];

  for (const senior of seniors) {
    await db.collection('users').doc(userId).collection('seniors').doc(senior.seniorId).set(senior);
    console.log(`✅ Created senior: ${senior.name}`);
  }
}
```

---

## ✅ 체크리스트

완료 여부를 확인하세요:

- [ ] Firebase Authentication에 `test@test.com` 사용자 생성
- [ ] 사용자 UID 확인
- [ ] Firebase Admin SDK 설치 (`npm install firebase-admin`)
- [ ] `create_test_call.js` 작성 및 실행
- [ ] Call ID 기록
- [ ] `upload_test_file.js` 작성 및 실행
- [ ] Storage에 파일 업로드 확인
- [ ] `check_firestore.js` 작성 및 실행
- [ ] Firestore 데이터 확인
- [ ] Firebase Console에서 모든 데이터 확인
  - [ ] Authentication
  - [ ] Firestore
  - [ ] Storage

---

## 🚀 다음 단계

테스트 데이터 생성이 완료되면:

1. **Week 6: Vercel 배포** 진행
2. Web App에서 `test@test.com`으로 로그인
3. 대시보드에서 테스트 데이터 확인
4. Calls 페이지에서 업로드된 통화 기록 확인

---

## 🔗 참고 링크

- [Firebase Authentication Console](https://console.firebase.google.com/project/my-project-54928-b9704/authentication/users)
- [Firestore Console](https://console.firebase.google.com/project/my-project-54928-b9704/firestore/databases/-default-/data)
- [Storage Console](https://console.firebase.google.com/project/my-project-54928-b9704/storage)
- [Functions Logs](https://console.firebase.google.com/project/my-project-54928-b9704/functions/logs)
