const admin = require('firebase-admin');

// Firebase Admin 초기화
if (!admin.apps.length) {
  admin.initializeApp({
    projectId: 'credible-runner-474101-f6'
  });
}

const db = admin.firestore();

async function checkCallResult() {
  try {
    const callId = 'call_1761069405069';
    const userId = 'nRFOdu4FFpcvpAGzrK2nDSvC6Og2';
    const seniorId = 'senior_1761067484011';

    console.log(`\n🔍 통화 분석 결과 조회: ${callId}\n`);

    const docRef = db.collection('users').doc(userId)
                     .collection('calls').doc(callId);

    const doc = await docRef.get();

    if (!doc.exists) {
      console.log('❌ 문서를 찾을 수 없습니다');
      return;
    }

    const data = doc.data();

    console.log('📊 통화 기본 정보:');
    console.log(`  - 파일: ${data.fileName || 'N/A'}`);
    console.log(`  - 업로드: ${data.timestamp?.toDate() || 'N/A'}`);
    console.log(`  - 상태: ${data.status || 'N/A'}`);
    console.log(`  - 분석상태: ${data.analysisStatus || 'N/A'}`);

    if (data.analysisResult) {
      console.log('\n✅ AI 분석 결과:');
      console.log(`  - 감정: ${data.analysisResult.sentiment || 'N/A'}`);
      console.log(`  - 우울: ${data.analysisResult.depression_score || 'N/A'}`);
      console.log(`  - 불안: ${data.analysisResult.anxiety_score || 'N/A'}`);
      console.log(`  - 스트레스: ${data.analysisResult.stress_level || 'N/A'}`);
      if (data.analysisResult.transcription) {
        console.log(`  - 전사: ${data.analysisResult.transcription.substring(0, 100)}...`);
      }
    } else {
      console.log('\n⏳ 분석 결과 대기 중...');
    }

    if (data.error) {
      console.log(`\n❌ 에러: ${data.error}`);
    }

    process.exit(0);
  } catch (error) {
    console.error('❌ 오류:', error);
    process.exit(1);
  }
}

checkCallResult();
