// Attendance Management JavaScript

// Firebase configuration
const firebaseConfig = {
    apiKey: "AIzaSyAr5KSpYvShZrCEJLMGf7ckrbfedta3W_M",
    authDomain: "valwaste-89930.firebaseapp.com",
    projectId: "valwaste-89930",
    storageBucket: "valwaste-89930.firebasestorage.app",
    messagingSenderId: "301491189774",
    appId: "1:301491189774:web:23f0fa68d2b264946b245f",
    measurementId: "G-C70DHXP9FW"
};

// Initialize Firebase if not already initialized
if (!firebase.apps.length) {
    firebase.initializeApp(firebaseConfig);
}
const db = firebase.firestore();
const storage = firebase.storage();

// Data storage
let attendanceData = [];
let teamMembers = [];

let currentTab = "team-records";
let selectedTeamMembers = [];
let currentTeamType = "Waste Collection";
let currentRecord = null;

// Initialize page
document.addEventListener('DOMContentLoaded', function() {
    loadAttendanceRecords();
    loadTeamMembers();
    updateCheckOutOptions();
});

// Load attendance records from Firebase
function loadAttendanceRecords() {
    console.log('Loading attendance records from Firebase...');
    
    db.collection('attendance').orderBy('checkInTime', 'desc').onSnapshot((snapshot) => {
        attendanceData = [];
        snapshot.forEach((doc) => {
            const data = doc.data();
            attendanceData.push({
                id: doc.id,
                ...data,
                expanded: false
            });
        });
        
        console.log('Loaded attendance records:', attendanceData.length);
        renderAttendanceTable();
        updateCheckOutOptions();
    }, (error) => {
        console.error('Error loading attendance records:', error);
        showError('Failed to load attendance records');
    });
}

// Load team members from Firebase
function loadTeamMembers() {
    console.log('Loading team members from Firebase...');
    
    db.collection('users')
        .where('role', 'in', ['Driver', 'Waste Collector', 'Palero'])
        .onSnapshot((snapshot) => {
            teamMembers = [];
            snapshot.forEach((doc) => {
                const data = doc.data();
                teamMembers.push({
                    id: doc.id,
                    name: data.name || data.firstName + ' ' + data.lastName,
                    role: data.role,
                    email: data.email
                });
            });
            
            console.log('Loaded team members:', teamMembers.length);
        }, (error) => {
            console.error('Error loading team members:', error);
        });
}

// Tab switching
function switchTab(tab) {
    currentTab = tab;
    
    // Update tab buttons
    document.querySelectorAll('.rm-tab').forEach(btn => {
        btn.classList.remove('active');
    });
    
    if (tab === 'team-records') {
        document.querySelector('.rm-tab:first-child').classList.add('active');
        document.querySelector('.att-title').textContent = 'Team Attendance Records';
        document.querySelector('.att-sub2').textContent = 'View all team attendance records for drivers, waste collectors, and paleros';
    } else {
        document.querySelector('.rm-tab:last-child').classList.add('active');
        document.querySelector('.att-title').textContent = 'Pending Verification';
        document.querySelector('.att-sub2').textContent = 'Team attendance records that need administrator verification';
    }
    
    renderAttendanceTable();
}

// Render attendance table
function renderAttendanceTable() {
    const tbody = document.getElementById('attendance-table-body');
    const filteredData = currentTab === 'pending-verification' 
        ? attendanceData.filter(r => r.status === 'pending')
        : attendanceData;
    
    if (filteredData.length === 0) {
        tbody.innerHTML = `
            <tr class="empty">
                <td colspan="6" style="text-align: center; color: #6b7280; padding: 40px 12px;">
                    ${currentTab === 'pending-verification' ? 'No pending records' : 'No records found'}
                </td>
            </tr>
        `;
        return;
    }
    
    tbody.innerHTML = filteredData.map(record => `
        <tr>
            <td>
                <div class="att-driver">
                    <button class="att-caret" onclick="toggleExpand('${record.id}')" aria-label="toggle">
                        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                            <polyline points="${record.expanded ? '6,9 12,15 18,9' : '9,18 15,12 9,6'}"></polyline>
                        </svg>
                    </button>
                    <div class="att-avatar">
                        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                            <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"></path>
                            <circle cx="12" cy="7" r="4"></circle>
                        </svg>
                    </div>
                    <div class="att-driver-meta">
                        <div class="att-driver-name">${record.driver}</div>
                        <span class="att-role-pill">${record.role}</span>
                    </div>
                </div>
            </td>
            <td>
                <div class="att-cell">
                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                        <path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"></path>
                        <circle cx="9" cy="7" r="4"></circle>
                        <path d="m22 21-3-3m0 0a2 2 0 0 0 0-4 2 2 0 0 0 0 4"></path>
                    </svg>
                    <span class="att-teamcount">${record.teamCount}</span>
                </div>
            </td>
            <td>
                <div class="att-cell att-mono">
                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                        <circle cx="12" cy="12" r="10"></circle>
                        <polyline points="12,6 12,12 16,14"></polyline>
                    </svg>
                    ${record.checkIn}
                </div>
            </td>
            <td>
                ${record.checkOut ? `
                    <div class="att-cell att-mono">
                        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                            <circle cx="12" cy="12" r="10"></circle>
                            <polyline points="12,6 12,12 16,14"></polyline>
                        </svg>
                        ${record.checkOut}
                    </div>
                ` : '<span class="att-badge att-badge-gray">Not Checked Out</span>'}
            </td>
            <td>
                <span class="att-badge ${getStatusBadgeClass(record.status)}">${getStatusLabel(record.status)}</span>
            </td>
            <td class="att-actions">
                <button class="btn-soft-sm" onclick="openDetailsModal('${record.id}')">Details</button>
            </td>
        </tr>
        ${record.expanded ? `
            <tr class="att-expand">
                <td colspan="6">
                    <div class="att-expand-grid">
                        <div class="att-col">
                            <div class="att-expand-title">Team Members</div>
                            <ul class="att-member-list">
                                <li class="att-member-row">
                                    <span class="att-role-pill">Driver</span>
                                    <span class="att-member-name">${record.driver}</span>
                                </li>
                                ${record.members.map(m => `
                                    <li class="att-member-row">
                                        <span class="${getChipClass(m.role)}">${getChipLabel(m.role)}</span>
                                        <span class="att-member-name">${m.name}</span>
                                    </li>
                                `).join('')}
                            </ul>
                        </div>
                        <div class="att-col">
                            <div class="att-expand-title">Additional Information</div>
                            <div class="att-kv">
                                <span class="att-k">Location:</span>
                                <span class="att-v">${record.location || '—'}</span>
                            </div>
                            <div class="att-note">${record.notes || '—'}</div>
                        </div>
                    </div>
                </td>
            </tr>
        ` : ''}
    `).join('');
}

// Helper functions
function getStatusBadgeClass(status) {
    switch(status) {
        case 'verified': return 'att-badge-green';
        case 'pending': return 'att-badge-amber';
        default: return 'att-badge-gray';
    }
}

function getStatusLabel(status) {
    switch(status) {
        case 'verified': return 'Verified';
        case 'pending': return 'Pending Verification';
        default: return 'Not Checked Out';
    }
}

function getChipClass(role) {
    const r = role.toLowerCase();
    if (r === 'collector' || r === 'waste collector') return 'att-chip att-chip-collector';
    if (r === 'palero') return 'att-chip att-chip-palero';
    return 'att-role-pill';
}

function getChipLabel(role) {
    const r = role.toLowerCase();
    if (r === 'collector' || r === 'waste collector') return 'Waste Collector';
    if (r === 'palero') return 'Palero';
    return role;
}

// Toggle expand row
function toggleExpand(id) {
    attendanceData = attendanceData.map(r => 
        r.id === id ? { ...r, expanded: !r.expanded } : r
    );
    renderAttendanceTable();
}

// Modal functions
function openCheckInModal() {
    document.getElementById('checkInModal').style.display = 'grid';
    resetCheckInForm();
}

function closeCheckInModal() {
    document.getElementById('checkInModal').style.display = 'none';
}

function openCheckOutModal() {
    document.getElementById('checkOutModal').style.display = 'grid';
    updateCheckOutOptions();
}

function closeCheckOutModal() {
    document.getElementById('checkOutModal').style.display = 'none';
}

function openDetailsModal(id) {
    const record = attendanceData.find(r => r.id === id);
    if (!record) return;
    
    currentRecord = record;
    
    // Populate modal data
    document.getElementById('checkin-time').textContent = `Check-in time: ${record.checkIn}`;
    document.getElementById('checkout-time').textContent = `Check-out time: ${record.checkOut || '—'}`;
    document.getElementById('location-info').textContent = record.location || '—';
    document.getElementById('notes-info').textContent = record.notes || '—';
    
    // Populate team members
    const membersList = document.getElementById('team-members-list');
    membersList.innerHTML = `
        <div style="display: flex; align-items: center; gap: 10px;">
            <span class="att-role-pill">Driver</span>
            <span style="font-weight: 600;">${record.driver}</span>
        </div>
        ${record.members.map(m => `
            <div style="display: flex; align-items: center; gap: 10px;">
                <span class="${getChipClass(m.role)}">${getChipLabel(m.role)}</span>
                <span>${m.name}</span>
            </div>
        `).join('')}
    `;
    
    // Show/hide action buttons for pending records
    const pendingActions = document.getElementById('pending-actions');
    if (record.status === 'pending') {
        pendingActions.style.display = 'flex';
    } else {
        pendingActions.style.display = 'none';
    }
    
    document.getElementById('detailsModal').style.display = 'grid';
}

function closeDetailsModal() {
    document.getElementById('detailsModal').style.display = 'none';
    currentRecord = null;
}

function closeModal(event, modalId) {
    if (event.target === event.currentTarget) {
        document.getElementById(modalId).style.display = 'none';
    }
}

// Team type selection
function setTeamType(type) {
    currentTeamType = type;
    document.querySelectorAll('.seg').forEach(btn => {
        btn.classList.remove('active');
    });
    event.target.classList.add('active');
}

// Team member management
function addTeamMember() {
    const select = document.getElementById('member-select');
    const member = select.value;
    
    if (!member || selectedTeamMembers.includes(member)) return;
    
    selectedTeamMembers.push(member);
    select.value = '';
    updateTeamMembersDisplay();
}

function removeTeamMember(member) {
    selectedTeamMembers = selectedTeamMembers.filter(m => m !== member);
    updateTeamMembersDisplay();
}

function updateTeamMembersDisplay() {
    const empty = document.getElementById('team-members-empty');
    const chips = document.getElementById('team-members-chips');
    
    if (selectedTeamMembers.length === 0) {
        empty.style.display = 'block';
        chips.style.display = 'none';
    } else {
        empty.style.display = 'none';
        chips.style.display = 'flex';
        chips.innerHTML = selectedTeamMembers.map(member => `
            <span class="checkin-chip">
                ${member}
                <button type="button" class="x" onclick="removeTeamMember('${member}')" aria-label="Remove ${member}">×</button>
            </span>
        `).join('');
    }
}

// Photo capture simulation
function capturePhoto(type) {
    const button = event.target.closest('.checkin-photo-btn');
    const textSpan = button.querySelector('span');
    
    button.classList.add('captured');
    textSpan.textContent = 'Photo Captured';
    
    // Simulate photo capture
    setTimeout(() => {
        alert('Photo captured successfully!');
    }, 100);
}

// Check-in function
async function handleCheckIn(event) {
    event.preventDefault();
    
    const driver = document.getElementById('check-in-driver').value;
    const location = document.getElementById('check-in-location').value;
    const notes = document.getElementById('check-in-notes').value;
    const photoInput = document.getElementById('check-in-photo');
    
    if (!driver || !location || selectedTeamMembers.length === 0) {
        showError('Please fill in all required fields');
        return;
    }
    
    // Create new record
    const id = 'r' + Math.random().toString(36).substr(2, 6);
    const newRecord = {
        id,
        driver,
        role: "Driver",
        teamCount: selectedTeamMembers.length,
        checkIn: formatDateTime(new Date()),
        checkOut: null,
        status: "pending",
        members: selectedTeamMembers.map(name => ({ name, role: "Collector" })),
        location,
        notes,
        expanded: false
    };
    
    attendanceData.unshift(newRecord);
    renderAttendanceTable();
    updateCheckOutOptions();
    closeCheckInModal();
    
    // Update pending count
    updatePendingCount();
    
    alert('Check-in recorded successfully!');
}

function submitCheckOut(event) {
    event.preventDefault();
    
    const teamId = document.getElementById('checkout-team-select').value;
    const notes = document.getElementById('checkout-notes').value;
    
    if (!teamId) {
        alert('Please select a team to check out.');
        return;
    }
    
    // Update record
    attendanceData = attendanceData.map(r => 
        r.id === teamId ? { ...r, checkOut: formatDateTime(new Date()) } : r
    );
    
    renderAttendanceTable();
    updateCheckOutOptions();
    closeCheckOutModal();
    
    alert('Check-out recorded successfully!');
}

// Update checkout options
function updateCheckOutOptions() {
    const select = document.getElementById('checkout-team-select');
    const activeTeams = attendanceData.filter(r => !r.checkOut);
    
    select.innerHTML = `
        <option value="" disabled selected>
            ${activeTeams.length ? 'Select driver/team to check out' : 'No teams available for check-out'}
        </option>
        ${activeTeams.map(r => `
            <option value="${r.id}">${r.driver} — In: ${r.checkIn}</option>
        `).join('')}
    `;
    
    // Handle team preview
    select.addEventListener('change', function() {
        const teamId = this.value;
        const team = attendanceData.find(r => r.id === teamId);
        const preview = document.getElementById('checkout-team-preview');
        const membersList = document.getElementById('checkout-members-list');
        
        if (team) {
            membersList.innerHTML = `
                <li class="att-member-row">
                    <span class="att-role-pill">Driver</span>
                    <span class="att-member-name">${team.driver}</span>
                </li>
                ${team.members.map(m => `
                    <li class="att-member-row">
                        <span class="${getChipClass(m.role)}">${getChipLabel(m.role)}</span>
                        <span class="att-member-name">${m.name}</span>
                    </li>
                `).join('')}
            `;
            preview.style.display = 'block';
        } else {
            preview.style.display = 'none';
        }
    });
}

// Record actions
async function verifyRecord(recordId) {
    try {
        await db.collection('attendance').doc(recordId).update({
            status: 'verified',
            verifiedAt: firebase.firestore.Timestamp.now(),
            verifiedBy: 'Administrator' // In production, get actual admin user
        });
        
        showSuccess('Record verified successfully!');
    } catch (error) {
        console.error('Error verifying record:', error);
        showError('Failed to verify record');
    }
}

async function rejectRecord(recordId) {
    if (confirm('Are you sure you want to reject this record?')) {
        try {
            await db.collection('attendance').doc(recordId).update({
                status: 'rejected',
                rejectedAt: firebase.firestore.Timestamp.now(),
                rejectedBy: 'Administrator' // In production, get actual admin user
            });
            
            closeDetailsModal();
            showSuccess('Record rejected');
        } catch (error) {
            console.error('Error rejecting record:', error);
            showError('Failed to reject record');
        }
    }
}

// Legacy reject function - redirects to async version
function rejectRecord() {
    if (currentRecord && currentRecord.id) {
        rejectRecord(currentRecord.id);
    }
}

// Reset forms
function resetCheckInForm() {
    document.getElementById('driver-select').value = '';
    document.getElementById('member-select').value = '';
    document.getElementById('location-input').value = '';
    document.getElementById('notes-input').value = '';
    document.getElementById('photo-text').textContent = 'Capture Team Photo';
    document.querySelector('.checkin-photo-btn').classList.remove('captured');
    
    selectedTeamMembers = [];
    updateTeamMembersDisplay();
    
    // Reset team type
    document.querySelectorAll('.seg').forEach(btn => btn.classList.remove('active'));
    document.querySelector('.seg').classList.add('active');
    currentTeamType = 'Waste Collection';
}

// Utility functions
function formatDateTime(date) {
    const months = ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"];
    let hours = date.getHours();
    const ampm = hours >= 12 ? 'PM' : 'AM';
    hours = hours % 12 || 12;
    const minutes = String(date.getMinutes()).padStart(2, '0');
    
    return `${months[date.getMonth()]} ${date.getDate()}, ${String(hours).padStart(2,'0')}:${minutes} ${ampm}`;
}

function updatePendingCount() {
    const pendingCount = attendanceData.filter(r => r.status === 'pending').length;
    const countDot = document.querySelector('.count-dot.count-red');
    if (countDot) {
        countDot.textContent = pendingCount;
        countDot.style.display = pendingCount > 0 ? 'inline-flex' : 'none';
    }
}

// Sidebar functionality (from auth.js)
function openSidebar() {
    document.querySelector('.sidebar').classList.add('is-open');
    document.querySelector('.backdrop').style.display = 'block';
}

function closeSidebar() {
    document.querySelector('.sidebar').classList.remove('is-open');
    document.querySelector('.backdrop').style.display = 'none';
}

// Close sidebar when clicking backdrop
document.addEventListener('click', function(e) {
    if (e.target.classList.contains('backdrop')) {
        closeSidebar();
    }
});
