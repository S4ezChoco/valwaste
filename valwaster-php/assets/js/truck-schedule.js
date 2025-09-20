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
    loadApprovedRequests();
    
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

// Render all drivers without filtering
function renderDrivers() {
    const driverMenu = document.getElementById('driver-dropdown-menu');
    driverMenu.innerHTML = '';
    
    if (allDrivers.length === 0) {
        const emptyItem = document.createElement('div');
        emptyItem.className = 'dropdown-item';
        emptyItem.style.color = '#6b7280';
        emptyItem.style.fontStyle = 'italic';
        emptyItem.innerHTML = 'No drivers available';
        driverMenu.appendChild(emptyItem);
        return;
    }
    
    allDrivers.forEach((driver) => {
        const driverItem = document.createElement('div');
        driverItem.className = 'dropdown-item';
        driverItem.innerHTML = `
            <span>${driver.displayName}${driver.barangay ? ` (${driver.barangay})` : ''}</span>
        `;
        driverItem.onclick = () => selectDriver(driver.id, driver.displayName, driver);
        driverMenu.appendChild(driverItem);
    });
}

// Load waste collectors - Static Filipino names (no database connection)
function loadWasteCollectors() {
    // Static array of 40 Filipino male names for waste collectors
    const filipinoCollectors = [
        'Juan Santos', 'Marco Garcia', 'Jose Reyes', 'Angelo Cruz', 'Pedro Gonzales',
        'Carlos Rivera', 'Antonio Lopez', 'Roberto Martinez', 'Miguel Torres', 'Luis Fernandez',
        'Carlos Morales', 'Emilio Castillo', 'Ramon Dela Cruz', 'Joseph Ramos', 'Eduardo Villanueva',
        'Rodrigo Aquino', 'Francisco Mendoza', 'Emmanuel Bautista', 'Ricardo Hernandez', 'Paolo Santos',
        'Alfredo Pascual', 'Gabriel Aguilar', 'Renato Silva', 'Cesar Valdez', 'Armando Jimenez',
        'Teodoro Flores', 'Danilo Castro', 'Nestor Perez', 'Roberto Padilla', 'Alberto Cruz',
        'Ernesto Lim', 'Nelson Tan', 'Leopoldo Mercado', 'Marcelino Santiago', 'Gerardo Navarro',
        'Domingo Ochoa', 'Florencio Diaz', 'Patricio Velasco', 'Rogelio Estrada', 'Christian Gutierrez'
    ];
    
    // Convert to collector objects - assign random barangays so they work with filtering
    const barangays = ['Bagbaguin', 'Balangkas', 'Bignay', 'Canumay East', 'Canumay West', 'Coloong', 'Dalandanan', 'Gen. T. de Leon', 'Hen. T. de Leon', 'Isla', 'Karuhatan', 'Lawang Bato', 'Lingunan', 'Mabolo', 'Malanday', 'Malinta', 'Mapulang Lupa', 'Marulas', 'Maysan', 'Palasan', 'Parada', 'Paso de Blas', 'Pasolo', 'Poblacion', 'Pulo', 'Rincon', 'Tagalag', 'Ugong', 'Viente Reales', 'Wawang Pulo'];
    
    allCollectors = filipinoCollectors.map((name, index) => ({
        id: `collector_${index + 1}`,
        displayName: name,
        role: 'Waste Collector',
        barangay: barangays[index % barangays.length] // Cycle through barangays
    }));
    
    // Initial render shows all collectors
    renderCollectors();
}

// Render collectors - Static list without barangay filtering
function renderCollectors() {
    const collectorsMenu = document.getElementById('collectors-dropdown-menu');
    collectorsMenu.innerHTML = '';
    
    // Show all static collectors (no filtering by barangay)
    const collectorsToShow = allCollectors;
    
    if (collectorsToShow.length === 0) {
        const emptyItem = document.createElement('div');
        emptyItem.className = 'dropdown-item';
        emptyItem.style.color = '#6b7280';
        emptyItem.style.fontStyle = 'italic';
        emptyItem.innerHTML = 'No paleros available';
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
        span.textContent = collector.displayName;
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
        addBtn.addEventListener('click', function(e) {
            e.preventDefault();
            e.stopPropagation();
            console.log('Plus button clicked for day:', day);
            const date = new Date(currentYear, currentMonth, day);
            console.log('Created date object:', date);
            openCreateModalForDate(date);
        });
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
    
    // Load approved requests immediately when modal opens
    loadApprovedRequests();
    
    // Initialize map when modal opens
    setTimeout(() => {
        initLocationMap();
    }, 300);
}

function openCreateModalForDate(date) {
    console.log('=== openCreateModalForDate called ===');
    console.log('Opening modal for date:', date);
    selectedDate = date;
    const formattedDate = formatDateForInput(date);
    console.log('Formatted date:', formattedDate);
    
    // Open modal first
    openCreateModal();
    
    // Then set the date after a small delay to ensure modal is loaded
    setTimeout(() => {
        const dateInput = document.getElementById('schedule-date');
        if (dateInput) {
            dateInput.value = formattedDate;
            console.log('Date input set to:', dateInput.value);
        } else {
            console.error('Date input element not found');
        }
    }, 100);
}

function closeCreateModal() {
    document.getElementById('create-schedule-modal').style.display = 'none';
    document.body.style.overflow = '';
    
    // Reset form
    document.getElementById('createScheduleForm').reset();
    // Only reset to today's date if no specific date was selected
    if (!selectedDate) {
        document.getElementById('schedule-date').value = formatDateForInput(new Date());
    }
    resetForm();
    closeAllDropdowns();
    
    // Clear selected date
    selectedDate = null;
}

// Reset form and filters
function resetForm() {
    // Reset selections
    selectedDriverId = null;
    selectedDriverData = null;
    selectedCollectors = [];
    selectedLocation = null;
    
    // Reset display texts
    document.getElementById('driver-selected-text').textContent = 'Select driver';
    document.getElementById('collectors-selected-text').textContent = 'Select waste collectors';
    document.getElementById('selected-driver').value = '';
    
    // Reset approved request selection
    const approvedRequestSelect = document.getElementById('approved-request-select');
    if (approvedRequestSelect) {
        approvedRequestSelect.selectedIndex = 0;
    }
    
    // Clear street markers (no longer used)
    if (window.streetMarkers) {
        streetMarkers = [];
    }
    
    // Clear any barangay markers (no longer used)
    if (window.barangayMarker) {
        window.barangayMarker = null;
    }
    
    // Reset coordinates display
    const coordsDisplay = document.getElementById('coordinates-display');
    if (coordsDisplay) {
        coordsDisplay.innerHTML = 'Select an approved request to see the resident location on the map';
    }
    
    // Clear street checklist
    const checklist = document.getElementById('streets-checklist');
    if (checklist) {
        checklist.innerHTML = '';
    }
    
    // Re-render drivers and collectors
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

// Pin functions removed - no longer using map pins

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
    // Streets are now just for reference - no filtering applied
    console.log('Street selected:', streetObj.display, 'Checked:', isChecked);
}

function updateCoordinatesDisplay() {
    const coordsDisplay = document.getElementById('coordinates-display');
    if (!coordsDisplay) return;
    
    // Check if we have an approved request location
    const approvedRequestSelect = document.getElementById('approved-request-select');
    if (approvedRequestSelect && approvedRequestSelect.value) {
        // We have an approved request selected, location should be set from that
        return; // Don't override the approved request location display
    }
    
    // Get selected streets from checkboxes
    const selectedStreets = document.querySelectorAll('input[name="selected-streets"]:checked');
    
    if (selectedStreets.length === 0) {
        coordsDisplay.innerHTML = 'Select an approved request to see the resident location on the map';
        selectedLocation = null;
    } else {
        coordsDisplay.innerHTML = `
            <strong>Selected Streets:</strong><br>
            ${selectedStreets.length} street(s) selected for this schedule
        `;
        // Set a default location for validation (Valenzuela center)
        selectedLocation = {
            lng: 120.9455,
            lat: 14.7077
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
    
    // Debug logging to see what's happening
    console.log('Schedule creation - selectedDriverId:', selectedDriverId);
    console.log('Schedule creation - selectedCollectors:', selectedCollectors);
    console.log('Schedule creation - selectedCollectors length:', selectedCollectors.length);
    
    // Validate required fields
    if (!selectedDriverId) {
        console.log('Driver validation failed');
        showError('Please select a driver.');
        return;
    }
    
    if (selectedCollectors.length !== 3) {
        console.log('Collectors validation failed - count:', selectedCollectors.length);
        showError(`Please select exactly 3 waste collectors. Currently selected: ${selectedCollectors.length}`);
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
        .then(async (docRef) => {
            console.log('Schedule created with ID:', docRef.id);
            
            // If an approved request is selected, update its status to scheduled
            const approvedRequestSelect = document.getElementById('approved-request-select');
            if (approvedRequestSelect && approvedRequestSelect.value) {
                try {
                    await db.collection('collections').doc(approvedRequestSelect.value).update({
                        status: 'scheduled',
                        scheduled_date: date,
                        scheduled_at: new Date().toISOString(),
                        scheduled_by: 'admin',
                        assigned_to: selectedDriverId,
                        assigned_role: 'driver',
                        assigned_at: new Date().toISOString(),
                        truck_id: truck,
                        start_time: startTime,
                        end_time: endTime
                    });
                    
                    console.log('Collection status updated to scheduled');
                    
                    // Send notification to the driver
                    try {
                        await db.collection('notifications').add({
                            user_id: selectedDriverId,
                            title: 'New Collection Assignment',
                            message: `You have been assigned a new collection for ${date} from ${startTime} to ${endTime}`,
                            type: 'collection_assigned',
                            data: {
                                collection_id: approvedRequestSelect.value,
                                scheduled_date: date,
                                truck_id: truck,
                                start_time: startTime,
                                end_time: endTime
                            },
                            created_at: new Date().toISOString(),
                            read: false
                        });
                        console.log('Notification sent to driver');
                    } catch (notificationError) {
                        console.log('Could not send notification to driver:', notificationError);
                    }
                    
                } catch (updateError) {
                    console.error('Error updating collection status:', updateError);
                }
            }
            
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
    document.getElementById('coordinates-display').innerHTML = 'Select an approved request to see the resident location on the map';
    
    // Show all streets immediately
    displayStreetsChecklist(getStreetsArray());
    
    // Load approved requests immediately when modal opens
    loadApprovedRequests();
    
    // Initialize map after modal animation completes
    setTimeout(() => {
        // Ensure map container is visible
        const mapContainer = document.getElementById('location-map');
        if (mapContainer) {
            mapContainer.style.display = 'block';
            mapContainer.style.visibility = 'visible';
        }
        
        // Initialize map if not already done
        if (!scheduleMap) {
            console.log('Initializing map for modal...');
            initLocationMap();
        } else {
            console.log('Map already initialized');
        }
        
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
    document.getElementById('coordinates-display').innerHTML = 'Select an approved request to see the resident location on the map';
    document.getElementById('streets-checklist').innerHTML = '';
    
    const searchInput = document.getElementById('street-search');
    if (searchInput) {
        searchInput.value = '';
    }
    
    // Clear all street markers (no longer used)
    streetMarkers = [];
    
    // Clear old location marker if it exists (no longer used)
    if (window.locationMarker) {
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

// ===== APPROVED REQUESTS FUNCTIONS =====

// Load approved collection requests
async function loadApprovedRequests() {
    try {
        console.log('Loading approved collection requests...');
        
        // Get approved requests from Firebase
        const approvedRequestsSnapshot = await db.collection('collections')
            .where('status', '==', 'approved')
            .orderBy('approved_at', 'desc')
            .get();
        
        const approvedRequests = [];
        approvedRequestsSnapshot.forEach(doc => {
            approvedRequests.push({
                id: doc.id,
                ...doc.data()
            });
        });
        
        console.log('Found approved requests:', approvedRequests.length);
        
        // Display in modal
        displayApprovedRequests(approvedRequests);
        
        // Show modal
        document.getElementById('approved-requests-modal').style.display = 'flex';
        
    } catch (error) {
        console.error('Error loading approved requests:', error);
        showError('Error loading approved requests: ' + error.message);
    }
}

// Display approved requests in the modal
function displayApprovedRequests(requests) {
    const container = document.getElementById('approved-requests-list');
    
    if (requests.length === 0) {
        container.innerHTML = `
            <div style="text-align: center; padding: 40px 20px; color: #6b7280;">
                <svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" style="margin: 0 auto 16px; opacity: 0.5;">
                    <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path>
                    <polyline points="14,2 14,8 20,8"></polyline>
                    <line x1="16" y1="13" x2="8" y2="13"></line>
                    <line x1="16" y1="17" x2="8" y2="17"></line>
                </svg>
                <div style="font-weight: 500; margin-bottom: 4px;">No Approved Requests</div>
                <div style="font-size: 14px;">All approved requests have been scheduled</div>
            </div>
        `;
        return;
    }
    
    let html = '';
    requests.forEach(request => {
        const wasteTypeText = getWasteTypeText(request.waste_type);
        const approvedDate = request.approved_at ? new Date(request.approved_at).toLocaleString() : 'Unknown';
        const scheduledDate = request.scheduled_date ? new Date(request.scheduled_date).toLocaleDateString() : 'Not scheduled';
        
        html += `
            <div class="approved-request-item" style="border: 1px solid #e5e7eb; border-radius: 8px; padding: 16px; margin-bottom: 12px; background: #fafafa;">
                <div style="display: flex; justify-content: space-between; align-items: flex-start; gap: 12px;">
                    <div style="flex: 1;">
                        <div style="display: flex; align-items: center; gap: 8px; margin-bottom: 8px;">
                            <span style="background: #10b981; color: white; padding: 4px 8px; border-radius: 12px; font-size: 12px; font-weight: bold;">
                                APPROVED
                            </span>
                            <span style="font-weight: 600; color: #374151;">${wasteTypeText}</span>
                        </div>
                        
                        <div style="margin-bottom: 8px;">
                            <div style="font-weight: 500; color: #374151; margin-bottom: 4px;">
                                ${request.quantity} ${request.unit} - ${request.description || 'No description'}
                            </div>
                            <div style="font-size: 14px; color: #6b7280; margin-bottom: 4px;">
                                📍 ${request.address}
                            </div>
                            <div style="font-size: 12px; color: #6b7280;">
                                Approved: ${approvedDate} | Scheduled: ${scheduledDate}
                            </div>
                            ${request.latitude && request.longitude ? `
                                <div style="font-size: 12px; color: #6b7280; margin-top: 4px;">
                                    📍 Lat: ${parseFloat(request.latitude).toFixed(6)}, Lng: ${parseFloat(request.longitude).toFixed(6)}
                                </div>
                            ` : ''}
                        </div>
                    </div>
                    
                    <div style="display: flex; gap: 8px; flex-shrink: 0;">
                        <button onclick="scheduleApprovedRequest('${request.id}')"
                            style="padding: 6px 12px; border: 1px solid #3b82f6; border-radius: 6px; background: white; cursor: pointer; font-size: 12px; color: #3b82f6; transition: all 0.2s;"
                            onmouseover="this.style.background='#eff6ff'"
                            onmouseout="this.style.background='white'">
                            📅 Schedule
                        </button>
                    </div>
                </div>
            </div>
        `;
    });
    
    container.innerHTML = html;
}

// Schedule an approved request
function scheduleApprovedRequest(requestId) {
    // Close the approved requests modal
    closeApprovedRequestsModal();
    
    // Open the create schedule modal with pre-filled data
    setTimeout(() => {
        openCreateModal();
        
        // Pre-fill the form with approved request data
        prefillScheduleForm(requestId);
    }, 300);
}

// Pre-fill the schedule form with approved request data
async function prefillScheduleForm(requestId) {
    try {
        const requestDoc = await db.collection('collections').doc(requestId).get();
        const requestData = requestDoc.data();
        
        if (requestData) {
            // Set the location from the approved request
            if (requestData.latitude && requestData.longitude) {
                selectedLocation = {
                    lat: parseFloat(requestData.latitude),
                    lng: parseFloat(requestData.longitude)
                };
                
                // Update coordinates display
                updateCoordinatesDisplay();
                
                // Center map on the location
                if (scheduleMap) {
                    scheduleMap.setCenter([selectedLocation.lng, selectedLocation.lat]);
                    scheduleMap.setZoom(16);
                }
            }
            
            // Store the request ID for later use
            window.currentApprovedRequestId = requestId;
            
            // Show a message that form is pre-filled
            showSuccess('Form pre-filled with approved request data. Please select truck, driver, and schedule time.');
        }
    } catch (error) {
        console.error('Error pre-filling form:', error);
        showError('Error loading request data');
    }
}

// Close approved requests modal
function closeApprovedRequestsModal() {
    document.getElementById('approved-requests-modal').style.display = 'none';
}

// Helper function to get waste type text
function getWasteTypeText(wasteType) {
    const wasteTypes = {
        'general': 'General Waste',
        'recyclable': 'Recyclable',
        'organic': 'Organic',
        'hazardous': 'Hazardous',
        'electronic': 'Electronic'
    };
    return wasteTypes[wasteType] || wasteType;
}

// Update the handleCreateSchedule function to handle approved requests
function handleCreateScheduleWithApprovedRequest(event) {
    event.preventDefault();
    
    // Get form values
    const truck = document.getElementById('truck-select').value;
    const date = document.getElementById('schedule-date').value;
    const startTime = document.getElementById('start-time').value;
    const endTime = document.getElementById('end-time').value;
    
    // Debug logging to see what's happening
    console.log('Schedule with approved request - selectedDriverId:', selectedDriverId);
    console.log('Schedule with approved request - selectedCollectors:', selectedCollectors);
    console.log('Schedule with approved request - selectedCollectors length:', selectedCollectors.length);
    
    // Validate required fields
    if (!selectedDriverId) {
        console.log('Driver validation failed');
        showError('Please select a driver.');
        return;
    }
    
    if (selectedCollectors.length !== 3) {
        console.log('Collectors validation failed - count:', selectedCollectors.length);
        showError(`Please select exactly 3 waste collectors. Currently selected: ${selectedCollectors.length}`);
        return;
    }
    
    if (!selectedLocation) {
        showError('Please select a location on the map.');
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
        streets: ['Approved Request Location'], // Default street
        status: 'scheduled',
        createdAt: firebase.firestore.FieldValue.serverTimestamp()
    };
    
    // If this is from an approved request, include the request ID
    if (window.currentApprovedRequestId) {
        schedule.approvedRequestId = window.currentApprovedRequestId;
    }
    
    // Save to Firestore
    db.collection('truck_schedule').add(schedule)
        .then(async (docRef) => {
            console.log('Schedule created with ID:', docRef.id);
            
            // If this is from an approved request, update the collection status
            if (window.currentApprovedRequestId) {
                try {
                    await db.collection('collections').doc(window.currentApprovedRequestId).update({
                        status: 'scheduled',
                        scheduled_by: 'Administrator', // You might want to get actual admin name
                        scheduled_at: firebase.firestore.FieldValue.serverTimestamp(),
                        schedule_id: docRef.id
                    });
                    
                    console.log('Updated collection status to scheduled');
                } catch (error) {
                    console.error('Error updating collection status:', error);
                }
                
                // Clear the approved request ID
                window.currentApprovedRequestId = null;
            }
            
            showSuccess('Schedule created successfully!');
            closeCreateModal();
            loadSchedules();
        })
        .catch((error) => {
            console.error('Error creating schedule:', error);
            showError('Error creating schedule: ' + error.message);
        });
}

// Close approved requests modal when clicking outside
document.addEventListener('click', function(event) {
    const modal = document.getElementById('approved-requests-modal');
    if (event.target === modal) {
        closeApprovedRequestsModal();
    }
});

// Load approved collection requests for dropdown
async function loadApprovedRequests() {
    try {
        console.log('Loading approved collection requests...');
        
        const approvedRequestSelect = document.getElementById('approved-request-select');
        if (!approvedRequestSelect) return;
        
        // Show loading state
        approvedRequestSelect.innerHTML = '<option value="" disabled selected>Loading approved requests...</option>';
        
        const snapshot = await db.collection('collections')
            .where('status', '==', 'approved')
            .get();
        
        console.log(`Found ${snapshot.size} approved collection requests`);
        
        // Clear existing options except the first one
        approvedRequestSelect.innerHTML = '<option value="" disabled selected>Select approved collection request</option>';
        
        if (snapshot.empty) {
            approvedRequestSelect.innerHTML = '<option value="" disabled selected>No approved requests found</option>';
            console.log('No approved requests found');
            return;
        }
        
        for (const doc of snapshot.docs) {
            const collectionData = doc.data();
            
            // Get user information
            let userName = 'Unknown User';
            try {
                const userDoc = await db.collection('users').doc(collectionData.user_id).get();
                if (userDoc.exists) {
                    const userData = userDoc.data();
                    userName = `${userData.firstName || ''} ${userData.lastName || ''}`.trim() || userData.email || 'Unknown User';
                }
            } catch (userError) {
                console.log('Could not fetch user data:', userError);
            }
            
            const option = document.createElement('option');
            option.value = doc.id;
            option.textContent = `${userName} - ${collectionData.waste_type || 'General'} (${collectionData.quantity || 0} ${collectionData.unit || 'kg'}) - ${collectionData.address || 'No address'}`;
            option.dataset.collectionData = JSON.stringify(collectionData);
            approvedRequestSelect.appendChild(option);
        }
        
        console.log('Approved requests loaded successfully');
        
    } catch (error) {
        console.error('Error loading approved requests:', error);
        const approvedRequestSelect = document.getElementById('approved-request-select');
        if (approvedRequestSelect) {
            approvedRequestSelect.innerHTML = '<option value="" disabled selected>Error loading requests</option>';
        }
        showError('Failed to load approved requests: ' + error.message);
    }
}

// Load approved request details and auto-fill form
async function loadApprovedRequestDetails() {
    try {
        const approvedRequestSelect = document.getElementById('approved-request-select');
        const selectedOption = approvedRequestSelect.options[approvedRequestSelect.selectedIndex];
        
        if (!selectedOption || !selectedOption.value) {
            return;
        }
        
        const collectionData = JSON.parse(selectedOption.dataset.collectionData);
        console.log('Loading details for collection:', collectionData);
        
        // Auto-fill location information
        if (collectionData.latitude && collectionData.longitude) {
            selectedLocation = {
                lat: collectionData.latitude,
                lng: collectionData.longitude,
                address: collectionData.address || 'Selected location'
            };
            
            // Update coordinates display immediately (doesn't depend on map)
            const coordinatesDisplay = document.getElementById('coordinates-display');
            if (coordinatesDisplay) {
                coordinatesDisplay.innerHTML = `
                    <strong>Selected Location:</strong><br>
                    ${collectionData.address || 'Selected location'}<br>
                    <small>Coordinates: ${collectionData.latitude}, ${collectionData.longitude}</small>
                `;
            }
            
            // Add pin to map for approved request location
            const addMarkerToMap = () => {
                if (scheduleMap && scheduleMap.isStyleLoaded && scheduleMap.isStyleLoaded()) {
                    // Clear existing markers
                    if (scheduleMap.getSource('resident-location')) {
                        scheduleMap.removeSource('resident-location');
                    }
                    if (scheduleMap.getLayer('resident-location-marker')) {
                        scheduleMap.removeLayer('resident-location-marker');
                    }
                    
                    // Add new marker for resident location using MapLibre GL
                    scheduleMap.addSource('resident-location', {
                        type: 'geojson',
                        data: {
                            type: 'Feature',
                            geometry: {
                                type: 'Point',
                                coordinates: [collectionData.longitude, collectionData.latitude]
                            },
                            properties: {
                                title: 'Resident Location',
                                address: collectionData.address || 'Selected location',
                                coordinates: `${collectionData.latitude}, ${collectionData.longitude}`
                            }
                        }
                    });
                    
                    // Add marker layer
                    scheduleMap.addLayer({
                        id: 'resident-location-marker',
                        type: 'circle',
                        source: 'resident-location',
                        paint: {
                            'circle-radius': 12,
                            'circle-color': '#0ea5e9',
                            'circle-stroke-width': 3,
                            'circle-stroke-color': '#ffffff',
                            'circle-opacity': 0.8
                        }
                    });
                    
                    // Add popup on click
                    scheduleMap.on('click', 'resident-location-marker', function(e) {
                        const coordinates = e.features[0].geometry.coordinates.slice();
                        const properties = e.features[0].properties;
                        
                        new maplibregl.Popup()
                            .setLngLat(coordinates)
                            .setHTML(`
                                <div style="padding: 8px;">
                                    <b>${properties.title}</b><br>
                                    ${properties.address}<br>
                                    <small>Coordinates: ${properties.coordinates}</small>
                                </div>
                            `)
                            .addTo(scheduleMap);
                    });
                    
                    // Change cursor on hover
                    scheduleMap.on('mouseenter', 'resident-location-marker', function() {
                        scheduleMap.getCanvas().style.cursor = 'pointer';
                    });
                    
                    scheduleMap.on('mouseleave', 'resident-location-marker', function() {
                        scheduleMap.getCanvas().style.cursor = '';
                    });
                    
                    // Center map on the location
                    scheduleMap.flyTo({
                        center: [collectionData.longitude, collectionData.latitude],
                        zoom: 15
                    });
                    
                    console.log('Added resident location marker to map for approved request');
                } else {
                    console.log('Map not ready, retrying in 500ms...');
                    setTimeout(addMarkerToMap, 500);
                }
            };
            
            // Try to add marker immediately, or wait for map to be ready
            if (scheduleMap && typeof scheduleMap.addSource === 'function') {
                addMarkerToMap();
            } else {
                console.log('Map not initialized, waiting for map to be ready...');
                // Wait for map to be initialized
                const waitForMap = () => {
                    if (scheduleMap && typeof scheduleMap.addSource === 'function') {
                        addMarkerToMap();
                    } else {
                        setTimeout(waitForMap, 500);
                    }
                };
                waitForMap();
            }
        } else {
            // If no coordinates, still show the address
            const coordinatesDisplay = document.getElementById('coordinates-display');
            if (coordinatesDisplay) {
                coordinatesDisplay.innerHTML = `
                    <strong>Selected Location:</strong><br>
                    ${collectionData.address || 'No address provided'}
                `;
            }
        }
        
        // Auto-fill waste type information (you can add this to a display area if needed)
        console.log('Auto-filled location:', selectedLocation);
        console.log('Collection details:', {
            wasteType: collectionData.waste_type,
            quantity: collectionData.quantity,
            unit: collectionData.unit,
            address: collectionData.address,
            coordinates: `${collectionData.latitude}, ${collectionData.longitude}`
        });
        
        // Show success message
        showSuccess('Collection details loaded successfully! Location and coordinates have been set.');
        
    } catch (error) {
        console.error('Error loading approved request details:', error);
        showError('Failed to load collection details: ' + error.message);
    }
}

// Auto-check street functionality removed - no longer using map pins

// Resident location option functionality removed - no longer using map pins

// Calculate distance between two coordinates (in kilometers)
function calculateDistance(lat1, lng1, lat2, lng2) {
    const R = 6371; // Radius of the Earth in kilometers
    const dLat = (lat2 - lat1) * Math.PI / 180;
    const dLng = (lng2 - lng1) * Math.PI / 180;
    const a = Math.sin(dLat/2) * Math.sin(dLat/2) +
              Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
              Math.sin(dLng/2) * Math.sin(dLng/2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
    return R * c;
}