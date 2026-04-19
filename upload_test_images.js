const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// Initialize Firebase Admin
admin.initializeApp({
  projectId: 'spotwise-12f82',
  credential: admin.credential.applicationDefault(),
  storageBucket: 'spotwise-12f82.appspot.com'
});

const db = admin.firestore();
const bucket = admin.storage().bucket();

// Test images directory
const TEST_IMAGES_DIR = 'Spotwise_Deployment/test_images';

// Mapping of image files to parking zones
const IMAGE_MAPPING = [
  {
    filename: '2012-09-12_12_32_38.jpg',
    imageId: 'img_male_a',
    parkingLotName: 'Male Campus - Zone A Camera',
    zoneId: 'zone_male_a',
    description: 'Live camera view of Zone A parking lot near Engineering Building'
  },
  {
    filename: '2012-10-13_14_43_55.jpg',
    imageId: 'img_male_b',
    parkingLotName: 'Male Campus - Zone B Camera',
    zoneId: 'zone_male_b',
    description: 'Live camera view of Zone B parking lot at Science Building'
  },
  {
    filename: '2012-12-22_15_40_12.jpg',
    imageId: 'img_male_c',
    parkingLotName: 'Male Campus - Zone C Camera',
    zoneId: 'zone_male_c',
    description: 'Live camera view of Zone C parking lot near Sports Complex'
  },
  {
    filename: '2012-12-25_12_35_07.jpg',
    imageId: 'img_female_a',
    parkingLotName: 'Female Campus - Zone A Camera',
    zoneId: 'zone_female_a',
    description: 'Live camera view of Zone A parking lot at Main Building'
  },
  {
    filename: '2013-03-13_10_45_05.jpg',
    imageId: 'img_female_b',
    parkingLotName: 'Female Campus - Zone B Camera',
    zoneId: 'zone_female_b',
    description: 'Live camera view of Zone B parking lot near Library'
  },
  {
    filename: '2013-03-16_16_55_12.jpg',
    imageId: 'img_visitor',
    parkingLotName: 'Visitor Parking Camera',
    zoneId: 'zone_visitor',
    description: 'Live camera view of Visitor parking area at Main Gate'
  }
];

async function uploadImageToStorage(localPath, storagePath) {
  try {
    await bucket.upload(localPath, {
      destination: storagePath,
      metadata: {
        contentType: 'image/jpeg',
        cacheControl: 'public, max-age=31536000',
      }
    });

    // Make the file publicly accessible
    const file = bucket.file(storagePath);
    await file.makePublic();

    // Get public URL
    const publicUrl = `https://storage.googleapis.com/${bucket.name}/${storagePath}`;
    return publicUrl;
  } catch (error) {
    console.error(`❌ Error uploading ${localPath}:`, error.message);
    return null;
  }
}

async function updateParkingImageDoc(imageId, imageUrl, parkingLotName, zoneId, description) {
  try {
    await db.collection('parking_images').doc(imageId).set({
      imageId: imageId,
      parkingLotName: parkingLotName,
      imageUrl: imageUrl,
      zoneId: zoneId,
      description: description,
      uploadedAt: admin.firestore.FieldValue.serverTimestamp(),
      cachedResults: null
    }, { merge: true });
    return true;
  } catch (error) {
    console.error(`❌ Error updating document ${imageId}:`, error.message);
    return false;
  }
}

async function main() {
  console.log('🚀 Uploading test images to Firebase Storage...');
  console.log('============================================================');
  console.log('');

  let successCount = 0;

  for (const mapping of IMAGE_MAPPING) {
    const { filename, imageId, parkingLotName, zoneId, description } = mapping;
    const localPath = path.join(TEST_IMAGES_DIR, filename);

    if (!fs.existsSync(localPath)) {
      console.log(`⚠️  Skipping ${filename}: File not found`);
      continue;
    }

    console.log(`📸 Processing: ${parkingLotName}`);
    console.log(`   File: ${filename}`);

    // Upload to Firebase Storage
    const storagePath = `parking-images/${filename}`;
    const imageUrl = await uploadImageToStorage(localPath, storagePath);

    if (imageUrl) {
      console.log(`   ✅ Uploaded to Storage: ${storagePath}`);
      console.log(`   🔗 URL: ${imageUrl}`);

      // Update Firestore document
      const updated = await updateParkingImageDoc(imageId, imageUrl, parkingLotName, zoneId, description);
      if (updated) {
        console.log(`   ✅ Updated Firestore document: ${imageId}`);
        successCount++;
      } else {
        console.log(`   ❌ Failed to update Firestore`);
      }
    } else {
      console.log(`   ❌ Failed to upload`);
    }

    console.log('');
  }

  console.log('============================================================');
  console.log(`✅ Successfully processed ${successCount}/${IMAGE_MAPPING.length} images`);
  console.log('============================================================');
  console.log('');
  console.log('🔄 Next steps:');
  console.log('   1. Hot restart your Flutter app (Press \'R\')');
  console.log('   2. Tap \'Live Cameras\' on home screen');
  console.log('   3. Select any parking lot to test AI detection');
  console.log('');
  console.log('📝 Note: AI detection will now work properly with these trained images!');
  console.log('');

  process.exit(0);
}

main().catch(error => {
  console.error('❌ Fatal error:', error.message);
  process.exit(1);
});
