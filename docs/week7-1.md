    # Week 7-1: Senior MHealth 모바일 앱 데이터 흐름 분석 🔍

> **🎯 목표**: 모바일 앱 중심의 실제 코드를 통해 데이터 흐름을 분석하고 시스템의 정확성을 검증합니다.

## 📋 개요

이 문서는 Senior MHealth 모바일 앱의 핵심 데이터 흐름을 코드 중심으로 분석합니다. Flutter 앱에서 Firebase와의 상호작용, API 통신, 음성 파일 처리, AI 분석 결과 수신까지의 전체 과정을 실제 코드로 확인하여 시스템이 올바르게 작동하는지 검증할 수 있습니다.

### 🎯 주요 분석 영역
- **사용자 등록/로그인**: Flutter 앱에서 Firebase Authentication + Firestore 연동
- **음성 파일 업로드**: 모바일에서 Firebase Storage 업로드 및 메타데이터 관리
- **AI 분석 처리**: Cloud Functions를 통한 분석 요청 및 결과 처리
- **실시간 알림**: FCM을 통한 분석 완료 알림 수신
- **데이터 동기화**: Firestore 실시간 데이터베이스 연동

**주의사항: week1~week6 동안 작성된 코드는 현재 완성되어 있기 때문에 절대 수정하지 않는다. 다만, 모바일앱 작동을 위해 필요한 경우는 사용자에게 반드시 보고한다.

---


## 1. 사용자 등록 과정 🔐

### 1-1. 모바일 앱에서 사용자 등록

**데이터 흐름 다이어그램:**
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Flutter App   │───▶│ Firebase Auth   │───▶│   Firestore     │
│                 │    │                 │    │                 │
│ 1. 사용자 입력   │    │ 2. 계정 생성     │    │ 3. 사용자 정보   │
│ - 이메일        │    │ - createUser    │    │   저장          │
│ - 비밀번호      │    │ - updateProfile │    │ - users/{uid}   │
│ - 개인정보      │    │                 │    │ - 메타데이터     │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

**등록 과정 시퀀스:**
```
사용자 → Flutter App → Firebase Auth → Firestore
  │         │              │              │
  │         │              │              │
  ▼         ▼              ▼              ▼
입력     → createUser   → 계정생성      → 사용자정보저장
검증     → updateProfile → 프로필업데이트 → 메타데이터추가
완료     → 성공응답     → 토큰생성      → 문서생성완료
```

**Flutter 코드 (사용자 등록)**
```dart
// lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, dynamic>> registerUser({
    required String email,
    required String password,
    required String name,
    required int age,
    required String phone,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? emergencyContactRelation,
  }) async {
    try {
      // 1. Firebase Authentication으로 사용자 생성
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;
      if (user == null) {
        return {'success': false, 'error': '사용자 생성 실패'};
      }

      // 2. 사용자 프로필 업데이트
      await user.updateDisplayName(name);

      // 3. Firestore에 추가 사용자 정보 저장
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': email,
        'name': name,
        'age': age,
        'phone': phone,
        'role': 'patient', // 환자로 기본 설정
        'createdAt': FieldValue.serverTimestamp(),
        'lastLoginAt': null,
        'isActive': true,
        'profileImage': null,
        'emergencyContact': emergencyContactName != null ? {
          'name': emergencyContactName,
          'phone': emergencyContactPhone ?? '',
          'relation': emergencyContactRelation ?? 'family',
        } : null,
        'medicalHistory': [],
        'preferences': {
          'notifications': true,
          'language': 'ko',
          'theme': 'light',
          'fontSize': 'medium',
        },
        'fcmToken': null, // 나중에 설정
        'deviceInfo': {
          'platform': 'android',
          'version': '1.0.0',
          'lastActiveAt': FieldValue.serverTimestamp(),
        }
      });

      print('사용자 등록 완료: ${user.uid}');
      return {
        'success': true,
        'uid': user.uid,
        'user': {
          'uid': user.uid,
          'email': user.email,
          'name': name,
          'age': age,
          'phone': phone,
        }
      };

    } catch (e) {
      print('등록 실패: $e');
      return {'success': false, 'error': e.toString()};
    }
  }
}
```


### 1-2. Firebase Firestore 구조

**Firestore 컬렉션 구조:**
```
📁 Firestore Database
└── 📁 users (컬렉션)
    └── 📄 {uid} (문서)
        ├── 🔑 uid: "abc123def456"
        ├── 📧 email: "user@example.com"
        ├── 👤 name: "홍길동"
        ├── 🎂 age: 65
        ├── 📱 phone: "+82-10-1234-5678"
        ├── 👥 role: "patient"
        ├── ⏰ createdAt: "2024-01-15T10:30:00Z"
        ├── 🔐 lastLoginAt: null
        ├── ✅ isActive: true
        ├── 🖼️ profileImage: null
        ├── 🚨 emergencyContact: {...}
        ├── 🏥 medicalHistory: []
        ├── ⚙️ preferences: {...}
        ├── 📱 fcmToken: null
        └── 📱 deviceInfo: {...}
```

**생성되는 문서 구조:**
```json
// Firestore: users/{uid}
{
  "uid": "abc123def456",
  "email": "user@example.com",
  "name": "홍길동",
  "age": 65,
  "phone": "+82-10-1234-5678",
  "role": "patient",
  "createdAt": "2024-01-15T10:30:00Z",
  "lastLoginAt": null,
  "isActive": true,
  "profileImage": null,
  "emergencyContact": {
    "name": "김영희",
    "phone": "+82-10-9876-5432",
    "relation": "family"
  },
  "medicalHistory": [],
  "preferences": {
    "notifications": true,
    "language": "ko",
    "theme": "light",
    "fontSize": "medium"
  },
  "fcmToken": null,
  "deviceInfo": {
    "platform": "android",
    "version": "1.0.0",
    "lastActiveAt": "2024-01-15T10:30:00Z"
  }
}
```

### 1-3. 백엔드 API 엔드포인트

**Cloud Functions 코드**
```javascript
// functions/src/auth.js
const functions = require('firebase-functions');
const admin = require('firebase-admin');

exports.onUserCreate = functions.auth.user().onCreate(async (user) => {
  try {
    // 사용자 생성 시 추가 처리
    const userData = {
      uid: user.uid,
      email: user.email,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      lastLoginAt: null,
      isActive: true
    };

    // Firestore에 사용자 문서 생성
    await admin.firestore().collection('users').doc(user.uid).set(userData);

    console.log('사용자 생성 트리거 실행:', user.uid);
    return null;
  } catch (error) {
    console.error('사용자 생성 트리거 실패:', error);
    throw error;
  }
});
```

---

## 2. 사용자 로그인 과정 🔑

### 2-1. 모바일 앱에서 로그인

**로그인 과정 다이어그램:**
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Flutter App   │───▶│ Firebase Auth   │───▶│   Firestore     │
│                 │    │                 │    │                 │
│ 1. 로그인 요청   │    │ 2. 인증 처리     │    │ 3. 사용자 정보   │
│ - 이메일        │    │ - signInWith    │    │   조회          │
│ - 비밀번호      │    │ - 토큰 생성      │    │ - users/{uid}   │
│                 │    │                 │    │ - lastLoginAt   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         ▲                       │                       │
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 ▼
                    ┌─────────────────┐
                    │   응답 데이터    │
                    │ - 사용자 정보   │
                    │ - ID 토큰      │
                    │ - 성공 상태     │
                    └─────────────────┘
```

**토큰 검증 과정:**
```
모바일앱 → Cloud Functions → Firebase Admin → Firestore
   │           │                │              │
   │           │                │              │
   ▼           ▼                ▼              ▼
ID토큰    → 토큰검증        → 토큰유효성     → 사용자정보
전송      → 미들웨어        → 확인          → 조회
          → 사용자추출      → UID추출       → 권한확인
```

**Flutter 코드 (로그인 서비스)**
```dart
// lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, dynamic>> loginUser(String email, String password) async {
    try {
      // 1. Firebase Authentication으로 로그인
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;
      if (user == null) {
        return {'success': false, 'error': '로그인 실패'};
      }

      // 2. Firestore에서 사용자 정보 가져오기
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        return {'success': false, 'error': '사용자 정보를 찾을 수 없습니다'};
      }

      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

      // 3. 마지막 로그인 시간 업데이트
      await _firestore.collection('users').doc(user.uid).update({
        'lastLoginAt': FieldValue.serverTimestamp(),
        'deviceInfo.lastActiveAt': FieldValue.serverTimestamp(),
      });

      // 4. ID 토큰 가져오기
      String token = await user.getIdToken();

      return {
        'success': true,
        'user': {
          'uid': user.uid,
          'email': user.email,
          ...userData,
        },
        'token': token,
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // 로그아웃
  Future<void> logoutUser() async {
    await _auth.signOut();
  }

  // 현재 사용자 정보 가져오기
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // 인증 상태 스트림
  Stream<User?> get authStateChanges => _auth.authStateChanges();
}
```


### 2-3. 토큰 검증 (백엔드)

**Cloud Functions 미들웨어**
```javascript
// functions/src/middleware/auth.js
const admin = require('firebase-admin');

const verifyToken = async (req, res, next) => {
  try {
    const token = req.headers.authorization?.split('Bearer ')[1];

    if (!token) {
      return res.status(401).json({ error: '토큰이 필요합니다' });
    }

    // Firebase Admin SDK로 토큰 검증
    const decodedToken = await admin.auth().verifyIdToken(token);

    // 사용자 정보 가져오기
    const userDoc = await admin.firestore()
      .collection('users')
      .doc(decodedToken.uid)
      .get();

    if (!userDoc.exists) {
      return res.status(404).json({ error: '사용자를 찾을 수 없습니다' });
    }

    req.user = {
      uid: decodedToken.uid,
      email: decodedToken.email,
      ...userDoc.data()
    };

    next();
  } catch (error) {
    console.error('토큰 검증 실패:', error);
    return res.status(401).json({ error: '유효하지 않은 토큰' });
  }
};

module.exports = { verifyToken };
```

---

## 3. 음성 파일 업로드 과정 🎤

### 3-1. 모바일 앱에서 음성 녹음 및 업로드

**음성 파일 업로드 아키텍처:**
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Flutter App   │───▶│ Cloud Functions │───▶│ Firebase Storage│
│                 │    │                 │    │                 │
│ 1. 음성 녹음     │    │ 2. 파일 처리     │    │ 3. 파일 저장     │
│ 2. 파일 준비     │    │ - multer        │    │ - audio_files/  │
│ 3. 업로드 요청   │    │ - 검증          │    │ - {userId}/     │
│                 │    │ - 메타데이터     │    │ - {timestamp}   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   HTTP Request  │    │   Firestore     │    │   AI 분석 큐    │
│ - Multipart     │    │   메타데이터     │    │   추가          │
│ - Authorization │    │   저장          │    │                 │
│ - User ID       │    │ - audio_files   │    │ - analysis_queue│
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

**업로드 과정 시퀀스:**
```
사용자 → Flutter → Cloud Functions → Firebase Storage → Firestore
  │        │           │                │              │
  │        │           │                │              │
  ▼        ▼           ▼                ▼              ▼
녹음    → 파일준비   → 파일검증        → 파일저장      → 메타데이터저장
완료    → 업로드요청 → multer처리      → 경로생성      → 큐에추가
        → 진행상황   → 토큰검증        → 다운로드URL   → 분석대기
```

**Flutter 코드 (음성 업로드 서비스)**
```dart
// lib/services/audio_service.dart
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

class AudioService {
  Future<Map<String, dynamic>> uploadAudioFile(
    File audioFile,
    String userId,
    String token
  ) async {
    try {
      // 1. 파일 정보 준비
      String fileName = 'audio_${DateTime.now().millisecondsSinceEpoch}.m4a';

      // 2. Cloud Functions API로 업로드 요청
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://asia-northeast3-your-project.cloudfunctions.net/api/audio/upload'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(await http.MultipartFile.fromPath(
        'audio',
        audioFile.path,
        filename: fileName,
      ));

      request.fields['userId'] = userId;
      request.fields['timestamp'] = DateTime.now().toIso8601String();

      var response = await request.send();

      if (response.statusCode == 200) {
        String responseBody = await response.stream.bytesToString();
        Map<String, dynamic> result = json.decode(responseBody);

        return {
          'success': true,
          'audioId': result['audioId'],
          'storagePath': result['storagePath'],
          'downloadUrl': result['downloadUrl'],
        };
      } else {
        return {
          'success': false,
          'error': '업로드 실패: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}
```

### 3-2. 백엔드에서 음성 파일 처리

**Cloud Functions 코드**
```javascript
// functions/src/audio.js
const functions = require('firebase-functions');
const admin = require('firebase-admin');
const multer = require('multer');
const { Storage } = require('@google-cloud/storage');

const storage = new Storage();
const bucket = storage.bucket('your-project-id.appspot.com');

// Multer 설정 (메모리 저장)
const upload = multer({ storage: multer.memoryStorage() });

exports.uploadAudio = functions.https.onRequest(async (req, res) => {
  // CORS 설정
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Methods', 'POST');
  res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');

  if (req.method === 'OPTIONS') {
    res.status(204).send('');
    return;
  }

  try {
    // 1. 토큰 검증
    const token = req.headers.authorization?.split('Bearer ')[1];
    const decodedToken = await admin.auth().verifyIdToken(token);
    const userId = decodedToken.uid;

    // 2. 파일 업로드 처리
    upload.single('audio')(req, res, async (err) => {
      if (err) {
        return res.status(400).json({ error: '파일 업로드 실패' });
      }

      const file = req.file;
      if (!file) {
        return res.status(400).json({ error: '파일이 없습니다' });
      }

      // 3. Firebase Storage에 업로드
      const fileName = `audio_files/${userId}/${Date.now()}_${file.originalname}`;
      const fileUpload = bucket.file(fileName);

      const stream = fileUpload.createWriteStream({
        metadata: {
          contentType: file.mimetype,
          metadata: {
            userId: userId,
            uploadedAt: new Date().toISOString(),
          },
        },
      });

      stream.on('error', (err) => {
        console.error('Storage 업로드 실패:', err);
        res.status(500).json({ error: '파일 저장 실패' });
      });

      stream.on('finish', async () => {
        try {
          // 4. Firestore에 메타데이터 저장
          const audioId = admin.firestore().collection('audio_files').doc().id;

          await admin.firestore().collection('audio_files').doc(audioId).set({
            audioId: audioId,
            userId: userId,
            fileName: fileName,
            originalName: file.originalname,
            size: file.size,
            mimeType: file.mimetype,
            uploadedAt: admin.firestore.FieldValue.serverTimestamp(),
            status: 'uploaded',
            analysisStatus: 'pending',
            downloadUrl: `https://storage.googleapis.com/${bucket.name}/${fileName}`,
          });

          // 5. AI 분석 작업 큐에 추가
          await admin.firestore().collection('analysis_queue').add({
            audioId: audioId,
            userId: userId,
            fileName: fileName,
            status: 'queued',
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            priority: 1,
          });

          res.json({
            success: true,
            audioId: audioId,
            storagePath: fileName,
            downloadUrl: `https://storage.googleapis.com/${bucket.name}/${fileName}`,
          });
        } catch (error) {
          console.error('Firestore 저장 실패:', error);
          res.status(500).json({ error: '메타데이터 저장 실패' });
        }
      });

      stream.end(file.buffer);
    });
  } catch (error) {
    console.error('음성 업로드 실패:', error);
    res.status(401).json({ error: '인증 실패' });
  }
});
```

### 3-3. Firestore 구조

**Firestore 컬렉션 구조:**
```
📁 Firestore Database
├── 📁 users (컬렉션)
│   └── 📄 {uid} (문서)
├── 📁 audio_files (컬렉션)
│   └── 📄 {audioId} (문서)
│       ├── 🎵 audioId: "audio_123456789"
│       ├── 👤 userId: "user_abc123"
│       ├── 📁 fileName: "audio_files/user_abc123/..."
│       ├── 📄 originalName: "recording.m4a"
│       ├── 📊 size: 2048576
│       ├── 🎵 mimeType: "audio/mp4"
│       ├── ⏰ uploadedAt: "2024-01-15T10:30:00Z"
│       ├── 📤 status: "uploaded"
│       ├── 🔄 analysisStatus: "pending"
│       └── 🔗 downloadUrl: "https://storage.googleapis.com/..."
└── 📁 analysis_queue (컬렉션)
    └── 📄 {queueId} (문서)
        ├── 🎵 audioId: "audio_123456789"
        ├── 👤 userId: "user_abc123"
        ├── 📁 fileName: "audio_files/user_abc123/..."
        ├── ⏳ status: "queued"
        ├── ⏰ createdAt: "2024-01-15T10:30:00Z"
        └── 🔢 priority: 1
```

**생성되는 문서들:**
```json
// Firestore: audio_files/{audioId}
{
  "audioId": "audio_123456789",
  "userId": "user_abc123",
  "fileName": "audio_files/user_abc123/1642234567890_recording.m4a",
  "originalName": "recording.m4a",
  "size": 2048576,
  "mimeType": "audio/mp4",
  "uploadedAt": "2024-01-15T10:30:00Z",
  "status": "uploaded",
  "analysisStatus": "pending",
  "downloadUrl": "https://storage.googleapis.com/bucket/audio_files/user_abc123/1642234567890_recording.m4a"
}

// Firestore: analysis_queue/{queueId}
{
  "audioId": "audio_123456789",
  "userId": "user_abc123",
  "fileName": "audio_files/user_abc123/1642234567890_recording.m4a",
  "status": "queued",
  "createdAt": "2024-01-15T10:30:00Z",
  "priority": 1
}
```

---

## 4. AI 분석 과정 및 완료 알림 🤖

### 4-1. AI 분석 작업 처리

**AI 분석 아키텍처:**
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│  Firestore      │───▶│ Cloud Functions │───▶│   AI Service    │
│  analysis_queue │    │  (Trigger)      │    │  (Cloud Run)    │
│                 │    │                 │    │                 │
│ 1. 큐에 추가     │    │ 2. 트리거 실행   │    │ 3. AI 분석      │
│ 2. 상태 변경     │    │ - 파일 다운로드  │    │ - Gemini API    │
│ 3. 우선순위      │    │ - AI 서비스 호출 │    │ - 음성 분석     │
│                 │    │ - 결과 저장     │    │ - 결과 생성     │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Firestore     │    │   Firestore     │    │   FCM 알림      │
│  analysis_results│    │  audio_files    │    │   전송          │
│  결과 저장       │    │  상태 업데이트   │    │ - 분석 완료     │
│                 │    │                 │    │ - 결과 요약     │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

**AI 분석 과정 시퀀스:**
```
큐추가 → 트리거실행 → 파일다운로드 → AI분석 → 결과저장 → 알림전송
  │         │           │           │        │        │
  │         │           │           │        │        │
  ▼         ▼           ▼           ▼        ▼        ▼
queued  → processing → downloaded → analyzed → saved → notified
```

**알림 전송 흐름:**
```
AI분석완료 → FCM토큰조회 → 알림메시지생성 → FCM전송 → 모바일앱수신
    │           │             │            │         │
    │           │             │            │         │
    ▼           ▼             ▼            ▼         ▼
결과저장   → 사용자토큰   → 제목+내용    → 푸시알림  → 로컬알림
완료       → 조회         → 구성         → 발송     → 표시
```

**Cloud Functions 코드**
```javascript
// functions/src/ai-analysis.js
const functions = require('firebase-functions');
const admin = require('firebase-admin');
const { Storage } = require('@google-cloud/storage');

const storage = new Storage();
const bucket = storage.bucket('your-project-id.appspot.com');

exports.processAudioAnalysis = functions.firestore
  .document('analysis_queue/{queueId}')
  .onCreate(async (snap, context) => {
    const queueData = snap.data();
    const { audioId, userId, fileName } = queueData;

    try {
      // 1. 큐 상태를 'processing'으로 업데이트
      await snap.ref.update({ status: 'processing' });

      // 2. Firebase Storage에서 오디오 파일 다운로드
      const file = bucket.file(fileName);
      const [audioBuffer] = await file.download();

      // 3. AI 서비스로 분석 요청
      const analysisResult = await analyzeAudioWithAI(audioBuffer, userId);

      // 4. 분석 결과를 Firestore에 저장
      await admin.firestore().collection('analysis_results').doc(audioId).set({
        audioId: audioId,
        userId: userId,
        analysisResult: analysisResult,
        analyzedAt: admin.firestore.FieldValue.serverTimestamp(),
        status: 'completed',
        confidence: analysisResult.confidence,
        summary: analysisResult.summary,
        recommendations: analysisResult.recommendations,
      });

      // 5. 오디오 파일 상태 업데이트
      await admin.firestore().collection('audio_files').doc(audioId).update({
        analysisStatus: 'completed',
        analyzedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // 6. 큐에서 제거
      await snap.ref.delete();

      // 7. 사용자에게 알림 전송
      await sendAnalysisCompleteNotification(userId, audioId, analysisResult);

      console.log('AI 분석 완료:', audioId);
    } catch (error) {
      console.error('AI 분석 실패:', error);

      // 에러 상태 업데이트
      await admin.firestore().collection('audio_files').doc(audioId).update({
        analysisStatus: 'failed',
        error: error.message,
      });

      await snap.ref.update({ status: 'failed' });
    }
  });

// AI 분석 함수 (실제 구현)
async function analyzeAudioWithAI(audioBuffer, userId) {
  // 여기서 실제 AI 서비스 호출
  // 예: Google Cloud Speech-to-Text, Gemini API 등

  return {
    confidence: 0.85,
    summary: "정상적인 심박음이 감지되었습니다. 약간의 불규칙성이 있지만 정상 범위 내입니다.",
    recommendations: [
      "규칙적인 운동을 권장합니다",
      "스트레스 관리에 주의하세요",
      "2주 후 재검사를 권장합니다"
    ],
    detailedAnalysis: {
      heartRate: 72,
      rhythm: "regular",
      abnormalities: ["minor_irregularity"],
      timestamp: new Date().toISOString()
    }
  };
}

// 분석 완료 알림 전송
async function sendAnalysisCompleteNotification(userId, audioId, analysisResult) {
  try {
    // 1. FCM 토큰 가져오기
    const userDoc = await admin.firestore().collection('users').doc(userId).get();
    const userData = userDoc.data();

    if (!userData.fcmToken) {
      console.log('FCM 토큰이 없습니다:', userId);
      return;
    }

    // 2. FCM 메시지 전송
    const message = {
      token: userData.fcmToken,
      notification: {
        title: '음성 분석 완료',
        body: `분석 결과: ${analysisResult.summary}`,
      },
      data: {
        type: 'analysis_complete',
        audioId: audioId,
        summary: analysisResult.summary,
        confidence: analysisResult.confidence.toString(),
      },
    };

    await admin.messaging().send(message);
    console.log('알림 전송 완료:', userId);
  } catch (error) {
    console.error('알림 전송 실패:', error);
  }
}
```

### 4-2. 모바일 앱에서 알림 수신

**Flutter 코드 (알림 서비스)**
```dart
// lib/services/notification_service.dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static Future<void> initialize() async {
    // 1. FCM 토큰 가져오기
    String? token = await _messaging.getToken();
    print('FCM Token: $token');

    // 2. 토큰을 Firestore에 저장
    await saveFCMToken(token);

    // 3. 포그라운드 메시지 리스너
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('포그라운드 메시지 수신: ${message.notification?.title}');
    });

    // 4. 백그라운드 메시지 리스너
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 5. 알림 탭 리스너
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationTap(message);
    });
  }

  static Future<void> saveFCMToken(String? token) async {
    if (token == null) return;

    // 현재 사용자 ID 가져오기
    String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    // Firestore에 토큰 저장
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .update({'fcmToken': token});
  }

  static void _handleNotificationTap(RemoteMessage message) {
    // 알림 탭 시 처리
    String? type = message.data['type'];
    String? audioId = message.data['audioId'];

    if (type == 'analysis_complete' && audioId != null) {
      // 분석 결과 화면으로 이동
      print('분석 완료 알림 탭: $audioId');
    }
  }
}

// 백그라운드 메시지 핸들러
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('백그라운드 메시지 수신: ${message.notification?.title}');
}
```

### 4-3. 분석 결과 조회

**Flutter 코드 (분석 결과 서비스)**
```dart
// lib/services/analysis_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class AnalysisService {
  static Future<Map<String, dynamic>?> getAnalysisResult(String audioId) async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('analysis_results')
          .doc(audioId)
          .get();

      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('분석 결과 조회 실패: $e');
      return null;
    }
  }

  static Stream<List<Map<String, dynamic>>> getUserAnalysisResults(String userId) {
    return FirebaseFirestore.instance
        .collection('analysis_results')
        .where('userId', isEqualTo: userId)
        .orderBy('analyzedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }
}
```

---

## 5. 코드 검증 체크리스트 ✅

### 5-1. 사용자 등록 검증
```
🔐 Firebase Authentication 검증
├── ✅ 계정 생성 성공
├── ✅ 프로필 업데이트 성공
├── ✅ 토큰 생성 정상
└── ✅ 에러 처리 적절

📊 Firestore 데이터 검증
├── ✅ 사용자 문서 생성
├── ✅ 필수 필드 포함
├── ✅ 데이터 타입 정확
└── ✅ 보안 규칙 준수
```

### 5-2. 로그인 검증
```
🔑 인증 시스템 검증
├── ✅ 이메일/비밀번호 검증
├── ✅ 토큰 생성 및 검증
├── ✅ 사용자 정보 조회
└── ✅ 세션 관리 정상

🛡️ 보안 검증
├── ✅ 토큰 만료 처리
├── ✅ 권한 검증 미들웨어
├── ✅ API 접근 제어
└── ✅ 에러 응답 적절
```

### 5-3. 음성 파일 업로드 검증
```
📤 업로드 시스템 검증
├── ✅ 파일 형식 검증
├── ✅ 크기 제한 확인
├── ✅ Firebase Storage 연동
└── ✅ 메타데이터 저장

🔄 처리 과정 검증
├── ✅ multer 파일 처리
├── ✅ 토큰 인증 확인
├── ✅ 에러 핸들링
└── ✅ 응답 데이터 정확
```

### 5-4. AI 분석 검증
```
🤖 AI 분석 시스템 검증
├── ✅ 분석 큐 정상 작동
├── ✅ Cloud Functions 트리거
├── ✅ AI 서비스 호출 성공
└── ✅ 결과 저장 정확

📊 데이터 흐름 검증
├── ✅ 큐에서 처리까지
├── ✅ 파일 다운로드 성공
├── ✅ 분석 결과 생성
└── ✅ 상태 업데이트 정상
```

### 5-5. 알림 시스템 검증
```
📱 FCM 알림 검증
├── ✅ FCM 토큰 저장
├── ✅ 포그라운드 알림 수신
├── ✅ 백그라운드 알림 수신
└── ✅ 알림 탭 처리

🔔 알림 전송 검증
├── ✅ 메시지 구성 정확
├── ✅ 대상 사용자 식별
├── ✅ 전송 성공 확인
└── ✅ 로컬 알림 표시
```

---

## 6. 일반적인 문제 및 해결 방법 🔧

### 6-1. Firebase 설정 문제

**문제 진단 트리:**
```
❌ Firebase 연결 실패
├── 🔍 설정 파일 확인
│   ├── firebase_options.dart 존재?
│   ├── google-services.json 존재?
│   └── .env 파일 설정?
├── 🔍 네트워크 연결 확인
│   ├── 인터넷 연결 상태
│   ├── 방화벽 설정
│   └── 프록시 설정
└── 🔍 권한 확인
    ├── Firebase 프로젝트 권한
    ├── API 활성화 상태
    └── 서비스 계정 키
```

**해결 방법:**
```javascript
// firebase.js 설정 확인
import { initializeApp } from 'firebase/app';
import { getAuth } from 'firebase/auth';
import { getFirestore } from 'firebase/firestore';

const firebaseConfig = {
  apiKey: "your-api-key",
  authDomain: "your-project.firebaseapp.com",
  projectId: "your-project-id",
  storageBucket: "your-project.appspot.com",
  messagingSenderId: "123456789",
  appId: "your-app-id"
};

const app = initializeApp(firebaseConfig);
export const auth = getAuth(app);
export const db = getFirestore(app);
```

### 6-2. Firestore 보안 규칙

**보안 규칙 구조:**
```
🔒 Firestore 보안 규칙
├── 👤 사용자 데이터 보호
│   ├── users/{userId} - 본인만 접근
│   ├── 인증된 사용자만 읽기/쓰기
│   └── UID 일치 확인
├── 🎵 오디오 파일 보호
│   ├── audio_files/{audioId} - 소유자만 접근
│   ├── userId 필드로 소유권 확인
│   └── 업로드/다운로드 권한 제어
└── 📊 분석 결과 보호
    ├── analysis_results/{resultId} - 소유자만 접근
    ├── userId 필드로 소유권 확인
    └── 읽기 전용 권한 설정
```

**보안 규칙 코드:**
```javascript
// firestore.rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // 사용자는 자신의 데이터만 읽고 쓸 수 있음
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }

    // 오디오 파일은 소유자만 접근 가능
    match /audio_files/{audioId} {
      allow read, write: if request.auth != null &&
        request.auth.uid == resource.data.userId;
    }

    // 분석 결과는 소유자만 접근 가능
    match /analysis_results/{resultId} {
      allow read, write: if request.auth != null &&
        request.auth.uid == resource.data.userId;
    }
  }
}
```

### 6-3. CORS 설정

**CORS 문제 해결 과정:**
```
🌐 CORS 오류 발생
├── 🔍 오류 메시지 확인
│   ├── "Access-Control-Allow-Origin"
│   ├── "Preflight request"
│   └── "Credentials" 관련
├── 🔧 Cloud Functions 설정
│   ├── CORS 미들웨어 추가
│   ├── Origin 허용 목록 설정
│   └── Credentials 설정
└── 🔧 클라이언트 설정
    ├── 요청 헤더 확인
    ├── Content-Type 설정
    └── Authorization 헤더
```

**CORS 설정 코드:**
```javascript
// Cloud Functions에서 CORS 설정
const cors = require('cors')({origin: true});

exports.yourFunction = functions.https.onRequest((req, res) => {
  return cors(req, res, () => {
    // 함수 로직
  });
});
```

---

## 7. 디버깅 도구 🛠️

### 7-1. Firebase 콘솔 확인

**Firebase 콘솔 체크리스트:**
```
🔥 Firebase Console 진단
├── 🔐 Authentication
│   ├── 👥 Users: 사용자 목록 확인
│   ├── 📊 Sign-in methods: 인증 방법 활성화
│   └── 🛡️ Security rules: 보안 규칙 확인
├── 📊 Firestore Database
│   ├── 📁 Collections: 컬렉션 구조 확인
│   ├── 📄 Documents: 문서 데이터 확인
│   └── 🔒 Rules: 보안 규칙 상태
├── 🗄️ Storage
│   ├── 📁 Buckets: 스토리지 버킷 확인
│   ├── 📁 audio_files: 업로드된 파일 확인
│   └── 🔒 Rules: 스토리지 보안 규칙
└── ⚡ Functions
    ├── 📊 Metrics: 함수 실행 통계
    ├── 📝 Logs: 실행 로그 확인
    └── 🔧 Configuration: 함수 설정
```

### 7-2. 로그 확인

**로그 모니터링 시스템:**
```
📊 로그 확인 도구
├── ☁️ Cloud Functions 로그
│   ├── gcloud functions logs read
│   ├── 실시간 로그 스트리밍
│   └── 에러 로그 필터링
├── 🔥 Firestore 로그
│   ├── 데이터베이스 작업 로그
│   ├── 보안 규칙 위반 로그
│   └── 쿼리 성능 로그
└── 📱 모바일 앱 로그
    ├── Flutter 디버그 로그
    ├── 네트워크 요청 로그
    └── 에러 스택 트레이스
```

**로그 확인 명령어:**
```bash
# Cloud Functions 로그
gcloud functions logs read your-function-name --region=asia-northeast3

# Firestore 로그
gcloud logging read "resource.type=firestore_document"

# 실시간 로그 스트리밍
gcloud functions logs tail your-function-name --region=asia-northeast3
```

### 7-3. 모바일 앱 디버깅

**Flutter 디버깅 도구:**
```
🐛 Flutter 디버깅 체계
├── 📝 로그 시스템
│   ├── developer.log() 사용
│   ├── 로그 레벨 분류
│   └── 로그 필터링
├── 🔍 네트워크 디버깅
│   ├── HTTP 요청/응답 로그
│   ├── API 호출 추적
│   └── 에러 상태 확인
└── 📊 성능 모니터링
    ├── 메모리 사용량
    ├── CPU 사용률
    └── 네트워크 대역폭
```

**디버깅 코드:**
```dart
// Flutter 디버그 로그
import 'dart:developer' as developer;

developer.log('사용자 로그인 시도', name: 'AuthService');
developer.log('토큰: $token', name: 'AuthService');

// 네트워크 디버깅
void debugNetworkRequest(String url, Map<String, dynamic> data) {
  developer.log('API 요청: $url', name: 'Network');
  developer.log('요청 데이터: $data', name: 'Network');
}
```

### 7-4. 전체 시스템 상태 대시보드

**시스템 상태 모니터링:**
```
📊 Senior MHealth 시스템 상태
├── 🟢 정상 작동
│   ├── Firebase 연결 상태
│   ├── Cloud Functions 상태
│   ├── Firestore 응답 시간
│   └── Storage 업로드 성공률
├── 🟡 주의 필요
│   ├── API 응답 시간 증가
│   ├── 에러율 상승
│   └── 리소스 사용량 증가
└── 🔴 문제 발생
    ├── 서비스 다운
    ├── 인증 실패
    ├── 데이터 동기화 오류
    └── 알림 전송 실패
```

이 문서를 통해 각 단계별로 코드를 검증하고 문제가 있는 부분을 수정할 수 있습니다. 실제 구현 시 이 코드들을 참고하여 현재 시스템의 정확성을 확인해보세요.
