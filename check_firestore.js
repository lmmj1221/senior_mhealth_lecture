const admin = require('firebase-admin');
const serviceAccount = require('./backend/service-account-key.json');

// Firebase Admin 초기화
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  storageBucket: 'credible-runner-474101-f6.firebasestorage.app'
});

const db = admin.firestore();

async function checkFirestore() {
  const userId = 'ZH4dY6r3y3fbABpoCVtVbDqqqzG3';
  const callId = 'test_call_1760593050419';

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
