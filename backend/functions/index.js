/**
 * Senior mHealth Backend Functions
 * 학생 실습용 템플릿 - 주차별로 구현해주세요!
 */

const functions = require('firebase-functions');
const admin = require('firebase-admin');
const axios = require('axios');

// 환경변수 검증
const validateEnvironment = () => {
  const requiredEnvVars = ['GCLOUD_PROJECT'];
  const warnings = [];

  requiredEnvVars.forEach(varName => {
    if (!process.env[varName]) {
      warnings.push(`Warning: 환경변수 ${varName}이 설정되지 않았습니다. Firebase 런타임에서 자동 설정됩니다.`);
    }
  });

  if (warnings.length > 0) {
    warnings.forEach(warning => functions.logger.warn(warning));
  }

  return true;
};

// 환경 검증 실행
validateEnvironment();

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
  memory: '1GiB'
  // bucket을 지정하지 않으면 기본 Firebase Storage 버킷 사용
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
        functions.logger.info('⚠️ 통화 문서를 찾을 수 없음 - 새로 생성:', callId);
        // 문서가 없으면 새로 생성
        await callDocRef.set({
          callId: callId,
          userId: userId,
          seniorId: seniorId,
          fileName: fileName,
          filePath: filePath,
          status: 'uploaded',
          analysisStatus: 'processing',
          uploadedAt: admin.firestore.FieldValue.serverTimestamp(),
          createdAt: admin.firestore.FieldValue.serverTimestamp()
        });
        functions.logger.info('✅ 통화 문서 생성 완료:', callId);
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
      const aiServiceUrl = process.env.CLOUD_RUN_AI_URL; // v2에서는 functions.config() 사용 불가

      // 테스트 모드: AI 서비스가 없을 때 더미 결과 반환
      if (!aiServiceUrl) {
        functions.logger.info('⚠️ AI 서비스 URL이 없음 - 테스트 모드로 더미 결과 생성');
        
        const dummyResult = {
          // 전체 요약
          summary: "어르신께서는 전반적으로 긍정적인 정서 상태를 보이고 있습니다. 대화 중 명확한 의사소통과 논리적인 사고 흐름이 관찰되었습니다.",
          
          // 정신건강 점수 (0-100점)
          depression_score: 25,      // 우울 점수: 낮을수록 좋음 (0-30: 정상, 31-50: 경증, 51-70: 중등도, 71-100: 심각)
          anxiety_score: 20,         // 불안 점수: 낮을수록 좋음 (0-30: 정상, 31-50: 경증, 51-70: 중등도, 71-100: 심각)
          cognitive_score: 85,       // 인지 점수: 높을수록 좋음 (80-100: 정상, 60-79: 경증, 40-59: 중등도, 0-39: 심각)
          
          // 감정 상태
          emotional_state: "안정적",  // 안정적, 긍정적, 중립적, 불안정, 우울함
          
          // 주요 관심사항
          key_concerns: [
            "일상 생활 유지 중",
            "가족과의 관계 양호",
            "규칙적인 생활 패턴"
          ],
          
          // 권장사항
          recommendations: [
            "현재의 긍정적인 생활 패턴을 유지하세요",
            "정기적인 사회 활동 참여를 권장합니다",
            "가족과의 소통을 지속하세요"
          ],
          
          // 세부 분석
          detailed_analysis: {
            speech_pattern: "명확하고 일관된 대화 패턴",
            memory_status: "최근 사건에 대한 기억력 양호",
            mood_assessment: "긍정적이고 안정적인 기분 상태",
            social_interaction: "적극적인 대화 참여와 반응"
          },
          
          // 메타데이터
          confidence: 0.85,
          transcript: "안녕하세요 어머니. 오늘 기분은 어떠세요? 네, 좋아요. 오늘 날씨가 참 좋네요. 아침에 산책도 다녀왔어요.",
          analyzed_at: new Date().toISOString(),
          test_mode: true
        };
        
        await callDocRef.update({
          analysisStatus: 'completed',
          analysisResult: dummyResult,
          updatedAt: admin.firestore.FieldValue.serverTimestamp()
        });
        functions.logger.info('✅ 테스트 모드 - 더미 분석 결과 저장 완료');
        
        // public_analyses에도 저장
        try {
          await db.collection('public_analyses').doc(callId).set({
            callId: callId,
            userId: userId,
            seniorId: seniorId,
            summary: dummyResult.summary,
            analysisResult: dummyResult,
            filePath: filePath,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            expiresAt: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
            isPublic: true
          });
          functions.logger.info('✅ public_analyses 저장 완료:', callId);
        } catch (publicSaveError) {
          functions.logger.error('⚠️ public_analyses 저장 실패:', publicSaveError);
        }
        
        // FCM 알림 전송
        try {
          functions.logger.info('📬 FCM 알림 전송 시작');
          await sendAnalysisCompleteNotification(userId, callId, seniorId, dummyResult);
          functions.logger.info('✅ FCM 알림 전송 완료');
        } catch (fcmError) {
          functions.logger.error('❌ FCM 알림 전송 실패:', fcmError);
        }
        
        return { success: true, callId, status: 'completed_test_mode' };
      }

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
          
          functions.logger.info('🎉 AI 분석 요청 성공');
          functions.logger.info('📊 AI 응답 데이터:', JSON.stringify(response.data).substring(0, 200));

          // 4-4. 분석 결과 Firestore에 저장
          await callDocRef.update({
            analysisStatus: 'completed',
            analysisResult: response.data, // AI 서비스의 전체 응답 저장
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            errorMessage: admin.firestore.FieldValue.delete() // 기존 에러 메시지 삭제
          });
          functions.logger.info('✅ Firestore 분석 결과 저장 완료');

          // 4-4a. public_analyses 컬렉션에도 저장 (공유용)
          try {
            await db.collection('public_analyses').doc(callId).set({
              callId: callId,
              userId: userId,
              seniorId: seniorId,
              summary: response.data.summary || response.data.emotional_state || response.data.health_summary || '분석 완료',
              analysisResult: response.data,
              filePath: filePath,
              createdAt: admin.firestore.FieldValue.serverTimestamp(),
              expiresAt: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000), // 30일 후 만료
              isPublic: true
            });
            functions.logger.info('✅ public_analyses 컬렉션 저장 완료:', callId);
          } catch (publicSaveError) {
            functions.logger.error('⚠️ public_analyses 저장 실패 (계속 진행):', publicSaveError);
          }

          // 4-5. FCM 알림 전송 (Week 7 추가)
          try {
            functions.logger.info('📬 FCM 알림 전송 시작');
            functions.logger.info('📬 FCM 파라미터:', { userId, callId, seniorId });
            await sendAnalysisCompleteNotification(userId, callId, seniorId, response.data);
            functions.logger.info('✅ FCM 알림 전송 완료');
          } catch (fcmError) {
            functions.logger.error('❌ FCM 알림 전송 중 오류 발생:', fcmError);
            functions.logger.error('❌ FCM 오류 스택:', fcmError.stack);
          }

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
// Week 7 추가 기능: FCM 알림 시스템
// ============================================================================

/**
 * FCM 토큰 등록 API
 * POST /registerFCMToken
 *
 * Body: {
 *   userId: string,
 *   token: string,
 *   platform: 'mobile' | 'web',
 *   email: string (optional)
 * }
 */
exports.registerFCMToken = functions.region('asia-northeast3').https.onRequest(async (req, res) => {
  // CORS 처리
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.set('Access-Control-Allow-Headers', 'Content-Type');

  // Preflight request 처리
  if (req.method === 'OPTIONS') {
    res.status(204).send('');
    return;
  }

  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  const { userId, token, platform, email } = req.body;

  // 필수 파라미터 검증
  if (!userId || !token) {
    functions.logger.error('❌ 필수 파라미터 누락:', { userId, token: token ? 'exists' : 'missing' });
    return res.status(400).json({ error: 'userId and token are required' });
  }

  try {
    functions.logger.info('📝 FCM 토큰 등록 요청:', { userId, platform, email });

    // Firestore에 FCM 토큰 저장 (merge 옵션으로 기존 필드 유지)
    await db.collection('users').doc(userId).set({
      fcmToken: token,
      fcmPlatform: platform || 'unknown',
      fcmUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
      email: email || null
    }, { merge: true });

    functions.logger.info('✅ FCM 토큰 등록 완료:', userId);

    res.json({
      success: true,
      message: 'Token registered successfully',
      userId: userId
    });
  } catch (error) {
    functions.logger.error('❌ FCM 토큰 등록 실패:', error);
    res.status(500).json({
      error: error.message,
      message: 'Failed to register FCM token'
    });
  }
});

/**
 * AI 분석 완료 알림 전송 (FCM)
 *
 * @param {string} userId - 사용자 ID
 * @param {string} callId - 통화 ID (분석 ID로도 사용)
 * @param {string} seniorId - 시니어 ID
 * @param {object} analysisResult - AI 분석 결과 객체
 */
async function sendAnalysisCompleteNotification(userId, callId, seniorId, analysisResult) {
  try {
    functions.logger.info('📲 FCM 알림 전송 함수 시작:', { userId, callId, seniorId });

    // 1. 사용자 문서에서 FCM 토큰 가져오기
    functions.logger.info('📱 사용자 문서 조회 시작:', userId);
    const userDoc = await db.collection('users').doc(userId).get();

    if (!userDoc.exists) {
      functions.logger.warn('⚠️ 사용자 문서를 찾을 수 없음:', userId);
      return;
    }

    const userData = userDoc.data();
    functions.logger.info('📱 사용자 데이터:', {
      hasFcmToken: !!userData.fcmToken,
      fcmPlatform: userData.fcmPlatform,
      email: userData.email
    });

    if (!userData.fcmToken) {
      functions.logger.info('⚠️ FCM 토큰이 없습니다:', userId);
      return;
    }

    // 2. 분석 결과에서 요약 정보 추출
    // AI 서비스에서 반환한 실제 필드명 사용
    const summary = analysisResult.emotional_state || analysisResult.summary || analysisResult.health_summary || '분석이 완료되었습니다.';
    const confidence = analysisResult.confidence || analysisResult.confidence_score || 0;

    functions.logger.info('📊 분석 결과 정보:', {
      hasEmotionalState: !!analysisResult.emotional_state,
      hasSummary: !!analysisResult.summary,
      confidence: confidence,
      keys: Object.keys(analysisResult).slice(0, 10)
    });

    // 3. FCM 메시지 생성
    const message = {
      token: userData.fcmToken,
      notification: {
        title: '음성 분석 완료 🎉',
        body: summary.substring(0, 100), // 알림은 100자로 제한
      },
      data: {
        type: 'analysis_complete',
        callId: callId,
        seniorId: seniorId || '',
        analysisId: callId, // Flutter 앱과 호환
        summary: summary,
        confidence: confidence.toString(),
        timestamp: new Date().toISOString(),
        webUrl: `https://senior-mhealth.vercel.app/analyses/${callId}` // 웹앱 상세보기 URL (수정됨)
      },
      android: {
        priority: 'high',
        notification: {
          sound: 'default',
          clickAction: 'FLUTTER_NOTIFICATION_CLICK',
          channelId: 'senior_mhealth_channel'
        }
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
            badge: 1
          }
        }
      }
    };

    // 4. FCM 전송
    const response = await admin.messaging().send(message);
    functions.logger.info('✅ FCM 알림 전송 완료:', { userId, messageId: response });

  } catch (error) {
    // FCM 전송 실패해도 전체 프로세스는 계속 진행
    functions.logger.error('❌ FCM 알림 전송 실패:', error);

    // 토큰 만료 오류인 경우 Firestore에서 토큰 제거
    if (error.code === 'messaging/registration-token-not-registered' ||
        error.code === 'messaging/invalid-registration-token') {
      functions.logger.info('🗑️ 만료된 FCM 토큰 제거:', userId);
      await db.collection('users').doc(userId).update({
        fcmToken: admin.firestore.FieldValue.delete(),
        fcmPlatform: admin.firestore.FieldValue.delete(),
        fcmUpdatedAt: admin.firestore.FieldValue.serverTimestamp()
      }).catch(err => functions.logger.error('FCM 토큰 제거 실패:', err));
    }
  }
}

// ============================================================================
// Week 7 추가 기능: 모바일 앱 API (Express 기반)
// ============================================================================

/**
 * Week 7: 모바일 앱을 위한 Express 기반 통합 API
 *
 * 엔드포인트:
 * - GET /health - Health check
 * - POST /api/audio/upload - 음성 파일 업로드
 * - POST /api/health-data - 건강 데이터 생성
 * - GET /api/health-data/:userId - 건강 데이터 조회
 */

const express = require('express');
const cors = require('cors');
const { Storage } = require('@google-cloud/storage');

// Express 앱 및 Storage 초기화
const app = express();
const storage = new Storage();
const bucketName = process.env.GCP_PROJECT_ID ?
  `${process.env.GCP_PROJECT_ID}.appspot.com` :
  `${process.env.GCLOUD_PROJECT}.appspot.com`;
const bucket = storage.bucket(bucketName);

// Multer 설정 (메모리 스토리지 사용)
const multer = require('multer');
const upload = multer({
  storage: multer.memoryStorage(),
  limits: {
    fileSize: 10 * 1024 * 1024, // 10MB 제한
  }
});

// CORS 설정
app.use(cors({
  origin: true, // 모든 origin 허용 (개발 환경)
  credentials: true
}));

// JSON 파싱
app.use(express.json());

// ============================================================================
// 엔드포인트 1: Health Check
// ============================================================================

/**
 * GET /health
 * 서버 상태 확인
 */
app.get('/health', (req, res) => {
  res.json({
    status: "healthy",
    timestamp: new Date().toISOString(),
    version: "1.0.0",
    service: "senior-mhealth-backend"
  });
});

// ============================================================================
// 엔드포인트 2: 음성 파일 업로드
// ============================================================================

/**
 * POST /api/audio/upload
 * 음성 파일 업로드 (multer 사용)
 *
 * Headers: Authorization: Bearer <token>
 * Body (multipart/form-data):
 *   - audio: File
 *   - seniorId: string (optional)
 */
app.post('/audio/upload', authenticateUser, upload.single('audio'), async (req, res) => {
  try {
    const file = req.file;
    const userId = req.user.uid;
    const seniorId = req.body.seniorId || 'default';

    if (!file) {
      return res.status(400).json({ error: '파일이 없습니다' });
    }

    functions.logger.info('📤 음성 파일 업로드 요청:', {
      userId,
      seniorId,
      fileName: file.originalname,
      size: file.size
    });

    // 고유한 callId 생성
    const callId = `call_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;

    // Firebase Storage 경로: calls/{userId}/{seniorId}/{callId}/filename
    const fileName = `calls/${userId}/${seniorId}/${callId}/${file.originalname}`;
    const fileUpload = bucket.file(fileName);

    // 파일 업로드 스트림 생성
    const stream = fileUpload.createWriteStream({
      metadata: {
        contentType: file.mimetype,
        metadata: {
          userId: userId,
          seniorId: seniorId,
          callId: callId,
          uploadedAt: new Date().toISOString(),
        },
      },
    });

    // 스트림 에러 처리
    stream.on('error', (err) => {
      functions.logger.error('❌ Storage 업로드 실패:', err);
      res.status(500).json({ error: '파일 저장 실패' });
    });

    // 스트림 완료 처리
    stream.on('finish', async () => {
      try {
        // Firestore에 통화 메타데이터 저장
        await db.collection('users').doc(userId).collection('calls').doc(callId).set({
          callId: callId,
          userId: userId,
          seniorId: seniorId,
          fileName: fileName,
          originalName: file.originalname,
          size: file.size,
          mimeType: file.mimetype,
          uploadedAt: admin.firestore.FieldValue.serverTimestamp(),
          status: 'uploaded',
          analysisStatus: 'pending',
          storagePath: fileName
        });

        functions.logger.info('✅ 음성 파일 업로드 완료:', callId);

        res.json({
          success: true,
          callId: callId,
          storagePath: fileName,
          message: '파일 업로드 성공'
        });
      } catch (error) {
        functions.logger.error('❌ Firestore 저장 실패:', error);
        res.status(500).json({ error: 'Firestore 저장 실패' });
      }
    });

    // 파일 버퍼 전송
    stream.end(file.buffer);

  } catch (error) {
    functions.logger.error('❌ 음성 업로드 실패:', error);
    res.status(500).json({ error: '업로드 실패' });
  }
});

// ============================================================================
// 엔드포인트 3: 건강 데이터 생성
// ============================================================================

/**
 * POST /api/health-data
 * 건강 데이터 생성
 *
 * Headers: Authorization: Bearer <token>
 * Body: {
 *   type: string (예: 'blood_pressure', 'heart_rate'),
 *   value: number,
 *   unit: string,
 *   timestamp: string (ISO 8601)
 * }
 */
app.post('/health-data', authenticateUser, async (req, res) => {
  try {
    const { type, value, unit, timestamp } = req.body;
    const userId = req.user.uid;

    // 필수 파라미터 검증
    if (!type || value === undefined || !unit) {
      return res.status(400).json({
        error: 'type, value, unit are required'
      });
    }

    functions.logger.info('📊 건강 데이터 생성 요청:', { userId, type, value });

    const healthData = {
      userId: userId,
      type: type,
      value: value,
      unit: unit,
      timestamp: timestamp ?
        admin.firestore.Timestamp.fromDate(new Date(timestamp)) :
        admin.firestore.FieldValue.serverTimestamp(),
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    };

    const docRef = await db.collection('healthData').add(healthData);

    functions.logger.info('✅ 건강 데이터 생성 완료:', docRef.id);

    res.json({
      success: true,
      id: docRef.id,
      data: healthData
    });
  } catch (error) {
    functions.logger.error('❌ 건강 데이터 생성 실패:', error);
    res.status(500).json({ error: error.message });
  }
});

// ============================================================================
// 엔드포인트 4: 건강 데이터 조회
// ============================================================================

/**
 * GET /api/health-data/:userId
 * 건강 데이터 조회
 *
 * Headers: Authorization: Bearer <token>
 * Query Parameters:
 *   - startDate: string (ISO 8601, optional)
 *   - endDate: string (ISO 8601, optional)
 *   - type: string (optional)
 */
app.get('/health-data/:userId', authenticateUser, async (req, res) => {
  try {
    const { userId } = req.params;
    const { startDate, endDate, type } = req.query;

    // 본인의 데이터만 조회 가능 (간단한 권한 검증)
    if (req.user.uid !== userId) {
      return res.status(403).json({ error: 'Forbidden: You can only access your own data' });
    }

    functions.logger.info('📋 건강 데이터 조회 요청:', { userId, type, startDate, endDate });

    let query = db.collection('healthData').where('userId', '==', userId);

    // 날짜 필터
    if (startDate) {
      query = query.where('timestamp', '>=', admin.firestore.Timestamp.fromDate(new Date(startDate)));
    }
    if (endDate) {
      query = query.where('timestamp', '<=', admin.firestore.Timestamp.fromDate(new Date(endDate)));
    }

    // 타입 필터
    if (type) {
      query = query.where('type', '==', type);
    }

    const snapshot = await query.orderBy('timestamp', 'desc').get();
    const data = snapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data()
    }));

    functions.logger.info('✅ 건강 데이터 조회 완료:', { count: data.length });

    res.json({
      success: true,
      count: data.length,
      data: data
    });
  } catch (error) {
    functions.logger.error('❌ 건강 데이터 조회 실패:', error);
    res.status(500).json({ error: error.message });
  }
});

// ============================================================================
// 엔드포인트 5: 수동 분석 트리거 (Storage 트리거 우회용)
// ============================================================================

/**
 * POST /api/v1/analyze/:callId
 * Storage 트리거 없이 직접 분석 실행
 *
 * Headers: Authorization: Bearer <token>
 * Parameters:
 *   - callId: 분석할 통화 ID
 *
 * Response:
 *   - success: boolean
 *   - message: string
 */
app.post('/api/v1/analyze/:callId', authenticateUser, async (req, res) => {
  try {
    const { callId } = req.params;
    const userId = req.user.uid;

    functions.logger.info('🔄 수동 분석 트리거 요청:', { userId, callId });

    // Firestore에서 calls 문서 가져오기
    const callDocRef = db.collection('users').doc(userId).collection('calls').doc(callId);
    const callDoc = await callDocRef.get();

    if (!callDoc.exists) {
      return res.status(404).json({
        success: false,
        error: '통화 문서를 찾을 수 없습니다'
      });
    }

    const callData = callDoc.data();
    
    // 더미 분석 결과 생성
    const dummyResult = {
      summary: "통화 분석이 완료되었습니다. 전반적으로 안정적인 대화였습니다.",
      emotional_state: "긍정적",
      health_summary: "건강 상태 양호",
      confidence: 0.85,
      transcript: "안녕하세요. 잘 지내시죠? 네, 잘 지냅니다. 요즘 날씨가 좋네요.",
      test_mode: true,
      manual_trigger: true
    };

    // Firestore 업데이트
    await callDocRef.update({
      analysisStatus: 'completed',
      analysisResult: dummyResult,
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });

    // public_analyses에 저장
    await db.collection('public_analyses').doc(callId).set({
      callId: callId,
      userId: userId,
      seniorId: callData.seniorId || 'unknown',
      summary: dummyResult.summary,
      analysisResult: dummyResult,
      filePath: callData.fileName || 'unknown',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      expiresAt: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
      isPublic: true
    });

    // FCM 알림 전송
    try {
      await sendAnalysisCompleteNotification(
        userId, 
        callId, 
        callData.seniorId || 'unknown', 
        dummyResult
      );
      functions.logger.info('✅ FCM 알림 전송 완료');
    } catch (fcmError) {
      functions.logger.error('❌ FCM 알림 전송 실패:', fcmError);
    }

    functions.logger.info('✅ 수동 분석 완료:', callId);

    res.json({
      success: true,
      message: '분석이 완료되었습니다',
      callId: callId,
      analysisResult: dummyResult
    });

  } catch (error) {
    functions.logger.error('❌ 수동 분석 실패:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// ============================================================================
// 엔드포인트 6: 시니어 목록 조회 (인증 필요)
// ============================================================================

/**
 * GET /api/v1/users/:userId/seniors
 * 사용자의 시니어 목록 조회
 *
 * Headers: Authorization: Bearer <token>
 * Parameters:
 *   - userId: 사용자 ID
 *
 * Response:
 *   - success: boolean
 *   - data: { seniors: [...] }
 */
app.get('/api/v1/users/:userId/seniors', authenticateUser, async (req, res) => {
  try {
    const { userId } = req.params;

    // 본인의 데이터만 조회 가능 (권한 검증)
    if (req.user.uid !== userId) {
      return res.status(403).json({ 
        success: false,
        error: 'Forbidden: You can only access your own data' 
      });
    }

    functions.logger.info('👴 시니어 목록 조회 요청:', userId);

    // Firestore에서 seniors 컬렉션 조회 (userId로 필터링)
    const seniorsSnapshot = await db.collection('seniors')
      .where('userId', '==', userId)
      .get();

    const seniors = [];
    seniorsSnapshot.forEach(doc => {
      seniors.push({
        id: doc.id,
        senior_id: doc.id, // 모바일 앱 호환성
        seniorId: doc.id,  // 추가 호환성
        ...doc.data()
      });
    });

    functions.logger.info('✅ 시니어 목록 조회 완료:', { count: seniors.length });

    res.json({
      success: true,
      data: {
        seniors: seniors
      }
    });

  } catch (error) {
    functions.logger.error('❌ 시니어 목록 조회 실패:', error);
    res.status(500).json({
      success: false,
      error: error.message || '시니어 목록 조회 중 오류가 발생했습니다'
    });
  }
});

// ============================================================================
// 엔드포인트 6: 공개 분석 결과 조회 (인증 불필요)
// ============================================================================

/**
 * GET /api/v1/calls/public/analysis/:callId
 * 공개 분석 결과 조회 - public_analyses 컬렉션에서 조회
 *
 * Parameters:
 *   - callId: 분석 ID
 *
 * Response:
 *   - success: boolean
 *   - data: 분석 결과 데이터
 */
app.get('/api/v1/calls/public/analysis/:callId', async (req, res) => {
  try {
    const { callId } = req.params;

    functions.logger.info('🔍 공개 분석 결과 조회 요청:', callId);

    // public_analyses 컬렉션에서 조회
    const publicDoc = await db.collection('public_analyses').doc(callId).get();

    if (!publicDoc.exists) {
      functions.logger.warn('⚠️ 분석 결과를 찾을 수 없음:', callId);
      return res.status(404).json({
        success: false,
        error: '분석 결과를 찾을 수 없습니다'
      });
    }

    const data = publicDoc.data();
    functions.logger.info('✅ 공개 분석 결과 조회 성공:', callId);

    // 성공 응답
    res.json({
      success: true,
      data: {
        ...data,
        id: publicDoc.id,
        callId: callId
      }
    });

  } catch (error) {
    functions.logger.error('❌ 공개 분석 결과 조회 실패:', error);
    res.status(500).json({
      success: false,
      error: error.message || '분석 결과 조회 중 오류가 발생했습니다'
    });
  }
});

// ============================================================================
// API 함수 내보내기
// ============================================================================

/**
 * Express 앱을 Cloud Functions로 내보내기
 * 엔드포인트: https://asia-northeast3-{project-id}.cloudfunctions.net/api
 */
exports.api = functions.region('asia-northeast3').https.onRequest(app);

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