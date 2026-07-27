import express from 'express';
import cors from 'cors';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

const DATA_DIR = path.join(__dirname, 'data');
if (!fs.existsSync(DATA_DIR)) {
  fs.mkdirSync(DATA_DIR);
}

// Helper to read/write local JSON files
const getLocalData = (filename, defaultVal = []) => {
  const filePath = path.join(DATA_DIR, filename);
  if (!fs.existsSync(filePath)) {
    fs.writeFileSync(filePath, JSON.stringify(defaultVal, null, 2));
    return defaultVal;
  }
  try {
    return JSON.parse(fs.readFileSync(filePath, 'utf-8'));
  } catch (e) {
    return defaultVal;
  }
};

const saveLocalData = (filename, data) => {
  const filePath = path.join(DATA_DIR, filename);
  fs.writeFileSync(filePath, JSON.stringify(data, null, 2));
};

// Config structure
let config = getLocalData('config.json', { appId: '', apiKey: '' });

// Helper to make MongoDB Data API calls
const callMongoAPI = async (action, collection, body) => {
  if (!config.appId || !config.apiKey || config.appId === 'YOUR_APP_ID' || config.apiKey === 'YOUR_API_KEY') {
    return null;
  }
  const url = `https://ap-south-1.aws.data.mongodb-api.com/app/${config.appId}/endpoint/data/v1/action/${action}`;
  try {
    const response = await fetch(url, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'api-key': config.apiKey
      },
      body: JSON.stringify({
        dataSource: 'Cluster0',
        database: 'icu_db',
        collection,
        ...body
      })
    });
    if (response.ok) {
      return await response.json();
    }
    const errText = await response.text();
    console.error(`MongoDB API Error (${action}):`, response.status, errText);
    return null;
  } catch (e) {
    console.error('MongoDB Connection Error:', e);
    return null;
  }
};

// Seed Medications if empty
const seedMedications = async () => {
  const localMeds = getLocalData('medications.json', []);
  if (localMeds.length === 0) {
    const defaultMeds = [
      { id: 'm1', name: 'Propofol', category: 'Anesthetic', standardDosePerKg: 2.0, minDosePerKg: 1.5, maxDosePerKg: 2.5, unit: 'mg', warning: 'Monitor for Propofol Infusion Syndrome.', interactions: ['m2', 'm3', 'm4'] },
      { id: 'm2', name: 'Midazolam', category: 'Sedative', standardDosePerKg: 0.05, minDosePerKg: 0.02, maxDosePerKg: 0.1, unit: 'mg', warning: 'High risk of respiratory depression.', interactions: ['m1', 'm3'] },
      { id: 'm3', name: 'Fentanyl', category: 'Analgesic', standardDosePerKg: 1.0, minDosePerKg: 0.5, maxDosePerKg: 2.0, unit: 'mcg', warning: 'Monitor respiratory rate closely.', interactions: ['m1', 'm2'] },
      { id: 'm4', name: 'Norepinephrine', category: 'Vasopressor', standardDosePerKg: 0.1, minDosePerKg: 0.01, maxDosePerKg: 0.5, unit: 'mcg/kg/min', warning: 'Monitor MAP and peripheral perfusion.', interactions: ['m1'] },
      { id: 'm5', name: 'Amiodarone', category: 'Antiarrhythmic', standardDosePerKg: 5.0, minDosePerKg: 3.0, maxDosePerKg: 7.0, unit: 'mg', warning: 'Monitor for hypotension and High risk of bradycardia.', interactions: ['m1'] },
      { id: 'm6', name: 'Dopamine', category: 'Inotrope', standardDosePerKg: 5.0, minDosePerKg: 2.0, maxDosePerKg: 20.0, unit: 'mcg/kg/min', warning: 'Monitor for tachyarrhythmias.' },
      { id: 'm7', name: 'Vasopressin', category: 'Vasopressor', standardDosePerKg: 0.03, minDosePerKg: 0.01, maxDosePerKg: 0.04, unit: 'units/min', warning: 'Monitor for water intoxication/hyponatremia.' },
      { id: 'm8', name: 'Heparin', category: 'Anticoagulant', standardDosePerKg: 18.0, minDosePerKg: 12.0, maxDosePerKg: 25.0, unit: 'units/kg/hr', warning: 'High bleed risk. Check aPTT every 6 hours.' },
      { id: 'm9', name: 'Dexmedetomidine', category: 'Sedative', standardDosePerKg: 0.7, minDosePerKg: 0.2, maxDosePerKg: 1.4, unit: 'mcg/kg/hr', warning: 'Monitor for bradycardia and hypotension.' },
      { id: 'm10', name: 'Insulin (Regular)', category: 'Glycemic Control', standardDosePerKg: 0.1, minDosePerKg: 0.01, maxDosePerKg: 0.2, unit: 'units/kg/hr', warning: 'Check blood glucose every 1-2 hours.' }
    ];
    saveLocalData('medications.json', defaultMeds);
  }
};
seedMedications();

// --- API ENDPOINTS ---

// Server status
app.get('/api/status', (req, res) => {
  res.json({ status: 'ok', time: new Date() });
});

// Settings / config
app.get('/api/config', (req, res) => {
  res.json(config);
});

app.post('/api/config', (req, res) => {
  config = {
    appId: req.body.appId || '',
    apiKey: req.body.apiKey || ''
  };
  saveLocalData('config.json', config);
  res.json({ success: true, config });
});

// Authentication
app.post('/api/auth/login', async (req, res) => {
  const { role, staffId, password } = req.body;
  
  // Try remote mongo login
  const mongoRes = await callMongoAPI('findOne', 'staff', { filter: { staffId, role } });
  if (mongoRes && mongoRes.document) {
    if (mongoRes.document.password === password) {
      return res.json({ success: true, role, staffId, source: 'remote' });
    }
  }

  // Fallback to local config
  const localStaff = getLocalData('staff.json', []);
  const user = localStaff.find(u => u.staffId === staffId && u.role === role && u.password === password);
  if (user) {
    return res.json({ success: true, role, staffId, source: 'local' });
  }

  // Default admin fallback
  if (staffId === 'admin' && password === 'admin123') {
    return res.json({ success: true, role: 'Admin', staffId: 'admin', source: 'default' });
  }

  res.status(401).json({ error: 'Invalid credentials' });
});

app.post('/api/auth/register', async (req, res) => {
  const { role, staffId, email, password } = req.body;

  // Try remote mongo
  let remoteSuccess = false;
  const existing = await callMongoAPI('findOne', 'staff', { filter: { staffId } });
  if (existing && existing.document) {
    return res.status(400).json({ error: 'Staff ID already exists' });
  }

  const result = await callMongoAPI('insertOne', 'staff', {
    document: { staffId, email, role, password, createdAt: new Date().toISOString() }
  });
  if (result) remoteSuccess = true;

  // Always write to local JSON backup
  const localStaff = getLocalData('staff.json', []);
  if (!localStaff.some(u => u.staffId === staffId)) {
    localStaff.push({ role, staffId, email, password, createdAt: new Date().toISOString() });
    saveLocalData('staff.json', localStaff);
  } else if (!remoteSuccess) {
    return res.status(400).json({ error: 'Staff ID already exists locally' });
  }

  res.json({ success: true });
});

app.post('/api/auth/reset-password', async (req, res) => {
  const { staffId, email, newPassword } = req.body;

  let remoteSuccess = false;
  const result = await callMongoAPI('updateOne', 'staff', {
    filter: { staffId, email },
    update: { $set: { password: newPassword } }
  });
  if (result && result.matchedCount > 0) remoteSuccess = true;

  // Local reset
  const localStaff = getLocalData('staff.json', []);
  const userIdx = localStaff.findIndex(u => u.staffId === staffId && u.email === email);
  if (userIdx !== -1) {
    localStaff[userIdx].password = newPassword;
    saveLocalData('staff.json', localStaff);
    return res.json({ success: true });
  }

  if (remoteSuccess) {
    return res.json({ success: true });
  }

  res.status(404).json({ error: 'Staff member not found' });
});

// Patients
app.get('/api/patients', async (req, res) => {
  const remoteRes = await callMongoAPI('find', 'patients', {});
  if (remoteRes && remoteRes.documents) {
    saveLocalData('patients.json', remoteRes.documents); // keep local in-sync
    return res.json(remoteRes.documents);
  }
  const localPatients = getLocalData('patients.json', []);
  res.json(localPatients);
});

app.post('/api/patients', async (req, res) => {
  const patient = req.body;
  
  await callMongoAPI('updateOne', 'patients', {
    filter: { id: patient.id },
    update: { $set: patient },
    upsert: true
  });

  const localPatients = getLocalData('patients.json', []);
  const idx = localPatients.findIndex(p => p.id === patient.id);
  if (idx !== -1) {
    localPatients[idx] = patient;
  } else {
    localPatients.unshift(patient);
  }
  saveLocalData('patients.json', localPatients);
  res.json({ success: true, patient });
});

app.delete('/api/patients/:id', async (req, res) => {
  const { id } = req.params;

  await callMongoAPI('deleteOne', 'patients', { filter: { id } });

  const localPatients = getLocalData('patients.json', []);
  const filtered = localPatients.filter(p => p.id !== id);
  saveLocalData('patients.json', filtered);
  res.json({ success: true });
});

// Prescriptions
app.get('/api/prescriptions', async (req, res) => {
  const remoteRes = await callMongoAPI('find', 'prescriptions', { sort: { date: -1 } });
  if (remoteRes && remoteRes.documents) {
    saveLocalData('prescriptions.json', remoteRes.documents);
    return res.json(remoteRes.documents);
  }
  const localPres = getLocalData('prescriptions.json', []);
  res.json(localPres);
});

app.post('/api/prescriptions', async (req, res) => {
  const prescription = req.body;

  await callMongoAPI('insertOne', 'prescriptions', { document: prescription });

  const localPres = getLocalData('prescriptions.json', []);
  localPres.unshift(prescription);
  saveLocalData('prescriptions.json', localPres);
  res.json({ success: true, prescription });
});

// Audit Logs
app.get('/api/logs', async (req, res) => {
  const remoteRes = await callMongoAPI('find', 'audit_logs', { sort: { timestamp: -1 } });
  if (remoteRes && remoteRes.documents) {
    saveLocalData('logs.json', remoteRes.documents);
    return res.json(remoteRes.documents);
  }
  const localLogs = getLocalData('logs.json', []);
  res.json(localLogs);
});

app.post('/api/logs', async (req, res) => {
  const log = req.body;
  log.timestamp = log.timestamp || new Date().toISOString();

  await callMongoAPI('insertOne', 'audit_logs', { document: log });

  const localLogs = getLocalData('logs.json', []);
  localLogs.unshift(log);
  saveLocalData('logs.json', localLogs);
  res.json({ success: true, log });
});

// Medications List (read-only for client reference)
app.get('/api/medications', async (req, res) => {
  const remoteRes = await callMongoAPI('find', 'medications', {});
  if (remoteRes && remoteRes.documents && remoteRes.documents.length > 0) {
    saveLocalData('medications.json', remoteRes.documents);
    return res.json(remoteRes.documents);
  }
  const localMeds = getLocalData('medications.json', []);
  res.json(localMeds);
});

// Catch-all to serve index.html for SPA frontend routing
app.get('*', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

app.listen(PORT, () => {
  console.log(`ICU Suite Pro backend running at http://localhost:${PORT}`);
});
