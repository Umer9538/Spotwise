const https = require('https');

const API_KEY = 'AIzaSyADMuPHuvFsAAkYizYAEXztbMY2M8N7NQI';
const PROJECT_ID = 'spotwise-12f82';

async function getToken() {
  return new Promise((resolve, reject) => {
    const data = JSON.stringify({
      email: 'student@psu.edu.sa',
      password: 'Student123!',
      returnSecureToken: true
    });

    const options = {
      hostname: 'identitytoolkit.googleapis.com',
      path: `/v1/accounts:signInWithPassword?key=${API_KEY}`,
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': data.length
      }
    };

    const req = https.request(options, (res) => {
      let body = '';
      res.on('data', chunk => body += chunk);
      res.on('end', () => {
        const result = JSON.parse(body);
        resolve(result.idToken);
      });
    });

    req.on('error', reject);
    req.write(data);
    req.end();
  });
}

async function addDocument(token, collection, docId, fields) {
  return new Promise((resolve, reject) => {
    const data = JSON.stringify({ fields });
    const path = `/v1/projects/${PROJECT_ID}/databases/(default)/documents/${collection}?documentId=${docId}`;

    const options = {
      hostname: 'firestore.googleapis.com',
      path: path,
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(data)
      }
    };

    const req = https.request(options, (res) => {
      let body = '';
      res.on('data', chunk => body += chunk);
      res.on('end', () => resolve(res.statusCode < 300));
    });

    req.on('error', reject);
    req.write(data);
    req.end();
  });
}

async function main() {
  console.log('Getting auth token...');
  const token = await getToken();
  if (!token) { console.log('Failed to get token'); return; }

  console.log('Adding parking zones...');

  const zones = [
    { id: 'zone_a', name: 'Zone A', desc: 'Main entrance - Female Campus', campus: 'female', total: 20, avail: 12 },
    { id: 'zone_b', name: 'Zone B', desc: 'Library parking - Female Campus', campus: 'female', total: 15, avail: 8 },
    { id: 'zone_c', name: 'Zone C', desc: 'Engineering - Male Campus', campus: 'male', total: 25, avail: 15 },
    { id: 'zone_d', name: 'Zone D', desc: 'Visitor parking', campus: 'visitor', total: 10, avail: 6 }
  ];

  for (const z of zones) {
    const fields = {
      zone_id: { stringValue: z.id },
      name: { stringValue: z.name },
      description: { stringValue: z.desc },
      campus: { stringValue: z.campus },
      total_spots: { integerValue: String(z.total) },
      available_spots: { integerValue: String(z.avail) },
      occupied_spots: { integerValue: String(z.total - z.avail - 2) },
      reserved_spots: { integerValue: '2' },
      latitude: { doubleValue: 24.7136 },
      longitude: { doubleValue: 46.6753 },
      image_url: { stringValue: '' },
      is_covered: { booleanValue: z.campus === 'visitor' },
      has_ev_charging: { booleanValue: z.campus === 'visitor' },
      is_accessible: { booleanValue: true }
    };
    await addDocument(token, 'parking_zones', z.id, fields);
    console.log('Added ' + z.name);
  }

  // Add spots for Zone A
  console.log('Adding spots for Zone A...');
  for (let i = 1; i <= 20; i++) {
    let status = i <= 6 ? 'occupied' : (i <= 8 ? 'reserved' : 'available');
    const spot = {
      spot_id: { stringValue: 'zone_a_spot_' + i },
      zone_id: { stringValue: 'zone_a' },
      spot_number: { stringValue: 'A' + i },
      status: { stringValue: status },
      floor: { integerValue: '1' },
      is_covered: { booleanValue: false },
      is_ev_charging: { booleanValue: false },
      is_accessible: { booleanValue: i <= 2 }
    };
    await addDocument(token, 'parking_spots', 'zone_a_spot_' + i, spot);
  }

  console.log('\\nSample data added successfully!');
  console.log('- 4 Zones, 20 Spots in Zone A');
}

main().catch(console.error);
