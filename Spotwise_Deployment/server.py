"""
Spotwise - Parking Space Detection Server (PKLot Model)
Clean production-ready Flask server
"""

from flask import Flask, request, jsonify, send_from_directory
from flask_cors import CORS
import numpy as np
import cv2
import tensorflow as tf
from tensorflow import keras
import base64
import os

app = Flask(__name__)
CORS(app)

# Configuration
MODEL_PATH = 'new_model/parking_model_converted.h5'
IMG_SIZE = 128  # PKLot model uses 128x128
NUM_CLASSES = 3  # Background, Free, Occupied

# Global model
model = None


def load_model():
    """Load the converted PKLot model"""
    global model
    
    if model is None:
        if not os.path.exists(MODEL_PATH):
            print(f"❌ ERROR: Model not found at {MODEL_PATH}")
            return None
        
        print(f"📦 Loading model from {MODEL_PATH}...")
        
        try:
            # Load the converted model (should work without custom objects)
            model = keras.models.load_model(MODEL_PATH)
            
            print("✅ Model loaded successfully!")
            print(f"   Input shape: {model.input_shape}")
            print(f"   Output shape: {model.output_shape}")
        except Exception as e:
            print(f"❌ Error loading model: {str(e)}")
            return None
    
    return model


def preprocess_image(image_data):
    """Preprocess image for model"""
    # Decode base64 image
    img_bytes = base64.b64decode(image_data.split(',')[1])
    nparr = np.frombuffer(img_bytes, np.uint8)
    img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
    img = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
    
    # Resize to model input size
    img_resized = cv2.resize(img, (IMG_SIZE, IMG_SIZE))
    img_normalized = img_resized.astype('float32') / 255.0
    
    return img, img_normalized


def extract_parking_spots(mask, original_shape, min_area=50):
    """Extract coordinates of individual parking spots"""
    # Scale factor from mask to original image
    scale_y = original_shape[0] / mask.shape[0]
    scale_x = original_shape[1] / mask.shape[1]

    free_spots = []
    occupied_spots = []

    # Extract free spots (class 1)
    free_mask = (mask == 1).astype(np.uint8) * 255
    contours_free, _ = cv2.findContours(free_mask, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)

    for contour in contours_free:
        area = cv2.contourArea(contour)
        if area >= min_area:
            x, y, w, h = cv2.boundingRect(contour)
            # Scale to original image coordinates
            free_spots.append({
                'x': int(x * scale_x),
                'y': int(y * scale_y),
                'width': int(w * scale_x),
                'height': int(h * scale_y),
                'center_x': int((x + w/2) * scale_x),
                'center_y': int((y + h/2) * scale_y),
                'area': int(area * scale_x * scale_y)
            })

    # Extract occupied spots (class 2)
    occupied_mask = (mask == 2).astype(np.uint8) * 255
    contours_occupied, _ = cv2.findContours(occupied_mask, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)

    for contour in contours_occupied:
        area = cv2.contourArea(contour)
        if area >= min_area:
            x, y, w, h = cv2.boundingRect(contour)
            # Scale to original image coordinates
            occupied_spots.append({
                'x': int(x * scale_x),
                'y': int(y * scale_y),
                'width': int(w * scale_x),
                'height': int(h * scale_y),
                'center_x': int((x + w/2) * scale_x),
                'center_y': int((y + h/2) * scale_y),
                'area': int(area * scale_x * scale_y)
            })

    return free_spots, occupied_spots


def create_overlay(original_img, mask):
    """Create visualization with green=free, red=occupied"""
    # Resize original to match mask
    img_resized = cv2.resize(original_img, (mask.shape[1], mask.shape[0]))
    overlay = img_resized.copy()

    # Green for free (class 1)
    free_mask = mask == 1
    overlay[free_mask] = overlay[free_mask] * 0.4 + np.array([0, 255, 0]) * 0.6

    # Red for occupied (class 2)
    occupied_mask = mask == 2
    overlay[occupied_mask] = overlay[occupied_mask] * 0.4 + np.array([255, 0, 0]) * 0.6

    # Resize back to original size
    overlay = cv2.resize(overlay, (original_img.shape[1], original_img.shape[0]))

    return overlay


@app.route('/')
def index():
    """Serve the HTML page"""
    return send_from_directory('.', 'test.html')


@app.route('/test_images/<path:filename>')
def serve_test_image(filename):
    """Serve test images"""
    return send_from_directory('test_images', filename)


@app.route('/predict', methods=['POST'])
def predict():
    """Predict parking spaces"""
    try:
        # Load model
        if load_model() is None:
            return jsonify({'error': 'Model not loaded'}), 500
        
        # Get image from request
        data = request.get_json()
        if 'image' not in data:
            return jsonify({'error': 'No image provided'}), 400
        
        # Preprocess
        original_img, img_normalized = preprocess_image(data['image'])
        img_batch = np.expand_dims(img_normalized, axis=0)
        
        # Predict
        prediction = model.predict(img_batch, verbose=0)[0]
        mask = np.argmax(prediction, axis=-1)

        # Count spaces
        free_pixels = np.sum(mask == 1)
        occupied_pixels = np.sum(mask == 2)

        # Extract spot coordinates
        free_spots, occupied_spots = extract_parking_spots(mask, original_img.shape)

        # Create overlay
        overlay = create_overlay(original_img, mask)

        # Encode result
        _, buffer = cv2.imencode('.png', cv2.cvtColor(overlay, cv2.COLOR_RGB2BGR))
        result_base64 = base64.b64encode(buffer).decode('utf-8')

        return jsonify({
            'success': True,
            'result_image': f'data:image/png;base64,{result_base64}',
            'statistics': {
                'free_pixels': int(free_pixels),
                'occupied_pixels': int(occupied_pixels),
                'free_percentage': float(free_pixels / (free_pixels + occupied_pixels + 1) * 100),
                'occupied_percentage': float(occupied_pixels / (free_pixels + occupied_pixels + 1) * 100),
                'total_free_spots': len(free_spots),
                'total_occupied_spots': len(occupied_spots)
            },
            'free_spots': free_spots,
            'occupied_spots': occupied_spots
        })
    
    except Exception as e:
        print(f"❌ Error: {str(e)}")
        return jsonify({'error': str(e)}), 500


@app.route('/test_images_list')
def test_images_list():
    """Get list of test images"""
    try:
        images = [f for f in os.listdir('test_images') if f.endswith('.jpg')]
        return jsonify({'images': images})
    except:
        return jsonify({'images': []})


if __name__ == '__main__':
    print("\n" + "="*60)
    print("🚗 SPOTWISE - PARKING SPACE DETECTION SERVER")
    print("="*60)
    print(f"Model: {MODEL_PATH}")
    print(f"Image size: {IMG_SIZE}x{IMG_SIZE}")
    print(f"Classes: Background, Free, Occupied")
    print("="*60)
    print("\n🌐 Starting server at http://localhost:5000")
    print("📂 Test images available in test_images/ folder\n")
    
    app.run(debug=True, host='0.0.0.0', port=5000)
