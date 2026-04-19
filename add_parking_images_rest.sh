#!/bin/bash

# Firebase project details
PROJECT_ID="spotwise-12f82"
BASE_URL="https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents"

echo "🚀 Adding parking images to Firestore..."
echo "=========================================="
echo ""

# Function to add a parking image
add_parking_image() {
    local image_id=$1
    local parking_lot_name=$2
    local image_url=$3
    local zone_id=$4
    local description=$5

    echo "📷 Adding: $parking_lot_name"

    curl -s -X PATCH "${BASE_URL}/parking_images/${image_id}" \
        -H "Content-Type: application/json" \
        -d "{
            \"fields\": {
                \"imageId\": {\"stringValue\": \"${image_id}\"},
                \"parkingLotName\": {\"stringValue\": \"${parking_lot_name}\"},
                \"imageUrl\": {\"stringValue\": \"${image_url}\"},
                \"zoneId\": {\"stringValue\": \"${zone_id}\"},
                \"description\": {\"stringValue\": \"${description}\"},
                \"uploadedAt\": {\"timestampValue\": \"$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")\"},
                \"cachedResults\": {\"nullValue\": null}
            }
        }" > /dev/null

    if [ $? -eq 0 ]; then
        echo "   ✅ Success: Image added for zone $zone_id"
    else
        echo "   ❌ Failed"
    fi
}

# Add all parking images with placeholder URLs
# NOTE: In production, replace these with actual Firebase Storage URLs of real parking lot images

add_parking_image \
    "img_male_a" \
    "Male Campus - Zone A Camera" \
    "https://images.unsplash.com/photo-1590674899484-d5640e854abe?w=800&q=80" \
    "zone_male_a" \
    "Live camera view of Zone A parking lot near Engineering Building"

add_parking_image \
    "img_male_b" \
    "Male Campus - Zone B Camera" \
    "https://images.unsplash.com/photo-1506521781263-d8422e82f27a?w=800&q=80" \
    "zone_male_b" \
    "Live camera view of Zone B parking lot at Science Building"

add_parking_image \
    "img_male_c" \
    "Male Campus - Zone C Camera" \
    "https://images.unsplash.com/photo-1590674899484-d5640e854abe?w=800&q=80" \
    "zone_male_c" \
    "Live camera view of Zone C parking lot near Sports Complex"

add_parking_image \
    "img_female_a" \
    "Female Campus - Zone A Camera" \
    "https://images.unsplash.com/photo-1506521781263-d8422e82f27a?w=800&q=80" \
    "zone_female_a" \
    "Live camera view of Zone A parking lot at Main Building"

add_parking_image \
    "img_female_b" \
    "Female Campus - Zone B Camera" \
    "https://images.unsplash.com/photo-1590674899484-d5640e854abe?w=800&q=80" \
    "zone_female_b" \
    "Live camera view of Zone B parking lot near Library"

add_parking_image \
    "img_visitor" \
    "Visitor Parking Camera" \
    "https://images.unsplash.com/photo-1506521781263-d8422e82f27a?w=800&q=80" \
    "zone_visitor" \
    "Live camera view of Visitor parking area at Main Gate"

echo ""
echo "=========================================="
echo "✅ All parking images added successfully!"
echo "=========================================="
echo ""
echo "🔄 Now restart your app to see the parking cameras:"
echo "   Press 'R' in your Flutter terminal"
echo ""
echo "📱 Navigate to the 'Live Cameras' button on the home screen"
echo ""
echo "⚠️  NOTE: These are placeholder images from Unsplash."
echo "   For production:"
echo "   1. Upload actual parking lot images to Firebase Storage"
echo "   2. Get the download URLs"
echo "   3. Update the imageUrl fields in parking_images collection"
echo ""
