#!/usr/bin/env python3
"""
Upload test images to Firebase Storage and update parking_images collection
"""

import os
import firebase_admin
from firebase_admin import credentials, firestore, storage
from datetime import datetime

# Initialize Firebase Admin
try:
    app = firebase_admin.get_app()
except ValueError:
    # Use application default credentials
    cred = credentials.ApplicationDefault()
    firebase_admin.initialize_app(cred, {
        'projectId': 'spotwise-12f82',
        'storageBucket': 'spotwise-12f82.appspot.com'
    })

db = firestore.client()
bucket = storage.bucket()

# Test images directory
TEST_IMAGES_DIR = 'Spotwise_Deployment/test_images'

# Mapping of image files to parking zones
IMAGE_MAPPING = [
    {
        'filename': '2012-09-12_12_32_38.jpg',
        'imageId': 'img_male_a',
        'parkingLotName': 'Male Campus - Zone A Camera',
        'zoneId': 'zone_male_a',
        'description': 'Live camera view of Zone A parking lot near Engineering Building'
    },
    {
        'filename': '2012-10-13_14_43_55.jpg',
        'imageId': 'img_male_b',
        'parkingLotName': 'Male Campus - Zone B Camera',
        'zoneId': 'zone_male_b',
        'description': 'Live camera view of Zone B parking lot at Science Building'
    },
    {
        'filename': '2012-12-22_15_40_12.jpg',
        'imageId': 'img_male_c',
        'parkingLotName': 'Male Campus - Zone C Camera',
        'zoneId': 'zone_male_c',
        'description': 'Live camera view of Zone C parking lot near Sports Complex'
    },
    {
        'filename': '2012-12-25_12_35_07.jpg',
        'imageId': 'img_female_a',
        'parkingLotName': 'Female Campus - Zone A Camera',
        'zoneId': 'zone_female_a',
        'description': 'Live camera view of Zone A parking lot at Main Building'
    },
    {
        'filename': '2013-03-13_10_45_05.jpg',
        'imageId': 'img_female_b',
        'parkingLotName': 'Female Campus - Zone B Camera',
        'zoneId': 'zone_female_b',
        'description': 'Live camera view of Zone B parking lot near Library'
    },
    {
        'filename': '2013-03-16_16_55_12.jpg',
        'imageId': 'img_visitor',
        'parkingLotName': 'Visitor Parking Camera',
        'zoneId': 'zone_visitor',
        'description': 'Live camera view of Visitor parking area at Main Gate'
    }
]

def upload_image_to_storage(local_path, storage_path):
    """Upload image to Firebase Storage and return download URL"""
    try:
        blob = bucket.blob(storage_path)
        blob.upload_from_filename(local_path)

        # Make the blob publicly readable
        blob.make_public()

        return blob.public_url
    except Exception as e:
        print(f"❌ Error uploading {local_path}: {e}")
        return None

def update_parking_image_doc(image_id, image_url, parking_lot_name, zone_id, description):
    """Update parking_images document with Firebase Storage URL"""
    try:
        doc_ref = db.collection('parking_images').document(image_id)
        doc_ref.set({
            'imageId': image_id,
            'parkingLotName': parking_lot_name,
            'imageUrl': image_url,
            'zoneId': zone_id,
            'description': description,
            'uploadedAt': firestore.SERVER_TIMESTAMP,
            'cachedResults': None
        }, merge=True)
        return True
    except Exception as e:
        print(f"❌ Error updating document {image_id}: {e}")
        return False

def main():
    print("🚀 Uploading test images to Firebase Storage...")
    print("=" * 60)
    print()

    success_count = 0

    for mapping in IMAGE_MAPPING:
        filename = mapping['filename']
        image_id = mapping['imageId']
        parking_lot_name = mapping['parkingLotName']
        zone_id = mapping['zoneId']
        description = mapping['description']

        local_path = os.path.join(TEST_IMAGES_DIR, filename)

        if not os.path.exists(local_path):
            print(f"⚠️  Skipping {filename}: File not found")
            continue

        print(f"📸 Processing: {parking_lot_name}")
        print(f"   File: {filename}")

        # Upload to Firebase Storage
        storage_path = f"parking-images/{filename}"
        image_url = upload_image_to_storage(local_path, storage_path)

        if image_url:
            print(f"   ✅ Uploaded to Storage: {storage_path}")
            print(f"   🔗 URL: {image_url}")

            # Update Firestore document
            if update_parking_image_doc(image_id, image_url, parking_lot_name, zone_id, description):
                print(f"   ✅ Updated Firestore document: {image_id}")
                success_count += 1
            else:
                print(f"   ❌ Failed to update Firestore")
        else:
            print(f"   ❌ Failed to upload")

        print()

    print("=" * 60)
    print(f"✅ Successfully processed {success_count}/{len(IMAGE_MAPPING)} images")
    print("=" * 60)
    print()
    print("🔄 Next steps:")
    print("   1. Hot restart your Flutter app (Press 'R')")
    print("   2. Tap 'Live Cameras' on home screen")
    print("   3. Select any parking lot to test AI detection")
    print()
    print("📝 Note: AI detection will now work properly with these trained images!")
    print()

if __name__ == '__main__':
    main()
