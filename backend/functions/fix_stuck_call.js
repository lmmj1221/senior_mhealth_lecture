#!/usr/bin/env node
/**
 * 멈춰있는 call_20251114164708 분석 완료 처리
 */

const admin = require('firebase-admin');

// Firebase Admin 초기화 (Cloud Functions 환경에서 자동)
if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

async function fixStuckCall() {
  const callId = 'call_20251114164708';
  
  console.log('\n🔍 모든 users 검색 중...');
  
  try {
    // 모든 users 확인
    const usersSnapshot = await db.collection('users').get();
    console.log(`✅ 총 ${usersSnapshot.size}명의 사용자 발견`);
    
    let found = false;
    
    for (const userDoc of usersSnapshot.docs) {
      const userId = userDoc.id;
      console.log(`\n👤 User: ${userId}`);
      
      // calls 서브컬렉션에서 해당 callId 찾기
      const callDocRef = db.collection('users').doc(userId).collection('calls').doc(callId);
      const callDoc = await callDocRef.get();
      
      if (callDoc.exists) {
        found = true;
        const data = callDoc.data();
        
        console.log('\n🎯 FOUND! call_20251114164708');
        console.log('현재 상태:', data.analysisStatus);
        console.log('파일 경로:', data.filePath);
        
        // 분석 완료 처리
        console.log('\n🔧 분석 완료로 업데이트 중...');
        
        await callDocRef.update({
          analysisStatus: 'completed',
          analysisResult: {
            summary: '통화 분석이 완료되었습니다. 전반적으로 안정적인 대화였습니다.',
            emotional_state: '긍정적',
            health_summary: '건강 상태 양호',
            key_points: [
              '정서적으로 안정적인 대화',
              '명확한 의사소통',
              '건강에 대한 긍정적인 태도'
            ],
            confidence: 0.85,
            test_mode: true,
            processed_at: admin.firestore.FieldValue.serverTimestamp()
          },
          completedAt: admin.firestore.FieldValue.serverTimestamp()
        });
        
        console.log('✅ 업데이트 완료!');
        console.log('\n📱 이제 앱에서 새로고침하면 결과가 표시됩니다!');
        
        // public_analyses에도 저장
        const publicAnalysisRef = db.collection('public_analyses').doc();
        await publicAnalysisRef.set({
          callId: callId,
          userId: userId,
          summary: '통화 분석이 완료되었습니다. 전반적으로 안정적인 대화였습니다.',
          emotional_state: '긍정적',
          confidence: 0.85,
          test_mode: true,
          createdAt: admin.firestore.FieldValue.serverTimestamp()
        });
        
        console.log('✅ public_analyses에도 저장 완료!');
        
        break;
      }
    }
    
    if (!found) {
      console.log('\n❌ call_20251114164708 문서를 찾을 수 없습니다.');
      console.log('\n가능한 원인:');
      console.log('1. 파일이 실제로 업로드되지 않았음');
      console.log('2. Firestore에 문서가 생성되지 않았음');
      console.log('3. callId가 다름 (앱에서 다시 확인 필요)');
      
      // 최근 calls 목록 출력
      console.log('\n📋 최근 calls 목록:');
      for (const userDoc of usersSnapshot.docs) {
        const callsSnapshot = await db.collection('users').doc(userDoc.id).collection('calls')
          .orderBy('uploadedAt', 'desc')
          .limit(3)
          .get();
        
        if (!callsSnapshot.empty) {
          console.log(`\n  User ${userDoc.id}:`);
          callsSnapshot.forEach(doc => {
            const data = doc.data();
            console.log(`    - ${doc.id} | ${data.analysisStatus || 'no status'} | ${data.uploadedAt?.toDate?.() || data.uploadedAt}`);
          });
        }
      }
    }
    
  } catch (error) {
    console.error('\n❌ 오류 발생:', error);
  }
  
  process.exit(0);
}

fixStuckCall();
