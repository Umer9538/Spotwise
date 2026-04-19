#!/usr/bin/env python3
"""
Quick API test script for Spotwise
"""
import requests
import base64
import json
import os

# Configuration
API_URL = "http://localhost:5000/predict"
TEST_IMAGE = "test_images/2012-09-12_12_32_38.jpg"

print("="*60)
print("🧪 SPOTWISE API TEST")
print("="*60)

# Check if test image exists
if not os.path.exists(TEST_IMAGE):
    print(f"❌ Error: Test image not found: {TEST_IMAGE}")
    print("   Make sure you're running this from the Spotwise directory")
    exit(1)

print(f"\n📷 Reading test image: {TEST_IMAGE}")

# Read and encode image
with open(TEST_IMAGE, 'rb') as f:
    img_data = base64.b64encode(f.read()).decode()
    img_data_uri = f'data:image/jpeg;base64,{img_data}'

print(f"   Image size: {len(img_data)} bytes")
print(f"\n🔄 Sending request to: {API_URL}")

try:
    # Send request
    response = requests.post(
        API_URL,
        json={'image': img_data_uri},
        timeout=30
    )

    print(f"   Status code: {response.status_code}")

    if response.status_code == 200:
        result = response.json()

        if result.get('success'):
            print("\n✅ SUCCESS!")
            print("\n📊 Statistics:")
            stats = result['statistics']
            print(f"   Total Free Spots: {stats['total_free_spots']}")
            print(f"   Total Occupied Spots: {stats['total_occupied_spots']}")
            print(f"   Free Percentage: {stats['free_percentage']:.1f}%")
            print(f"   Occupied Percentage: {stats['occupied_percentage']:.1f}%")
            print(f"   Free Pixels: {stats['free_pixels']:,}")
            print(f"   Occupied Pixels: {stats['occupied_pixels']:,}")

            print("\n🟢 Free Spot Locations:")
            for i, spot in enumerate(result['free_spots'][:5], 1):  # Show first 5
                print(f"   Spot {i}:")
                print(f"      Position: ({spot['x']}, {spot['y']})")
                print(f"      Size: {spot['width']}x{spot['height']}")
                print(f"      Center: ({spot['center_x']}, {spot['center_y']})")
                print(f"      Area: {spot['area']} pixels")

            if len(result['free_spots']) > 5:
                print(f"   ... and {len(result['free_spots']) - 5} more")

            print("\n🔴 Occupied Spot Locations:")
            for i, spot in enumerate(result['occupied_spots'][:3], 1):  # Show first 3
                print(f"   Spot {i}:")
                print(f"      Position: ({spot['x']}, {spot['y']})")
                print(f"      Size: {spot['width']}x{spot['height']}")

            if len(result['occupied_spots']) > 3:
                print(f"   ... and {len(result['occupied_spots']) - 3} more")

            print(f"\n🖼️  Result image: {len(result.get('result_image', ''))} bytes")

            # Save result to file
            print("\n💾 Saving full response to 'test_result.json'")
            with open('test_result.json', 'w') as f:
                # Remove large base64 images for readability
                result_copy = result.copy()
                result_copy['result_image'] = "[Base64 image data - removed for readability]"
                json.dump(result_copy, f, indent=2)

            print("\n" + "="*60)
            print("✅ API TEST PASSED")
            print("="*60)

        else:
            print("\n❌ API returned success=false")
            print(f"   Error: {result.get('error', 'Unknown error')}")

    else:
        print(f"\n❌ Request failed with status {response.status_code}")
        try:
            error = response.json()
            print(f"   Error: {error.get('error', 'Unknown error')}")
        except:
            print(f"   Response: {response.text[:200]}")

except requests.exceptions.ConnectionError:
    print("\n❌ ERROR: Could not connect to server")
    print("   Make sure the server is running:")
    print("   python server.py")

except requests.exceptions.Timeout:
    print("\n❌ ERROR: Request timed out")
    print("   Server may be overloaded or processing is taking too long")

except Exception as e:
    print(f"\n❌ ERROR: {type(e).__name__}: {str(e)}")

print()
