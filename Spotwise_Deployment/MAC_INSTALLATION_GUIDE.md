# 🍎 Spotwise - Mac Installation Guide

Complete step-by-step guide to install and run Spotwise on macOS.

---

## System Requirements

- **macOS**: 10.15 (Catalina) or later
- **RAM**: Minimum 4GB (8GB recommended)
- **Storage**: 2GB free space
- **Python**: 3.8 - 3.10 (Python 3.11+ may have compatibility issues with TensorFlow)

---

## Installation Steps

### Step 1: Install Homebrew (if not installed)

Open Terminal and run:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

Verify installation:
```bash
brew --version
```

---

### Step 2: Install Python 3.10

```bash
# Install Python 3.10
brew install python@3.10

# Verify installation
python3.10 --version
```

Expected output: `Python 3.10.x`

---

### Step 3: Extract Spotwise Package

```bash
# Navigate to your desired location
cd ~/Desktop

# Extract the zip file (double-click or use command)
unzip Spotwise_Deployment.zip

# Navigate to the folder
cd Spotwise_Deployment
```

---

### Step 4: Create Virtual Environment

```bash
# Create virtual environment with Python 3.10
python3.10 -m venv venv

# Activate virtual environment
source venv/bin/activate
```

You should see `(venv)` in your terminal prompt.

---

### Step 5: Install Dependencies

```bash
# Upgrade pip
pip install --upgrade pip

# Install required packages
pip install -r requirements.txt
```

This will install:
- TensorFlow 2.13
- Flask 2.3
- OpenCV 4.8
- NumPy 1.24
- And other dependencies

**Note**: Installation may take 5-10 minutes depending on your internet speed.

---

### Step 6: Verify Model Files

Check that the model file exists:

```bash
ls -lh new_model/
```

You should see:
- `parking_model_converted.h5` (approximately 7.9 MB)

If missing, contact support.

---

### Step 7: Start the Server

```bash
python server.py
```

You should see output like:

```
============================================================
🚗 SPOTWISE - PARKING SPACE DETECTION SERVER
============================================================
Model: new_model/parking_model_converted.h5
Image size: 128x128
Classes: Background, Free, Occupied
============================================================

📦 Loading model from new_model/parking_model_converted.h5...
✅ Model loaded successfully!
   Input shape: (None, 128, 128, 3)
   Output shape: (None, 128, 128, 3)

🌐 Starting server at http://localhost:5000
📂 Test images available in test_images/ folder

 * Running on all addresses (0.0.0.0)
 * Running on http://127.0.0.1:5000
 * Running on http://192.168.x.x:5000
```

---

### Step 8: Test the Installation

**Option 1: Web Browser**

Open your browser and go to:
```
http://localhost:5000
```

You should see the Spotwise web interface.

**Option 2: Test with cURL**

Open a new terminal window and run:

```bash
# Test health check
curl http://localhost:5000/test_images_list
```

Expected response:
```json
{"images": ["2012-09-12_12_32_38.jpg", ...]}
```

**Option 3: Test with Sample Image**

```bash
# Use Python to test
python3 << 'EOF'
import requests
import base64

# Read a test image
with open('test_images/2012-09-12_12_32_38.jpg', 'rb') as f:
    img_data = base64.b64encode(f.read()).decode()

# Send request
response = requests.post('http://localhost:5000/predict', json={
    'image': f'data:image/jpeg;base64,{img_data}'
})

result = response.json()
print(f"Success: {result['success']}")
print(f"Free spots: {result['statistics']['total_free_spots']}")
print(f"Occupied spots: {result['statistics']['total_occupied_spots']}")
EOF
```

---

## Accessing from Mobile Device

### On Same WiFi Network

1. Find your Mac's local IP address:
```bash
ifconfig | grep "inet " | grep -v 127.0.0.1
```

Example output: `inet 192.168.1.100`

2. On your mobile device, use:
```
http://192.168.1.100:5000
```

### Open Firewall (if needed)

```bash
# Allow incoming connections on port 5000
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --add $(which python3)
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --unblockapp $(which python3)
```

---

## Running in Production Mode

For production deployment, use Gunicorn:

```bash
# Install Gunicorn
pip install gunicorn

# Run with Gunicorn (4 workers)
gunicorn -w 4 -b 0.0.0.0:5000 server:app
```

---

## Run Server on Startup (Optional)

Create a launch agent to start the server automatically:

```bash
# Create launch agent directory
mkdir -p ~/Library/LaunchAgents

# Create plist file
cat > ~/Library/LaunchAgents/com.spotwise.server.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.spotwise.server</string>
    <key>ProgramArguments</key>
    <array>
        <string>/Users/YOUR_USERNAME/Desktop/Spotwise_Deployment/venv/bin/python</string>
        <string>/Users/YOUR_USERNAME/Desktop/Spotwise_Deployment/server.py</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardErrorPath</key>
    <string>/tmp/spotwise.err</string>
    <key>StandardOutPath</key>
    <string>/tmp/spotwise.out</string>
</dict>
</plist>
EOF

# Replace YOUR_USERNAME with your actual username
# Load the launch agent
launchctl load ~/Library/LaunchAgents/com.spotwise.server.plist
```

To stop:
```bash
launchctl unload ~/Library/LaunchAgents/com.spotwise.server.plist
```

---

## Troubleshooting

### Issue: "command not found: python3.10"

**Solution:**
```bash
# Use default Python 3
python3 -m venv venv
```

### Issue: "Model not found"

**Solution:**
```bash
# Check if model file exists
ls -lh new_model/parking_model_converted.h5

# If missing, check if you extracted the full zip
```

### Issue: TensorFlow installation fails

**Solution:**
```bash
# For Apple Silicon (M1/M2/M3 Macs)
pip install tensorflow-macos==2.13.0
pip install tensorflow-metal==1.0.0

# Then install other dependencies
pip install flask flask-cors opencv-python numpy pillow scikit-learn matplotlib
```

### Issue: "Address already in use"

**Solution:**
```bash
# Find process using port 5000
lsof -ti:5000

# Kill the process
kill -9 $(lsof -ti:5000)

# Or use a different port
python server.py --port 5001
```

### Issue: Slow performance

**Solution:**
- Use Apple Silicon optimized TensorFlow (tensorflow-macos + tensorflow-metal)
- Close other resource-intensive applications
- Consider using smaller images

### Issue: Camera/Mobile access not working

**Solution:**
```bash
# Check firewall settings
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate

# Get your local IP
ifconfig | grep "inet " | grep -v 127.0.0.1

# Use this IP in your mobile app
```

---

## Stopping the Server

Press `Ctrl + C` in the terminal where the server is running.

To deactivate the virtual environment:
```bash
deactivate
```

---

## Updating the Server

```bash
# Navigate to project folder
cd ~/Desktop/Spotwise_Deployment

# Activate virtual environment
source venv/bin/activate

# Pull latest changes (if using git)
git pull

# Update dependencies
pip install --upgrade -r requirements.txt

# Restart server
python server.py
```

---

## Uninstallation

```bash
# Remove the project folder
rm -rf ~/Desktop/Spotwise_Deployment

# Remove launch agent (if configured)
launchctl unload ~/Library/LaunchAgents/com.spotwise.server.plist
rm ~/Library/LaunchAgents/com.spotwise.server.plist

# (Optional) Uninstall Homebrew packages
brew uninstall python@3.10
```

---

## Performance Benchmarks (Mac)

| Mac Model | Processor | Avg. Response Time |
|-----------|-----------|-------------------|
| MacBook Air M1 | Apple M1 | ~0.8s |
| MacBook Pro M1 Pro | Apple M1 Pro | ~0.6s |
| MacBook Air Intel | Intel i5 | ~2.5s |
| iMac Intel | Intel i7 | ~1.8s |

---

## Security Recommendations

1. **Firewall**: Only allow access from trusted networks
2. **HTTPS**: Use reverse proxy (nginx) with SSL for production
3. **Authentication**: Add API key authentication for production
4. **Rate Limiting**: Implement rate limiting to prevent abuse

---

## Support & Resources

- **API Documentation**: See `API_DOCUMENTATION.md`
- **Project Documentation**: See `PROJECT_DOCUMENTATION.md`
- **Python Docs**: https://docs.python.org/3/
- **Flask Docs**: https://flask.palletsprojects.com/
- **TensorFlow Docs**: https://www.tensorflow.org/

---

## Quick Reference Commands

```bash
# Start server
source venv/bin/activate && python server.py

# Stop server
Ctrl + C

# Check server status
curl http://localhost:5000/test_images_list

# View server logs
tail -f /tmp/spotwise.out

# Restart server
pkill -f "python server.py" && python server.py
```

---

**Installation complete! 🎉**

Your Spotwise server is now ready to accept requests from mobile applications.
