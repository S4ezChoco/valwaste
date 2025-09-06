// Truck Management JavaScript

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

// Initialize Firebase
firebase.initializeApp(firebaseConfig);
const db = firebase.firestore();

let allTrucks = [];
let allSchedules = [];
let currentFilter = 'all';
let currentSearchTerm = '';

// Load trucks and schedules on page load
document.addEventListener('DOMContentLoaded', async () => {
    await loadTrucks();
    await loadTruckSchedules();
    updateTruckGrid();
});

// Load trucks from Firebase
async function loadTrucks() {
    try {
        const trucksRef = db.collection('trucks');
        const snapshot = await trucksRef.orderBy('name').get();
        
        allTrucks = [];
        snapshot.forEach(doc => {
            allTrucks.push({
                id: doc.id,
                ...doc.data()
            });
        });
        
        console.log('Loaded trucks:', allTrucks.length);
    } catch (error) {
        console.error('Error loading trucks:', error);
        showError('Error loading trucks');
    }
}

// Load truck schedules from Firebase
async function loadTruckSchedules() {
    try {
        const schedulesRef = db.collection('truck_schedule');
        const snapshot = await schedulesRef.get();
        
        allSchedules = [];
        snapshot.forEach(doc => {
            allSchedules.push({
                id: doc.id,
                ...doc.data()
            });
        });
        
        console.log('Loaded schedules:', allSchedules.length);
    } catch (error) {
        console.error('Error loading schedules:', error);
    }
}

// Update truck grid display
function updateTruckGrid() {
    const grid = document.getElementById('truck-grid');
    
    // Filter trucks based on current filter and search
    let filteredTrucks = allTrucks.filter(truck => {
        const matchesStatus = currentFilter === 'all' || truck.status === currentFilter;
        const matchesSearch = currentSearchTerm === '' || 
            truck.name.toLowerCase().includes(currentSearchTerm.toLowerCase()) ||
            truck.licensePlate.toLowerCase().includes(currentSearchTerm.toLowerCase());
        
        return matchesStatus && matchesSearch;
    });
    
    if (filteredTrucks.length === 0) {
        grid.innerHTML = `
            <div class="empty-state" style="grid-column: 1 / -1;">
                <svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <rect x="1" y="3" width="15" height="13"></rect>
                    <polygon points="16 8 20 8 23 11 23 16 16 16 16 8"></polygon>
                    <circle cx="5.5" cy="18.5" r="2.5"></circle>
                    <circle cx="18.5" cy="18.5" r="2.5"></circle>
                </svg>
                <h3>No trucks found</h3>
                <p>No trucks match your current filter criteria.</p>
            </div>
        `;
        return;
    }
    
    grid.innerHTML = filteredTrucks.map(truck => createTruckCard(truck)).join('');
}

// Create truck card HTML
function createTruckCard(truck) {
    const truckSchedules = allSchedules.filter(schedule => schedule.truck === truck.name);
    const upcomingSchedules = truckSchedules.filter(schedule => {
        const scheduleDate = new Date(schedule.date);
        const today = new Date();
        return scheduleDate >= today;
    }).slice(0, 2);
    
    return `
        <div class="truck-card" data-truck-id="${truck.id}">
            <div class="truck-header">
                <div class="truck-name">${truck.name}</div>
                <div class="truck-status ${truck.status}">${truck.status.replace('-', ' ')}</div>
            </div>
            
            <div class="truck-details">
                <div class="truck-detail">
                    <span class="label">License Plate:</span>
                    <span class="value">${truck.licensePlate}</span>
                </div>
                <div class="truck-detail">
                    <span class="label">Capacity:</span>
                    <span class="value">${truck.capacity} tons</span>
                </div>
                ${truck.model ? `
                    <div class="truck-detail">
                        <span class="label">Model/Year:</span>
                        <span class="value">${truck.model}</span>
                    </div>
                ` : ''}
                <div class="truck-detail">
                    <span class="label">Last Updated:</span>
                    <span class="value">${formatDate(truck.updatedAt || truck.createdAt)}</span>
                </div>
            </div>
            
            ${upcomingSchedules.length > 0 ? `
                <div style="margin-top: 12px;">
                    <div style="font-size: 12px; color: #6b7280; margin-bottom: 8px;">Upcoming Schedules:</div>
                    ${upcomingSchedules.map(schedule => `
                        <div class="truck-schedule-item">
                            <div class="schedule-date">${formatDate(schedule.date)}</div>
                            <div class="schedule-time">${schedule.startTime} - ${schedule.endTime}</div>
                        </div>
                    `).join('')}
                </div>
            ` : ''}
            
            <div class="truck-actions">
                <button class="btn-mini primary" onclick="editTruck('${truck.id}')">Edit</button>
                <button class="btn-mini" onclick="viewTruckSchedule('${truck.name}')">Schedule</button>
                <button class="btn-mini" onclick="deleteTruck('${truck.id}')">Delete</button>
            </div>
        </div>
    `;
}

// Tab switching
function switchTab(tabName) {
    // Update tab buttons
    document.querySelectorAll('.truck-tab').forEach(tab => {
        tab.classList.toggle('active', tab.dataset.tab === tabName);
    });
    
    // Update tab content
    document.querySelectorAll('.tab-content').forEach(content => {
        content.style.display = 'none';
    });
    
    document.getElementById(`${tabName}-tab`).style.display = 'block';
    
    if (tabName === 'schedule') {
        loadScheduleView();
    }
}

// Filter functions
function filterByStatus(status) {
    currentFilter = status;
    
    // Update filter buttons
    document.querySelectorAll('.status-filter button').forEach(btn => {
        btn.classList.toggle('active', btn.dataset.status === status);
    });
    
    updateTruckGrid();
}

function filterTrucks() {
    currentSearchTerm = document.getElementById('truck-search').value;
    updateTruckGrid();
}

// Modal functions
function openAddTruckModal() {
    document.getElementById('add-truck-modal').style.display = 'flex';
}

function closeAddTruckModal() {
    document.getElementById('add-truck-modal').style.display = 'none';
    document.getElementById('add-truck-form').reset();
}

function openEditTruckModal() {
    document.getElementById('edit-truck-modal').style.display = 'flex';
}

function closeEditTruckModal() {
    document.getElementById('edit-truck-modal').style.display = 'none';
    document.getElementById('edit-truck-form').reset();
}

// Add truck function
async function handleAddTruck(event) {
    event.preventDefault();
    
    const formData = new FormData(event.target);
    const truckData = {
        name: document.getElementById('truck-name').value.trim(),
        licensePlate: document.getElementById('truck-plate').value.trim(),
        capacity: parseFloat(document.getElementById('truck-capacity').value),
        model: document.getElementById('truck-model').value.trim(),
        status: document.getElementById('truck-status').value,
        notes: document.getElementById('truck-notes').value.trim(),
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString()
    };
    
    try {
        // Check if truck name already exists
        const existingTruck = allTrucks.find(truck => truck.name.toLowerCase() === truckData.name.toLowerCase());
        if (existingTruck) {
            showError('Truck with this name already exists');
            return;
        }
        
        // Add truck to Firebase
        await db.collection('trucks').add(truckData);
        
        showSuccess('Truck added successfully');
        closeAddTruckModal();
        
        // Reload trucks
        await loadTrucks();
        updateTruckGrid();
        
    } catch (error) {
        console.error('Error adding truck:', error);
        showError('Error adding truck');
    }
}

// Edit truck function
async function editTruck(truckId) {
    const truck = allTrucks.find(t => t.id === truckId);
    if (!truck) return;
    
    // Populate form
    document.getElementById('edit-truck-id').value = truck.id;
    document.getElementById('edit-truck-name').value = truck.name;
    document.getElementById('edit-truck-plate').value = truck.licensePlate;
    document.getElementById('edit-truck-capacity').value = truck.capacity;
    document.getElementById('edit-truck-model').value = truck.model || '';
    document.getElementById('edit-truck-status').value = truck.status;
    document.getElementById('edit-truck-notes').value = truck.notes || '';
    
    openEditTruckModal();
}

async function handleEditTruck(event) {
    event.preventDefault();
    
    const truckId = document.getElementById('edit-truck-id').value;
    const truckData = {
        name: document.getElementById('edit-truck-name').value.trim(),
        licensePlate: document.getElementById('edit-truck-plate').value.trim(),
        capacity: parseFloat(document.getElementById('edit-truck-capacity').value),
        model: document.getElementById('edit-truck-model').value.trim(),
        status: document.getElementById('edit-truck-status').value,
        notes: document.getElementById('edit-truck-notes').value.trim(),
        updatedAt: new Date().toISOString()
    };
    
    try {
        // Check if truck name already exists (excluding current truck)
        const existingTruck = allTrucks.find(truck => 
            truck.name.toLowerCase() === truckData.name.toLowerCase() && truck.id !== truckId
        );
        if (existingTruck) {
            showError('Another truck with this name already exists');
            return;
        }
        
        // Update truck in Firebase
        await db.collection('trucks').doc(truckId).update(truckData);
        
        showSuccess('Truck updated successfully');
        closeEditTruckModal();
        
        // Reload trucks
        await loadTrucks();
        updateTruckGrid();
        
    } catch (error) {
        console.error('Error updating truck:', error);
        showError('Error updating truck');
    }
}

// Delete truck function
async function deleteTruck(truckId) {
    const truck = allTrucks.find(t => t.id === truckId);
    if (!truck) return;
    
    // Use custom confirmation dialog
    showConfirm(
        `Are you sure you want to delete "${truck.name}"? This action cannot be undone.`,
        async () => {
            try {
                await db.collection('trucks').doc(truckId).delete();
                
                showSuccess('Truck deleted successfully');
                
                // Reload trucks
                await loadTrucks();
                updateTruckGrid();
                
            } catch (error) {
                console.error('Error deleting truck:', error);
                showError('Error deleting truck');
            }
        }
    );
    return;
    
}

// View truck schedule
function viewTruckSchedule(truckName) {
    // Switch to schedule tab and filter by truck
    switchTab('schedule');
    // Implementation for filtering schedule by truck would go here
}

// Load schedule view
function loadScheduleView() {
    const container = document.getElementById('truck-schedule-calendar');
    
    if (allSchedules.length === 0) {
        container.innerHTML = `
            <div class="empty-state">
                <svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <rect x="3" y="4" width="18" height="18" rx="2" ry="2"></rect>
                    <line x1="16" y1="2" x2="16" y2="6"></line>
                    <line x1="8" y1="2" x2="8" y2="6"></line>
                    <line x1="3" y1="10" x2="21" y2="10"></line>
                </svg>
                <h3>No schedules found</h3>
                <p>No truck schedules have been created yet.</p>
            </div>
        `;
        return;
    }
    
    // Group schedules by date
    const schedulesByDate = {};
    allSchedules.forEach(schedule => {
        const date = schedule.date;
        if (!schedulesByDate[date]) {
            schedulesByDate[date] = [];
        }
        schedulesByDate[date].push(schedule);
    });
    
    const sortedDates = Object.keys(schedulesByDate).sort();
    
    container.innerHTML = `
        <div style="display: flex; flex-direction: column; gap: 16px;">
            ${sortedDates.map(date => `
                <div style="background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 8px; padding: 16px;">
                    <h4 style="margin: 0 0 12px 0; color: #1e293b;">${formatDate(date)}</h4>
                    <div style="display: grid; gap: 12px;">
                        ${schedulesByDate[date].map(schedule => `
                            <div style="background: white; border: 1px solid #e2e8f0; border-radius: 6px; padding: 12px;">
                                <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 8px;">
                                    <span style="font-weight: 600; color: #1e293b;">${schedule.truck}</span>
                                    <span style="color: #64748b; font-size: 14px;">${schedule.startTime} - ${schedule.endTime}</span>
                                </div>
                                <div style="font-size: 14px; color: #64748b;">
                                    Driver: ${schedule.driver}<br>
                                    Location: ${schedule.location}
                                </div>
                            </div>
                        `).join('')}
                    </div>
                </div>
            `).join('')}
        </div>
    `;
}

// Utility functions
function formatDate(dateString) {
    const date = new Date(dateString);
    return date.toLocaleDateString('en-US', {
        year: 'numeric',
        month: 'short',
        day: 'numeric'
    });
}

function showNotification(message, type = 'info') {
    // Use the modern notification system
    switch(type) {
        case 'success':
            showSuccess(message);
            break;
        case 'error':
            showError(message);
            break;
        case 'warning':
            showWarning(message);
            break;
        default:
            showInfo(message);
    }
}

// Close modals when clicking outside
document.addEventListener('click', (e) => {
    if (e.target.classList.contains('um-modal')) {
        e.target.style.display = 'none';
    }
});
