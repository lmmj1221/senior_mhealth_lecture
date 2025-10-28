/**
 * Senior mHealth Backend Functions
 * 학생 실습용 템플릿 - 주차별로 구현해주세요!
 */

const functions = require('firebase-functions');
const admin = require('firebase-admin');
const axios = require('axios');

// Firebase Admin 초기화
admin.initializeApp();

// Firestore 참조
const db = admin.firestore();
const auth = admin.auth();

// ============================================================================
// 2주차 TODO: Authentication API 구현
// ============================================================================

/**
 * 사용자 회원가입 API
 * POST /api/auth/register
 *
 * Body: {
 *   email: string,
 *   password: string,
 *   name: string,
 *   role: 'senior' | 'caregiver'
 * }
 */
// exports.authAPI = functions.https.onRequest(async (req, res) => {
//   // TODO: 2주차에 구현하세요
//   // 1. Express 앱 설정
//   // 2. CORS 설정
//   // 3. 회원가입 엔드포인트 구현
//   // 4. 로그인 엔드포인트 구현
//   // 5. Custom Claims 설정
// });

// ============================================================================
// 3주차 TODO: Health Data CRUD API 구현
// ============================================================================

/**
 * 건강 데이터 CRUD API
 * GET/POST/PUT/DELETE /api/health-data
 */
// exports.healthAPI = functions.https.onRequest(async (req, res) => {
//   // TODO: 3주차에 구현하세요
//   // 1. 건강 데이터 생성 (CREATE)
//   // 2. 건강 데이터 조회 (READ)
//   // 3. 건강 데이터 수정 (UPDATE)
//   // 4. 건강 데이터 삭제 (DELETE)
//   // 5. 실시간 리스너 설정
// });

// ============================================================================
// 4주차 TODO: Cloud Functions 트리거 및 스케줄러 구현
// ============================================================================

/**
 * Firestore 트리거 - 건강 데이터 변경 감지
 */
// exports.detectHealthAnomaly = functions.firestore
//   .document('users/{userId}/healthData/{docId}')
//   .onCreate(async (snap, context) => {
//     // TODO: 4주차에 구현하세요
//     // 1. 건강 이상 수치 감지
//     // 2. alerts 컬렉션에 알림 생성
//     // 3. 보호자에게 알림 발송 준비
//   });

/**
 * 스케줄 함수 - 일일 리포트 생성
 */
// exports.dailyReportScheduler = functions.pubsub
//   .schedule('0 9 * * *')
//   .timeZone('Asia/Seoul')
//   .onRun(async (context) => {
//     // TODO: 4주차에 구현하세요
//     // 1. 모든 활성 사용자 조회
//     // 2. 전날 건강 데이터 집계
//     // 3. 일일 리포트 생성
//     // 4. reports 컬렉션에 저장
//   });

/**
 * HTTP Functions - 리포트 생성 API
 */
// exports.reportAPI = functions.https.onRequest(async (req, res) => {
//   // TODO: 4주차에 구현하세요
//   // 1. POST /api/reports/generate 엔드포인트
//   // 2. 건강 데이터 집계 및 분석
//   // 3. PDF 또는 JSON 형식으로 리포트 생성
// });

// ============================================================================
// 5주차 TODO: Storage, AI 연동, FCM 알림 구현
// ============================================================================

/**
 * 음성 파일 업로드 API
 */
// exports.voiceAPI = functions.https.onRequest(async (req, res) => {
//   // TODO: 5주차에 구현하세요
//   // 1. POST /api/voice/upload 엔드포인트
//   // 2. Multer로 파일 업로드 처리
//   // 3. Cloud Storage에 저장
//   // 4. 메타데이터 Firestore 저장
// });

const FormData = require('form-data');

/**
 * Storage 트리거 - 음성 파일 자동 처리 (v2)
 */
const {onObjectFinalized} = require('firebase-functions/v2/storage');

exports.processVoiceFile = onObjectFinalized({
  region: 'asia-northeast3',
  timeoutSeconds: 540,
  memory: '1GiB',
  bucket: 'credible-runner-474101-f6.firebasestorage.app'
}, async (event) => {
    const object = event.data;
    const filePath = object.name;
    const bucketName = object.bucket;
    const metadata = object.metadata || {};

    functions.logger.info('🔔 Storage 트리거 발생:', filePath);
    
    // 음성 파일 경로인지 확인 (calls/{userId}/{seniorId}/{callId}/filename)
    if (!filePath.startsWith('calls/')) {
      functions.logger.info('❌ 음성 파일이 아님:', filePath);
      return null;
    }

    // AI 서비스가 생성한 변환 파일은 무시 (중복 트리거 방지)
    if (filePath.includes('_converted.wav')) {
      functions.logger.info('⏭️ AI 서비스 변환 파일 무시:', filePath);
      return null;
    }

    // 변수 선언을 try 블록 밖으로 이동
    let callDocRef;
    try {
      // 1. 파일 경로에서 정보 추출
      const pathParts = filePath.split('/');
      if (pathParts.length < 5) {
        functions.logger.info('❌ 잘못된 경로 구조:', filePath);
        return null;
      }

      const userId = pathParts[1];
      const seniorId = pathParts[2];
      const callId = pathParts[3];
      const fileName = pathParts[4] || 'unknown';

      functions.logger.info('📋 파일 정보:', { userId, seniorId, callId, fileName });
      
      // 2. Firestore에서 해당 통화 문서 찾기 (변수 정의 후)
      callDocRef = db.collection('users').doc(userId).collection('calls').doc(callId);
      const callDoc = await callDocRef.get();

      if (!callDoc.exists) {
        functions.logger.info('❌ 통화 문서를 찾을 수 없음:', callId);
        return null;
      }

      // 중복 처리 방지: 이미 처리 중이거나 완료된 경우 스킵
      const currentStatus = callDoc.data().analysisStatus;
      if (currentStatus === 'processing' || currentStatus === 'completed') {
        functions.logger.info('⏭️ 이미 처리됨:', callId, '상태:', currentStatus);
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
      
      functions.logger.info('✅ Firestore 업데이트 완료:', callId);

      // 4. AI 분석 서비스 호출
      const aiServiceUrl = process.env.CLOUD_RUN_AI_URL || functions.config().services?.ai_url;

      if (aiServiceUrl) {
        functions.logger.info('🤖 AI 분석 요청 시작:', aiServiceUrl);

        // 4-1. Storage URI 생성 (LongRunningRecognize 사용)
        const storageUri = `gs://${bucketName}/${filePath}`;
        functions.logger.info('📦 Storage URI:', storageUri);

        // 4-2. multipart/form-data 요청 생성 (Storage URI 전송)
        const form = new FormData();
        form.append('storage_uri', storageUri);
        form.append('filename', fileName);
        form.append('user_id', userId);
        form.append('session_id', callId);

        // 4-3. HTTP 요청으로 AI 서비스 호출
        try {
          const response = await axios.post(
            `${aiServiceUrl}/analyze-audio`, // 통합 분석 엔드포인트 사용
            form,
            {
              headers: {
                ...form.getHeaders() // form-data가 생성한 헤더 사용
              },
              timeout: 540000, // 타임아웃 9분으로 증가 (LongRunningRecognize는 최대 5분 소요 가능)
            }
          );
          
          functions.logger.info('🎉 AI 분석 요청 성공:', response.data);
          
          // 4-4. 분석 결과 Firestore에 저장
          await callDocRef.update({
            analysisStatus: 'completed',
            analysisResult: response.data, // AI 서비스의 전체 응답 저장
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            errorMessage: admin.firestore.FieldValue.delete() // 기존 에러 메시지 삭제
          });
          
        } catch (aiError) {
          let errorMessage = aiError.message;
          if (aiError.response) {
            functions.logger.error('❌ AI 서비스 응답 오류:', aiError.response.status, aiError.response.data);
            errorMessage = `AI Service Error: ${aiError.response.status} - ${JSON.stringify(aiError.response.data)}`;
          } else {
            functions.logger.error('❌ AI 분석 요청 실패:', errorMessage);
          }
          
          // 분석 요청 실패시 상태 업데이트
          await callDocRef.update({
            analysisStatus: 'failed',
            errorMessage: errorMessage,
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
          });
        }
      } else {
        functions.logger.info('⚠️ AI 서비스 URL이 설정되지 않음');
        
        // AI 서비스 URL이 없을 때 상태 업데이트
        await callDocRef.update({
          analysisStatus: 'pending_config',
          errorMessage: 'AI service URL not configured',
          updatedAt: admin.firestore.FieldValue.serverTimestamp()
        });
      }
      
      return { success: true, callId, status: 'processed' };
      
    } catch (error) {
      functions.logger.error('❌ processVoiceFile 오류:', error);
      // 오류 발생 시에도 Firestore에 상태 기록 시도
      if (callDocRef) {
        await callDocRef.update({
          analysisStatus: 'function_failed',
          errorMessage: error.message,
          updatedAt: admin.firestore.FieldValue.serverTimestamp()
        }).catch(err => functions.logger.error('❌ Firestore 오류 상태 업데이트 실패:', err));
      }
      return { success: false, error: error.message };
    }
  });

/**
 * AI 분석 API
 */
// exports.aiAPI = functions.https.onRequest(async (req, res) => {
//   // TODO: 5주차에 구현하세요
//   // 1. POST /api/ai/analyze-voice 엔드포인트
//   // 2. Gemini API 호출 (시뮬레이션)
//   // 3. 분석 결과 저장
//   // 4. 이상 감지 시 알림 트리거
// });

/**
 * FCM 알림 API
 */
// exports.notificationAPI = functions.https.onRequest(async (req, res) => {
//   // TODO: 5주차에 구현하세요
//   // 1. POST /api/notifications/send 엔드포인트
//   // 2. FCM 메시지 생성
//   // 3. 대상별 알림 발송
// });

// ============================================================================
// 6주차 TODO: 프로덕션 배포 준비
// ============================================================================

/**
 * 헬스체크 API
 */
// exports.healthCheck = functions.https.onRequest(async (req, res) => {
//   // TODO: 6주차에 구현하세요
//   // 1. 시스템 상태 확인
//   // 2. 데이터베이스 연결 확인
//   // 3. 외부 API 상태 확인
// });

// ============================================================================
// 유틸리티 함수들 (참고용)
// ============================================================================

/**
 * 인증 미들웨어 (참고용)
 */
async function authenticateUser(req, res, next) {
  try {
    const token = req.headers.authorization?.split('Bearer ')[1];
    if (!token) {
      return res.status(401).json({ error: '토큰이 필요합니다' });
    }

    const decodedToken = await auth.verifyIdToken(token);
    req.user = decodedToken;
    next();
  } catch (error) {
    return res.status(401).json({ error: '유효하지 않은 토큰입니다' });
  }
}

/**
 * 에러 처리 미들웨어 (참고용)
 */
function handleError(error, req, res, next) {
  console.error('에러 발생:', error);
  res.status(500).json({
    error: '서버 내부 오류',
    message: error.message
  });
}

/**
 * 성공 응답 헬퍼 (참고용)
 */
function sendSuccess(res, data, message = '성공') {
  res.status(200).json({
    success: true,
    message: message,
    data: data
  });
}

/**
 * 에러 응답 헬퍼 (참고용)
 */
function sendError(res, statusCode, message, error = null) {
  res.status(statusCode).json({
    success: false,
    message: message,
    error: error
  });
}

// ============================================================================
// 개발용 테스트 함수 (삭제 예정)
// ============================================================================

/**
 * 테스트용 Hello World (v2)
 * 개발 환경에서만 사용 (프로덕션에서는 삭제)
 */
const {onRequest} = require('firebase-functions/v2/https');

exports.helloWorld = onRequest({
  region: 'asia-northeast3'
}, (request, response) => {
  functions.logger.info("Hello World 함수 호출됨", { structuredData: true });
  response.send("Hello from Senior mHealth Backend! 🏥💪");
});

/**
 * 테스트용 데이터베이스 연결 확인 (v2)
 */
exports.testDB = onRequest({
  region: 'asia-northeast3'
}, async (request, response) => {
  try {
    // Firestore 연결 테스트
    const testDoc = await db.collection('test').doc('connection').get();
    response.json({
      success: true,
      message: 'Firestore 연결 성공',
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    response.status(500).json({
      success: false,
      message: 'Firestore 연결 실패',
      error: error.message
    });
  }
});

// ============================================================================
// 주의사항 및 가이드라인
// ============================================================================

/**
 * 🚨 개발 시 주의사항:
 *
 * 1. 각 주차별로 주석을 해제하며 구현하세요
 * 2. 에러 처리를 반드시 포함하세요
 * 3. 로그를 적절히 남기세요 (functions.logger 사용)
 * 4. 보안을 고려하여 인증/인가를 구현하세요
 * 5. API 응답 형식을 일관성 있게 유지하세요
 *
 * 📚 참고 자료:
 * - Firebase Functions 문서: https://firebase.google.com/docs/functions
 * - Express.js 문서: https://expressjs.com/
 * - Firebase Admin SDK: https://firebase.google.com/docs/admin/setup
 */