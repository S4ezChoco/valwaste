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
let selectedCollectors = [];
let schedules = [];

// Month names
const monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
];

// MapTiler API key
const MAPTILER_KEY = 'Kr1k642bLPyqdCL0A5yM';

// Initialize on page load
document.addEventListener('DOMContentLoaded', function() {
    generateCalendar();
    updateMonthYearDisplay();
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

// Load drivers from Firebase
function loadDrivers() {
    db.collection('users').where('role', '==', 'Driver').onSnapshot((snapshot) => {
        const driverMenu = document.getElementById('driver-dropdown-menu');
        driverMenu.innerHTML = '';
        
        snapshot.forEach((doc) => {
            const userData = doc.data();
            const driverItem = document.createElement('div');
            driverItem.className = 'dropdown-item';
            driverItem.innerHTML = `
                <span>${userData.firstName} ${userData.lastName}</span>
            `;
            driverItem.onclick = () => selectDriver(doc.id, userData.firstName + ' ' + userData.lastName);
            driverMenu.appendChild(driverItem);
        });
    });
}

// Load waste collectors from Firebase
function loadWasteCollectors() {
    db.collection('users').where('role', 'in', ['Driver', 'Waste Collector']).onSnapshot((snapshot) => {
        const collectorsMenu = document.getElementById('collectors-dropdown-menu');
        collectorsMenu.innerHTML = '';
        
        snapshot.forEach((doc) => {
            const userData = doc.data();
            const collectorItem = document.createElement('div');
            collectorItem.className = 'dropdown-item';
            
            // Create checkbox element programmatically to avoid quote issues
            const checkbox = document.createElement('input');
            checkbox.type = 'checkbox';
            checkbox.id = `collector-${doc.id}`;
            checkbox.addEventListener('change', function() {
                toggleCollector(doc.id, `${userData.firstName} ${userData.lastName}`);
            });
            
            const span = document.createElement('span');
            span.textContent = `${userData.firstName} ${userData.lastName} (Palero)`;
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

function selectDriver(driverId, driverName) {
    selectedDriverId = driverId;
    document.getElementById('driver-selected-text').textContent = driverName;
    document.getElementById('selected-driver').value = driverId;
    closeAllDropdowns();
}

function toggleCollector(collectorId, collectorName) {
    const checkbox = document.getElementById(`collector-${collectorId}`);
    
    if (checkbox.checked) {
        if (selectedCollectors.length >= 3) {
            checkbox.checked = false;
            showWarning('You can only select up to 3 waste collectors.');
            return;
        }
        selectedCollectors.push({ id: collectorId, name: collectorName });
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
            // Valenzuela City center coordinates
            const center = [120.97, 14.72]; // Note: MapLibre uses [lng, lat]
            
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
                style: `https://api.maptiler.com/maps/streets-v2/style.json?key=${MAPTILER_KEY}`,
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
                            center: [120.97, 14.72], // Valenzuela center
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
    return {
        'District 1': {
            'Arkong Bato': {
                coordinates: [120.9650, 14.7350],
                streets: ['M.H. del Pilar Street']
            },
            'Balangkas': {
                coordinates: [120.9720, 14.7280],
                streets: ['P. Deato Street', 'Sampaguita Street']
            },
            'Bignay': {
                coordinates: [120.9580, 14.7420],
                streets: ['Bignay-Llano Road', 'Hulo Street']
            },
            'Bisig': {
                coordinates: [120.9680, 14.7380],
                streets: ['Bisig Road']
            },
            'Canumay East': {
                coordinates: [120.9750, 14.7200],
                streets: ['NLEx East Service Road']
            },
            'Canumay West': {
                coordinates: [120.9700, 14.7220],
                streets: ['J. Gregorio Street']
            },
            'Coloong': {
                coordinates: [120.9620, 14.7300],
                streets: ['Coloong 1 Road', 'Coloong 2 Road', 'Cabeza C. Porciuncula Street']
            },
            'Dalandanan': {
                coordinates: [120.9550, 14.7450],
                streets: ['Dalandanan-Veinte Reales Road', 'G. Lazaro Road']
            },
            'Isla': {
                coordinates: [120.9600, 14.7400],
                streets: ['Isla Road']
            },
            'Lawang Bato': {
                coordinates: [120.9780, 14.7150],
                streets: ['Lawang Bato Road', 'NLEx East Service Road']
            },
            'Lingunan': {
                coordinates: [120.9640, 14.7320],
                streets: ['T. Santiago Street', 'Maxima Steel Road']
            },
            'Mabolo': {
                coordinates: [120.9660, 14.7340],
                streets: ['M.H. del Pilar Street']
            },
            'Malanday': {
                coordinates: [120.9700, 14.7250],
                streets: ['MacArthur Highway', 'M.H. del Pilar Street']
            },
            'Malinta': {
                coordinates: [120.9720, 14.7180],
                streets: ['Maysan Road', 'MacArthur Highway']
            },
            'Palasan': {
                coordinates: [120.9680, 14.7360],
                streets: ['M.H. del Pilar Street']
            },
            'Pariancillo Villa': {
                coordinates: [120.9750, 14.7100],
                streets: ['Gen. Velilla Street', 'Dr. Pio Valenzuela Street']
            },
            'Pasolo': {
                coordinates: [120.9670, 14.7330],
                streets: ['Pasolo Road', 'M.H. del Pilar Street']
            },
            'Poblacion': {
                coordinates: [120.9700, 14.7200],
                streets: ['Polo Road', 'M.H. del Pilar Street']
            },
            'Polo': {
                coordinates: [120.9710, 14.7190],
                streets: ['Polo Road', 'M.H. del Pilar Street']
            },
            'Punturin': {
                coordinates: [120.9800, 14.7050],
                streets: ['Punturin Road', 'NLEx Service Road']
            },
            'Rincon': {
                coordinates: [120.9650, 14.7350],
                streets: ['Rincon-Pasolo-Mabolo Road']
            },
            'Tagalag': {
                coordinates: [120.9590, 14.7410],
                streets: ['Tagalag Road']
            },
            'Veinte Reales': {
                coordinates: [120.9520, 14.7480],
                streets: ['Veinte Reales Road']
            },
            'Wawang Pulo': {
                coordinates: [120.9580, 14.7430],
                streets: ['Tullahan River Area Streets']
            }
        },
        'District 2': {
            'Bagbaguin': {
                coordinates: [120.9850, 14.6950],
                streets: ['ITC Compound Streets']
            },
            'Gen. T. de Leon': {
                coordinates: [120.9820, 14.7000],
                streets: ['Gen. T. de Leon Street']
            },
            'Karuhatan': {
                coordinates: [120.9800, 14.7020],
                streets: ['MacArthur Highway', 'A. Pablo Street']
            },
            'Mapulang Lupa': {
                coordinates: [120.9780, 14.7080],
                streets: ['Industrial Area Streets']
            },
            'Marulas': {
                coordinates: [120.9750, 14.7120],
                streets: ['MacArthur Highway', 'Pio Valenzuela Street']
            },
            'Maysan': {
                coordinates: [120.9730, 14.7160],
                streets: ['Maysan Road', 'C. Cabral Street']
            },
            'Parada': {
                coordinates: [120.9760, 14.7100],
                streets: ['Residential Streets']
            },
            'Paso de Blas': {
                coordinates: [120.9810, 14.6980],
                streets: ['NLEx Service Road']
            },
            'Ugong': {
                coordinates: [120.9840, 14.6920],
                streets: ['Mindanao Avenue Extension']
            }
        }
    };
}

function getStreetsArray() {
    const streetsData = getAllValenzuelaStreets();
    const allStreets = [];
    
    // Flatten the structure to get all streets with coordinates
    Object.keys(streetsData).forEach(district => {
        Object.keys(streetsData[district]).forEach(barangay => {
            const barangayData = streetsData[district][barangay];
            barangayData.streets.forEach(street => {
                allStreets.push({
                    display: `${street} (${barangay}, ${district})`,
                    street: street,
                    barangay: barangay,
                    district: district,
                    coordinates: barangayData.coordinates
                });
            });
        });
    });
    
    return allStreets.sort((a, b) => a.display.localeCompare(b.display));
}

function loadNearbyStreets(lat, lng) {
    // Determine which district/barangay based on coordinates
    let nearbyStreets = [];
    
    // Simple location-based logic for Valenzuela
    if (lat > 14.73) {
        // Northern area - likely District 1
        nearbyStreets = [
            'MacArthur Highway (Malanday, District 1)',
            'M.H. del Pilar Street (Malanday, District 1)',
            'Maysan Road (Malinta, District 1)',
            'Polo Road (Poblacion, District 1)',
            'Isla Road (Isla, District 1)',
            'Punturin Road (Punturin, District 1)'
        ];
    } else {
        // Southern area - likely District 2
        nearbyStreets = [
            'MacArthur Highway (Karuhatan, District 2)',
            'Gen. T. de Leon Street (Gen. T. de Leon, District 2)',
            'A. Pablo Street (Karuhatan, District 2)',
            'Maysan Road (Maysan, District 2)',
            'NLEx Service Road (Paso de Blas, District 2)',
            'Mindanao Avenue Extension (Ugong, District 2)'
        ];
    }
    
    displayStreetsChecklist(nearbyStreets);
}

// Global variable to store map markers
let streetMarkers = [];

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
