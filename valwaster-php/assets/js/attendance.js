// Attendance Management JavaScript

// Attendance data - will be populated from Firebase/database
let attendanceData = [];
let db = null; // Will be set when Firebase is available

let currentTab = "team-records";
let selectedTeamMembers = [];
let currentTeamType = "Waste Collection";
let currentRecord = null;

// Initialize page
document.addEventListener('DOMContentLoaded', function() {
    console.log('🔄 DOM Content Loaded - Initializing attendance page...');
    
    // Show that JavaScript is working
    console.log('✅ JavaScript is working!');
    
    // Force clear any cached data and browser storage
    attendanceData = [];
    localStorage.removeItem('attendanceData');
    sessionStorage.removeItem('attendanceData');
    
    // Wait for Firebase to be available
    waitForFirebase();
    
    // Add refresh button functionality
    addRefreshButton();
});

// Wait for Firebase to be available
function waitForFirebase() {
    console.log('🔄 Waiting for Firebase to be available...');
    
    // Check if Firebase is available every 100ms
    const checkFirebase = setInterval(() => {
        if (window.firebase && window.firebase.firestore) {
            console.log('✅ Firebase is available!');
            clearInterval(checkFirebase);
            
            // Initialize Firebase
            initializeFirebase();
        } else {
            console.log('⏳ Firebase not ready yet...');
        }
    }, 100);
    
    // Timeout after 10 seconds
    setTimeout(() => {
        clearInterval(checkFirebase);
        console.error('❌ Firebase initialization timeout');
        showNotification('Firebase initialization failed. Using mock data for testing.', 'warning');
        
        // Load mock data for testing
        loadMockData();
    }, 10000);
}

// Initialize Firebase
function initializeFirebase() {
    try {
        console.log('🔄 Initializing Firebase...');
        
        // Use Firebase v8 compat version for compatibility
        if (!firebase.apps || firebase.apps.length === 0) {
            const firebaseConfig = {
                apiKey: "AIzaSyAr5KSpYvShZrCEJLMGf7ckrbfedta3W_M",
                authDomain: "valwaste-89930.firebaseapp.com",
                projectId: "valwaste-89930",
                storageBucket: "valwaste-89930.firebasestorage.app",
                messagingSenderId: "301491189774",
                appId: "1:301491189774:web:23f0fa68d2b264946b245f",
                measurementId: "G-C70DHXP9FW"
            };
            firebase.initializeApp(firebaseConfig);
        }
        
        db = firebase.firestore();
        console.log('✅ Firebase initialized successfully');
        
        // Now load attendance data
        loadAttendanceData();
        
        // Initialize other components
    renderAttendanceTable();
    updateCheckOutOptions();
    updatePendingCount();
        
    } catch (error) {
        console.error('❌ Firebase initialization error:', error);
        showNotification('Firebase initialization failed: ' + error.message, 'error');
    }
}

// Load mock data for testing (DISABLED - using real Firebase data only)
function loadMockData() {
    console.log('🔄 Mock data loading disabled - using real Firebase data only');
    console.log('🔄 Current attendance data:', attendanceData);
    
    // Don't load mock data, just show current data
    renderAttendanceTable();
    updatePendingCount();
}

// Load attendance data from Firebase
async function loadAttendanceData() {
    try {
        console.log('🔄 Loading attendance data from Firebase...');
        console.log('🔄 Firebase db instance:', db);
        
        if (!db) {
            throw new Error('Firebase database not initialized');
        }
        
        // Get attendance records from Firebase using v8 compat syntax
        const attendanceSnapshot = await db.collection('attendance')
            .orderBy('createdAt', 'desc')
            .get();
        
        console.log('🔄 Snapshot:', attendanceSnapshot);
        console.log('🔄 Snapshot size:', attendanceSnapshot.size);
        
        attendanceData = [];
        attendanceSnapshot.forEach(doc => {
            const data = doc.data();
            data.id = doc.id;
            data.expanded = false; // Initialize expanded state
            attendanceData.push(data);
            console.log('✅ Loaded attendance record:', data);
        });
        
        console.log(`✅ Loaded ${attendanceData.length} attendance records total`);
        
        // Re-render the table with new data
        renderAttendanceTable();
        updatePendingCount();
        
    } catch (error) {
        console.error('❌ Error loading attendance data:', error);
        console.error('❌ Error details:', error.message);
        console.error('❌ Error stack:', error.stack);
        // Show error message to user
        showNotification('Failed to load attendance data: ' + error.message, 'error');
    }
}

// Add refresh button functionality
function addRefreshButton() {
    // Add refresh button to the page header
    const pageHeader = document.querySelector('.att-pagehead');
    if (pageHeader) {
        const refreshButton = document.createElement('button');
        refreshButton.className = 'btn-soft';
        refreshButton.innerHTML = `
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <polyline points="23,4 23,10 17,10"></polyline>
                <polyline points="1,20 1,14 7,14"></polyline>
                <path d="M20.49,9A9,9,0,0,0,5.64,5.64L1,10m22,4L18.36,18.36A9,9,0,0,1,3.51,15"></path>
            </svg>
            Refresh Data
        `;
        refreshButton.onclick = () => {
            console.log('🔄 Manual refresh button clicked');
            loadAttendanceData();
        };
        
        // Add a test button to show raw data
        const testButton = document.createElement('button');
        testButton.className = 'btn-soft';
        testButton.style.marginLeft = '10px';
        testButton.innerHTML = `
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path>
                <polyline points="14,2 14,8 20,8"></polyline>
                <line x1="16" y1="13" x2="8" y2="13"></line>
                <line x1="16" y1="17" x2="8" y2="17"></line>
                <polyline points="10,9 9,9 8,9"></polyline>
            </svg>
            Test Data
        `;
        testButton.onclick = () => {
            console.log('🔄 Test button clicked');
            console.log('🔄 Current attendanceData:', attendanceData);
            console.log('🔄 Current tab:', currentTab);
            alert(`Current data: ${attendanceData.length} records\nCurrent tab: ${currentTab}\nCheck console for details`);
        };
        
        // Mock data button removed - using real Firebase data only
        
        pageHeader.insertBefore(testButton, existingButtons);
    }
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
    
    // Force clear the table first
    tbody.innerHTML = '';
    
    console.log('🔄 Rendering attendance table...');
    console.log('🔄 Current tab:', currentTab);
    console.log('🔄 Total attendance data:', attendanceData.length);
    console.log('🔄 All attendance data:', attendanceData);
    
    // Filter data based on current tab
    let filteredData = attendanceData;
    if (currentTab === 'pending-verification') {
        filteredData = attendanceData.filter(record => record.status === 'active' || record.status === 'pending');
        console.log('🔄 Filtered for pending-verification (active/pending status):', filteredData.length);
    } else {
        // Show ALL records in team-records tab regardless of status
        filteredData = attendanceData; // Don't filter at all
        console.log('🔄 Showing all records in team-records (no filtering):', filteredData.length);
    }
    
    console.log('🔄 Filtered data:', filteredData);
    
    // Show empty state if no data
    if (filteredData.length === 0) {
        console.log('🔄 No filtered data found, showing empty state');
    tbody.innerHTML = `
        <tr class="empty">
            <td colspan="5" style="text-align: center; color: #6b7280; padding: 40px 12px;">
                ${currentTab === 'pending-verification' ? 'No pending verification records' : 'No attendance records found'}
            </td>
        </tr>
    `;
    return;
    }
    
    console.log('🔄 About to render', filteredData.length, 'records');
    
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
                        <div class="att-driver-name">${record.driverName || 'Unknown Driver'}</div>
                        <span class="att-role-pill">Driver</span>
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
                    <span class="att-teamcount">${record.teamName || record.truckInfo || 'N/A'}</span>
                </div>
            </td>
            <td>
                <div class="att-cell att-mono">
                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                        <circle cx="12" cy="12" r="10"></circle>
                        <polyline points="12,6 12,12 16,14"></polyline>
                    </svg>
                    ${record.checkInTime ? new Date(record.checkInTime).toLocaleString('en-US', {
                        month: 'short',
                        day: 'numeric',
                        hour: '2-digit',
                        minute: '2-digit'
                    }) : '—'}
                </div>
            </td>
            <td>
                ${record.checkOutTime ? `
                    <div class="att-cell att-mono">
                        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                            <circle cx="12" cy="12" r="10"></circle>
                            <polyline points="12,6 12,12 16,14"></polyline>
                        </svg>
                        ${record.checkOutTime ? new Date(record.checkOutTime).toLocaleString('en-US', {
                            month: 'short',
                            day: 'numeric',
                            hour: '2-digit',
                            minute: '2-digit'
                        }) : '—'}
                    </div>
                ` : '<span class="att-badge att-badge-gray">Not Checked Out</span>'}
            </td>
            <td>
                <span class="att-badge ${getStatusBadgeClass(record.status)}">${getStatusLabel(record.status)}</span>
            </td>
        </tr>
        ${record.expanded ? `
            <tr class="att-expand">
                <td colspan="5">
                    <div class="att-details-container">
                        <div class="att-details-grid">
                            <div class="att-detail-section">
                                <h4>Driver Information</h4>
                                <div class="att-detail-row"><span>Name:</span> ${record.driverName || 'N/A'}</div>
                                <div class="att-detail-row"><span>Driver ID:</span> ${record.driverId || 'N/A'}</div>
                                <div class="att-detail-row"><span>Truck:</span> ${record.truckInfo || 'N/A'}</div>
                                <div class="att-detail-row"><span>Plate Number:</span> ${record.plateNumber || 'N/A'}</div>
                            </div>
                            
                            <div class="att-detail-section">
                                <h4>Attendance Times</h4>
                                <div class="att-detail-row"><span>Check-In:</span> ${record.checkInTime ? new Date(record.checkInTime).toLocaleString() : 'N/A'}</div>
                                <div class="att-detail-row"><span>Check-Out:</span> ${record.checkOutTime ? new Date(record.checkOutTime).toLocaleString() : 'N/A'}</div>
                                <div class="att-detail-row"><span>Total Hours:</span> ${formatHours(record.totalHours)}</div>
                            </div>
                            
                            <div class="att-detail-section">
                                <h4>Work Summary</h4>
                                <div class="att-detail-row"><span>Collections:</span> ${record.collectionsCompleted || 0}</div>
                                <div class="att-detail-row"><span>Location:</span> ${record.location || 'N/A'}</div>
                                <div class="att-detail-row"><span>Status:</span> <span class="att-badge ${getStatusBadgeClass(record.status)}">${getStatusLabel(record.status)}</span></div>
                            </div>
                        </div>
                        ${record.members && record.members.length > 0 ? `
                            <div class="att-team-members">
                                <h4>Team Members</h4>
                                <div class="att-members-grid">
                                    <div class="att-member-item">
                                        <span class="att-role-pill">Driver</span>
                                        <span>${record.driverName || 'Unknown Driver'}</span>
                                    </div>
                                    ${record.members.map(m => `
                                        <div class="att-member-item">
                                            <span class="${getChipClass(m.role)}">${getChipLabel(m.role)}</span>
                                            <span>${m.name}</span>
                                        </div>
                                    `).join('')}
                                </div>
                            </div>
                        ` : ''}
                    </div>
                </td>
            </tr>
        ` : ''}
    `).join('');
    
    console.log('🔄 Table rendered successfully with', filteredData.length, 'records');
}

// Helper functions
function getStatusBadgeClass(status) {
    switch(status) {
        case 'active': return 'att-badge-amber';
        case 'completed': return 'att-badge-green';
        case 'abandoned': return 'att-badge-red';
        case 'verified': return 'att-badge-green';
        case 'pending': return 'att-badge-amber';
        default: return 'att-badge-gray';
    }
}

function getStatusLabel(status) {
    switch(status) {
        case 'active': return 'Active';
        case 'completed': return 'Completed';
        case 'abandoned': return 'Abandoned';
        case 'verified': return 'Verified';
        case 'pending': return 'Pending Verification';
        default: return 'Unknown';
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
    console.log('🔄 Toggle expand clicked for ID:', id);
    
    // Find the record and toggle its expanded state
    const record = attendanceData.find(r => r.id === id);
    if (record) {
        record.expanded = !record.expanded;
        console.log('🔄 Toggled expanded state for record:', record);
        
        // Re-render the table to show/hide the details
        renderAttendanceTable();
    } else {
        console.error('❌ Record not found for ID:', id);
    }
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
    console.log('🔄 Opening details modal for ID:', id);
    
    const record = attendanceData.find(r => r.id === id);
    if (!record) {
        console.error('❌ Record not found for ID:', id);
        return;
    }
    
    console.log('🔄 Found record:', record);
    currentRecord = record;
    
    // Create modal HTML dynamically
    const modalHTML = `
        <div id="detailsModal" class="modal" style="display: grid; position: fixed; top: 0; left: 0; width: 100%; height: 100%; background: rgba(0,0,0,0.5); z-index: 1000; place-items: center;">
            <div class="modal-content" style="background: white; padding: 24px; border-radius: 12px; max-width: 600px; width: 90%; max-height: 80vh; overflow-y: auto;">
                <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 20px;">
                    <h3 style="margin: 0; color: #1f2937; font-size: 20px; font-weight: 600;">Attendance Details</h3>
                    <button onclick="closeDetailsModal()" style="background: none; border: none; font-size: 24px; cursor: pointer; color: #6b7280;">&times;</button>
                </div>
                
                <div style="display: grid; gap: 16px;">
                    <!-- Driver Information -->
                    <div style="padding: 16px; background: #f9fafb; border-radius: 8px;">
                        <h4 style="margin: 0 0 12px 0; color: #374151; font-size: 16px; font-weight: 600;">Driver Information</h4>
                        <div style="display: grid; gap: 8px;">
                            <div><strong>Name:</strong> ${record.driverName || 'N/A'}</div>
                            <div><strong>Driver ID:</strong> ${record.driverId || 'N/A'}</div>
                            <div><strong>Truck:</strong> ${record.truckInfo || 'N/A'}</div>
                            <div><strong>Team:</strong> ${record.teamName || 'N/A'}</div>
                            <div><strong>Plate Number:</strong> ${record.plateNumber || 'N/A'}</div>
                        </div>
                    </div>
                    
                    <!-- Attendance Times -->
                    <div style="padding: 16px; background: #f9fafb; border-radius: 8px;">
                        <h4 style="margin: 0 0 12px 0; color: #374151; font-size: 16px; font-weight: 600;">Attendance Times</h4>
                        <div style="display: grid; gap: 8px;">
                            <div><strong>Check-In:</strong> ${record.checkInTime ? new Date(record.checkInTime).toLocaleString() : 'N/A'}</div>
                            <div><strong>Check-Out:</strong> ${record.checkOutTime ? new Date(record.checkOutTime).toLocaleString() : 'N/A'}</div>
                            <div><strong>Status:</strong> <span class="att-badge ${getStatusBadgeClass(record.status)}">${getStatusLabel(record.status)}</span></div>
                        </div>
                    </div>
                    
                    <!-- Work Summary -->
                    <div style="padding: 16px; background: #f9fafb; border-radius: 8px;">
                        <h4 style="margin: 0 0 12px 0; color: #374151; font-size: 16px; font-weight: 600;">Work Summary</h4>
                        <div style="display: grid; gap: 8px;">
                            <div><strong>Collections Completed:</strong> ${record.collectionsCompleted || 0}</div>
                            <div><strong>Total Hours:</strong> ${record.totalHours || 0} hours</div>
                            <div><strong>Created:</strong> ${record.createdAt ? new Date(record.createdAt).toLocaleString() : 'N/A'}</div>
                            <div><strong>Last Updated:</strong> ${record.updatedAt ? new Date(record.updatedAt).toLocaleString() : 'N/A'}</div>
                        </div>
                    </div>
                </div>
                
                <div style="margin-top: 20px; display: flex; justify-content: flex-end; gap: 12px;">
                    <button onclick="closeDetailsModal()" style="padding: 8px 16px; background: #6b7280; color: white; border: none; border-radius: 6px; cursor: pointer;">Close</button>
                </div>
        </div>
            </div>
    `;
    
    // Remove existing modal if any
    const existingModal = document.getElementById('detailsModal');
    if (existingModal) {
        existingModal.remove();
    }
    
    // Add modal to page
    document.body.insertAdjacentHTML('beforeend', modalHTML);
    
    // Add CSS for status badges if not already present
    if (!document.getElementById('attendance-modal-styles')) {
        const style = document.createElement('style');
        style.id = 'attendance-modal-styles';
        style.textContent = `
            .att-badge {
                display: inline-block;
                padding: 4px 8px;
                border-radius: 12px;
                font-size: 12px;
                font-weight: 500;
                text-transform: uppercase;
            }
            .att-badge-green { background: #d1fae5; color: #065f46; }
            .att-badge-amber { background: #fef3c7; color: #92400e; }
            .att-badge-red { background: #fee2e2; color: #991b1b; }
            .att-badge-gray { background: #f3f4f6; color: #374151; }
        `;
        document.head.appendChild(style);
    }
    
    console.log('✅ Details modal opened successfully');
}

function closeDetailsModal() {
    console.log('🔄 Closing details modal...');
    
    const modal = document.getElementById('detailsModal');
    if (modal) {
        modal.remove();
        console.log('✅ Details modal closed and removed');
    }
    
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

// Form submissions
function submitCheckIn(event) {
    event.preventDefault();
    
    const driver = document.getElementById('driver-select').value;
    const location = document.getElementById('location-input').value;
    const notes = document.getElementById('notes-input').value;
    
    if (!driver) {
        alert('Please select a driver.');
        return;
    }
    
    if (selectedTeamMembers.length === 0) {
        alert('Please add at least one team member.');
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
function verifyRecord() {
    if (!currentRecord) return;
    
    attendanceData = attendanceData.map(r => 
        r.id === currentRecord.id ? { 
            ...r, 
            status: 'verified',
            checkOut: r.checkOut || formatDateTime(new Date())
        } : r
    );
    
    renderAttendanceTable();
    updatePendingCount();
    closeDetailsModal();
    
    alert('Record verified successfully!');
}

function rejectRecord() {
    if (!currentRecord) return;
    
    attendanceData = attendanceData.map(r => 
        r.id === currentRecord.id ? { ...r, status: 'not-out' } : r
    );
    
    renderAttendanceTable();
    updatePendingCount();
    closeDetailsModal();
    
    alert('Record rejected.');
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

// Format hours to display properly (e.g., 0.16666666 -> "10 minutes")
function formatHours(hours) {
    if (!hours || hours === 0) return '0 hours';
    
    const totalMinutes = Math.round(hours * 60);
    const wholeHours = Math.floor(totalMinutes / 60);
    const remainingMinutes = totalMinutes % 60;
    
    if (wholeHours === 0) {
        return `${remainingMinutes} minute${remainingMinutes !== 1 ? 's' : ''}`;
    } else if (remainingMinutes === 0) {
        return `${wholeHours} hour${wholeHours !== 1 ? 's' : ''}`;
    } else {
        return `${wholeHours}h ${remainingMinutes}m`;
    }
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

// Show notification function
function showNotification(message, type = 'info') {
    // Create notification element
    const notification = document.createElement('div');
    notification.className = `notification notification-${type}`;
    notification.textContent = message;
    
    // Style the notification
    notification.style.cssText = `
        position: fixed;
        top: 20px;
        right: 20px;
        padding: 12px 20px;
        border-radius: 8px;
        color: white;
        font-weight: 500;
        z-index: 10000;
        max-width: 400px;
        box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
    `;
    
    // Set background color based on type
    switch(type) {
        case 'error':
            notification.style.backgroundColor = '#ef4444';
            break;
        case 'success':
            notification.style.backgroundColor = '#10b981';
            break;
        case 'warning':
            notification.style.backgroundColor = '#f59e0b';
            break;
        default:
            notification.style.backgroundColor = '#3b82f6';
    }
    
    // Add to page
    document.body.appendChild(notification);
    
    // Remove after 5 seconds
    setTimeout(() => {
        if (notification.parentNode) {
            notification.parentNode.removeChild(notification);
        }
    }, 5000);
}
