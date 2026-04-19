const admin = require('firebase-admin');

// Initialize Firebase Admin
const serviceAccount = require('./spotwise-12f82-firebase-adminsdk-g4uh9-cf6c2c9c75.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

const OLD_URL = 'https://0ecf63a497cd.ngrok-free.app';
const NEW_URL = 'https://3da6d63a053b.ngrok-free.app';

async function updateImageUrls() {
  try {
    console.log('🔄 Updating parking_images URLs...');
    console.log(`Old: ${OLD_URL}`);
    console.log(`New: ${NEW_URL}\n`);

    const snapshot = await db.collection('parking_images').get();
    
    if (snapshot.empty) {
      console.log('❌ No documents found in parking_images collection');
      process.exit(1);
    }

    let updateCount = 0;
    const batch = db.batch();

    snapshot.forEach(doc => {
      const data = doc.data();
      
      if (data.imageUrl && data.imageUrl.includes(OLD_URL)) {
        const newImageUrl = data.imageUrl.replace(OLD_URL, NEW_URL);
        
        console.log(`📝 Updating ${doc.id}:`);
        console.log(`   Old: ${data.imageUrl}`);
        console.log(`   New: ${newImageUrl}`);
        
        batch.update(doc.ref, { imageUrl: newImageUrl });
        updateCount++;
      } else {
        console.log(`ℹ️  ${doc.id}: URL doesn't need updating`);
      }
    });

    if (updateCount > 0) {
      await batch.commit();
      console.log(`\n✅ Successfully updated ${updateCount} document(s)!`);
    } else {
      console.log('\nℹ️  No documents needed updating');
    }

    process.exit(0);
  } catch (error) {
    console.error('❌ Error updating URLs:', error);
    process.exit(1);
  }
}

updateImageUrls();
