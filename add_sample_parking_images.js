const admin = require('firebase-admin');

// Initialize Firebase Admin
admin.initializeApp({
  projectId: 'spotwise-12f82',
  credential: admin.credential.applicationDefault(),
});

const db = admin.firestore();

// Sample parking images with placeholder URLs
// In production, these would be actual Firebase Storage URLs of real parking lot images
const sampleParkingImages = [
  {
    imageId: 'img_male_a',
    parkingLotName: 'Male Campus - Zone A Camera',
    imageUrl: 'https://images.unsplash.com/photo-1590674899484-d5640e854abe?w=800&q=80',
    zoneId: 'zone_male_a',
    description: 'Live camera view of Zone A parking lot near Engineering Building',
    uploadedAt: admin.firestore.FieldValue.serverTimestamp(),
    cachedResults: null,
  },
  {
    imageId: 'img_male_b',
    parkingLotName: 'Male Campus - Zone B Camera',
    imageUrl: 'https://images.unsplash.com/photo-1506521781263-d8422e82f27a?w=800&q=80',
    zoneId: 'zone_male_b',
    description: 'Live camera view of Zone B parking lot at Science Building',
    uploadedAt: admin.firestore.FieldValue.serverTimestamp(),
    cachedResults: null,
  },
  {
    imageId: 'img_male_c',
    parkingLotName: 'Male Campus - Zone C Camera',
    imageUrl: 'https://images.unsplash.com/photo-1506521781263-d8422e82f27a?w=800&q=80',
    zoneId: 'zone_male_c',
    description: 'Live camera view of Zone C parking lot near Sports Complex',
    uploadedAt: admin.firestore.FieldValue.serverTimestamp(),
    cachedResults: null,
  },
  {
    imageId: 'img_female_a',
    parkingLotName: 'Female Campus - Zone A Camera',
    imageUrl: 'https://images.unsplash.com/photo-1590674899484-d5640e854abe?w=800&q=80',
    zoneId: 'zone_female_a',
    description: 'Live camera view of Zone A parking lot at Main Building',
    uploadedAt: admin.firestore.FieldValue.serverTimestamp(),
    cachedResults: null,
  },
  {
    imageId: 'img_female_b',
    parkingLotName: 'Female Campus - Zone B Camera',
    imageUrl: 'https://images.unsplash.com/photo-1506521781263-d8422e82f27a?w=800&q=80',
    zoneId: 'zone_female_b',
    description: 'Live camera view of Zone B parking lot near Library',
    uploadedAt: admin.firestore.FieldValue.serverTimestamp(),
    cachedResults: null,
  },
  {
    imageId: 'img_visitor',
    parkingLotName: 'Visitor Parking Camera',
    imageUrl: 'https://images.unsplash.com/photo-1590674899484-d5640e854abe?w=800&q=80',
    zoneId: 'zone_visitor',
    description: 'Live camera view of Visitor parking area at Main Gate',
    uploadedAt: admin.firestore.FieldValue.serverTimestamp(),
    cachedResults: null,
  },
];

async function addSampleParkingImages() {
  try {
    console.log('Adding sample parking images to Firestore...\n');

    const batch = db.batch();

    sampleParkingImages.forEach(image => {
      const imageRef = db.collection('parking_images').doc(image.imageId);
      batch.set(imageRef, image);
      console.log(`✓ Adding: ${image.parkingLotName}`);
    });

    await batch.commit();

    console.log('\n========================================');
    console.log('✅ Successfully added ' + sampleParkingImages.length + ' parking images!');
    console.log('========================================');
    console.log('\nImages added:');
    sampleParkingImages.forEach(image => {
      console.log(`  • ${image.parkingLotName}`);
      console.log(`    📷 Zone: ${image.zoneId}`);
      console.log(`    📝 Description: ${image.description}\n`);
    });

    console.log('🔄 Restart your app to see the parking cameras!');
    console.log('\n⚠️  NOTE: These are placeholder images from Unsplash.');
    console.log('   For production, upload actual parking lot images to Firebase Storage');
    console.log('   and update the imageUrl fields with the download URLs.');
    console.log('========================================\n');

  } catch (error) {
    console.error('❌ Error adding parking images:', error.message);
  }

  process.exit(0);
}

addSampleParkingImages();
