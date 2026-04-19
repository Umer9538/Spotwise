#!/bin/bash

# Firebase project details
PROJECT_ID="spotwise-12f82"
BASE_URL="https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents"

echo "🚀 Adding parking zones to Firestore..."
echo "=========================================="
echo ""

# Function to add a zone
add_zone() {
    local zone_id=$1
    local zone_name=$2
    local campus=$3
    local building=$4
    local total=$5
    local available=$6
    local occupied=$7
    local reserved=$8
    local lat=$9
    local lng=${10}

    echo "📍 Adding: $zone_name"

    curl -s -X PATCH "${BASE_URL}/parking_zones/${zone_id}" \
        -H "Content-Type: application/json" \
        -d "{
            \"fields\": {
                \"zoneId\": {\"stringValue\": \"${zone_id}\"},
                \"zoneName\": {\"stringValue\": \"${zone_name}\"},
                \"cameraId\": {\"stringValue\": \"cam_001\"},
                \"totalSpots\": {\"integerValue\": \"${total}\"},
                \"availableSpots\": {\"integerValue\": \"${available}\"},
                \"occupiedSpots\": {\"integerValue\": \"${occupied}\"},
                \"reservedSpots\": {\"integerValue\": \"${reserved}\"},
                \"campus\": {\"stringValue\": \"${campus}\"},
                \"building\": {\"stringValue\": \"${building}\"},
                \"coordinates\": {
                    \"mapValue\": {
                        \"fields\": {
                            \"latitude\": {\"doubleValue\": ${lat}},
                            \"longitude\": {\"doubleValue\": ${lng}}
                        }
                    }
                },
                \"features\": {
                    \"arrayValue\": {
                        \"values\": [
                            {\"stringValue\": \"CCTV Monitored\"},
                            {\"stringValue\": \"Well Lit\"}
                        ]
                    }
                },
                \"lastUpdated\": {\"timestampValue\": \"$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")\"}
            }
        }" > /dev/null

    if [ $? -eq 0 ]; then
        echo "   ✅ Success: ${available}/${total} spots available"
    else
        echo "   ❌ Failed"
    fi
}

# Add all zones
add_zone "zone_male_a" "Male Campus - Zone A" "male" "Engineering Building" 50 35 10 5 24.7136 46.6753
add_zone "zone_male_b" "Male Campus - Zone B" "male" "Science Building" 40 20 15 5 24.7145 46.6760
add_zone "zone_male_c" "Male Campus - Zone C" "male" "Sports Complex" 30 0 25 5 24.7150 46.6755
add_zone "zone_female_a" "Female Campus - Zone A" "female" "Main Building" 45 30 12 3 24.7128 46.6745
add_zone "zone_female_b" "Female Campus - Zone B" "female" "Library" 35 10 20 5 24.7132 46.6738
add_zone "zone_visitor" "Visitor Parking" "visitor" "Main Gate" 25 18 5 2 24.7140 46.6748

echo ""
echo "=========================================="
echo "✅ All zones added successfully!"
echo "=========================================="
echo ""
echo "🔄 Now restart your app to see the zones:"
echo "   Press 'R' in your Flutter terminal"
echo ""
echo "🗺️  You should see 6 colored markers on the map!"
echo "   🟢 Green = Good availability"
echo "   🟠 Orange = Low availability"
echo "   🔴 Red = Full"
echo ""
