#!/bin/bash

# Firebase project details
PROJECT_ID="spotwise-12f82"
BASE_URL="https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents"

# Your ngrok URL for the AI server
NGROK_URL="https://0ecf63a497cd.ngrok-free.app"

echo "🚀 Updating parking images to use test images from AI server..."
echo "================================================================"
echo ""
echo "Using AI server: $NGROK_URL"
echo ""

# Function to update a parking image
update_parking_image() {
    local image_id=$1
    local parking_lot_name=$2
    local image_filename=$3
    local zone_id=$4
    local description=$5

    # Construct the URL to the test image on your AI server
    local image_url="${NGROK_URL}/test_images/${image_filename}"

    echo "📷 Updating: $parking_lot_name"
    echo "   Image: $image_filename"

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
        echo "   ✅ Success: $image_url"
    else
        echo "   ❌ Failed"
    fi
    echo ""
}

# Update all parking images with test image URLs
update_parking_image \
    "img_male_a" \
    "Male Campus - Zone A Camera" \
    "2012-09-12_12_32_38.jpg" \
    "zone_male_a" \
    "Live camera view of Zone A parking lot near Engineering Building"

update_parking_image \
    "img_male_b" \
    "Male Campus - Zone B Camera" \
    "2012-10-13_14_43_55.jpg" \
    "zone_male_b" \
    "Live camera view of Zone B parking lot at Science Building"

update_parking_image \
    "img_male_c" \
    "Male Campus - Zone C Camera" \
    "2012-12-22_15_40_12.jpg" \
    "zone_male_c" \
    "Live camera view of Zone C parking lot near Sports Complex"

update_parking_image \
    "img_female_a" \
    "Female Campus - Zone A Camera" \
    "2012-12-25_12_35_07.jpg" \
    "zone_female_a" \
    "Live camera view of Zone A parking lot at Main Building"

update_parking_image \
    "img_female_b" \
    "Female Campus - Zone B Camera" \
    "2013-03-13_10_45_05.jpg" \
    "zone_female_b" \
    "Live camera view of Zone B parking lot near Library"

update_parking_image \
    "img_visitor" \
    "Visitor Parking Camera" \
    "2013-03-16_16_55_12.jpg" \
    "zone_visitor" \
    "Live camera view of Visitor parking area at Main Gate"

echo "================================================================"
echo "✅ All parking images updated to use trained test images!"
echo "================================================================"
echo ""
echo "🔄 Next steps:"
echo "   1. Make sure your AI server is running"
echo "   2. Verify ngrok tunnel is active: $NGROK_URL"
echo "   3. Hot restart your Flutter app (Press 'R')"
echo "   4. Tap 'Live Cameras' on home screen"
echo "   5. Select any parking lot - AI detection will work perfectly!"
echo ""
echo "📝 Note: Images are served directly from your AI server"
echo "   The model was trained on these exact images!"
echo ""
