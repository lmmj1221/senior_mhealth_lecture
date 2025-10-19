const admin = require('firebase-admin');
const serviceAccount = require('./backend/service-account-key.json');

const projectId = serviceAccount.project_id;
const storageBucket = `${projectId}.firebasestorage.app`;

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  storageBucket: storageBucket
});

const db = admin.firestore();

async function checkUsersStructure() {
  try {
    // test@test.com 사용자 UID
    const userId = 'ZH4dY6r3y3fbABpoCVtVbDqqqzG3';
    
    console.log('📊 Checking users collection structure...\n');
    
    // 1. 사용자 문서 확인
    console.log('1️⃣ User Document:');
    const userDoc = await db.collection('users').doc(userId).get();
    if (userDoc.exists) {
      console.log('✅ User document exists');
      console.log('Fields:', Object.keys(userDoc.data()));
      console.log('Data:', JSON.stringify(userDoc.data(), null, 2));
    } else {
      console.log('❌ User document not found');
    }
    
    console.log('\n2️⃣ Calls Subcollection:');
    const callsSnapshot = await db.collection('users').doc(userId).collection('calls').limit(5).get();
    console.log(`Found ${callsSnapshot.size} calls`);
    callsSnapshot.forEach(doc => {
      console.log(`\n📞 Call ID: ${doc.id}`);
      console.log('Fields:', Object.keys(doc.data()));
      console.log('Data:', JSON.stringify(doc.data(), null, 2));
    });
    
    console.log('\n3️⃣ Analyses Subcollection:');
    const analysesSnapshot = await db.collection('users').doc(userId).collection('analyses').limit(5).get();
    console.log(`Found ${analysesSnapshot.size} analyses`);
    analysesSnapshot.forEach(doc => {
      console.log(`\n🧠 Analysis ID: ${doc.id}`);
      console.log('Fields:', Object.keys(doc.data()));
      console.log('Data:', JSON.stringify(doc.data(), null, 2));
    });
    
    console.log('\n4️⃣ Seniors Subcollection:');
    const seniorsSnapshot = await db.collection('users').doc(userId).collection('seniors').limit(5).get();
    console.log(`Found ${seniorsSnapshot.size} seniors`);
    seniorsSnapshot.forEach(doc => {
      console.log(`\n👴 Senior ID: ${doc.id}`);
      console.log('Fields:', Object.keys(doc.data()));
      console.log('Data:', JSON.stringify(doc.data(), null, 2));
    });
    
  } catch (error) {
    console.error('❌ Error:', error);
  }
}

checkUsersStructure()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
