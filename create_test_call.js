const admin = require('firebase-admin');
const serviceAccount = require('./backend/service-account-key.json');

// 환경 변수에서 값 가져오기
const projectId = serviceAccount.project_id || process.env.GCP_PROJECT_ID;
const storageBucket = `${projectId}.firebasestorage.app`;

// Firebase Admin 초기화
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  storageBucket: storageBucket
});

const db = admin.firestore();

async function createTestCall() {
  // 환경 변수에서 UID 가져오기 (Step 1에서 확인한 값)
  const userId = process.env.TEST_USER_UID;
  if (!userId) {
    throw new Error('TEST_USER_UID 환경 변수가 설정되지 않았습니다. Step 1을 먼저 완료하세요.');
  }

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
