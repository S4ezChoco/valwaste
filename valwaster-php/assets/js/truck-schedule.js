// Truck Schedule JavaScript

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
const app = firebase.initializeApp(firebaseConfig);
const db = firebase.firestore();

// Current date state
let currentDate = new Date();
let currentMonth = currentDate.getMonth();
let currentYear = currentDate.getFullYear();
let selectedDate = null;

// Global variables
let scheduleMap;
let selectedLocation = null;
let selectedDriverId = null;
let selectedDriverData = null;
let selectedCollectors = [];
let schedules = [];
let allDrivers = [];
let allCollectors = [];
let currentBarangayFilter = null;

// Month names
const monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
];

// MapTiler API key
const MAPTILER_KEY = 'Kr1k642bLPyqdCL0A5yM';

// Helper function to format date for input
function formatDateForInput(date) {
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    return `${year}-${month}-${day}`;
}

// Notification helper functions
function showInfo(message) {
    if (window.notifications && window.notifications.info) {
        window.notifications.info(message);
    } else {
        console.log('Info:', message);
    }
}

function showWarning(message) {
    if (window.notifications && window.notifications.warning) {
        window.notifications.warning(message);
    } else {
        console.warn('Warning:', message);
        alert('Warning: ' + message);
    }
}

function showError(message) {
    if (window.notifications && window.notifications.error) {
        window.notifications.error(message);
    } else {
        console.error('Error:', message);
        alert('Error: ' + message);
    }
}

// Initialize on page load
document.addEventListener('DOMContentLoaded', function() {
    generateCalendar();
    updateMonthYearDisplay();
    loadTrucks();
    loadDrivers();
    loadWasteCollectors();
    loadSchedules();
    
    // Clean up old schedules (older than 7 days)
    cleanupOldSchedules();
    
    // Set today's date as default in the modal
    const today = new Date();
    document.getElementById('schedule-date').value = formatDateForInput(today);
    
    // Setup dropdown event listeners
    setupDropdowns();
    
    // Setup search input event listener
    setupSearchListener();
    
    // Initialize map when modal is opened
    const modal = document.getElementById('create-schedule-modal');
    if (modal) {
        modal.addEventListener('shown.bs.modal', function() {
            // Small delay to ensure modal is fully visible
            setTimeout(() => {
                initLocationMap();
            }, 300);
        });
    }
});

// Load trucks from Firebase
function loadTrucks() {
    db.collection('trucks').onSnapshot((snapshot) => {
        const truckSelect = document.getElementById('truck-select');
        // Keep the default option
        truckSelect.innerHTML = '<option value="" disabled selected>Truck</option>';
        
        if (snapshot.empty) {
            const noTrucksOption = document.createElement('option');
            noTrucksOption.disabled = true;
            noTrucksOption.textContent = 'No trucks available';
            truckSelect.appendChild(noTrucksOption);
            return;
        }
        
        // Get all trucks and filter/sort in JavaScript
        const trucks = [];
        snapshot.forEach((doc) => {
            const truckData = doc.data();
            if (truckData.status === 'available') {
                trucks.push(truckData);
            }
        });
        
        // Sort trucks by name
        trucks.sort((a, b) => a.name.localeCompare(b.name));
        
        if (trucks.length === 0) {
            const noTrucksOption = document.createElement('option');
            noTrucksOption.disabled = true;
            noTrucksOption.textContent = 'No available trucks';
            truckSelect.appendChild(noTrucksOption);
            return;
        }
        
        // Add trucks to dropdown
        trucks.forEach((truckData) => {
            const option = document.createElement('option');
            option.value = truckData.name;
            option.textContent = `${truckData.name} (${truckData.licensePlate})`;
            truckSelect.appendChild(option);
        });
    }, (error) => {
        console.error('Error loading trucks:', error);
        showError('Error loading trucks. Please refresh the page.');
    });
}

// Load drivers from Firebase
function loadDrivers() {
    db.collection('users').where('role', '==', 'Driver').onSnapshot((snapshot) => {
        allDrivers = [];
        snapshot.forEach((doc) => {
            const userData = doc.data();
            allDrivers.push({
                id: doc.id,
                ...userData,
                displayName: `${userData.firstName} ${userData.lastName}`
            });
        });
        
        // Initial render shows all drivers
        renderDrivers();
    });
}

// Render drivers based on current filter
function renderDrivers() {
    const driverMenu = document.getElementById('driver-dropdown-menu');
    driverMenu.innerHTML = '';
    
    // Filter drivers based on current barangay filter
    let driversToShow = allDrivers;
    if (currentBarangayFilter) {
        driversToShow = allDrivers.filter(driver => 
            driver.barangay === currentBarangayFilter
        );
    }
    
    if (driversToShow.length === 0) {
        const emptyItem = document.createElement('div');
        emptyItem.className = 'dropdown-item';
        emptyItem.style.color = '#6b7280';
        emptyItem.style.fontStyle = 'italic';
        emptyItem.innerHTML = currentBarangayFilter ? 
            `No drivers in ${currentBarangayFilter}` : 
            'No drivers available';
        driverMenu.appendChild(emptyItem);
        return;
    }
    
    driversToShow.forEach((driver) => {
        const driverItem = document.createElement('div');
        driverItem.className = 'dropdown-item';
        driverItem.innerHTML = `
            <span>${driver.displayName}${driver.barangay ? ` (${driver.barangay})` : ''}</span>
        `;
        driverItem.onclick = () => selectDriver(driver.id, driver.displayName, driver);
        driverMenu.appendChild(driverItem);
    });
}

// Load waste collectors from Firebase
function loadWasteCollectors() {
    db.collection('users').where('role', 'in', ['Driver', 'Waste Collector']).onSnapshot((snapshot) => {
        allCollectors = [];
        snapshot.forEach((doc) => {
            const userData = doc.data();
            allCollectors.push({
                id: doc.id,
                ...userData,
                displayName: `${userData.firstName} ${userData.lastName}`
            });
        });
        
        // Initial render shows all collectors
        renderCollectors();
    });
}

// Render collectors based on current filter
function renderCollectors() {
    const collectorsMenu = document.getElementById('collectors-dropdown-menu');
    collectorsMenu.innerHTML = '';
    
    // Filter collectors based on current barangay filter
    let collectorsToShow = allCollectors;
    if (currentBarangayFilter) {
        collectorsToShow = allCollectors.filter(collector => 
            collector.barangay === currentBarangayFilter
        );
    }
    
    if (collectorsToShow.length === 0) {
        const emptyItem = document.createElement('div');
        emptyItem.className = 'dropdown-item';
        emptyItem.style.color = '#6b7280';
        emptyItem.style.fontStyle = 'italic';
        emptyItem.innerHTML = currentBarangayFilter ? 
            `No paleros in ${currentBarangayFilter}` : 
            'No paleros available';
        collectorsMenu.appendChild(emptyItem);
        return;
    }
    
    collectorsToShow.forEach((collector) => {
        const collectorItem = document.createElement('div');
        collectorItem.className = 'dropdown-item';
        
        // Create checkbox element programmatically
        const checkbox = document.createElement('input');
        checkbox.type = 'checkbox';
        checkbox.id = `collector-${collector.id}`;
        
        // Check if this collector was previously selected
        const isSelected = selectedCollectors.some(c => c.id === collector.id);
        checkbox.checked = isSelected;
        
        checkbox.addEventListener('change', function() {
            toggleCollector(collector.id, collector.displayName, collector);
        });
        
        const span = document.createElement('span');
        span.textContent = `${collector.displayName} (${collector.role === 'Waste Collector' ? 'Palero' : 'Driver'})${collector.barangay ? ` - ${collector.barangay}` : ''}`;
        span.style.marginLeft = '8px';
        span.style.cursor = 'pointer';
        
        // Make the span clickable to toggle checkbox
        span.addEventListener('click', function() {
            checkbox.checked = !checkbox.checked;
            checkbox.dispatchEvent(new Event('change'));
        });
        
        collectorItem.appendChild(checkbox);
        collectorItem.appendChild(span);
        collectorsMenu.appendChild(collectorItem);
    });
}

// Load schedules from Firebase
function loadSchedules() {
    db.collection('truck_schedule').onSnapshot((snapshot) => {
        schedules = [];
        snapshot.forEach((doc) => {
            schedules.push({ id: doc.id, ...doc.data() });
        });
        generateCalendar(); // Refresh calendar with schedules
    });
}

// Generate calendar grid
function generateCalendar() {
    const calendarGrid = document.getElementById('calendar-grid');
    calendarGrid.innerHTML = '';
    
    // Get first day of month and number of days
    const firstDay = new Date(currentYear, currentMonth, 1);
    const lastDay = new Date(currentYear, currentMonth + 1, 0);
    const daysInMonth = lastDay.getDate();
    const startingDayOfWeek = firstDay.getDay();
    
    // Get today's date for comparison
    const today = new Date();
    const isCurrentMonth = today.getFullYear() === currentYear && today.getMonth() === currentMonth;
    const todayDate = today.getDate();
    
    // Create empty cells for days before month starts
    for (let i = 0; i < startingDayOfWeek; i++) {
        const emptyCell = document.createElement('div');
        emptyCell.className = 'cal-cell is-empty';
        calendarGrid.appendChild(emptyCell);
    }
    
    // Create cells for each day of the month
    for (let day = 1; day <= daysInMonth; day++) {
        const cell = document.createElement('div');
        cell.className = 'cal-cell';
        
        // Check if this is today
        if (isCurrentMonth && day === todayDate) {
            cell.classList.add('is-today');
        }
        
        // Add day number
        const dayNum = document.createElement('div');
        dayNum.className = 'cal-daynum';
        dayNum.innerHTML = `<span>${day}</span>`;
        cell.appendChild(dayNum);
        
        // Check for schedules on this day
        const cellDate = `${currentYear}-${String(currentMonth + 1).padStart(2, '0')}-${String(day).padStart(2, '0')}`;
        const daySchedules = schedules.filter(schedule => schedule.date === cellDate);
        
        // Add schedule events (show max 3, then a "more" button)
        const maxVisible = 3;
        daySchedules.slice(0, maxVisible).forEach((schedule, index) => {
            const event = document.createElement('div');
            event.className = 'schedule-event';
            event.textContent = `${schedule.truck} - ${schedule.startTime}`;
            event.title = `${schedule.truck} - ${schedule.driver}`;
            event.style.top = `${8 + (index * 16)}px`; // Stack events vertically
            event.onclick = function(e) {
                e.stopPropagation();
                openScheduleDetails(schedule);
            };
            cell.appendChild(event);
        });
        
        // Add "more" button if there are more than 3 schedules
        if (daySchedules.length > maxVisible) {
            const moreBtn = document.createElement('button');
            moreBtn.className = 'schedule-more-btn';
            moreBtn.textContent = `+${daySchedules.length - maxVisible} more`;
            moreBtn.style.top = `${8 + (maxVisible * 16)}px`;
            moreBtn.onclick = function(e) {
                e.stopPropagation();
                openDaySchedulesModal(cellDate, daySchedules);
            };
            cell.appendChild(moreBtn);
        }
        
        // Add plus button
        const addBtn = document.createElement('button');
        addBtn.className = 'cal-add';
        addBtn.type = 'button';
        addBtn.textContent = '+';
        addBtn.setAttribute('aria-label', 'Create schedule for this day');
        addBtn.onclick = function() {
            const date = new Date(currentYear, currentMonth, day);
            openCreateModalForDate(date);
        };
        cell.appendChild(addBtn);
        
        calendarGrid.appendChild(cell);
    }
    
    // Fill remaining cells to complete the grid
    const totalCells = calendarGrid.children.length;
    const remainingCells = 42 - totalCells; // 6 rows × 7 days = 42
    for (let i = 0; i < remainingCells; i++) {
        const emptyCell = document.createElement('div');
        emptyCell.className = 'cal-cell is-empty';
        calendarGrid.appendChild(emptyCell);
    }
}

// Update month and year display
function updateMonthYearDisplay() {
    document.getElementById('month-display').textContent = monthNames[currentMonth];
    document.getElementById('month-year-display').textContent = `${monthNames[currentMonth]} ${currentYear}`;
    
    // Update active state in dropdown
    const monthItems = document.querySelectorAll('#month-dropdown .um-menu-item');
    monthItems.forEach((item, index) => {
        if (index === currentMonth) {
            item.classList.add('active');
            item.querySelector('.um-check').classList.add('show');
        } else {
            item.classList.remove('active');
            item.querySelector('.um-check').classList.remove('show');
        }
    });
}

// Navigation functions
function previousMonth() {
    currentMonth--;
    if (currentMonth < 0) {
        currentMonth = 11;
        currentYear--;
    }
    generateCalendar();
    updateMonthYearDisplay();
}

function nextMonth() {
    currentMonth++;
    if (currentMonth > 11) {
        currentMonth = 0;
        currentYear++;
    }
    generateCalendar();
    updateMonthYearDisplay();
}

function goToToday() {
    const today = new Date();
    currentMonth = today.getMonth();
    currentYear = today.getFullYear();
    generateCalendar();
    updateMonthYearDisplay();
}

// Month dropdown functions
function toggleMonthDropdown() {
    const dropdown = document.getElementById('month-dropdown');
    const isVisible = dropdown.style.display !== 'none';
    
    if (isVisible) {
        dropdown.style.display = 'none';
    } else {
        dropdown.style.display = 'block';
    }
}

function selectMonth(monthIndex) {
    currentMonth = monthIndex;
    generateCalendar();
    updateMonthYearDisplay();
    document.getElementById('month-dropdown').style.display = 'none';
}

// Close dropdown when clicking outside
document.addEventListener('click', function(event) {
    const monthDropdown = document.querySelector('.month-dd');
    if (!monthDropdown.contains(event.target)) {
        document.getElementById('month-dropdown').style.display = 'none';
    }
});

// Modal functions
function openCreateModal() {
    document.getElementById('create-schedule-modal').style.display = 'flex';
    document.body.style.overflow = 'hidden';
    
    // Initialize map when modal opens
    setTimeout(() => {
        initLocationMap();
    }, 300);
}

function openCreateModalForDate(date) {
    selectedDate = date;
    document.getElementById('schedule-date').value = formatDateForInput(date);
    openCreateModal();
}

function closeCreateModal() {
    document.getElementById('create-schedule-modal').style.display = 'none';
    document.body.style.overflow = '';
    
    // Reset form
    document.getElementById('createScheduleForm').reset();
    document.getElementById('schedule-date').value = formatDateForInput(new Date());
    resetForm();
    closeAllDropdowns();
}

// Reset form and filters
function resetForm() {
    // Reset selections
    selectedDriverId = null;
    selectedDriverData = null;
    selectedCollectors = [];
    selectedLocation = null;
    currentBarangayFilter = null;
    
    // Reset display texts
    document.getElementById('driver-selected-text').textContent = 'Select driver';
    document.getElementById('collectors-selected-text').textContent = 'Select waste collectors';
    document.getElementById('selected-driver').value = '';
    
    // Clear street markers
    if (window.streetMarkers) {
        streetMarkers.forEach(m => m.marker.remove());
        streetMarkers = [];
    }
    
    // Clear any barangay markers
    if (window.barangayMarker) {
        window.barangayMarker.remove();
        window.barangayMarker = null;
    }
    
    // Reset coordinates display
    const coordsDisplay = document.getElementById('coordinates-display');
    if (coordsDisplay) {
        coordsDisplay.innerHTML = 'Click on the map to select a location';
    }
    
    // Clear street checklist
    const checklist = document.getElementById('streets-checklist');
    if (checklist) {
        checklist.innerHTML = '';
    }
    
    // Re-render drivers and collectors without filter
    renderDrivers();
    renderCollectors();
    
    // Uncheck all collector checkboxes
    document.querySelectorAll('[id^="collector-"]').forEach(checkbox => {
        checkbox.checked = false;
    });
}

// Close modal when clicking outside
document.addEventListener('click', function(event) {
    const modal = document.getElementById('create-schedule-modal');
    if (event.target === modal) {
        closeCreateModal();
    }
});

// Close modal with Escape key
document.addEventListener('keydown', function(event) {
    if (event.key === 'Escape') {
        const modal = document.getElementById('create-schedule-modal');
        if (modal.style.display === 'flex') {
            closeCreateModal();
        }
    }
});

// Setup dropdown functionality
function setupDropdowns() {
    // Driver dropdown
    document.getElementById('driver-dropdown-btn').addEventListener('click', function() {
        toggleDropdown('driver-dropdown-menu', this);
    });
    
    // Collectors dropdown
    document.getElementById('collectors-dropdown-btn').addEventListener('click', function() {
        toggleDropdown('collectors-dropdown-menu', this);
    });
    
    // Close dropdowns when clicking outside
    document.addEventListener('click', function(event) {
        if (!event.target.closest('.dropdown-container')) {
            closeAllDropdowns();
        }
    });
}

function toggleDropdown(menuId, button) {
    const menu = document.getElementById(menuId);
    const isOpen = menu.classList.contains('show');
    
    closeAllDropdowns();
    
    if (!isOpen) {
        menu.classList.add('show');
        button.classList.add('active');
    }
}

function closeAllDropdowns() {
    document.querySelectorAll('.dropdown-menu').forEach(menu => {
        menu.classList.remove('show');
    });
    document.querySelectorAll('.dropdown-button').forEach(btn => {
        btn.classList.remove('active');
    });
}

function selectDriver(driverId, driverName, driverData) {
    selectedDriverId = driverId;
    selectedDriverData = driverData;
    document.getElementById('driver-selected-text').textContent = driverName;
    document.getElementById('selected-driver').value = driverId;
    closeAllDropdowns();
    
    // If driver has a barangay, apply filter and pin location
    if (driverData && driverData.barangay) {
        console.log('Driver selected with barangay:', driverData.barangay);
        
        // Set the barangay filter
        currentBarangayFilter = driverData.barangay;
        
        // Re-render drivers and collectors with the new filter
        renderDrivers();
        renderCollectors();
        
        // Clear previously selected collectors if they're not from the same barangay
        selectedCollectors = selectedCollectors.filter(c => c.barangay === driverData.barangay);
        updateCollectorsDisplay();
        
        // Pin the barangay on the map (but don't replace street checklist)
        pinDriverBarangayOnMap(driverData.barangay);
        
        // Show notification
        if (window.showInfo) {
            window.showInfo(`Filtered to ${driverData.barangay} barangay`);
        }
    }
}

function toggleCollector(collectorId, collectorName, collectorData) {
    const checkbox = document.getElementById(`collector-${collectorId}`);
    
    if (checkbox.checked) {
        if (selectedCollectors.length >= 3) {
            checkbox.checked = false;
            showWarning('You can only select up to 3 waste collectors.');
            return;
        }
        selectedCollectors.push({ 
            id: collectorId, 
            name: collectorName,
            barangay: collectorData ? collectorData.barangay : null 
        });
    } else {
        selectedCollectors = selectedCollectors.filter(c => c.id !== collectorId);
    }
    
    updateCollectorsDisplay();
}

function updateCollectorsDisplay() {
    const text = selectedCollectors.length > 0 
        ? `${selectedCollectors.length} collector(s) selected`
        : 'Select waste collectors';
    document.getElementById('collectors-selected-text').textContent = text;
}

// Initialize map for location selection
function initLocationMap() {
    console.log('Initializing location map...');
    
    // Make sure the map container exists
    const mapContainer = document.getElementById('location-map');
    if (!mapContainer) {
        console.error('Map container not found');
        return;
    }
    
    // Clean up existing map if any
    if (scheduleMap) {
        try {
            scheduleMap.remove();
        } catch (e) {
            console.log('Error removing existing map:', e);
        }
        scheduleMap = null;
    }
    
    // Make sure container is visible and has dimensions
    mapContainer.style.display = 'block';
    mapContainer.style.visibility = 'visible';
    
    // Ensure parent container is visible
    const parentContainer = mapContainer.closest('.location-map-container');
    if (parentContainer) {
        parentContainer.style.display = 'flex';
    }
    
    // Clean up existing map
    if (scheduleMap) {
        try {
            scheduleMap.remove();
        } catch (e) {
            console.log('Error removing existing map:', e);
        }
        scheduleMap = null;
    }
    
    if (window.locationMarker) {
        try {
            window.locationMarker.remove();
        } catch (e) {
            console.log('Error removing marker:', e);
        }
        window.locationMarker = null;
    }
    
    // Wait for container to be visible and DOM to be ready
    const initMap = () => {
        const container = document.getElementById('location-map');
        if (!container) {
            console.error('Map container not found');
            setTimeout(initMap, 100);
            return;
        }
        
        console.log('Container found, initializing...');
        
        try {
            // Valenzuela City center coordinates (using Poblacion as center)
            const center = [120.9455, 14.7077]; // Note: MapLibre uses [lng, lat]
            
            // Philippines bounds [southwest, northeast]
            const philippinesBounds = [
                [116.0, 4.5],  // Southwest coordinates
                [127.0, 21.0]  // Northeast coordinates
            ];
            
            // Ensure container is visible before creating map
            const container = document.getElementById('location-map');
            if (!container) {
                console.error('Map container not found');
                return;
            }
            
            // Make sure container has dimensions
            container.style.display = 'block';
            container.style.visibility = 'visible';
            
            scheduleMap = new maplibregl.Map({
                container: container,
                style: {
                    "version": 8,
                    "sources": {
                        "google-street": {
                            "type": "raster",
                            "tiles": [
                                "https://mt0.google.com/vt/lyrs=m&hl=en&x={x}&y={y}&z={z}"
                            ],
                            "tileSize": 256
                        }
                    },
                    "layers": [
                        {
                            "id": "google-street-layer",
                            "type": "raster",
                            "source": "google-street",
                            "minzoom": 0,
                            "maxzoom": 22
                        }
                    ]
                },
                center: center,
                zoom: 12,
                minZoom: 5,
                maxZoom: 18,
                maxBounds: philippinesBounds,
                pitch: 0,
                bearing: 0,
                antialias: true,
                attributionControl: false
            });
            
            // Force a resize after a small delay
            setTimeout(() => {
                if (scheduleMap) {
                    scheduleMap.resize();
                }
            }, 100);

            // Add navigation control
            scheduleMap.addControl(new maplibregl.NavigationControl(), 'top-right');

            // Enable right-click drag for 3D rotation
            scheduleMap.dragRotate.enable();
            scheduleMap.touchZoomRotate.enableRotation();

            // Add map load event
            scheduleMap.on('load', () => {
                console.log('Schedule map loaded successfully');
                
                // Force resize and recenter to ensure proper display
                setTimeout(() => {
                    if (scheduleMap) {
                        scheduleMap.resize();
                        scheduleMap.jumpTo({
                            center: [120.9455, 14.7077], // Valenzuela center (Poblacion)
                            zoom: 12
                        });
                    }
                }, 100);
                
                // Add a click handler to the document to close dropdowns when clicking outside
                document.addEventListener('click', function mapClickHandler(e) {
                    if (!e.target.closest('.dropdown-container') && !e.target.closest('.maplibregl-ctrl')) {
                        closeAllDropdowns();
                    }
                });
            });
            
            // Remove click handler for location selection - now using street checklist only
            
            // Handle map errors
            scheduleMap.on('error', function(e) {
                console.error('Map error:', e);
            });
            
        } catch (error) {
            console.error('Error creating map:', error);
        }
    };
    
    // Initialize map immediately
    initMap();
    
    // Add resize observer to handle container size changes
    const resizeObserver = new ResizeObserver(() => {
        if (scheduleMap) {
            scheduleMap.resize();
        }
    });
    
    // Observe both the map container and its parent
    if (mapContainer) {
        resizeObserver.observe(mapContainer);
        const parent = mapContainer.parentElement;
        if (parent) {
            resizeObserver.observe(parent);
        }
    }
}


// Search streets function
function searchStreets() {
    const query = document.getElementById('street-search').value;
    if (!query.trim()) {
        // Show all streets if empty search
        displayStreetsChecklist(getStreetsArray());
        return;
    }
    
    const filteredStreets = getStreetsArray().filter(streetObj => 
        streetObj.display.toLowerCase().includes(query.toLowerCase())
    );
    
    displayStreetsChecklist(filteredStreets);
}

function getAllValenzuelaStreets() {
    // Barangays with coordinates from user's data
    const barangaysWithCoords = [
        { name: "Bagbaguin", lat: 14.7161552, lng: 120.9964147 },
        { name: "Balangkas", lat: 14.7138, lng: 120.9403 },
        { name: "Bignay", lat: 14.7456, lng: 120.9962 },
        { name: "Bisig", lat: 14.7166705, lng: 120.9370332 },
        { name: "Canumay East", lat: 14.7165, lng: 120.9919 },
        { name: "Canumay West", lat: 14.7133062, lng: 120.9750933 },
        { name: "Coloong", lat: 14.7259, lng: 120.946 },
        { name: "Dalandanan", lat: 14.7026, lng: 120.9633 },
        { name: "Gen. T. de Leon", lat: 14.6864941, lng: 120.9924079 },
        { name: "Isla", lat: 14.7035, lng: 120.9525 },
        { name: "Karuhatan", lat: 14.6869, lng: 120.9733 },
        { name: "Lawang Bato", lat: 14.7265258, lng: 120.9841003 },
        { name: "Pasolo", lat: 14.708, lng: 120.9526 },
        { name: "Poblacion", lat: 14.7081343, lng: 120.9412695 },
        { name: "Punturin", lat: 14.7353, lng: 120.9962 },
        { name: "Rincon", lat: 14.699, lng: 120.9581 },
        { name: "Tagalag", lat: 14.7271, lng: 120.9374 },
        { name: "Ugong", lat: 14.6965, lng: 121.0134 },
        { name: "Veinte Reales", lat: 14.7147, lng: 120.969 },
        { name: "Wawang Pulo", lat: 14.7336, lng: 120.9288 }
    ];
    
    // Additional barangays with specific coordinates
    const extraBarangaysWithCoords = [
        { name: "Arkong Bato", lat: 14.698169, lng: 120.9460715 },
        { name: "Lingunan", lat: 14.7156733, lng: 120.9673923 },
        { name: "Mabolo", lat: 14.7118669, lng: 120.9462916 },
        { name: "Malanday", lat: 14.7214241, lng: 120.937715 },
        { name: "Malinta", lat: 14.6881948, lng: 120.9547038 },
        { name: "Mapulang Lupa", lat: 14.7025595, lng: 120.9980711 },
        { name: "Marulas", lat: 14.6760978, lng: 120.9452279 },
        { name: "Maysan", lat: 14.6986493, lng: 120.9667263 },
        { name: "Palasan", lat: 14.7029132, lng: 120.9376807 },
        { name: "Parada", lat: 14.6960116, lng: 120.9781539 },
        { name: "Paso de Blas", lat: 14.7049578, lng: 120.9823692 },
        { name: "Polo", lat: 14.7100422, lng: 120.9398335 },
        { name: "Pariancillo Villa", lat: 14.708006, lng: 120.9415701 }
    ];
    
    const result = {};
    
    // Add barangays with coordinates
    barangaysWithCoords.forEach(barangay => {
        result[barangay.name] = {
            coordinates: [barangay.lng, barangay.lat],
            streets: [barangay.name + " Area"] // Just use barangay name as area
        };
    });
    
    // Add extra barangays with specific coordinates
    extraBarangaysWithCoords.forEach(barangay => {
        result[barangay.name] = {
            coordinates: [barangay.lng, barangay.lat],
            streets: [barangay.name + " Area"]
        };
    });
    
    return result;
}

function getStreetsArray() {
    const streetsData = getAllValenzuelaStreets();
    const allStreets = [];
    
    // Flatten the structure to get all barangays with coordinates
    Object.keys(streetsData).forEach(barangayName => {
        const barangayData = streetsData[barangayName];
        barangayData.streets.forEach(street => {
            allStreets.push({
                display: `${barangayName} Area`,
                street: street,
                barangay: barangayName,
                coordinates: barangayData.coordinates
            });
        });
    });
    
    return allStreets.sort((a, b) => a.display.localeCompare(b.display));
}

function loadNearbyStreets(lat, lng) {
    // Get all streets and find the nearest ones based on coordinates
    const allStreets = getStreetsArray();
    let nearbyStreets = [];
    
    // Calculate distance from clicked point to each barangay
    const calculateDistance = (lat1, lng1, lat2, lng2) => {
        const R = 6371; // Earth's radius in km
        const dLat = (lat2 - lat1) * Math.PI / 180;
        const dLng = (lng2 - lng1) * Math.PI / 180;
        const a = Math.sin(dLat/2) * Math.sin(dLat/2) +
                Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
                Math.sin(dLng/2) * Math.sin(dLng/2);
        const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
        return R * c;
    };
    
    // Find streets within 3km radius, sorted by distance
    const streetsWithDistance = allStreets.map(street => {
        const distance = calculateDistance(lat, lng, street.coordinates[1], street.coordinates[0]);
        return { ...street, distance };
    }).filter(street => street.distance <= 3) // Within 3km
      .sort((a, b) => a.distance - b.distance)
      .slice(0, 15); // Show max 15 nearest streets
    
    // If no streets found within 3km, show all streets
    if (streetsWithDistance.length === 0) {
        nearbyStreets = allStreets.slice(0, 10); // Show first 10 streets
    } else {
        nearbyStreets = streetsWithDistance;
    }
    
    displayStreetsChecklist(nearbyStreets);
}

// Global variable to store map markers
let streetMarkers = [];
let barangayMarker = null;

// Function to pin barangay on map (preserves existing street checklist)
function pinDriverBarangayOnMap(barangayName) {
    if (!scheduleMap) return;
    
    // Get barangay coordinates
    const barangayData = getBarangayCoordinates(barangayName);
    if (!barangayData) {
        console.log('No coordinates found for barangay:', barangayName);
        return;
    }
    
    // Remove existing barangay marker if any
    if (window.barangayMarker) {
        window.barangayMarker.remove();
        window.barangayMarker = null;
    }
    
    // Add new marker for barangay
    window.barangayMarker = new maplibregl.Marker({
        color: '#3b82f6' // Blue color for barangay center
    })
        .setLngLat(barangayData.coordinates)
        .addTo(scheduleMap);
    
    // Center map on barangay only if no streets are currently selected
    if (streetMarkers.length === 0) {
        scheduleMap.flyTo({
            center: barangayData.coordinates,
            zoom: 13,
            duration: 1000
        });
    }
    
    // Don't touch the street checklist - preserve user's selections
}

// Function to pin barangay on map (for initial street loading)
function pinBarangayOnMap(barangayName) {
    if (!scheduleMap) return;
    
    // Get barangay coordinates
    const barangayData = getBarangayCoordinates(barangayName);
    if (!barangayData) {
        console.log('No coordinates found for barangay:', barangayName);
        return;
    }
    
    // Remove existing barangay marker if any
    if (window.barangayMarker) {
        window.barangayMarker.remove();
        window.barangayMarker = null;
    }
    
    // Add new marker for barangay
    window.barangayMarker = new maplibregl.Marker({
        color: '#3b82f6' // Blue color for barangay center
    })
        .setLngLat(barangayData.coordinates)
        .addTo(scheduleMap);
    
    // Center map on barangay
    scheduleMap.flyTo({
        center: barangayData.coordinates,
        zoom: 13,
        duration: 1000
    });
    
    // Load streets for this barangay in the checklist (only for initial loading)
    const streetsData = getAllValenzuelaStreets();
    if (streetsData[barangayName]) {
        const barangayStreets = streetsData[barangayName].streets.map(street => ({
            display: `${barangayName} Area`,
            street: street,
            barangay: barangayName,
            coordinates: barangayData.coordinates
        }));
        displayStreetsChecklist(barangayStreets);
    }
}

// Get barangay coordinates
function getBarangayCoordinates(barangayName) {
    const streetsData = getAllValenzuelaStreets();
    if (streetsData[barangayName]) {
        return {
            name: barangayName,
            coordinates: streetsData[barangayName].coordinates
        };
    }
    return null;
}

// Extract barangay name from street display
function extractBarangayFromStreet(streetDisplay) {
    // Street display format is usually "BarangayName Area"
    if (streetDisplay && streetDisplay.includes(' Area')) {
        return streetDisplay.replace(' Area', '');
    }
    
    // Fallback: check if the street display matches any barangay name
    const streetsData = getAllValenzuelaStreets();
    for (const barangayName in streetsData) {
        if (streetDisplay.includes(barangayName)) {
            return barangayName;
        }
    }
    
    return null;
}

function displayStreetsChecklist(streets) {
    const checklist = document.getElementById('streets-checklist');
    if (!checklist) {
        console.error('Streets checklist container not found');
        return;
    }
    
    checklist.innerHTML = '';
    
    if (streets.length === 0) {
        checklist.innerHTML = '<div class="street-item" style="color: #6b7280; font-style: italic;">No streets found</div>';
        return;
    }
    
    streets.forEach((streetObj, index) => {
        const streetItem = document.createElement('div');
        streetItem.className = 'street-item';
        const streetId = `street-${index}-${streetObj.display.replace(/\s+/g, '-').replace(/[^a-zA-Z0-9-]/g, '')}`;
        
        const checkbox = document.createElement('input');
        checkbox.type = 'checkbox';
        checkbox.id = streetId;
        checkbox.name = 'selected-streets';
        checkbox.value = streetObj.display;
        checkbox.addEventListener('change', function() {
            handleStreetSelection(streetObj, this.checked);
        });
        
        const label = document.createElement('label');
        label.htmlFor = streetId;
        label.style.cursor = 'pointer';
        label.style.flex = '1';
        label.textContent = streetObj.display;
        
        streetItem.appendChild(checkbox);
        streetItem.appendChild(label);
        checklist.appendChild(streetItem);
    });
    
    console.log(`Displayed ${streets.length} streets in checklist`);
}

function handleStreetSelection(streetObj, isChecked) {
    if (!scheduleMap) return;
    
    if (isChecked) {
        // Add marker to map
        const marker = new maplibregl.Marker({
            color: '#22c55e' // Green color for selected streets
        })
            .setLngLat(streetObj.coordinates)
            .addTo(scheduleMap);
        
        // Store marker with street info
        streetMarkers.push({
            marker: marker,
            streetData: streetObj
        });
        
        // Update coordinates display
        updateCoordinatesDisplay();
        
        // Apply barangay filter based on selected street
        const streetBarangay = streetObj.barangay || extractBarangayFromStreet(streetObj.display);
        
        if (streetBarangay) {
            currentBarangayFilter = streetBarangay;
            
            // Clear selected driver if it's from a different barangay
            if (selectedDriverData && selectedDriverData.barangay && selectedDriverData.barangay !== streetBarangay) {
                selectedDriverId = null;
                selectedDriverData = null;
                document.getElementById('driver-selected-text').textContent = 'Select driver';
                document.getElementById('selected-driver').value = '';
            }
            
            // Clear selected collectors from different barangays
            selectedCollectors = selectedCollectors.filter(c => c.barangay === streetBarangay);
            updateCollectorsDisplay();
            
            // Re-render drivers and collectors with the new filter
            renderDrivers();
            renderCollectors();
            
            // Show notification
            showInfo(`Filtered to ${streetBarangay} barangay`);
        }
        
        // Center map on the selected area if it's the first selection
        if (streetMarkers.length === 1) {
            scheduleMap.flyTo({
                center: streetObj.coordinates,
                zoom: 14,
                duration: 1000
            });
        }
    } else {
        // Remove marker from map
        const markerIndex = streetMarkers.findIndex(m => 
            m.streetData.display === streetObj.display
        );
        
        if (markerIndex !== -1) {
            streetMarkers[markerIndex].marker.remove();
            streetMarkers.splice(markerIndex, 1);
        }
        
        // Update coordinates display
        updateCoordinatesDisplay();
        
        // If no more streets are selected, clear the barangay filter
        if (streetMarkers.length === 0) {
            currentBarangayFilter = null;
            renderDrivers();
            renderCollectors();
            
            // Show notification
            showInfo('Filter cleared - showing all personnel');
        }
    }
}

function updateCoordinatesDisplay() {
    const coordsDisplay = document.getElementById('coordinates-display');
    if (!coordsDisplay) return;
    
    if (streetMarkers.length === 0) {
        coordsDisplay.innerHTML = 'Select streets from the checklist to pin locations on the map';
        selectedLocation = null;
    } else if (streetMarkers.length === 1) {
        const coords = streetMarkers[0].streetData.coordinates;
        coordsDisplay.innerHTML = `
            <strong>Selected Location:</strong><br>
            ${streetMarkers[0].streetData.barangay}, ${streetMarkers[0].streetData.district}<br>
            Latitude: ${coords[1].toFixed(6)}, Longitude: ${coords[0].toFixed(6)}
        `;
        selectedLocation = {
            lng: coords[0],
            lat: coords[1]
        };
    } else {
        // Calculate center point of all selected streets
        const avgLng = streetMarkers.reduce((sum, m) => sum + m.streetData.coordinates[0], 0) / streetMarkers.length;
        const avgLat = streetMarkers.reduce((sum, m) => sum + m.streetData.coordinates[1], 0) / streetMarkers.length;
        
        coordsDisplay.innerHTML = `
            <strong>Selected Locations:</strong><br>
            ${streetMarkers.length} streets selected<br>
            Center: ${avgLat.toFixed(6)}, ${avgLng.toFixed(6)}
        `;
        selectedLocation = {
            lng: avgLng,
            lat: avgLat
        };
    }
}

// Handle form submission
function handleCreateSchedule(event) {
    event.preventDefault();
    
    // Get form values
    const truck = document.getElementById('truck-select').value;
    const date = document.getElementById('schedule-date').value;
    const startTime = document.getElementById('start-time').value;
    const endTime = document.getElementById('end-time').value;
    
    // Validate required fields
    if (!selectedDriverId) {
        showError('Please select a driver.');
        return;
    }
    
    if (selectedCollectors.length !== 3) {
        showError('Please select exactly 3 waste collectors.');
        return;
    }
    
    // Get selected streets
    const selectedStreets = [];
    document.querySelectorAll('input[name="selected-streets"]:checked').forEach(checkbox => {
        selectedStreets.push(checkbox.value);
    });
    
    if (selectedStreets.length === 0) {
        showError('Please select at least one street from the checklist.');
        return;
    }
    
    // selectedLocation is now automatically set when streets are selected
    if (!selectedLocation) {
        showError('Please select at least one street to set the location.');
        return;
    }
    
    // Validate time
    if (endTime <= startTime) {
        showError('End time must be later than start time.');
        return;
    }
    
    // Create schedule object
    const schedule = {
        truck,
        date,
        startTime,
        endTime,
        driverId: selectedDriverId,
        driver: document.getElementById('driver-selected-text').textContent,
        collectors: selectedCollectors,
        location: selectedLocation,
        streets: selectedStreets,
        status: 'scheduled',
        createdAt: firebase.firestore.FieldValue.serverTimestamp()
    };
    
    // Save to Firestore
    db.collection('truck_schedule').add(schedule)
        .then((docRef) => {
            console.log('Schedule created with ID:', docRef.id);
            showSuccess('Schedule created successfully!');
            closeCreateModal();
            resetForm();
        })
        .catch((error) => {
            console.error('Error creating schedule:', error);
            showError('Error creating schedule. Please try again.');
        });
}

// Setup search input event listener
function setupSearchListener() {
    // Add event listener when DOM is ready, but delay to ensure modal elements exist
    document.addEventListener('click', function() {
        const searchInput = document.getElementById('street-search');
        if (searchInput && !searchInput.hasAttribute('data-listener-added')) {
            searchInput.setAttribute('data-listener-added', 'true');
            
            // Real-time search as user types
            searchInput.addEventListener('input', function() {
                searchStreets();
            });
            
            // Also trigger search on Enter key
            searchInput.addEventListener('keypress', function(e) {
                if (e.key === 'Enter') {
                    e.preventDefault();
                    searchStreets();
                }
            });
        }
    });
}

function openCreateModal() {
    const modal = document.getElementById('create-schedule-modal');
    if (!modal) return;
    
    // Show modal
    modal.style.display = 'flex';
    document.body.style.overflow = 'hidden';
    
    // Reset form
    document.getElementById('createScheduleForm')?.reset();
    selectedDriverId = null;
    selectedCollectors = [];
    selectedLocation = null;
    
    // Update UI
    document.getElementById('driver-selected-text').textContent = 'Select driver';
    document.getElementById('collectors-selected-text').textContent = 'Select waste collectors';
    document.getElementById('coordinates-display').innerHTML = 'Select streets from the checklist to pin locations on the map';
    
    // Show all streets immediately
    displayStreetsChecklist(getStreetsArray());
    
    // Initialize map after modal animation completes
    setTimeout(() => {
        // Ensure map container is visible
        const mapContainer = document.getElementById('location-map');
        if (mapContainer) {
            mapContainer.style.display = 'block';
            mapContainer.style.visibility = 'visible';
        }
        
        // Initialize map
        initLocationMap();
        
        // Force resize after a small delay
        setTimeout(() => {
            if (scheduleMap) {
                scheduleMap.resize();
            }
        }, 100);
    }, 300);
}

function resetForm() {
    selectedDriverId = null;
    selectedCollectors = [];
    selectedLocation = null;
    
    document.getElementById('driver-selected-text').textContent = 'Select driver';
    document.getElementById('collectors-selected-text').textContent = 'Select waste collectors';
    document.getElementById('coordinates-display').innerHTML = 'Select streets from the checklist to pin locations on the map';
    document.getElementById('streets-checklist').innerHTML = '';
    
    const searchInput = document.getElementById('street-search');
    if (searchInput) {
        searchInput.value = '';
    }
    
    // Clear all street markers
    streetMarkers.forEach(markerObj => {
        markerObj.marker.remove();
    });
    streetMarkers = [];
    
    // Clear old location marker if it exists
    if (window.locationMarker) {
        window.locationMarker.remove();
        window.locationMarker = null;
    }
}

// Clean up schedules older than 7 days
async function cleanupOldSchedules() {
    try {
        const sevenDaysAgo = new Date();
        sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);
        
        console.log('Checking for schedules older than:', sevenDaysAgo.toDateString());
        
        const schedulesRef = firebase.firestore().collection('truck_schedule');
        const oldSchedulesQuery = schedulesRef.where('date', '<', sevenDaysAgo.toISOString().split('T')[0]);
        
        const querySnapshot = await oldSchedulesQuery.get();
        
        if (!querySnapshot.empty) {
            const batch = firebase.firestore().batch();
            let deleteCount = 0;
            
            querySnapshot.forEach((doc) => {
                batch.delete(doc.ref);
                deleteCount++;
                console.log('Marking for deletion:', doc.id, 'Date:', doc.data().date);
            });
            
            await batch.commit();
            console.log(`✅ Successfully deleted ${deleteCount} old schedule(s)`);
            
            // Show notification to admin
            if (deleteCount > 0 && typeof showInfo === 'function') {
                showInfo(`Cleaned up ${deleteCount} old schedule(s) from last week`);
            }
        } else {
            console.log('No old schedules found to delete');
        }
        
    } catch (error) {
        console.error('Error cleaning up old schedules:', error);
    }
}

// Format date for input field
function formatDateForInput(date) {
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    return `${year}-${month}-${day}`;
}

// Schedule details modal functions
function openScheduleDetails(schedule) {
    // Populate modal with schedule data
    document.getElementById('detail-truck').textContent = schedule.truck || 'N/A';
    document.getElementById('detail-date').textContent = formatDateDisplay(schedule.date);
    document.getElementById('detail-time').textContent = `${schedule.startTime} - ${schedule.endTime}`;
    document.getElementById('detail-driver').textContent = schedule.driver || 'N/A';
    
    // Display collectors
    const collectorsContainer = document.getElementById('detail-collectors');
    if (schedule.collectors && schedule.collectors.length > 0) {
        collectorsContainer.innerHTML = schedule.collectors.map(collector => 
            `<div style="margin-bottom: 4px;">• ${collector.name}</div>`
        ).join('');
    } else {
        collectorsContainer.textContent = 'No collectors assigned';
    }
    
    // Display location
    const locationText = schedule.location ? 
        `Lat: ${schedule.location.lat.toFixed(6)}, Lng: ${schedule.location.lng.toFixed(6)}` : 
        'No location selected';
    document.getElementById('detail-location').textContent = locationText;
    
    // Display streets
    const streetsContainer = document.getElementById('detail-streets');
    if (schedule.streets && schedule.streets.length > 0) {
        streetsContainer.innerHTML = schedule.streets.map(street => 
            `<div style="margin-bottom: 4px;">• ${street}</div>`
        ).join('');
    } else {
        streetsContainer.textContent = 'No streets assigned';
    }
    
    // Display status with appropriate styling
    const statusElement = document.getElementById('detail-status');
    const status = schedule.status || 'scheduled';
    statusElement.textContent = status;
    statusElement.className = `detail-value status-badge ${status}`;
    
    // Store schedule ID for potential editing
    window.currentScheduleId = schedule.id;
    
    // Show modal
    document.getElementById('schedule-details-modal').style.display = 'flex';
    document.body.style.overflow = 'hidden';
}

function closeDetailsModal() {
    document.getElementById('schedule-details-modal').style.display = 'none';
    document.body.style.overflow = '';
    window.currentScheduleId = null;
}

function editSchedule() {
    // TODO: Implement edit functionality
    showInfo('Edit functionality will be implemented in the future.');
    closeDetailsModal();
}

function formatDateDisplay(dateString) {
    const date = new Date(dateString + 'T00:00:00');
    return date.toLocaleDateString('en-US', { 
        weekday: 'long', 
        year: 'numeric', 
        month: 'long', 
        day: 'numeric' 
    });
}

// Day schedules modal functions
let selectedDayDate = null;

function openDaySchedulesModal(dateString, daySchedules) {
    selectedDayDate = dateString;
    const modal = document.getElementById('day-schedules-modal');
    const dateDisplay = document.getElementById('selected-day-date');
    const schedulesList = document.getElementById('day-schedules-list');
    
    // Format and display the date
    dateDisplay.textContent = formatDateDisplay(dateString);
    
    // Clear previous content
    schedulesList.innerHTML = '';
    
    // Populate schedules
    daySchedules.forEach(schedule => {
        const scheduleItem = document.createElement('div');
        scheduleItem.className = 'day-schedule-item';
        scheduleItem.onclick = () => {
            closeDaySchedulesModal();
            openScheduleDetails(schedule);
        };
        
        scheduleItem.innerHTML = `
            <div class="day-schedule-header">
                <div class="day-schedule-truck">${schedule.truck}</div>
                <div class="day-schedule-time">${schedule.startTime} - ${schedule.endTime}</div>
            </div>
            <div class="day-schedule-details">
                <div><strong>Driver:</strong> ${schedule.driver}</div>
                <div><strong>Collectors:</strong> ${schedule.collectors ? schedule.collectors.map(c => c.name).join(', ') : 'N/A'}</div>
                <div><strong>Streets:</strong> ${schedule.streets ? schedule.streets.slice(0, 2).join(', ') + (schedule.streets.length > 2 ? ` +${schedule.streets.length - 2} more` : '') : 'N/A'}</div>
            </div>
        `;
        
        schedulesList.appendChild(scheduleItem);
    });
    
    // Show modal
    modal.style.display = 'flex';
    document.body.style.overflow = 'hidden';
}

function closeDaySchedulesModal() {
    const modal = document.getElementById('day-schedules-modal');
    modal.style.display = 'none';
    document.body.style.overflow = '';
    selectedDayDate = null;
}

function createNewScheduleForDay() {
    if (selectedDayDate) {
        const date = new Date(selectedDayDate + 'T00:00:00');
        closeDaySchedulesModal();
        openCreateModalForDate(date);
    }
}

// Close details modal when clicking outside
document.addEventListener('click', function(event) {
    const modal = document.getElementById('schedule-details-modal');
    if (event.target === modal) {
        closeDetailsModal();
    }
});

// Close details modal with Escape key
document.addEventListener('keydown', function(event) {
    if (event.key === 'Escape') {
        const modal = document.getElementById('schedule-details-modal');
        if (modal && modal.style.display === 'flex') {
            closeDetailsModal();
        }
    }
});
