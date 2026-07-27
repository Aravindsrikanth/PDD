// ==========================================
// ICU SUITE PRO - SPA FRONTEND ENGINE
// ==========================================

// Global state variables
let state = {
  currentUser: null,
  patients: [],
  prescriptions: [],
  logs: [],
  config: { appId: '', apiKey: '' },
  medications: [],
  selectedBed: null,
  activeView: 'dashboard',
  isDarkMode: false,
  offlineMode: false // set to true if express server is offline
};

// Base URL for API requests
const API_BASE = window.location.origin.includes('localhost') || window.location.origin.includes('127.0.0.1')
  ? ''
  : 'http://localhost:3000';

// ==========================================
// 1. DRUGS & MEDICATION REFERENCE DATABASE
// ==========================================
const DRUG_DATABASE = [
  {
    id: 'm1',
    name: 'Propofol',
    category: 'Anesthetic',
    standardDosePerKg: 2.0,
    minDosePerKg: 1.5,
    maxDosePerKg: 2.5,
    unit: 'mg',
    conc: 10, // 10 mg/ml (1%)
    isInfusion: false,
    isWeightBased: true,
    warning: 'Monitor closely for Propofol Infusion Syndrome (PRIS), severe metabolic acidosis, hyperlipidemia, and bradycardia.',
    description: 'Short-acting intravenous anesthetic agent used for induction and maintenance of general anesthesia, and sedation in critical care.',
    interactions: ['m2', 'm3', 'm9']
  },
  {
    id: 'm2',
    name: 'Midazolam',
    category: 'Sedative',
    standardDosePerKg: 0.05,
    minDosePerKg: 0.02,
    maxDosePerKg: 0.1,
    unit: 'mg',
    conc: 1, // 1 mg/ml
    isInfusion: false,
    isWeightBased: true,
    warning: 'High risk of respiratory depression and accumulation in renal impairment.',
    description: 'Short-acting benzodiazepine central nervous system depressant used for sedation, anxiolysis, and amnesia.',
    interactions: ['m1', 'm3', 'm9']
  },
  {
    id: 'm3',
    name: 'Fentanyl',
    category: 'Analgesic',
    standardDosePerKg: 1.0,
    minDosePerKg: 0.5,
    maxDosePerKg: 2.0,
    unit: 'mcg',
    conc: 0.05, // 50 mcg/ml (0.05 mg/ml)
    isInfusion: false,
    isWeightBased: true,
    warning: 'Monitor respiratory rate closely. Synergistic CNS and respiratory depression with sedatives.',
    description: 'Potent synthetic opioid analgesic with rapid onset and short duration of action.',
    interactions: ['m1', 'm2', 'm9']
  },
  {
    id: 'm4',
    name: 'Norepinephrine',
    category: 'Vasopressor',
    standardDosePerKg: 0.1, // mcg/kg/min
    minDosePerKg: 0.01,
    maxDosePerKg: 0.5,
    unit: 'mcg/kg/min',
    conc: 0.016, // 16 mcg/ml (4mg in 250ml)
    isInfusion: true,
    isWeightBased: true,
    warning: 'Ensure central venous line placement to prevent extravasation necrosis. Monitor peripheral perfusion and MAP.',
    description: 'Sympathomimetic amine used as a peripheral vasoconstrictor and inotropic stimulator of the heart in shock states.',
    interactions: ['m7']
  },
  {
    id: 'm5',
    name: 'Amiodarone',
    category: 'Antiarrhythmic',
    standardDosePerKg: 5.0,
    minDosePerKg: 3.0,
    maxDosePerKg: 7.0,
    unit: 'mg',
    conc: 50, // 50 mg/ml
    isInfusion: false,
    isWeightBased: true,
    warning: 'Monitor for severe hypotension and bradycardia. Long half-life with potential thyroid and pulmonary toxicity.',
    description: 'Class III antiarrhythmic agent used to treat ventricular arrhythmias and atrial fibrillation.',
    interactions: []
  },
  {
    id: 'm6',
    name: 'Dopamine',
    category: 'Inotrope',
    standardDosePerKg: 5.0, // mcg/kg/min
    minDosePerKg: 2.0,
    maxDosePerKg: 20.0,
    unit: 'mcg/kg/min',
    conc: 1.6, // 1600 mcg/ml (400mg in 250ml)
    isInfusion: true,
    isWeightBased: true,
    warning: 'Monitor for tachyarrhythmias, PVCs, and myocardial ischemia.',
    description: 'Endogenous catecholamine acting on dopaminergic, beta-1, and alpha receptors depending on infusion rate.',
    interactions: []
  },
  {
    id: 'm7',
    name: 'Vasopressin',
    category: 'Vasopressor',
    standardDosePerKg: 0.03, // units/min
    minDosePerKg: 0.01,
    maxDosePerKg: 0.04,
    unit: 'units/min',
    conc: 0.2, // 0.2 units/ml (20 units in 100ml)
    isInfusion: true,
    isWeightBased: false,
    warning: 'Monitor for water intoxication, hyponatremia, and myocardial ischemia.',
    description: 'Antidiuretic hormone receptor agonist causing direct vasoconstriction of vascular smooth muscle.',
    interactions: ['m4']
  },
  {
    id: 'm8',
    name: 'Heparin',
    category: 'Anticoagulant',
    standardDosePerKg: 18.0, // units/kg/hr
    minDosePerKg: 12.0,
    maxDosePerKg: 25.0,
    unit: 'units/kg/hr',
    conc: 100, // 100 units/ml (25000 units in 250ml)
    isInfusion: true,
    isWeightBased: true,
    warning: 'High bleeding risk. Check aPTT every 6 hours and monitor platelets for heparin-induced thrombocytopenia (HIT).',
    description: 'Rapid-acting anticoagulant that prevents clotting by accelerating the action of antithrombin III.',
    interactions: []
  },
  {
    id: 'm9',
    name: 'Dexmedetomidine',
    category: 'Sedative',
    standardDosePerKg: 0.7, // mcg/kg/hr
    minDosePerKg: 0.2,
    maxDosePerKg: 1.4,
    unit: 'mcg/kg/hr',
    conc: 0.004, // 4 mcg/ml (200 mcg in 50ml)
    isInfusion: true,
    isWeightBased: true,
    warning: 'Monitor for transient hypertension, bradycardia, and sinus arrest.',
    description: 'Selective alpha-2 adrenergic agonist providing sedation, analgesia, and sympatholysis without respiratory depression.',
    interactions: ['m1', 'm2', 'm3']
  },
  {
    id: 'm10',
    name: 'Insulin (Regular)',
    category: 'Glycemic Control',
    standardDosePerKg: 0.1, // units/kg/hr
    minDosePerKg: 0.01,
    maxDosePerKg: 0.2,
    unit: 'units/kg/hr',
    conc: 1.0, // 1 unit/ml (100 units in 100ml)
    isInfusion: true,
    isWeightBased: true,
    warning: 'Check blood glucose every 1-2 hours to prevent severe hypoglycemia and hypokalemia.',
    description: 'Short-acting human insulin used to control hyperglycemia in patients with diabetic ketoacidosis or stress-induced diabetes.',
    interactions: []
  }
];

state.medications = DRUG_DATABASE;

// ==========================================
// 2. API REQUEST CLIENT (WITH LOCAL FALLBACK)
// ==========================================
async function apiCall(endpoint, method = 'GET', body = null) {
  if (state.offlineMode) {
    return localFallbackCall(endpoint, method, body);
  }

  try {
    const options = {
      method,
      headers: { 'Content-Type': 'application/json' }
    };
    if (body) {
      options.body = JSON.stringify(body);
    }
    const response = await fetch(`${API_BASE}${endpoint}`, options);
    
    if (!response.ok) {
      throw new Error(`API Error: ${response.status}`);
    }
    return await response.json();
  } catch (error) {
    console.warn(`Express server offline. Falling back to browser LocalStorage: ${error.message}`);
    state.offlineMode = true;
    showNotificationBanner('System operates in local browser mode (Server Offline)', 'orange');
    return localFallbackCall(endpoint, method, body);
  }
}

// Local Storage Fallback Engine
function localFallbackCall(endpoint, method, body) {
  const getStore = (key, def = []) => JSON.parse(localStorage.getItem(key)) || def;
  const saveStore = (key, data) => localStorage.setItem(key, JSON.stringify(data));

  if (endpoint.startsWith('/api/auth/login')) {
    const { role, staffId, password } = body;
    const staff = getStore('local_staff', []);
    const found = staff.find(u => u.staffId === staffId && u.role === role && u.password === password);
    if (found || (staffId === 'admin' && password === 'admin123')) {
      return { success: true, role, staffId, source: 'local-browser' };
    }
    throw new Error('Invalid credentials');
  }

  if (endpoint.startsWith('/api/auth/register')) {
    const staff = getStore('local_staff', []);
    if (staff.some(u => u.staffId === body.staffId)) {
      throw new Error('Staff ID already exists');
    }
    staff.push({ ...body, createdAt: new Date().toISOString() });
    saveStore('local_staff', staff);
    return { success: true };
  }

  if (endpoint.startsWith('/api/auth/reset-password')) {
    const staff = getStore('local_staff', []);
    const idx = staff.findIndex(u => u.staffId === body.staffId && u.email === body.email);
    if (idx !== -1) {
      staff[idx].password = body.newPassword;
      saveStore('local_staff', staff);
      return { success: true };
    }
    throw new Error('User not found');
  }

  if (endpoint.startsWith('/api/patients')) {
    const patients = getStore('local_patients', []);
    if (method === 'GET') {
      return patients;
    }
    if (method === 'POST') {
      const pIdx = patients.findIndex(p => p.id === body.id);
      if (pIdx !== -1) {
        patients[pIdx] = body;
      } else {
        patients.unshift(body);
      }
      saveStore('local_patients', patients);
      return { success: true, patient: body };
    }
    if (method === 'DELETE') {
      const match = endpoint.match(/\/api\/patients\/(.+)/);
      const id = match ? match[1] : null;
      const filtered = patients.filter(p => p.id !== id);
      saveStore('local_patients', filtered);
      return { success: true };
    }
  }

  if (endpoint.startsWith('/api/prescriptions')) {
    const pres = getStore('local_prescriptions', []);
    if (method === 'GET') {
      return pres;
    }
    if (method === 'POST') {
      pres.unshift(body);
      saveStore('local_prescriptions', pres);
      return { success: true, prescription: body };
    }
  }

  if (endpoint.startsWith('/api/logs')) {
    const logs = getStore('local_logs', []);
    if (method === 'GET') {
      return logs;
    }
    if (method === 'POST') {
      body.timestamp = body.timestamp || new Date().toISOString();
      logs.unshift(body);
      saveStore('local_logs', logs);
      return { success: true, log: body };
    }
  }

  if (endpoint.startsWith('/api/config')) {
    if (method === 'GET') {
      return getStore('local_config', { appId: '', apiKey: '' });
    }
    if (method === 'POST') {
      saveStore('local_config', body);
      return { success: true, config: body };
    }
  }

  return null;
}

// ==========================================
// 3. WARD CORE STATE SYNCHRONIZATION
// ==========================================
async function syncData() {
  try {
    const configRes = await apiCall('/api/config');
    if (configRes) state.config = configRes;

    const patientsRes = await apiCall('/api/patients');
    if (patientsRes) state.patients = patientsRes;

    const presRes = await apiCall('/api/prescriptions');
    if (presRes) state.prescriptions = presRes;

    const logsRes = await apiCall('/api/logs');
    if (logsRes) state.logs = logsRes;

    renderDashboard();
    renderBedGrid();
    renderSOFAPatientDropdown();
    renderPrescriptionDropdowns();
    renderPrescriptionsTable();
    renderAuditTimeline();
    renderAnalytics();
    
    console.log('SYNC: Core data sync complete.');
  } catch (error) {
    console.error('Data Sync Error:', error);
  }
}

// Log clinical action helper
async function logAction(actionText) {
  const logObj = {
    time: new Date().toISOString(),
    user: state.currentUser ? state.currentUser.role : 'System',
    action: actionText
  };
  await apiCall('/api/logs', 'POST', logObj);
  
  // Update local copy
  const logsRes = await apiCall('/api/logs');
  if (logsRes) state.logs = logsRes;
  renderDashboard();
  renderAuditTimeline();
}

// ==========================================
// 4. FRONTEND VIEWS ROUTING (SPA)
// ==========================================
function switchView(viewId) {
  // Hide active view
  document.querySelectorAll('.view-section').forEach(sec => sec.classList.remove('active'));
  document.querySelectorAll('.menu-link').forEach(link => link.classList.remove('active'));

  // Show selected view
  const targetSec = document.getElementById(`view-${viewId}`);
  if (targetSec) {
    targetSec.classList.add('active');
    state.activeView = viewId;
  }

  // Highlight menu link
  const menuLink = document.querySelector(`.menu-link[data-view="${viewId}"]`);
  if (menuLink) {
    menuLink.classList.add('active');
  }

  // Update title in header
  const titles = {
    dashboard: 'Overview Dashboard',
    patient_management: 'Patient Management',
    dose_calculator: 'Dose Calculator',
    scoring: 'Clinical SOFA Scoring',
    interaction_checker: 'Interaction Checker',
    drug_database: 'Drug Reference Database',
    prescriptions: 'Active Prescriptions',
    analytics: 'Medication Analytics',
    audit_logs: 'Audit History Logs',
    config: 'Database Configuration',
    emergency: 'Emergency Portal'
  };
  document.getElementById('view-title').innerText = titles[viewId] || 'ICU Command Center';
  
  // Collapse sidebar on mobile
  document.getElementById('sidebar').classList.remove('open');

  // Trigger special view updates
  if (viewId === 'analytics') {
    renderAnalytics();
  } else if (viewId === 'patient_management') {
    renderBedGrid();
    showAdmissionForm(); // Default panel view
  } else if (viewId === 'scoring') {
    resetSofaCalculator();
  }
}

// ==========================================
// 5. OVERVIEW DASHBOARD RENDERING
// ==========================================
function renderDashboard() {
  const totalBeds = 50;
  const occupiedCount = state.patients.length;
  const criticalCount = state.patients.filter(p => p.status === 'Critical').length;
  const occupancyPercent = Math.round((occupiedCount / totalBeds) * 100) || 0;

  // SOFA calculation
  let totalSofa = 0;
  let sofaPatientsCount = 0;
  state.patients.forEach(p => {
    let score = calculateSofaForPatient(p);
    totalSofa += score;
    if (score > 0) sofaPatientsCount++;
  });
  const avgSofa = occupiedCount > 0 ? (totalSofa / occupiedCount).toFixed(1) : 0;

  // Set values
  document.getElementById('stat-active-patients').innerText = occupiedCount;
  document.getElementById('stat-critical-patients').innerText = criticalCount;
  document.getElementById('stat-occupancy-percent').innerText = `${occupancyPercent}%`;
  document.getElementById('stat-avg-sofa').innerText = avgSofa;

  // Critical alerts text
  const alertContainer = document.getElementById('critical-patients-alert');
  if (criticalCount > 0) {
    const criticalBeds = state.patients.filter(p => p.status === 'Critical').map(p => p.bedNumber).sort().join(', ');
    document.getElementById('critical-patients-text').innerText = `Critical patient(s) located at bed(s) [${criticalBeds}] need immediate attention!`;
    alertContainer.style.display = 'block';
    document.getElementById('stat-critical-desc').innerText = `${criticalCount} Beds in Danger`;
  } else {
    alertContainer.style.display = 'none';
    document.getElementById('stat-critical-desc').innerText = 'All clinical paths stable';
  }

  document.getElementById('stat-occupancy-desc').innerText = `${occupiedCount} bed slots in use`;
  
  if (avgSofa < 3) {
    document.getElementById('stat-sofa-desc').innerText = 'Low risk mortality profile';
    document.getElementById('stat-sofa-desc').style.color = 'var(--accent)';
  } else if (avgSofa < 7) {
    document.getElementById('stat-sofa-desc').innerText = 'Moderate clinical risk';
    document.getElementById('stat-sofa-desc').style.color = 'var(--warning)';
  } else {
    document.getElementById('stat-sofa-desc').innerText = 'High mortality danger';
    document.getElementById('stat-sofa-desc').style.color = 'var(--error)';
  }

  // Handover notes
  const localHandover = localStorage.getItem('shift_handover') || "Current ward status: Stable. All clinical monitors operational. Next rounds at 12:00.";
  document.getElementById('handover-text-box').value = localHandover;

  // Short Dashboard Timeline
  const recentLogs = state.logs.slice(0, 3);
  const timelineEl = document.getElementById('dashboard-activity-timeline');
  timelineEl.innerHTML = '';

  if (recentLogs.length === 0) {
    timelineEl.innerHTML = '<div style="color: var(--text-secondary); text-align: center; padding: 20px;">No recent logs recorded.</div>';
    return;
  }

  recentLogs.forEach(l => {
    const timeStr = formatTime(l.timestamp);
    const badgeIcon = l.action.includes('CRITICAL') || l.action.includes('ALERT')
      ? '<i class="fa-solid fa-triangle-exclamation" style="color: var(--error);"></i>'
      : '<i class="fa-solid fa-user-doctor"></i>';
    
    const div = document.createElement('div');
    div.className = 'timeline-item';
    div.innerHTML = `
      <div class="timeline-badge">${badgeIcon}</div>
      <div class="timeline-content">
        <span class="timeline-time">${timeStr}</span>
        <div class="timeline-title">${l.user}</div>
        <div class="timeline-desc">${l.action}</div>
      </div>
    `;
    timelineEl.appendChild(div);
  });
}

// ==========================================
// 6. PATIENT WARD & GRID LAYOUT MAP
// ==========================================
function renderBedGrid() {
  const gridEl = document.getElementById('ward-bed-grid');
  gridEl.innerHTML = '';

  // Generate 50 beds
  for (let i = 1; i <= 50; i++) {
    const bedNo = `ICU-${i.toString().padStart(2, '0')}`;
    const patient = state.patients.find(p => p.bedNumber === bedNo);

    const slot = document.createElement('div');
    
    if (patient) {
      const statusClass = patient.status.toLowerCase(); // stable, recovering, critical
      slot.className = `bed-slot ${statusClass}`;
      
      let sofaScore = calculateSofaForPatient(patient);
      slot.innerHTML = `
        <span class="bed-no">${bedNo.replace('ICU-', '')}</span>
        <span class="bed-patient-initial">${patient.name.split(' ')[0]}</span>
        <span style="font-size: 0.65rem; opacity: 0.7; font-weight: bold;">SOFA: ${sofaScore}</span>
      `;
      
      slot.addEventListener('click', () => showPatientDetails(patient.id));
    } else {
      slot.className = 'bed-slot vacant';
      slot.innerHTML = `
        <span class="bed-no">${bedNo.replace('ICU-', '')}</span>
        <span class="bed-patient-initial" style="opacity: 0.5;"><i class="fa-solid fa-plus"></i> VACANT</span>
      `;
      slot.addEventListener('click', () => showAdmissionForm(bedNo));
    }
    
    gridEl.appendChild(slot);
  }
}

// Show Admission form for a selected Bed
function showAdmissionForm(bedNo = null) {
  state.selectedBed = bedNo;
  const panel = document.getElementById('patient-detail-panel');
  
  // Available beds dropdown list
  const occupiedBeds = state.patients.map(p => p.bedNumber);
  let bedOptions = '';
  for (let i = 1; i <= 50; i++) {
    const b = `ICU-${i.toString().padStart(2, '0')}`;
    if (!occupiedBeds.includes(b) || b === bedNo) {
      const selectedAttr = b === bedNo ? 'selected' : '';
      bedOptions += `<option value="${b}" ${selectedAttr}>${b}</option>`;
    }
  }

  panel.innerHTML = `
    <div class="split-card-header">
      <h3><i class="fa-solid fa-user-plus"></i> Clinical Bed Admission</h3>
    </div>
    <form id="admission-form">
      <div class="form-group">
        <label for="adm-bed">Select Bed Slot</label>
        <select id="adm-bed" required>
          ${bedOptions}
        </select>
      </div>
      <div class="form-group">
        <label for="adm-name">Patient Full Name</label>
        <input type="text" id="adm-name" class="form-control" placeholder="e.g. John Doe" required>
      </div>
      <div class="form-group" style="display: flex; gap: 12px;">
        <div style="flex: 1;">
          <label for="adm-age">Age (Years)</label>
          <input type="number" id="adm-age" class="form-control" placeholder="65" required min="1" max="120">
        </div>
        <div style="flex: 1;">
          <label for="adm-weight">Weight (kg)</label>
          <input type="number" id="adm-weight" class="form-control" placeholder="75" required min="1" max="300" step="0.1">
        </div>
      </div>
      <div class="form-group">
        <label for="adm-status">Clinical Urgency Status</label>
        <select id="adm-status" required>
          <option value="Stable">Stable</option>
          <option value="Recovering" selected>Recovering</option>
          <option value="Critical">Critical</option>
        </select>
      </div>
      
      <div style="border-top: 1px solid var(--border); margin: 20px 0; padding-top: 15px;">
        <h4 style="font-family: var(--font-title); font-size: 0.95rem; margin-bottom: 12px;">Initial Baseline Vitals</h4>
        <div class="form-group" style="display: flex; gap: 12px;">
          <div style="flex: 1;">
            <label for="adm-sys">Systolic BP (mmHg)</label>
            <input type="number" id="adm-sys" class="form-control" placeholder="120" min="40" max="250">
          </div>
          <div style="flex: 1;">
            <label for="adm-dia">Diastolic BP (mmHg)</label>
            <input type="number" id="adm-dia" class="form-control" placeholder="80" min="30" max="150">
          </div>
        </div>
        <div class="form-group">
          <label for="adm-hr">Heart Rate (bpm)</label>
          <input type="number" id="adm-hr" class="form-control" placeholder="78" min="30" max="220">
        </div>
      </div>

      <button type="submit" class="btn btn-primary"><i class="fa-solid fa-clipboard-check"></i> ADMIT CLINICAL CASE</button>
    </form>
  `;

  // Attach submit listener
  document.getElementById('admission-form').addEventListener('submit', handleAdmissionSubmit);
}

// Handle Admission Form Submission
async function handleAdmissionSubmit(e) {
  e.preventDefault();
  
  const name = document.getElementById('adm-name').value;
  const bedNumber = document.getElementById('adm-bed').value;
  const age = parseInt(document.getElementById('adm-age').value);
  const weight = parseFloat(document.getElementById('adm-weight').value);
  const status = document.getElementById('adm-status').value;
  
  const systolicBP = parseFloat(document.getElementById('adm-sys').value) || null;
  const diastolicBP = parseFloat(document.getElementById('adm-dia').value) || null;
  const heartRate = parseInt(document.getElementById('adm-hr').value) || null;

  const patientId = 'p_' + Math.random().toString(36).substr(2, 9);
  
  const newPatient = {
    id: patientId,
    name,
    age,
    bedNumber,
    status,
    weight,
    systolicBP,
    diastolicBP,
    heartRate,
    bilirubin: null,
    platelets: null,
    creatinine: null,
    gcs: 15,
    fiO2: 0.21,
    paO2: null,
    history: [`Patient admitted to ${bedNumber} at ${new Date().toLocaleString()}`]
  };

  try {
    const res = await apiCall('/api/patients', 'POST', newPatient);
    if (res && res.success) {
      await logAction(`Admission: ${name} admitted to ${bedNumber}`);
      await syncData();
      showPatientDetails(patientId);
      showNotificationBanner(`Patient ${name} admitted successfully`, 'green');
    }
  } catch (error) {
    showNotificationBanner('Admission submission failed', 'red');
  }
}

// Display Patient Vitals & Clinical Scoring Detail Card
function showPatientDetails(patientId) {
  const p = state.patients.find(pat => pat.id === patientId);
  if (!p) return;

  const panel = document.getElementById('patient-detail-panel');
  
  const sysVal = p.systolicBP || '--';
  const diaVal = p.diastolicBP || '--';
  const bpString = p.systolicBP && p.diastolicBP ? `${p.systolicBP}/${p.diastolicBP}` : '--';
  const hrVal = p.heartRate || '--';
  const sofaScore = calculateSofaForPatient(p);
  
  // MAP calculation
  const mapVal = p.systolicBP && p.diastolicBP 
    ? Math.round((p.systolicBP + 2 * p.diastolicBP) / 3) 
    : '--';

  // Status Badge Class
  const badgeColors = { Stable: 'var(--accent)', Recovering: 'var(--warning)', Critical: 'var(--error)' };
  
  // Log history render
  let historyItems = '';
  const revHistory = [...p.history].reverse();
  revHistory.forEach(h => {
    historyItems += `<div style="font-size: 0.8rem; border-bottom: 1px solid var(--border); padding: 8px 0; color: var(--text-secondary);">${h}</div>`;
  });

  panel.innerHTML = `
    <div class="split-card-header">
      <div>
        <h3 style="font-family: var(--font-title); font-weight: 800; display: flex; align-items: center; gap: 8px;">
          <i class="fa-solid fa-hospital-user"></i> ${p.name}
        </h3>
        <span style="font-size: 0.78rem; font-weight: bold; color: var(--text-secondary);">${p.bedNumber} | Age ${p.age} | ${p.weight} kg</span>
      </div>
      <span class="badge" style="background-color: ${badgeColors[p.status] || 'gray'}; color: #fff; padding: 6px 12px; border-radius: 20px; font-size: 0.78rem; font-weight: 800;">${p.status}</span>
    </div>

    <!-- Vitals boxes -->
    <div class="vitals-grid">
      <div class="vital-box">
        <div class="vital-icon" style="background-color: rgba(239, 68, 68, 0.1); color: var(--error);"><i class="fa-solid fa-heart-pulse"></i></div>
        <div class="vital-info">
          <span class="vital-label">HEART RATE</span>
          <span class="vital-value">${hrVal} <span style="font-size: 0.8rem; font-weight: normal;">bpm</span></span>
        </div>
      </div>
      <div class="vital-box">
        <div class="vital-icon" style="background-color: rgba(13, 71, 161, 0.1); color: var(--primary);"><i class="fa-solid fa-gauge-simple-high"></i></div>
        <div class="vital-info">
          <span class="vital-label">BLOOD PRESSURE</span>
          <span class="vital-value">${bpString} <span style="font-size: 0.75rem; font-weight: normal; color: var(--text-secondary);">(${mapVal} MAP)</span></span>
        </div>
      </div>
    </div>

    <!-- Update Panel Tabs -->
    <div style="margin-top: 24px;">
      <h4 style="font-family: var(--font-title); font-size: 0.95rem; margin-bottom: 12px; border-bottom: 1px solid var(--border); padding-bottom: 6px;"><i class="fa-solid fa-pen-to-square"></i> Clinical Updates</h4>
      
      <div class="form-group" style="display: flex; gap: 10px;">
        <div style="flex: 1;">
          <label>Systolic</label>
          <input type="number" id="upd-sys" class="form-control" value="${p.systolicBP || ''}" style="padding: 8px 12px;">
        </div>
        <div style="flex: 1;">
          <label>Diastolic</label>
          <input type="number" id="upd-dia" class="form-control" value="${p.diastolicBP || ''}" style="padding: 8px 12px;">
        </div>
        <div style="flex: 1;">
          <label>HR</label>
          <input type="number" id="upd-hr" class="form-control" value="${p.heartRate || ''}" style="padding: 8px 12px;">
        </div>
      </div>

      <div class="form-group" style="display: flex; gap: 10px;">
        <div style="flex: 1;">
          <label>Bilirubin (Liver)</label>
          <input type="number" id="upd-bili" class="form-control" value="${p.bilirubin || ''}" step="0.1" style="padding: 8px 12px;">
        </div>
        <div style="flex: 1;">
          <label>Platelets (Coag)</label>
          <input type="number" id="upd-plat" class="form-control" value="${p.platelets || ''}" style="padding: 8px 12px;">
        </div>
      </div>

      <div class="form-group" style="display: flex; gap: 10px;">
        <div style="flex: 1;">
          <label>Creatinine (Renal)</label>
          <input type="number" id="upd-creat" class="form-control" value="${p.creatinine || ''}" step="0.1" style="padding: 8px 12px;">
        </div>
        <div style="flex: 1;">
          <label>GCS Score (CNS)</label>
          <select id="upd-gcs" class="form-control" style="padding: 8px 12px;">
            ${[15,14,13,12,11,10,9,8,7,6,5,4,3].map(n => `<option value="${n}" ${p.gcs == n ? 'selected' : ''}>${n}</option>`).join('')}
          </select>
        </div>
      </div>

      <div class="form-group" style="display: flex; gap: 10px;">
        <div style="flex: 1;">
          <label>FiO2 Ratio (Oxygen)</label>
          <input type="number" id="upd-fio2" class="form-control" value="${p.fiO2 || '0.21'}" step="0.01" style="padding: 8px 12px;">
        </div>
        <div style="flex: 1;">
          <label>PaO2 (mmHg)</label>
          <input type="number" id="upd-pao2" class="form-control" value="${p.paO2 || ''}" style="padding: 8px 12px;">
        </div>
      </div>

      <div class="form-group">
        <label>Urgency Status</label>
        <select id="upd-status" class="form-control" style="padding: 8px 12px;">
          <option value="Stable" ${p.status === 'Stable' ? 'selected' : ''}>Stable</option>
          <option value="Recovering" ${p.status === 'Recovering' ? 'selected' : ''}>Recovering</option>
          <option value="Critical" ${p.status === 'Critical' ? 'selected' : ''}>Critical</option>
        </select>
      </div>

      <div style="display: flex; gap: 8px; margin-top: 15px;">
        <button class="btn btn-primary" onclick="updatePatientVitals('${p.id}')" style="flex: 1;"><i class="fa-solid fa-floppy-disk"></i> SAVE VALUES</button>
        <button class="btn btn-secondary" onclick="loadClinicalScoreTab('${p.id}')" style="width: auto;"><i class="fa-solid fa-list-check"></i> SCORE SOFA</button>
      </div>
      
      <div style="margin-top: 8px;">
        <button class="btn btn-secondary" id="btn-gen-report-${p.id}" onclick="generateClinicalReport('${p.id}')" style="background-color: var(--primary-light); color: var(--primary);"><i class="fa-solid fa-file-pdf"></i> GENERATE CLINICAL REPORT</button>
      </div>
    </div>

    <!-- History list -->
    <div style="margin-top: 24px; max-height: 150px; overflow-y: auto; border: 1px solid var(--border); border-radius: 8px; padding: 12px;">
      <h5 style="font-family: var(--font-title); font-size: 0.85rem; margin-bottom: 6px;">Clinical Timeline History</h5>
      <div id="patient-history-log-list">${historyItems}</div>
    </div>

    <!-- Discharge Patient -->
    <div style="margin-top: 24px; border-top: 1px solid var(--border); padding-top: 15px;">
      <button class="btn btn-danger" onclick="dischargePatient('${p.id}')"><i class="fa-solid fa-house-user"></i> DISCHARGE WARD PATIENT</button>
    </div>
  `;
}

// Update clinical vitals logic
async function updatePatientVitals(patientId) {
  const p = state.patients.find(pat => pat.id === patientId);
  if (!p) return;

  const sys = parseFloat(document.getElementById('upd-sys').value) || null;
  const dia = parseFloat(document.getElementById('upd-dia').value) || null;
  const hr = parseInt(document.getElementById('upd-hr').value) || null;
  const bili = parseFloat(document.getElementById('upd-bili').value) || null;
  const plat = parseFloat(document.getElementById('upd-plat').value) || null;
  const creat = parseFloat(document.getElementById('upd-creat').value) || null;
  const gcs = parseFloat(document.getElementById('upd-gcs').value) || 15;
  const fiO2 = parseFloat(document.getElementById('upd-fio2').value) || 0.21;
  const paO2 = parseFloat(document.getElementById('upd-pao2').value) || null;
  const status = document.getElementById('upd-status').value;

  p.systolicBP = sys;
  p.diastolicBP = dia;
  p.heartRate = hr;
  p.bilirubin = bili;
  p.platelets = plat;
  p.creatinine = creat;
  p.gcs = gcs;
  p.fiO2 = fiO2;
  p.paO2 = paO2;
  
  if (p.status !== status) {
    p.status = status;
    p.history.push(`Status escalated/changed to ${status} at ${new Date().toLocaleTimeString()}`);
  }
  
  p.history.push(`Clinical vitals/labs updated by ${state.currentUser ? state.currentUser.role : 'Staff'} at ${new Date().toLocaleTimeString()}`);

  try {
    const res = await apiCall('/api/patients', 'POST', p);
    if (res && res.success) {
      await logAction(`Telemetry: Clinical data update for ${p.name} (${p.bedNumber})`);
      await syncData();
      showPatientDetails(patientId);
      showNotificationBanner('Vitals saved successfully', 'green');
    }
  } catch (e) {
    showNotificationBanner('Failed to save vitals', 'red');
  }
}

// Discharge patient function
async function dischargePatient(patientId) {
  const p = state.patients.find(pat => pat.id === patientId);
  if (!p) return;

  if (!confirm(`Are you absolutely sure you want to discharge ${p.name} from ${p.bedNumber}?`)) {
    return;
  }

  try {
    const res = await apiCall(`/api/patients/${patientId}`, 'DELETE');
    if (res && res.success) {
      await logAction(`Discharge: ${p.name} discharged from ${p.bedNumber}`);
      await syncData();
      showAdmissionForm();
      showNotificationBanner('Patient discharged successfully', 'green');
    }
  } catch (e) {
    showNotificationBanner('Discharge request failed', 'red');
  }
}

// Load patient into SOFA calculator screen helper
function loadClinicalScoreTab(patientId) {
  switchView('scoring');
  document.getElementById('sofa-patient-select').value = patientId;
  handleSofaPatientSelect(patientId);
}

// ==========================================
// 6B. REPORT GENERATOR ENGINE (SIMULATION)
// ==========================================
async function generateClinicalReport(patientId) {
  const p = state.patients.find(pat => pat.id === patientId);
  if (!p) return;

  const btn = document.getElementById(`btn-gen-report-${patientId}`);
  const originalHtml = btn.innerHTML;
  btn.innerHTML = `<i class="fa-solid fa-spinner fa-spin"></i> COMPILING DATA...`;
  btn.disabled = true;

  // Simulate complex compiling
  await new Promise(resolve => setTimeout(resolve, 2000));

  btn.innerHTML = originalHtml;
  btn.disabled = false;

  // Update history
  const timeNow = new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
  p.history.push(`Clinical PDF Report Generated at ${timeNow}`);
  await apiCall('/api/patients', 'POST', p);

  // Add Log
  await logAction(`Report: Generated medical summary for ${p.name} (${p.bedNumber})`);
  await syncData();

  // Populate Report Modal
  const modal = document.getElementById('clinical-report-modal');
  const content = document.getElementById('clinical-report-modal-content');
  
  const bpString = p.systolicBP && p.diastolicBP ? `${p.systolicBP}/${p.diastolicBP} mmHg` : 'N/A';
  const mapVal = p.systolicBP && p.diastolicBP ? Math.round((p.systolicBP + 2 * p.diastolicBP) / 3) + ' mmHg' : 'N/A';
  const hrVal = p.heartRate ? p.heartRate + ' bpm' : 'N/A';
  const sofa = calculateSofaForPatient(p);
  const activePres = state.prescriptions.filter(pr => pr.patientId === patientId);

  let presListHtml = '';
  if (activePres.length === 0) {
    presListHtml = '<li style="color: var(--text-secondary);">No active medications authorized.</li>';
  } else {
    activePres.forEach(pr => {
      presListHtml += `<li><strong>${pr.med}</strong> - Dosing: <code>${pr.dose}</code></li>`;
    });
  }

  content.innerHTML = `
    <div style="font-family: monospace; font-size: 0.85rem; border: 1px solid var(--border); padding: 20px; border-radius: 8px; background-color: var(--bg); color: var(--text-primary);">
      <div style="text-align: center; border-bottom: 2px double var(--border); padding-bottom: 12px; margin-bottom: 16px;">
        <h2 style="font-family: var(--font-title); font-weight: 800; margin: 0; color: var(--primary);">ICU SUITE PRO CLINICAL SUMMARY</h2>
        <span style="font-size: 0.72rem; color: var(--text-secondary);">SECURE DECRYPTION METHOD - CONFIDENTIAL HOSPITAL DOC</span>
      </div>
      
      <table style="width: 100%; border-collapse: collapse; margin-bottom: 15px; font-size: 0.8rem;">
        <tr>
          <td style="padding: 4px 0; font-weight: bold;">Patient Name:</td>
          <td style="padding: 4px 0;">${p.name}</td>
          <td style="padding: 4px 0; font-weight: bold;">Bed Number:</td>
          <td style="padding: 4px 0;">${p.bedNumber}</td>
        </tr>
        <tr>
          <td style="padding: 4px 0; font-weight: bold;">Patient Age:</td>
          <td style="padding: 4px 0;">${p.age} Years</td>
          <td style="padding: 4px 0; font-weight: bold;">Physiol. Weight:</td>
          <td style="padding: 4px 0;">${p.weight} kg</td>
        </tr>
        <tr>
          <td style="padding: 4px 0; font-weight: bold;">Clinical Urgency:</td>
          <td style="padding: 4px 0; font-weight: bold; color: ${p.status === 'Critical' ? 'var(--error)' : 'var(--accent)'};">${p.status}</td>
          <td style="padding: 4px 0; font-weight: bold;">Assessed SOFA:</td>
          <td style="padding: 4px 0; font-weight: bold;">${sofa} / 24</td>
        </tr>
      </table>

      <h4 style="border-bottom: 1px dashed var(--border); padding-bottom: 4px; margin-top: 15px; margin-bottom: 8px; font-family: var(--font-title); font-size: 0.9rem;">1. CARDIOVASCULAR & RESPIRATORY MONITORING</h4>
      <ul style="padding-left: 20px; margin-bottom: 15px; font-size: 0.8rem; line-height: 1.5;">
        <li>Heart Rate: <strong>${hrVal}</strong></li>
        <li>Blood Pressure: <strong>${bpString}</strong> (MAP: <strong>${mapVal}</strong>)</li>
        <li>Partial Pressure Oxygen (PaO2): <strong>${p.paO2 || 'N/A'} mmHg</strong></li>
        <li>Fraction Inspired Oxygen (FiO2): <strong>${p.fiO2 || '0.21'}</strong></li>
      </ul>

      <h4 style="border-bottom: 1px dashed var(--border); padding-bottom: 4px; margin-top: 15px; margin-bottom: 8px; font-family: var(--font-title); font-size: 0.9rem;">2. CLINICAL LAB PATHOLOGY</h4>
      <ul style="padding-left: 20px; margin-bottom: 15px; font-size: 0.8rem; line-height: 1.5;">
        <li>Total Serum Bilirubin: <strong>${p.bilirubin !== null ? p.bilirubin + ' mg/dL' : 'N/A'}</strong></li>
        <li>Platelets Count: <strong>${p.platelets !== null ? p.platelets + ' x10^3/µL' : 'N/A'}</strong></li>
        <li>Serum Creatinine: <strong>${p.creatinine !== null ? p.creatinine + ' mg/dL' : 'N/A'}</strong></li>
        <li>Glasgow Coma Scale (GCS): <strong>${p.gcs} / 15</strong></li>
      </ul>

      <h4 style="border-bottom: 1px dashed var(--border); padding-bottom: 4px; margin-top: 15px; margin-bottom: 8px; font-family: var(--font-title); font-size: 0.9rem;">3. AUTHORIZED MEDICATIONS</h4>
      <ul style="padding-left: 20px; margin-bottom: 15px; font-size: 0.8rem; line-height: 1.5;">
        ${presListHtml}
      </ul>

      <h4 style="border-bottom: 1px dashed var(--border); padding-bottom: 4px; margin-top: 15px; margin-bottom: 8px; font-family: var(--font-title); font-size: 0.9rem;">4. CLINICAL HISTORY LOGS</h4>
      <div style="font-size: 0.72rem; line-height: 1.4; color: var(--text-secondary); max-height: 100px; overflow-y: auto;">
        ${p.history.map(h => `<div>• ${h}</div>`).join('')}
      </div>
      
      <div style="margin-top: 24px; text-align: right; border-top: 1px dashed var(--border); padding-top: 12px; font-size: 0.75rem; color: var(--text-secondary);">
        Compiled by: ${state.currentUser ? state.currentUser.role : 'System'} (ID: ${state.currentUser ? state.currentUser.staffId : 'admin'})<br>
        Timestamp: ${new Date().toLocaleString()}
      </div>
    </div>
  `;

  modal.style.display = 'flex';
}

function closeReportModal() {
  document.getElementById('clinical-report-modal').style.display = 'none';
}

function printClinicalReport() {
  const content = document.getElementById('clinical-report-modal-content').innerHTML;
  const printWindow = window.open('', '_blank');
  printWindow.document.write(`
    <html>
      <head>
        <title>ICU Suite Pro - Medical Report</title>
        <style>
          body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; padding: 40px; color: #000; background: #fff; }
          code { background: #f3f4f6; padding: 2px 6px; border-radius: 4px; }
        </style>
      </head>
      <body>
        ${content}
        <script>
          window.onload = function() { window.print(); window.close(); }
        </script>
      </body>
    </html>
  `);
  printWindow.document.close();
}

window.closeReportModal = closeReportModal;
window.printClinicalReport = printClinicalReport;

// ==========================================
// 7. WEIGHT-BASED DOSE CALCULATOR
// ==========================================
function renderDoseMedicationDropdown() {
  const drop = document.getElementById('calc-med');
  drop.innerHTML = '<option value="">-- Select Medication --</option>';
  
  state.medications.forEach(m => {
    const isInfLabel = m.isInfusion ? ' [Infusion]' : '';
    drop.innerHTML += `<option value="${m.id}">${m.name} (${m.standardDosePerKg} ${m.unit})${isInfLabel}</option>`;
  });

  // Attach change listener
  drop.addEventListener('change', () => {
    const medId = drop.value;
    const m = state.medications.find(med => med.id === medId);
    const warningBanner = document.getElementById('calc-warning-banner');
    
    if (m && m.warning) {
      warningBanner.innerText = `🚨 Warning: ${m.warning}`;
      warningBanner.style.display = 'block';
    } else {
      warningBanner.style.display = 'none';
    }
  });
}

function handleDoseCalculation() {
  const weight = parseFloat(document.getElementById('calc-weight').value);
  const medId = document.getElementById('calc-med').value;
  
  const valOut = document.getElementById('calc-output-value');
  const infOut = document.getElementById('calc-output-infusion');
  const guidanceOut = document.getElementById('calc-output-guidance');

  if (!weight || !medId) {
    valOut.innerText = '0.00';
    infOut.innerText = '';
    guidanceOut.innerText = 'Please input a valid weight and select medication.';
    return;
  }

  const m = state.medications.find(med => med.id === medId);
  if (!m) return;

  const totalDose = m.isWeightBased ? weight * m.standardDosePerKg : m.standardDosePerKg;
  valOut.innerText = `${totalDose.toFixed(2)} ${m.unit.split('/')[0]}`;

  if (m.isInfusion) {
    let rate = 0;
    
    if (m.unit.includes('mcg')) {
      const concMcg = m.conc * 1000;
      const dosePerMin = totalDose; 
      rate = (dosePerMin * 60) / concMcg;
    } else if (m.unit.includes('units')) {
      rate = (totalDose * 60) / m.conc;
    }
    infOut.innerText = `Infusion Speed: ${rate.toFixed(2)} mL/hr`;
    guidanceOut.innerText = `Based on concentration of ${m.conc} mg/mL (${m.conc * 1000} mcg/mL) standard ICU mix. Dosing range: ${m.minDosePerKg} to ${m.maxDosePerKg} ${m.unit}.`;
  } else {
    infOut.innerText = 'Bolus / Non-Infusion';
    guidanceOut.innerText = `Administer bolus dose. Standard range: ${m.minDosePerKg} - ${m.maxDosePerKg} ${m.unit} based on patient physiological characteristics.`;
  }
}

// ==========================================
// 8. SOFA CLINICAL SCORING ENGINE
// ==========================================
let sofaScores = { resp: 0, cardio: 0, liver: 0, coag: 0, renal: 0, cns: 0 };

function resetSofaCalculator() {
  sofaScores = { resp: 0, cardio: 0, liver: 0, coag: 0, renal: 0, cns: 0 };
  document.querySelectorAll('.score-chip').forEach(c => {
    c.classList.remove('active');
    if (c.getAttribute('data-score') === '0') {
      c.classList.add('active');
    }
  });
  updateSofaUI();
}

function renderSOFAPatientDropdown() {
  const drop = document.getElementById('sofa-patient-select');
  drop.innerHTML = '<option value="">-- Choose Patient to Autofill --</option>';
  state.patients.forEach(p => {
    drop.innerHTML += `<option value="${p.id}">${p.name} (${p.bedNumber})</option>`;
  });
}

function handleSofaPatientSelect(patientId) {
  if (!patientId) {
    resetSofaCalculator();
    document.getElementById('save-sofa-history-btn').style.display = 'none';
    return;
  }

  const p = state.patients.find(pat => pat.id === patientId);
  if (!p) return;

  // 1. Respiration autofill (PaO2/FiO2 ratio)
  if (p.paO2 && p.fiO2) {
    const ratio = p.paO2 / p.fiO2;
    if (ratio < 100) sofaScores.resp = 4;
    else if (ratio < 200) sofaScores.resp = 3;
    else if (ratio < 300) sofaScores.resp = 2;
    else if (ratio < 400) sofaScores.resp = 1;
    else sofaScores.resp = 0;
  } else {
    sofaScores.resp = 0;
  }

  // 2. Coagulation autofill (Platelets)
  if (p.platelets) {
    const pl = p.platelets;
    if (pl < 20) sofaScores.coag = 4;
    else if (pl < 50) sofaScores.coag = 3;
    else if (pl < 100) sofaScores.coag = 2;
    else if (pl < 150) sofaScores.coag = 1;
    else sofaScores.coag = 0;
  } else {
    sofaScores.coag = 0;
  }

  // 3. Liver autofill (Bilirubin)
  if (p.bilirubin) {
    const b = p.bilirubin;
    if (b >= 12.0) sofaScores.liver = 4;
    else if (b >= 6.0) sofaScores.liver = 3;
    else if (b >= 2.0) sofaScores.liver = 2;
    else if (b >= 1.2) sofaScores.liver = 1;
    else sofaScores.liver = 0;
  } else {
    sofaScores.liver = 0;
  }

  // 4. Cardio autofill (MAP)
  const map = p.systolicBP && p.diastolicBP ? (p.systolicBP + 2 * p.diastolicBP) / 3 : null;
  if (map !== null && map < 70) {
    sofaScores.cardio = 1;
  } else {
    sofaScores.cardio = 0;
  }

  // 5. CNS autofill (GCS)
  if (p.gcs) {
    const g = p.gcs;
    if (g < 6) sofaScores.cns = 4;
    else if (g <= 9) sofaScores.cns = 3;
    else if (g <= 12) sofaScores.cns = 2;
    else if (g <= 14) sofaScores.cns = 1;
    else sofaScores.cns = 0;
  } else {
    sofaScores.cns = 0;
  }

  // 6. Renal autofill (Creatinine)
  if (p.creatinine) {
    const c = p.creatinine;
    if (c >= 5.0) sofaScores.renal = 4;
    else if (c >= 3.5) sofaScores.renal = 3;
    else if (c >= 2.0) sofaScores.renal = 2;
    else if (c >= 1.2) sofaScores.renal = 1;
    else sofaScores.renal = 0;
  } else {
    sofaScores.renal = 0;
  }

  // Sync Chips UI
  syncSofaChips('sofa-resp', sofaScores.resp);
  syncSofaChips('sofa-cardio', sofaScores.cardio);
  syncSofaChips('sofa-liver', sofaScores.liver);
  syncSofaChips('sofa-coag', sofaScores.coag);
  syncSofaChips('sofa-renal', sofaScores.renal);
  syncSofaChips('sofa-cns', sofaScores.cns);

  updateSofaUI();

  // Show save history button
  document.getElementById('save-sofa-history-btn').style.display = 'block';
}

function syncSofaChips(rowId, score) {
  const row = document.getElementById(rowId);
  if (!row) return;
  row.querySelectorAll('.score-chip').forEach(c => {
    c.classList.remove('active');
    if (parseInt(c.getAttribute('data-score')) === score) {
      c.classList.add('active');
    }
  });
}

function updateSofaUI() {
  const total = sofaScores.resp + sofaScores.cardio + sofaScores.liver + sofaScores.coag + sofaScores.renal + sofaScores.cns;
  document.getElementById('sofa-total-score').innerText = total;

  const container = document.getElementById('sofa-risk-container');
  const txt = document.getElementById('sofa-risk-text');

  container.className = 'sofa-summary-container';
  if (total < 5) {
    container.classList.add('risk-low');
    txt.innerText = 'LOW MORTALITY RISK (<10%)';
  } else if (total < 10) {
    container.classList.add('risk-moderate');
    txt.innerText = 'MODERATE RISK (~20-30%)';
  } else {
    container.classList.add('risk-high');
    txt.innerText = 'HIGH MORTALITY RISK (>50%)';
  }
}

// Function to calculate SOFA specifically for a patient model
function calculateSofaForPatient(p) {
  let score = 0;
  // Respi
  if (p.paO2 && p.fiO2) {
    const pf = p.paO2 / p.fiO2;
    if (pf < 100) score += 4;
    else if (pf < 200) score += 3;
    else if (pf < 300) score += 2;
    else if (pf < 400) score += 1;
  }
  // Coag
  if (p.platelets) {
    if (p.platelets < 20) score += 4;
    else if (p.platelets < 50) score += 3;
    else if (p.platelets < 100) score += 2;
    else if (p.platelets < 150) score += 1;
  }
  // Liver
  if (p.bilirubin) {
    if (p.bilirubin >= 12.0) score += 4;
    else if (p.bilirubin >= 6.0) score += 3;
    else if (p.bilirubin >= 2.0) score += 2;
    else if (p.bilirubin >= 1.2) score += 1;
  }
  // Cardio
  const mapVal = p.systolicBP && p.diastolicBP ? (p.systolicBP + 2 * p.diastolicBP) / 3 : null;
  if (mapVal !== null && mapVal < 70) score += 1;
  
  // CNS
  if (p.gcs) {
    if (p.gcs < 6) score += 4;
    else if (p.gcs <= 9) score += 3;
    else if (p.gcs <= 12) score += 2;
    else if (p.gcs <= 14) score += 1;
  }
  // Renal
  if (p.creatinine) {
    if (p.creatinine >= 5.0) score += 4;
    else if (p.creatinine >= 3.5) score += 3;
    else if (p.creatinine >= 2.0) score += 2;
    else if (p.creatinine >= 1.2) score += 1;
  }
  return score;
}

// ==========================================
// 9. DRUG INTERACTION CHECKER
// ==========================================
function renderInteractionCheckerGrid() {
  const grid = document.getElementById('checker-drug-grid');
  grid.innerHTML = '';

  state.medications.forEach(m => {
    const card = document.createElement('div');
    card.className = 'drug-checkbox-card';
    card.setAttribute('data-id', m.id);
    card.innerHTML = `
      <input type="checkbox" id="check-${m.id}" value="${m.id}">
      <span style="font-size: 0.9rem; font-weight: 500;">${m.name}</span>
    `;
    
    card.addEventListener('click', (e) => {
      if (e.target.tagName !== 'INPUT') {
        const cb = card.querySelector('input');
        cb.checked = !cb.checked;
        cb.dispatchEvent(new Event('change'));
      }
    });

    const checkbox = card.querySelector('input');
    checkbox.addEventListener('change', () => {
      if (checkbox.checked) {
        card.classList.add('selected');
      } else {
        card.classList.remove('selected');
      }
      runInteractionChecks();
    });

    grid.appendChild(card);
  });
}

function runInteractionChecks() {
  const checkedBoxes = document.querySelectorAll('#checker-drug-grid input:checked');
  const selectedIds = Array.from(checkedBoxes).map(cb => cb.value);
  
  document.getElementById('interaction-count-badge').innerText = `${selectedIds.length} Selected`;

  const warningContainer = document.getElementById('interaction-warning-container');
  const warningList = document.getElementById('interaction-warnings-list');
  const safeBox = document.getElementById('interaction-safe-box');
  
  warningList.innerHTML = '';
  let warnings = [];

  for (let i = 0; i < selectedIds.length; i++) {
    for (let j = i + 1; j < selectedIds.length; j++) {
      const drugA = state.medications.find(d => d.id === selectedIds[i]);
      const drugB = state.medications.find(d => d.id === selectedIds[j]);

      if (drugA.interactions.includes(drugB.id) || drugB.interactions.includes(drugA.id)) {
        warnings.push(`Potential severe reaction between <strong>${drugA.name}</strong> and <strong>${drugB.name}</strong>. Concurrent usage amplifies risk of profound cardiovascular collapse, respiratory depression, or altered pharmacology. Monitor patient vitals closely.`);
      }
    }
  }

  if (warnings.length > 0) {
    warningContainer.style.display = 'block';
    safeBox.style.display = 'none';
    
    const uniqueWarnings = [...new Set(warnings)];
    uniqueWarnings.forEach(w => {
      warningList.innerHTML += `<div class="interaction-item">${w}</div>`;
    });
  } else {
    warningContainer.style.display = 'none';
    if (selectedIds.length >= 2) {
      safeBox.style.display = 'flex';
    } else {
      safeBox.style.display = 'none';
    }
  }
}

// ==========================================
// 10. DRUG INDEX / REFERENCE
// ==========================================
function renderDrugReferenceDatabase() {
  const el = document.getElementById('drug-reference-list');
  el.innerHTML = '';

  state.medications.forEach(m => {
    const item = document.createElement('div');
    item.className = 'drug-db-item';

    const interactionsNames = m.interactions.map(id => {
      const target = state.medications.find(med => med.id === id);
      return target ? target.name : '';
    }).filter(n => n !== '').join(', ') || 'None documented';

    item.innerHTML = `
      <div class="drug-db-header">
        <span>${m.name} <span style="font-size: 0.78rem; font-weight: normal; color: var(--text-secondary);">(${m.category})</span></span>
        <i class="fa-solid fa-chevron-down"></i>
      </div>
      <div class="drug-db-content">
        <p style="margin-bottom: 12px; font-size: 0.9rem; line-height: 1.5;">${m.description}</p>
        <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 15px; font-size: 0.82rem; margin-top: 10px;">
          <div>
            <strong>Standard Dose Range:</strong> ${m.minDosePerKg} - ${m.maxDosePerKg} ${m.unit}<br>
            <strong>Default Concentration:</strong> ${m.conc} mg/mL
          </div>
          <div>
            <strong>Known Interactions:</strong> ${interactionsNames}<br>
            <strong>Dose Type:</strong> ${m.isInfusion ? 'Continuous Infusion' : 'Bolus IV'}
          </div>
        </div>
        ${m.warning ? `<div style="background-color: rgba(239, 68, 68, 0.05); color: var(--error); border-left: 3px solid var(--error); padding: 8px 12px; border-radius: 4px; font-size: 0.8rem; margin-top: 15px;"><strong>Clinical Warning:</strong> ${m.warning}</div>` : ''}
      </div>
    `;

    item.querySelector('.drug-db-header').addEventListener('click', () => {
      const content = item.querySelector('.drug-db-content');
      const icon = item.querySelector('.drug-db-header i');
      const isOpen = content.classList.contains('open');

      document.querySelectorAll('.drug-db-content').forEach(c => c.classList.remove('open'));
      document.querySelectorAll('.drug-db-header i').forEach(i => {
        i.className = 'fa-solid fa-chevron-down';
      });

      if (!isOpen) {
        content.classList.add('open');
        icon.className = 'fa-solid fa-chevron-up';
      }
    });

    el.appendChild(item);
  });
}

// ==========================================
// 11. PRESCRIPTIONS
// ==========================================
function renderPrescriptionDropdowns() {
  const pSelect = document.getElementById('presc-patient');
  const mSelect = document.getElementById('presc-med');

  pSelect.innerHTML = '<option value="">-- Select Bed Occupant --</option>';
  mSelect.innerHTML = '<option value="">-- Choose Drug --</option>';

  state.patients.forEach(p => {
    pSelect.innerHTML += `<option value="${p.id}" data-name="${p.name}">${p.bedNumber} - ${p.name}</option>`;
  });

  state.medications.forEach(m => {
    mSelect.innerHTML += `<option value="${m.id}">${m.name} (${m.category})</option>`;
  });
}

function renderPrescriptionsTable() {
  const tbody = document.getElementById('prescriptions-table-body');
  tbody.innerHTML = '';

  if (state.prescriptions.length === 0) {
    tbody.innerHTML = '<tr><td colspan="4" style="text-align: center; color: var(--text-secondary);">No medication orders authorized.</td></tr>';
    return;
  }

  state.prescriptions.forEach(p => {
    tbody.innerHTML += `
      <tr>
        <td style="font-weight: 600;">${p.patient}</td>
        <td>${p.med}</td>
        <td><code style="background-color: var(--primary-light); color: var(--primary); padding: 4px 8px; border-radius: 4px; font-size: 0.82rem;">${p.dose}</code></td>
        <td>${formatTime(p.date)}</td>
      </tr>
    `;
  });
}

async function handlePrescriptionSubmit(e) {
  e.preventDefault();
  
  const patientSelect = document.getElementById('presc-patient');
  const patientId = patientSelect.value;
  const patientName = patientSelect.options[patientSelect.selectedIndex].getAttribute('data-name');
  
  const medSelect = document.getElementById('presc-med');
  const medId = medSelect.value;
  const medName = medSelect.options[medSelect.selectedIndex].text.split(' (')[0];
  
  const dose = document.getElementById('presc-dose').value;

  if (!patientId || !medId || !dose) return;

  const newPres = {
    id: 'pr_' + Math.random().toString(36).substr(2, 9),
    patientId,
    patient: patientName,
    medId,
    med: medName,
    dose,
    date: new Date().toISOString()
  };

  try {
    const res = await apiCall('/api/prescriptions', 'POST', newPres);
    if (res && res.success) {
      const patient = state.patients.find(p => p.id === patientId);
      if (patient) {
        patient.history.push(`New Prescription Order: ${medName} (${dose}) authorized at ${new Date().toLocaleTimeString()}`);
        await apiCall('/api/patients', 'POST', patient);
      }

      await logAction(`Prescribe: Ordered ${medName} (${dose}) for ${patientName}`);
      await syncData();
      
      document.getElementById('presc-dose').value = '';
      patientSelect.value = '';
      medSelect.value = '';
      
      showNotificationBanner(`Prescription authorized for ${patientName}`, 'green');
    }
  } catch (e) {
    showNotificationBanner('Failed to authorize prescription', 'red');
  }
}

// ==========================================
// 12. MEDICATION ANALYTICS CHARTS (SVG/HTML BARS)
// ==========================================
function renderAnalytics() {
  const classWrapper = document.getElementById('chart-med-classes');
  const usageWrapper = document.getElementById('chart-med-usage');

  classWrapper.innerHTML = '';
  usageWrapper.innerHTML = '';

  let categories = {};
  state.prescriptions.forEach(p => {
    const med = state.medications.find(m => m.name === p.med);
    const cat = med ? med.category : 'General';
    categories[cat] = (categories[cat] || 0) + 1;
  });

  const catKeys = Object.keys(categories);
  if (catKeys.length === 0) {
    classWrapper.innerHTML = '<div style="color: var(--text-secondary); padding: 30px;">Not enough prescription data.</div>';
  } else {
    const maxVal = Math.max(...Object.values(categories));
    catKeys.forEach(k => {
      const count = categories[k];
      const percent = (count / maxVal) * 80 + 10;
      
      const bar = document.createElement('div');
      bar.className = 'chart-bar-container';
      bar.innerHTML = `
        <div class="chart-bar" style="height: ${percent}%;">
          <div class="chart-bar-tooltip">${count} Active Order(s)</div>
        </div>
        <div class="chart-bar-label">${k}</div>
      `;
      classWrapper.appendChild(bar);
    });
  }

  let usage = {};
  state.prescriptions.forEach(p => {
    usage[p.med] = (usage[p.med] || 0) + 1;
  });

  const usageKeys = Object.keys(usage);
  if (usageKeys.length === 0) {
    usageWrapper.innerHTML = '<div style="color: var(--text-secondary); padding: 30px;">Not enough prescription data.</div>';
  } else {
    const maxVal = Math.max(...Object.values(usage));
    usageKeys.forEach(k => {
      const count = usage[k];
      const percent = (count / maxVal) * 80 + 10;
      
      const bar = document.createElement('div');
      bar.className = 'chart-bar-container';
      bar.innerHTML = `
        <div class="chart-bar" style="height: ${percent}%;">
          <div class="chart-bar-tooltip">${count} Order(s)</div>
        </div>
        <div class="chart-bar-label">${k}</div>
      `;
      usageWrapper.appendChild(bar);
    });
  }
}

// ==========================================
// 13. AUDIT TIMELINE
// ==========================================
function renderAuditTimeline() {
  const el = document.getElementById('full-audit-timeline');
  el.innerHTML = '';

  if (state.logs.length === 0) {
    el.innerHTML = '<div style="color: var(--text-secondary); text-align: center; padding: 30px;">No security logs recorded.</div>';
    return;
  }

  state.logs.forEach(l => {
    const date = new Date(l.timestamp);
    const timeStr = date.toLocaleString();
    
    const isAlert = l.action.includes('CRITICAL') || l.action.includes('ALERT');
    const badgeIcon = isAlert
      ? '<i class="fa-solid fa-circle-exclamation" style="color: var(--error);"></i>'
      : '<i class="fa-solid fa-clipboard-list"></i>';

    const div = document.createElement('div');
    div.className = 'timeline-item';
    div.innerHTML = `
      <div class="timeline-badge" style="${isAlert ? 'background-color: rgba(239,68,68,0.1); color: var(--error);' : ''}">${badgeIcon}</div>
      <div class="timeline-content" style="${isAlert ? 'border-color: var(--error); background-color: rgba(239, 68, 68, 0.01);' : ''}">
        <span class="timeline-time" style="font-weight: 500;">${timeStr}</span>
        <div class="timeline-title">${l.user}</div>
        <div class="timeline-desc" style="${isAlert ? 'color: #991b1b; font-weight: 600;' : ''}">${l.action}</div>
      </div>
    `;
    el.appendChild(div);
  });
}

// ==========================================
// 14. EMERGENCY PORTAL ALERTS
// ==========================================
async function triggerEmergencyAlert(alertName) {
  if (!confirm(`Warning: You are initiating a global '${alertName}' alert. Continue?`)) {
    return;
  }
  
  showNotificationBanner(`CRITICAL ALERT: ${alertName} broadcasted!`, 'red');

  const logText = `CRITICAL ALERT: '${alertName}' emergency trigger activated.`;
  await logAction(logText);
  
  if ('speechSynthesis' in window) {
    const utterance = new SpeechSynthesisUtterance(`Attention. Critical Alert. ${alertName} activated.`);
    utterance.rate = 0.95;
    window.speechSynthesis.speak(utterance);
  }
}

// ==========================================
// 15. SETTINGS / DATABASE SETUP
// ==========================================
async function handleConfigSubmit(e) {
  e.preventDefault();
  
  const appId = document.getElementById('config-appId').value;
  const apiKey = document.getElementById('config-apiKey').value;

  try {
    const res = await apiCall('/api/config', 'POST', { appId, apiKey });
    if (res && res.success) {
      state.config = res.config;
      state.offlineMode = false; 
      showNotificationBanner('MongoDB Configuration saved. Synchronizing ward telemetry...', 'green');
      await syncData();
    }
  } catch (error) {
    showNotificationBanner('Failed to save config options.', 'red');
  }
}

// ==========================================
// 16. POPUP NOTIFICATION ALERTS
// ==========================================
function showNotificationBanner(message, type = 'green') {
  const banner = document.getElementById('popup-alert-banner');
  const msgText = document.getElementById('popup-alert-message');
  
  msgText.innerHTML = message;
  
  const colors = {
    green: 'var(--accent)',
    orange: 'var(--warning)',
    red: 'var(--error)'
  };
  
  banner.style.backgroundColor = colors[type] || 'var(--primary)';
  banner.style.display = 'flex';

  setTimeout(() => {
    banner.style.display = 'none';
  }, 4500);
}

// ==========================================
// 17. USER AUTHENTICATIONS LOGIC
// ==========================================
async function handleLoginSubmit(e) {
  e.preventDefault();
  const role = document.getElementById('login-role').value;
  const staffId = document.getElementById('login-staffId').value;
  const password = document.getElementById('login-password').value;

  try {
    const res = await apiCall('/api/auth/login', 'POST', { role, staffId, password });
    if (res && res.success) {
      loginSuccess(res);
    }
  } catch (err) {
    showNotificationBanner('Login failed. Verify credentials.', 'red');
  }
}

async function handleRegisterSubmit(e) {
  e.preventDefault();
  const role = document.getElementById('reg-role').value;
  const staffId = document.getElementById('reg-staffId').value;
  const email = document.getElementById('reg-email').value;
  const password = document.getElementById('reg-password').value;

  try {
    const res = await apiCall('/api/auth/register', 'POST', { role, staffId, email, password });
    if (res && res.success) {
      showNotificationBanner('Staff profile registered. Please log in.', 'green');
      
      document.getElementById('reg-staffId').value = '';
      document.getElementById('reg-email').value = '';
      document.getElementById('reg-password').value = '';
      
      document.getElementById('auth-register-card').style.display = 'none';
      document.getElementById('auth-login-card').style.display = 'block';
    }
  } catch (err) {
    showNotificationBanner(err.message || 'Registration failed.', 'red');
  }
}

async function handleForgotSubmit(e) {
  e.preventDefault();
  const staffId = document.getElementById('forgot-staffId').value;
  const email = document.getElementById('forgot-email').value;
  const newPassword = document.getElementById('forgot-newPassword').value;

  try {
    const res = await apiCall('/api/auth/reset-password', 'POST', { staffId, email, newPassword });
    if (res && res.success) {
      showNotificationBanner('Security key updated. You can login now.', 'green');
      
      document.getElementById('forgot-staffId').value = '';
      document.getElementById('forgot-email').value = '';
      document.getElementById('forgot-newPassword').value = '';
      
      document.getElementById('auth-forgot-card').style.display = 'none';
      document.getElementById('auth-login-card').style.display = 'block';
    }
  } catch (err) {
    showNotificationBanner('Verification failed. Key not matched.', 'red');
  }
}

function loginSuccess(authRes) {
  state.currentUser = {
    role: authRes.role,
    staffId: authRes.staffId
  };

  localStorage.setItem('session_user', JSON.stringify(state.currentUser));

  document.getElementById('user-avatar-char').innerText = authRes.role.charAt(0);
  document.getElementById('user-display-name').innerText = `Staff: ${authRes.role}`;
  document.getElementById('user-display-role').innerText = `ID: ${authRes.staffId} (${authRes.source})`;

  document.getElementById('auth-screen').style.display = 'none';
  document.getElementById('app-shell').style.display = 'flex';

  logAction(`Session: Logged into system`);
  syncData();
  switchView('dashboard');
  showNotificationBanner(`Welcome back, ${authRes.role}!`, 'green');
}

function logoutUser() {
  logAction(`Session: Logged out of system`);
  state.currentUser = null;
  localStorage.removeItem('session_user');
  
  document.getElementById('app-shell').style.display = 'none';
  document.getElementById('auth-screen').style.display = 'flex';
  document.getElementById('auth-login-card').style.display = 'block';
  document.getElementById('auth-register-card').style.display = 'none';
  document.getElementById('auth-forgot-card').style.display = 'none';
}

// ==========================================
// 18. TELEMETRY EVENT LOOPS
// ==========================================

window.addEventListener('DOMContentLoaded', async () => {
  const savedTheme = localStorage.getItem('theme') || 'light';
  document.documentElement.setAttribute('data-theme', savedTheme);
  state.isDarkMode = savedTheme === 'dark';
  updateThemeIcon();

  renderDoseMedicationDropdown();
  renderInteractionCheckerGrid();
  renderDrugReferenceDatabase();

  document.querySelectorAll('.menu-link').forEach(link => {
    link.addEventListener('click', (e) => {
      const viewId = link.getAttribute('data-view');
      if (viewId) switchView(viewId);
    });
  });

  document.getElementById('theme-toggle-btn').addEventListener('click', toggleThemeMode);

  document.getElementById('sync-server-btn').addEventListener('click', async () => {
    const syncBtn = document.getElementById('sync-server-btn');
    syncBtn.querySelector('i').classList.add('fa-spin');
    await syncData();
    setTimeout(() => {
      syncBtn.querySelector('i').classList.remove('fa-spin');
      showNotificationBanner('Database Synchronized', 'green');
    }, 800);
  });

  document.getElementById('notification-bell').addEventListener('click', () => {
    showNotificationBanner('Ward telemetries normal. 0 unread alerts.', 'green');
  });

  document.getElementById('save-handover-btn').addEventListener('click', () => {
    const text = document.getElementById('handover-text-box').value;
    localStorage.setItem('shift_handover', text);
    logAction('Ward: Shift handover clinical notes updated');
    showNotificationBanner('Handover report saved successfully', 'green');
  });

  document.getElementById('calculate-dose-btn').addEventListener('click', handleDoseCalculation);

  document.getElementById('save-sofa-history-btn').addEventListener('click', async () => {
    const patientId = document.getElementById('sofa-patient-select').value;
    const p = state.patients.find(pat => pat.id === patientId);
    if (!p) return;

    const total = sofaScores.resp + sofaScores.cardio + sofaScores.liver + sofaScores.coag + sofaScores.renal + sofaScores.cns;
    const timeNow = new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
    const scoreEntry = `SOFA Score: ${total} calculated at ${timeNow} (CNS: ${sofaScores.cns}, Cardio: ${sofaScores.cardio}, Resp: ${sofaScores.resp}, Renal: ${sofaScores.renal}, Liver: ${sofaScores.liver}, Coag: ${sofaScores.coag})`;

    p.history.push(scoreEntry);
    
    try {
      const res = await apiCall('/api/patients', 'POST', p);
      if (res && res.success) {
        await logAction(`Telemetry: SOFA score calculated for ${p.name} (Value: ${total})`);
        await syncData();
        showNotificationBanner('SOFA Score saved to patient record', 'green');
      }
    } catch (e) {
      showNotificationBanner('Failed to save score history', 'red');
    }
  });

  document.getElementById('prescription-form').addEventListener('submit', handlePrescriptionSubmit);
  document.getElementById('config-form').addEventListener('submit', handleConfigSubmit);

  document.getElementById('go-to-register').addEventListener('click', (e) => {
    e.preventDefault();
    document.getElementById('auth-login-card').style.display = 'none';
    document.getElementById('auth-register-card').style.display = 'block';
  });
  
  document.getElementById('reg-to-login').addEventListener('click', (e) => {
    e.preventDefault();
    document.getElementById('auth-register-card').style.display = 'none';
    document.getElementById('auth-login-card').style.display = 'block';
  });

  document.getElementById('go-to-forgot').addEventListener('click', (e) => {
    e.preventDefault();
    document.getElementById('auth-login-card').style.display = 'none';
    document.getElementById('auth-forgot-card').style.display = 'block';
  });

  document.getElementById('forgot-to-login').addEventListener('click', (e) => {
    e.preventDefault();
    document.getElementById('auth-forgot-card').style.display = 'none';
    document.getElementById('auth-login-card').style.display = 'block';
  });

  document.getElementById('login-form').addEventListener('submit', handleLoginSubmit);
  document.getElementById('register-form').addEventListener('submit', handleRegisterSubmit);
  document.getElementById('forgot-form').addEventListener('submit', handleForgotSubmit);

  document.getElementById('logout-btn').addEventListener('click', logoutUser);

  document.getElementById('menu-toggle').addEventListener('click', () => {
    document.getElementById('sidebar').classList.toggle('open');
  });

  document.getElementById('sofa-patient-select').addEventListener('change', (e) => {
    handleSofaPatientSelect(e.target.value);
  });

  const sofaCategories = ['resp', 'cardio', 'liver', 'coag', 'renal', 'cns'];
  sofaCategories.forEach(cat => {
    const container = document.getElementById(`sofa-${cat}`);
    if (container) {
      container.querySelectorAll('.score-chip').forEach(chip => {
        chip.addEventListener('click', () => {
          container.querySelectorAll('.score-chip').forEach(c => c.classList.remove('active'));
          chip.classList.add('active');
          const score = parseInt(chip.getAttribute('data-score'));
          sofaScores[cat] = score;
          updateSofaUI();
        });
      });
    }
  });

  setTimeout(() => {
    document.getElementById('splash-screen').style.display = 'none';
    
    const savedSession = localStorage.getItem('session_user');
    if (savedSession) {
      try {
        const sessionData = JSON.parse(savedSession);
        loginSuccess({
          role: sessionData.role,
          staffId: sessionData.staffId,
          source: 'saved-session'
        });
      } catch (err) {
        localStorage.removeItem('session_user');
        document.getElementById('auth-screen').style.display = 'flex';
      }
    } else {
      document.getElementById('auth-screen').style.display = 'flex';
    }
  }, 1800);
});

// Theme Management Functions
function toggleThemeMode() {
  state.isDarkMode = !state.isDarkMode;
  const theme = state.isDarkMode ? 'dark' : 'light';
  document.documentElement.setAttribute('data-theme', theme);
  localStorage.setItem('theme', theme);
  updateThemeIcon();
}

function updateThemeIcon() {
  const icon = document.querySelector('#theme-toggle-btn i');
  if (icon) {
    icon.className = state.isDarkMode ? 'fa-solid fa-sun' : 'fa-solid fa-moon';
  }
}

function formatTime(isoStr) {
  if (!isoStr) return '--';
  try {
    const d = new Date(isoStr);
    return d.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit', second: '2-digit' }) + ' ' + d.toLocaleDateString([], { month: 'short', day: 'numeric' });
  } catch (e) {
    return isoStr;
  }
}
