const admin = require('firebase-admin');

if (!admin.apps.length) {
  admin.initializeApp({
    projectId: 'credible-runner-474101-f6'
  });
}

const db = admin.firestore();

async function checkFCMToken() {
  try {
    const userId = 'nRFOdu4FFpcvpAGzrK2nDSvC6Og2';

    console.log(`\n🔍 FCM 토큰 확인: ${userId}\n`);

    const doc = await db.collection('users').doc(userId).get();

    if (!doc.exists) {
      console.log('❌ 사용자 문서를 찾을 수 없습니다');
      return;
    }

    const data = doc.data();

    console.log('📱 FCM 정보:');
    console.log(`  - 토큰: ${data.fcmToken ? data.fcmToken.substring(0, 40) + '...' : 'N/A'}`);
    console.log(`  - 플랫폼: ${data.fcmPlatform || 'N/A'}`);
    console.log(`  - 업데이트: ${data.fcmUpdatedAt?.toDate() || 'N/A'}`);
    console.log(`  - 이메일: ${data.email || 'N/A'}`);

    if (data.fcmToken) {
      console.log('\n✅ FCM 토큰 등록 완료!');
    } else {
      console.log('\n❌ FCM 토큰이 없습니다');
    }

    process.exit(0);
  } catch (error) {
    console.error('❌ 오류:', error);
    process.exit(1);
  }
}

checkFCMToken();
