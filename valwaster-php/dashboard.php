<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Dashboard - ValWaste Admin</title>
    <link rel="stylesheet" href="assets/css/styles.css">
    <script src="https://unpkg.com/maplibre-gl@3.6.2/dist/maplibre-gl.js"></script>
    <link href="https://unpkg.com/maplibre-gl@3.6.2/dist/maplibre-gl.css" rel="stylesheet" />
    <style>
        .role-toggle-minimal {
            background: none;
            border: none;
            cursor: pointer;
            padding: 4px;
            border-radius: 3px;
            color: #6b7280;
            transition: all 0.2s;
            opacity: 0.8;
        }
        .role-toggle-minimal:hover {
            background: #f3f4f6;
            color: #374151;
            opacity: 1;
        }
        .role-toggle-minimal.expanded svg {
            transform: rotate(180deg);
        }
        .user-breakdown-minimal {
            margin-top: 8px;
            position: absolute;
            background: white;
            border: 2px solid #d1d5db;
            border-radius: 6px;
            padding: 8px;
            box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1);
            z-index: 1000;
            min-width: 160px;
            left: 0;
            top: 100%;
        }
        .stats-card {
            position: relative;
        }
        .users-card .stats-meta {
            display: flex;
            flex-direction: column;
            gap: 6px;
            justify-content: center;
        }
        .role-item {
            display: flex;
            align-items: center;
            justify-content: space-between;
            margin-bottom: 4px;
            font-size: 11px;
            color: #6b7280;
        }
        .role-item:last-child {
            margin-bottom: 0;
        }
        .role-dot {
            width: 8px;
            height: 8px;
            border-radius: 50%;
            margin-right: 8px;
            flex-shrink: 0;
        }
        .role-dot.resident { background: #10b981; }
        .role-dot.official { background: #3b82f6; }
        .role-dot.driver { background: #f59e0b; }
        .role-dot.admin { background: #8b5cf6; }
        .role-text strong {
            color: #374151;
        }
        
        /* Traffic toggle button styling */
        #toggleTraffic.active {
            background: rgba(59, 130, 246, 0.2);
            color: #3B82F6;
            border-color: rgba(59, 130, 246, 0.3);
        }
        
        #toggleTraffic.active svg {
            stroke: #3B82F6;
        }
    </style>
</head>
<body>
    <div class="app-shell">
        <div class="brandbar">
            <div class="brand">
                <div class="brand-circle">V</div>
                <div class="brand-name">ValWaste</div>
            </div>
        </div>

        <div class="topbar">
            <button class="hamburger" aria-label="Open sidebar" onclick="openSidebar()">
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <line x1="3" y1="6" x2="21" y2="6"></line>
                    <line x1="3" y1="12" x2="21" y2="12"></line>
                    <line x1="3" y1="18" x2="21" y2="18"></line>
                </svg>
            </button>
            <h1 class="page-title">Dashboard</h1>
        </div>

        <?php include 'components/sidebar.php'; ?>

        <main class="content">
            <div class="page-container">
                <!-- Stats -->
                <section class="stats-grid">
                    <div class="card stats-card users-card">
                        <div class="stats-meta">
                            <p class="stats-label" style="margin: 0;">Total Users
                                <button id="toggleUserView" class="role-toggle-minimal" title="View breakdown" style="float: right; margin-top: -2px;">
                                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
                                        <polyline points="6 9 12 15 18 9"></polyline>
                                    </svg>
                                </button>
                            </p>
                            <h3 class="stats-value" id="totalUsers">0</h3>
                            <div id="userBreakdown" class="user-breakdown-minimal" style="display: none;">
                                <div class="role-item">
                                    <div style="display: flex; align-items: center;">
                                        <span class="role-dot resident"></span>Residents:
                                    </div>
                                    <strong id="totalResidents">0</strong>
                                </div>
                                <div class="role-item">
                                    <div style="display: flex; align-items: center;">
                                        <span class="role-dot official"></span>Officials:
                                    </div>
                                    <strong id="totalBarangayOfficials">0</strong>
                                </div>
                                <div class="role-item">
                                    <div style="display: flex; align-items: center;">
                                        <span class="role-dot driver"></span>Drivers:
                                    </div>
                                    <strong id="totalDrivers">0</strong>
                                </div>
                                <div class="role-item">
                                    <div style="display: flex; align-items: center;">
                                        <span class="role-dot admin"></span>Admins:
                                    </div>
                                    <strong id="totalAdministrators">0</strong>
                                </div>
                            </div>
                            <p class="stats-sub" id="usersSub">Registered in the system</p>
                        </div>
                        <div class="stats-icon">
                            <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"></path>
                                <circle cx="9" cy="7" r="4"></circle>
                                <path d="M23 21v-2a4 4 0 0 0-3-3.87"></path>
                                <path d="M16 3.13a4 4 0 0 1 0 7.75"></path>
                            </svg>
                        </div>
                    </div>

                    <div class="card stats-card">
                        <div class="stats-meta">
                            <p class="stats-label">Total Reports</p>
                            <div class="stats-value" style="color: #333;" id="totalReportsCount">0</div>
                            <p class="stats-sub">Reports made by users</p>
                        </div>
                        <div class="stats-icon">
                            <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path>
                                <polyline points="14,2 14,8 20,8"></polyline>
                                <line x1="16" y1="13" x2="8" y2="13"></line>
                                <line x1="16" y1="17" x2="8" y2="17"></line>
                                <polyline points="10,9 9,9 8,9"></polyline>
                            </svg>
                        </div>
                    </div>

                    <div class="card stats-card">
                        <div class="stats-meta">
                            <p class="stats-label">Total Trucks</p>
                            <h3 class="stats-value" id="totalTrucks">3</h3>
                            <p class="stats-sub">Available on the map</p>
                        </div>
                        <div class="stats-icon">
                            <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                <rect x="1" y="3" width="15" height="13"></rect>
                                <polygon points="16 8 20 8 23 11 23 16 16 16 16 8"></polygon>
                                <circle cx="5.5" cy="18.5" r="2.5"></circle>
                                <circle cx="18.5" cy="18.5" r="2.5"></circle>
                            </svg>
                        </div>
                    </div>

                    <div class="card stats-card">
                        <div class="stats-meta">
                            <p class="stats-label">Critical Issues</p>
                            <h3 class="stats-value" id="criticalIssues">0</h3>
                            <p class="stats-sub">Requiring immediate attention</p>
                        </div>
                        <div class="stats-icon">
                            <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                <path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"></path>
                                <line x1="12" y1="9" x2="12" y2="13"></line>
                                <line x1="12" y1="17" x2="12.01" y2="17"></line>
                            </svg>
                        </div>
                    </div>
                </section>

                <!-- Map + Recent -->
                <section class="main-grid">
                    <div class="card map-panel">
                        <div class="map-controls">
                            <div class="map-control-group">
                                <button id="toggle3D" class="map-control-btn" title="Toggle 3D View">
                                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                        <path d="M21 16V8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16z"></path>
                                        <polyline points="3.27,6.96 12,12.01 20.73,6.96"></polyline>
                                        <line x1="12" y1="22.08" x2="12" y2="12"></line>
                                    </svg>
                                </button>
                                <button id="resetNorth" class="map-control-btn" title="Reset to North">
                                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                        <polygon points="3,11 22,2 13,21 11,13 3,11"></polygon>
                                    </svg>
                                </button>
                                <button id="refreshPins" class="map-control-btn" title="Refresh Truck Locations">
                                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                        <polyline points="23 4 23 10 17 10"></polyline>
                                        <polyline points="1 20 1 14 7 14"></polyline>
                                        <path d="M20.49 9A9 9 0 0 0 5.64 5.64L1 10m22 4l-4.64 4.36A9 9 0 0 1 3.51 15"></path>
                                    </svg>
                                </button>
                            </div>
                            <div class="map-control-group">
                                <button id="toggleTerrain" class="map-control-btn" title="Toggle Terrain">
                                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                        <path d="M8 21l4-7 6 7"></path>
                                        <path d="M2 21l4-7 4 7"></path>
                                        <path d="M15 5l7 7"></path>
                                    </svg>
                                </button>
                                <button id="toggleBuildings" class="map-control-btn" title="Toggle 3D Buildings">
                                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                        <path d="M6 22V4a2 2 0 0 1 2-2h8a2 2 0 0 1 2 2v18Z"></path>
                                        <path d="M6 12h12"></path>
                                        <path d="M6 8h12"></path>
                                        <path d="M6 16h12"></path>
                                    </svg>
                                </button>
                                <button id="toggleSatellite" class="map-control-btn" title="Toggle Satellite View">
                                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                        <circle cx="12" cy="12" r="10"></circle>
                                        <path d="M12 2a14.5 14.5 0 0 0 0 20 14.5 14.5 0 0 0 0-20"></path>
                                        <path d="M2 12h20"></path>
                                    </svg>
                                </button>
                                <button id="toggleFullscreen" class="map-control-btn" title="Toggle Fullscreen">
                                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                        <path d="M8 3H5a2 2 0 0 0-2 2v3m18 0V5a2 2 0 0 0-2-2h-3m0 18h3a2 2 0 0 0 2-2v-3M3 16v3a2 2 0 0 0 2 2h3"></path>
                                    </svg>
                                </button>
                            </div>
                        </div>
                        <div id="map" class="map-container"></div>
                    </div>

                    <aside class="card recent">
                        <h3 class="recent-title">Recent Reports</h3>
                        <div class="recent-list" id="recentReportsList">
                            <!-- Reports will be loaded from Firebase -->
                            <div style="text-align: center; padding: 20px; color: #6b7280;">
                                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="margin: 0 auto; animation: spin 1s linear infinite;">
                                    <path d="M21 12a9 9 0 11-6.219-8.56"/>
                                </svg>
                                <p style="margin-top: 8px;">Loading reports...</p>
                            </div>
                        </div>
                        <button class="btn-outline" type="button" onclick="window.location.href='report-management.php'">
                            View All Reports
                        </button>
                    </aside>
                </section>

                <!-- Announcements -->
                <section class="card annc-card">
                    <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 16px;">
                        <h4 class="annc-title">Announcements</h4>
                        <div style="display: flex; gap: 8px;">
                            <button type="button" class="btn-outline" onclick="viewArchivedAnnouncements()" style="padding: 8px 16px; font-size: 14px;">
                                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="margin-right: 4px;">
                                    <polyline points="21 8 21 21 3 21 3 8"></polyline>
                                    <rect x="1" y="3" width="22" height="5"></rect>
                                    <line x1="10" y1="12" x2="14" y2="12"></line>
                                </svg>
                                Archive
                            </button>
                            <button type="button" class="btn-outline" onclick="editAnnouncement()">
                                Create Announcement
                            </button>
                        </div>
                    </div>
                    
                    <div id="announcementSection">
                        <div id="announcementsList">
                            <!-- Announcements will be loaded here -->
                        </div>
                    </div>
                    
                    <div id="editAnnouncementSection" style="display: none;">
                        <textarea class="annc-textarea" id="announcementTextarea" placeholder="Type your announcement..." maxlength="500"></textarea>
                        <div style="text-align: right; margin: 4px 0; color: #6b7280; font-size: 12px;">
                            <span id="charCount">0</span>/500 characters
                        </div>
                        <div style="margin: 12px 0;">
                            <label style="display: block; margin-bottom: 6px; font-weight: 500; color: #374151; font-size: 14px;">
                                Auto-delete after:
                            </label>
                            <div style="display: flex; align-items: center; gap: 8px;">
                                <input type="number" id="announcementDuration" 
                                       value="24" min="1" max="24" 
                                       style="width: 80px; padding: 8px 12px; border: 1px solid #d1d5db; border-radius: 6px; font-size: 14px;">
                                <span style="color: #6b7280; font-size: 14px;">hours</span>
                                <small style="color: #6b7280; font-size: 12px; margin-left: 8px;">
                                    (Max: 24 hours)
                                </small>
                            </div>
                        </div>
                        <div class="annc-actions">
                            <button type="button" class="btn-primary" onclick="sendAnnouncement()" id="sendAnnouncementBtn">
                                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="margin-right: 4px;">
                                    <line x1="22" y1="2" x2="11" y2="13"></line>
                                    <polygon points="22,2 15,22 11,13 2,9"></polygon>
                                </svg>
                                Send
                            </button>
                            <button type="button" class="btn-ghost" onclick="cancelAnnouncement()">Cancel</button>
                        </div>
                    </div>
                </section>

                <!-- Bottom quick actions -->
                <section class="action-grid">
                    <a href="user-management.php" class="card action-card action-green">
                        <div class="action-icon">
                            <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"></path>
                                <circle cx="9" cy="7" r="4"></circle>
                                <path d="M23 21v-2a4 4 0 0 0-3-3.87"></path>
                                <path d="M16 3.13a4 4 0 0 1 0 7.75"></path>
                            </svg>
                        </div>
                        <div class="action-copy">
                            <div class="action-title">User Management</div>
                            <div class="action-desc">Manage residents, collectors, and drivers</div>
                        </div>
                    </a>

                    <a href="report-management.php" class="card action-card action-blue">
                        <div class="action-icon">
                            <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path>
                                <polyline points="14,2 14,8 20,8"></polyline>
                                <line x1="16" y1="13" x2="8" y2="13"></line>
                                <line x1="16" y1="17" x2="8" y2="17"></line>
                                <polyline points="10,9 9,9 8,9"></polyline>
                            </svg>
                        </div>
                        <div class="action-copy">
                            <div class="action-title">Report Management</div>
                            <div class="action-desc">View and respond to community reports</div>
                        </div>
                    </a>

                    <a href="truck-schedule.php" class="card action-card action-teal">
                        <div class="action-icon">
                            <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                <rect x="1" y="3" width="15" height="13"></rect>
                                <polygon points="16 8 20 8 23 11 23 16 16 16 16 8"></polygon>
                                <circle cx="5.5" cy="18.5" r="2.5"></circle>
                                <circle cx="18.5" cy="18.5" r="2.5"></circle>
                            </svg>
                        </div>
                        <div class="action-copy">
                            <div class="action-title">Truck Schedules</div>
                            <div class="action-desc">Manage collection routes and schedules</div>
                        </div>
                    </a>
                </section>
            </div>
        </main>
    </div>

    <!-- Firebase CDN -->
    <script src="https://www.gstatic.com/firebasejs/9.23.0/firebase-app-compat.js"></script>
    <script src="https://www.gstatic.com/firebasejs/9.23.0/firebase-auth-compat.js"></script>
    <script src="https://www.gstatic.com/firebasejs/9.23.0/firebase-firestore-compat.js"></script>
    
    <script type="module" src="assets/js/auth.js"></script>
    <script src="assets/js/notifications.js"></script>
    <script>
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

        // Initialize map with MapLibre GL JS and MapTiler
        let map;
        let currentAnnouncement = "No announcement yet.";
        let is3DEnabled = false;
        let isTerrainEnabled = false;
        let isBuildingsEnabled = false;
        let isSatelliteEnabled = false;
        let isFullscreenEnabled = false;
        let truckMarkers = [];
        let scheduleData = [];

        // MapTiler API key
        const MAPTILER_KEY = 'Kr1k642bLPyqdCL0A5yM';

        // Load and count users by role
        function loadUserCounts() {
            console.log('Loading user counts from Firebase...');
            
            db.collection('users').onSnapshot((snapshot) => {
                const roleCounts = {
                    'Resident': 0,
                    'Barangay Official': 0,
                    'Driver': 0,
                    'Administrator': 0
                };
                
                snapshot.forEach((doc) => {
                    const userData = doc.data();
                    const role = userData.role;
                    
                    if (roleCounts.hasOwnProperty(role)) {
                        roleCounts[role]++;
                    }
                });
                
                // Calculate total users
                const totalUsers = Object.values(roleCounts).reduce((sum, count) => sum + count, 0);
                
                // Update dashboard counters
                document.getElementById('totalUsers').textContent = totalUsers;
                document.getElementById('totalResidents').textContent = roleCounts['Resident'];
                document.getElementById('totalBarangayOfficials').textContent = roleCounts['Barangay Official'];
                document.getElementById('totalDrivers').textContent = roleCounts['Driver'];
                document.getElementById('totalAdministrators').textContent = roleCounts['Administrator'];
                
                console.log('User counts updated:', roleCounts, 'Total:', totalUsers);
            }, (error) => {
                console.error('Error loading user counts:', error);
            });
        }

        // Toggle user breakdown view
        function toggleUserBreakdown() {
            const breakdown = document.getElementById('userBreakdown');
            const toggleBtn = document.getElementById('toggleUserView');
            const isExpanded = breakdown.style.display !== 'none';
            
            if (isExpanded) {
                breakdown.style.display = 'none';
                toggleBtn.classList.remove('expanded');
            } else {
                breakdown.style.display = 'block';
                toggleBtn.classList.add('expanded');
            }
        }

        function initMap() {
            // Valenzuela City center coordinates
            const center = [120.97, 14.72]; // Note: MapLibre uses [lng, lat]
            
            // Philippines bounds [southwest, northeast]
            const philippinesBounds = [
                [116.0, 4.5],  // Southwest coordinates
                [127.0, 21.0]  // Northeast coordinates
            ];
            
            map = new maplibregl.Map({
                container: 'map',
                style: `https://api.maptiler.com/maps/streets-v2/style.json?key=${MAPTILER_KEY}`,
                center: center,
                zoom: 12,
                minZoom: 5,
                maxZoom: 18,
                maxBounds: philippinesBounds,
                pitch: 0,
                bearing: 0,
                antialias: true
            });
            
            // Remove duplicate labels when style loads
            map.on('style.load', () => {
                hideDuplicateLabels();
            });

            // Add navigation control
            map.addControl(new maplibregl.NavigationControl(), 'top-right');

            // Enable right-click drag for 3D rotation
            map.dragRotate.enable();
            map.touchZoomRotate.enableRotation();


            // Add truck markers when map loads
            map.on('load', () => {
                // Load truck schedules and add markers
                loadTruckSchedules();

                // Setup 3D buildings layer (initially hidden)
                setupBuildingsLayer();
                
                // Setup traffic layer (initially hidden)
                setupTrafficLayer();
            });

            // Setup control event listeners
            setupMapControls();
        }

        // Load truck schedules from Firebase
        function loadTruckSchedules() {
            console.log('Loading truck schedules from Firebase...');
            
            db.collection('truck_schedule').onSnapshot((snapshot) => {
                scheduleData = [];
                snapshot.forEach((doc) => {
                    const schedule = { id: doc.id, ...doc.data() };
                    scheduleData.push(schedule);
                });
                
                console.log('Loaded schedules:', scheduleData);
                addTruckMarkers();
            }, (error) => {
                console.error('Error loading truck schedules:', error);
            });
            
            // Also start listening for driver locations
            loadDriverLocations();
        }

        // Driver location tracking with optimization
        let driverMarkers = {};
        let locationUpdateTimeout = null;
        let lastLocationUpdate = {};
        const LOCATION_UPDATE_THROTTLE = 5000; // Only update every 5 seconds
        
        function loadDriverLocations() {
            console.log('Starting driver location tracking...');
            
            // Listen for active driver locations with throttling
            db.collection('driver_locations')
                .where('isActive', '==', true)
                .where('lastUpdate', '>', new Date(Date.now() - 30 * 60 * 1000)) // Only show drivers active in last 30 min
                .onSnapshot((snapshot) => {
                    snapshot.forEach((doc) => {
                        const driverId = doc.id;
                        const locationData = doc.data();
                        
                        // Throttle updates per driver
                        const now = Date.now();
                        if (lastLocationUpdate[driverId] && (now - lastLocationUpdate[driverId]) < LOCATION_UPDATE_THROTTLE) {
                            return;
                        }
                        lastLocationUpdate[driverId] = now;
                        
                        updateDriverMarker(driverId, locationData);
                    });
                }, (error) => {
                    console.error('Error loading driver locations:', error);
                });
        }
        
        function updateDriverMarker(driverId, locationData) {
            // Remove old marker if exists
            if (driverMarkers[driverId]) {
                driverMarkers[driverId].remove();
            }
            
            // Create truck icon element
            const el = document.createElement('div');
            el.className = 'driver-marker';
            el.innerHTML = `
                <svg width="32" height="32" viewBox="0 0 24 24" fill="#3B82F6" style="filter: drop-shadow(0 2px 4px rgba(0,0,0,0.3)); transform: rotate(${locationData.heading || 0}deg);">
                    <path d="M20 8h-3V4H3c-1.1 0-2 .9-2 2v11h2c0 1.66 1.34 3 3 3s3-1.34 3-3h6c0 1.66 1.34 3 3 3s3-1.34 3-3h2v-5l-3-4zM6 18.5c-.83 0-1.5-.67-1.5-1.5s.67-1.5 1.5-1.5 1.5.67 1.5 1.5-.67 1.5-1.5 1.5zm13.5-9l1.96 2.5H17V9.5h2.5zm-1.5 9c-.83 0-1.5-.67-1.5-1.5s.67-1.5 1.5-1.5 1.5.67 1.5 1.5-.67 1.5-1.5 1.5z"/>
                </svg>
            `;
            
            // Create popup with driver details
            const popup = new maplibregl.Popup({ offset: 25 })
                .setHTML(`
                    <div style="min-width: 200px;">
                        <strong>Driver: ${locationData.driverName || 'Unknown'}</strong><br/>
                        <strong>Truck:</strong> ${locationData.truckId || 'Not Assigned'}<br/>
                        <strong>Status:</strong> ${locationData.status || 'Active'}<br/>
                        <strong>Speed:</strong> ${locationData.speed ? locationData.speed.toFixed(1) + ' km/h' : 'N/A'}<br/>
                        <strong>Last Update:</strong> ${locationData.lastUpdate ? new Date(locationData.lastUpdate.seconds * 1000).toLocaleTimeString() : 'Unknown'}<br/>
                        ${locationData.scheduleDetails ? `
                            <hr style="margin: 8px 0; border: none; border-top: 1px solid #e5e7eb;">
                            <strong>Route:</strong> ${locationData.scheduleDetails.streets ? locationData.scheduleDetails.streets.slice(0, 3).join(', ') : 'N/A'}<br/>
                            <strong>Time:</strong> ${locationData.scheduleDetails.startTime} - ${locationData.scheduleDetails.endTime}
                        ` : ''}
                    </div>
                `);
            
            const marker = new maplibregl.Marker(el)
                .setLngLat([locationData.longitude, locationData.latitude])
                .setPopup(popup)
                .addTo(map);
            
            driverMarkers[driverId] = marker;
        }

        function addTruckMarkers() {
            // Clear existing markers
            truckMarkers.forEach(marker => marker.remove());
            truckMarkers = [];

            // Get today's date for filtering current schedules
            const today = new Date();
            const todayString = `${today.getFullYear()}-${String(today.getMonth() + 1).padStart(2, '0')}-${String(today.getDate()).padStart(2, '0')}`;
            
            // Filter schedules for today
            const todaySchedules = scheduleData.filter(schedule => schedule.date === todayString);
            
            console.log('Today\'s schedules:', todaySchedules);

            // Add markers for today's schedules
            todaySchedules.forEach((schedule) => {
                if (schedule.location && schedule.location.lat && schedule.location.lng) {
                    const el = document.createElement('div');
                    el.className = 'truck-marker';
                    
                    // Determine status color based on time
                    const now = new Date();
                    const currentTime = `${String(now.getHours()).padStart(2, '0')}:${String(now.getMinutes()).padStart(2, '0')}`;
                    let status = 'scheduled';
                    let statusColor = '#6B7280'; // Gray for scheduled
                    
                    if (currentTime >= schedule.startTime && currentTime <= schedule.endTime) {
                        status = 'active';
                        statusColor = '#3B82F6'; // Blue for active
                    } else if (currentTime > schedule.endTime) {
                        status = 'completed';
                        statusColor = '#10B981'; // Green for completed
                    }
                    
                    el.style.cssText = `
                        width: 24px; height: 24px; border-radius: 50%; 
                        border: 3px solid white; box-shadow: 0 2px 6px rgba(0,0,0,0.3);
                        background: ${statusColor};
                        cursor: pointer;
                    `;

                    // Create popup with schedule details
                    const collectorsText = schedule.collectors ? 
                        schedule.collectors.map(c => c.name).join(', ') : 
                        'No collectors assigned';
                    
                    const streetsText = schedule.streets && schedule.streets.length > 0 ? 
                        schedule.streets.slice(0, 3).join(', ') + (schedule.streets.length > 3 ? '...' : '') :
                        'No streets assigned';

                    const popup = new maplibregl.Popup({ offset: 25 })
                        .setHTML(`
                            <div style="min-width: 200px;">
                                <strong>${schedule.truck}</strong><br/>
                                <strong>Status:</strong> ${status.charAt(0).toUpperCase() + status.slice(1)}<br/>
                                <strong>Time:</strong> ${schedule.startTime} - ${schedule.endTime}<br/>
                                <strong>Driver:</strong> ${schedule.driver}<br/>
                                <strong>Collectors:</strong> ${collectorsText}<br/>
                                <strong>Streets:</strong> ${streetsText}
                            </div>
                        `);

                    const marker = new maplibregl.Marker(el)
                        .setLngLat([schedule.location.lng, schedule.location.lat])
                        .setPopup(popup)
                        .addTo(map);
                        
                    truckMarkers.push(marker);
                }
            });
            
            // Update truck count
            document.getElementById('totalTrucks').textContent = todaySchedules.length;
        }

        function setupBuildingsLayer() {
            try {
                // Check if buildings layer already exists
                if (map.getLayer('3d-buildings')) {
                    map.removeLayer('3d-buildings');
                }
                
                // Add MapTiler 3D buildings source and layer
                if (!map.getSource('maptiler-buildings')) {
                    map.addSource('maptiler-buildings', {
                        'type': 'vector',
                        'url': `https://api.maptiler.com/tiles/v3/tiles.json?key=${MAPTILER_KEY}`
                    });
                }
                
                // Add 3D buildings layer
                map.addLayer({
                    'id': '3d-buildings',
                    'source': 'maptiler-buildings',
                    'source-layer': 'building',
                    'type': 'fill-extrusion',
                    'minzoom': 14,
                    'paint': {
                        'fill-extrusion-color': [
                            'case',
                            ['has', 'colour'],
                            ['get', 'colour'],
                            '#aaa'
                        ],
                        'fill-extrusion-height': [
                            'case',
                            ['has', 'render_height'],
                            ['get', 'render_height'],
                            ['case',
                                ['has', 'height'],
                                ['get', 'height'],
                                5
                            ]
                        ],
                        'fill-extrusion-base': [
                            'case',
                            ['has', 'render_min_height'],
                            ['get', 'render_min_height'],
                            0
                        ],
                        'fill-extrusion-opacity': 0.8
                    }
                });
                
                // Initially hide buildings
                map.setLayoutProperty('3d-buildings', 'visibility', 'none');
                isBuildingsEnabled = false;
                document.getElementById('toggleBuildings').classList.remove('active');
                
            } catch (error) {
                console.warn('Could not setup 3D buildings:', error);
                // Fallback: try to use any existing building layers from the style
                const layers = map.getStyle().layers;
                const buildingLayer = layers.find(layer => 
                    layer.type === 'fill-extrusion' && 
                    (layer.id.includes('building') || layer['source-layer'] === 'building')
                );
                
                if (buildingLayer) {
                    map.setLayoutProperty(buildingLayer.id, 'visibility', 'none');
                    // Update the layer ID for toggle functionality
                    window.buildingLayerId = buildingLayer.id;
                }
            }
        }
        
        function hideDuplicateLabels() {
            try {
                const style = map.getStyle();
                if (!style || !style.layers) return;
                
                // Hide duplicate text/symbol layers while keeping roads and 3D features
                style.layers.forEach((layer, index) => {
                    if (layer.type === 'symbol' && 
                        (layer.layout && layer.layout['text-field']) &&
                        (layer.id.includes('place') || 
                         layer.id.includes('poi') || 
                         layer.id.includes('label') ||
                         layer.id.includes('text'))) {
                        
                        // Only hide secondary label layers, keep primary ones
                        if (index > 10) { // Keep first few essential label layers
                            map.setLayoutProperty(layer.id, 'visibility', 'none');
                        }
                    }
                });
                
                console.log('Duplicate labels hidden');
            } catch (error) {
                console.warn('Could not hide duplicate labels:', error);
            }
        }
        
        function setupTrafficLayer() {
            // WARNING: This uses unofficial Google Maps tiles which may violate ToS
            // For production, use official APIs like HERE, TomTom, or Mapbox Traffic
            try {
                if (!map.getSource('google-traffic')) {
                    map.addSource('google-traffic', {
                        'type': 'raster',
                        'tiles': [
                            'https://mt0.google.com/vt/lyrs=h@159000000,traffic|seconds_into_week:-1&hl=en&gl=ph&x={x}&y={y}&z={z}'
                        ],
                        'tileSize': 256,
                        'attribution': 'Unofficial Google Maps data'
                    });
                }
                
                map.addLayer({
                    'id': 'google-traffic-layer',
                    'type': 'raster',
                    'source': 'google-traffic',
                    'layout': {
                        'visibility': 'visible'
                    },
                    'paint': {
                        'raster-opacity': 0.8
                    }
                });
                
                console.log('Traffic layer setup (unofficial)');
                
            } catch (error) {
                console.warn('Could not setup traffic layer:', error);
            }
        }

        function setupMapControls() {
            // 3D Toggle
            document.getElementById('toggle3D').addEventListener('click', () => {
                is3DEnabled = !is3DEnabled;
                const btn = document.getElementById('toggle3D');
                
                if (is3DEnabled) {
                    map.easeTo({ pitch: 60, duration: 1000 });
                    btn.classList.add('active');
                } else {
                    map.easeTo({ pitch: 0, duration: 1000 });
                    btn.classList.remove('active');
                }
            });

            // Reset North
            document.getElementById('resetNorth').addEventListener('click', () => {
                map.easeTo({ bearing: 0, duration: 500 });
            });

            // Terrain Toggle
            document.getElementById('toggleTerrain').addEventListener('click', () => {
                isTerrainEnabled = !isTerrainEnabled;
                const btn = document.getElementById('toggleTerrain');
                
                if (isTerrainEnabled) {
                    map.addSource('mapbox-dem', {
                        'type': 'raster-dem',
                        'url': `https://api.maptiler.com/tiles/terrain-rgb-v2/tiles.json?key=${MAPTILER_KEY}`,
                        'tileSize': 256
                    });
                    map.setTerrain({ 'source': 'mapbox-dem', 'exaggeration': 1.5 });
                    btn.classList.add('active');
                } else {
                    map.setTerrain(null);
                    if (map.getSource('mapbox-dem')) {
                        map.removeSource('mapbox-dem');
                    }
                    btn.classList.remove('active');
                }
            });

            // Buildings Toggle
            document.getElementById('toggleBuildings').addEventListener('click', () => {
                isBuildingsEnabled = !isBuildingsEnabled;
                const btn = document.getElementById('toggleBuildings');
                
                try {
                    const layerId = window.buildingLayerId || '3d-buildings';
                    
                    if (isBuildingsEnabled) {
                        // Ensure layer exists before showing
                        if (!map.getLayer(layerId)) {
                            setupBuildingsLayer();
                        }
                        map.setLayoutProperty(layerId, 'visibility', 'visible');
                        btn.classList.add('active');
                    } else {
                        if (map.getLayer(layerId)) {
                            map.setLayoutProperty(layerId, 'visibility', 'none');
                        }
                        btn.classList.remove('active');
                    }
                } catch (error) {
                    console.warn('Buildings layer not available:', error);
                    isBuildingsEnabled = false;
                    btn.classList.remove('active');
                }
            });

            // Refresh Pins Toggle
            document.getElementById('refreshPins').addEventListener('click', () => {
                loadTruckSchedules();
                // Visual feedback
                const btn = document.getElementById('refreshPins');
                btn.style.transform = 'rotate(360deg)';
                setTimeout(() => {
                    btn.style.transform = 'rotate(0deg)';
                }, 300);
            });

            // Satellite Toggle
            document.getElementById('toggleSatellite').addEventListener('click', () => {
                isSatelliteEnabled = !isSatelliteEnabled;
                const btn = document.getElementById('toggleSatellite');
                
                if (isSatelliteEnabled) {
                    map.setStyle(`https://api.maptiler.com/maps/hybrid/style.json?key=${MAPTILER_KEY}`);
                    btn.classList.add('active');
                } else {
                    map.setStyle(`https://api.maptiler.com/maps/streets-v2/style.json?key=${MAPTILER_KEY}`);
                    btn.classList.remove('active');
                }
                
                // Re-add markers, buildings, and traffic after style change
                map.once('styledata', () => {
                    loadTruckSchedules();
                    hideDuplicateLabels(); // Hide duplicate labels on style change
                    if (isBuildingsEnabled) {
                        setupBuildingsLayer();
                        setTimeout(() => {
                            if (map.getLayer('3d-buildings')) {
                                map.setLayoutProperty('3d-buildings', 'visibility', 'visible');
                            }
                        }, 100);
                    }
                    // Always show traffic after style change
                    setupTrafficLayer();
                });
            });
            

            // Fullscreen Toggle
            document.getElementById('toggleFullscreen').addEventListener('click', () => {
                isFullscreenEnabled = !isFullscreenEnabled;
                const btn = document.getElementById('toggleFullscreen');
                const mapPanel = document.querySelector('.map-panel');
                
                if (isFullscreenEnabled) {
                    mapPanel.classList.add('fullscreen');
                    btn.classList.add('active');
                } else {
                    mapPanel.classList.remove('fullscreen');
                    btn.classList.remove('active');
                }
                
                // Resize map after fullscreen toggle
                setTimeout(() => {
                    map.resize();
                }, 100);
            });
        }


        function editAnnouncement() {
            document.getElementById('announcementSection').style.display = 'none';
            document.getElementById('editAnnouncementSection').style.display = 'block';
            document.getElementById('announcementTextarea').value = "";
            document.getElementById('charCount').textContent = "0";
            
            // Add character counter
            const textarea = document.getElementById('announcementTextarea');
            textarea.addEventListener('input', function() {
                document.getElementById('charCount').textContent = this.value.length;
            });
        }

        async function sendAnnouncement() {
            const text = document.getElementById('announcementTextarea').value.trim();
            const sendBtn = document.getElementById('sendAnnouncementBtn');
            
            if (!text) {
                showError('Please enter an announcement message.');
                return;
            }

            // Get and validate duration
            const durationHours = parseInt(document.getElementById('announcementDuration').value);
            if (isNaN(durationHours) || durationHours < 1 || durationHours > 24) {
                showError('Please enter a valid duration between 1 and 24 hours.');
                return;
            }

            // Disable button and show loading state
            sendBtn.disabled = true;
            const isEditing = currentEditingId !== null;
            sendBtn.innerHTML = `
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="margin-right: 4px; animation: spin 1s linear infinite;">
                    <path d="M21 12a9 9 0 11-6.219-8.56"/>
                </svg>
                ${isEditing ? 'Updating...' : 'Sending...'}
            `;

            try {
                const now = new Date();
                
                if (isEditing) {
                    // Update existing announcement
                    const updateData = {
                        message: text,
                        updatedAt: firebase.firestore.Timestamp.fromDate(now)
                    };
                    
                    await db.collection('announcements').doc(currentEditingId).update(updateData);
                    showSuccess('Announcement updated successfully!');
                } else {
                    // Create new announcement with custom duration
                    const expiryDate = new Date(now.getTime() + durationHours * 60 * 60 * 1000);
                    
                    const announcementData = {
                        message: text,
                        createdAt: firebase.firestore.Timestamp.fromDate(now),
                        expiresAt: firebase.firestore.Timestamp.fromDate(expiryDate),
                        createdBy: 'Administrator',
                        isActive: true
                    };

                    await db.collection('announcements').add(announcementData);
                    showSuccess('Announcement sent successfully!');
                }
                
                cancelAnnouncement();

            } catch (error) {
                console.error('Error with announcement:', error);
                showError(`Error ${isEditing ? 'updating' : 'sending'} announcement. Please try again.`);
            } finally {
                // Reset button
                sendBtn.disabled = false;
                sendBtn.innerHTML = `
                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="margin-right: 4px;">
                        <line x1="22" y1="2" x2="11" y2="13"></line>
                        <polygon points="22,2 15,22 11,13 2,9"></polygon>
                    </svg>
                    ${isEditing ? 'Update' : 'Send'}
                `;
            }
        }

        function displayAnnouncementItem(announcement, id) {
            const createdAt = announcement.createdAt instanceof Date ? announcement.createdAt : announcement.createdAt.toDate();
            const expiresAt = announcement.expiresAt instanceof Date ? announcement.expiresAt : announcement.expiresAt.toDate();
            
            return `
                <div class="announcement-item" style="margin-bottom: 12px; padding: 12px; border: 1px solid #e5e7eb; border-radius: 6px; background: #f9fafb; position: relative;">
                    <div style="display: flex; justify-content: space-between; align-items: flex-start; gap: 12px;">
                        <div style="flex: 1;">
                            <p class="annc-body" style="margin: 0 0 8px 0;">${announcement.message}</p>
                            <div class="annc-meta">
                                <small style="color: #6b7280; font-size: 12px;">
                                    Posted: ${createdAt.toLocaleString()} | 
                                    Expires: ${expiresAt.toLocaleString()}
                                </small>
                            </div>
                        </div>
                        <div style="display: flex; gap: 6px; flex-shrink: 0;">
                            <button onclick="editAnnouncement('${id}', '${announcement.message.replace(/'/g, "\\'")}')"
                                style="padding: 4px 8px; border: 1px solid #d1d5db; border-radius: 4px; background: white; cursor: pointer; font-size: 12px; color: #374151; transition: all 0.2s;"
                                onmouseover="this.style.background='#f9fafb'"
                                onmouseout="this.style.background='white'">
                                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                    <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"></path>
                                    <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"></path>
                                </svg>
                                Edit
                            </button>
                            <button onclick="deleteAnnouncement('${id}')"
                                style="padding: 4px 8px; border: 1px solid #dc2626; border-radius: 4px; background: white; cursor: pointer; font-size: 12px; color: #dc2626; transition: all 0.2s;"
                                onmouseover="this.style.background='#fee2e2'"
                                onmouseout="this.style.background='white'">
                                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                    <polyline points="3,6 5,6 21,6"></polyline>
                                    <path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"></path>
                                    <line x1="10" y1="11" x2="10" y2="17"></line>
                                    <line x1="14" y1="11" x2="14" y2="17"></line>
                                </svg>
                                Delete
                            </button>
                        </div>
                    </div>
                </div>
            `;
        }

        function loadAllAnnouncements() {
            console.log('Loading all announcements...');
            
            // First try to load all announcements without complex queries
            db.collection('announcements')
                .onSnapshot((snapshot) => {
                    console.log('Raw announcements snapshot:', snapshot.size, 'documents');
                    const announcementsList = document.getElementById('announcementsList');
                    
                    if (snapshot.empty) {
                        announcementsList.innerHTML = '<p class="annc-body" style="color: #6b7280;">No announcements yet.</p>';
                        return;
                    }
                    
                    const now = new Date();
                    let html = '';
                    let activeCount = 0;
                    
                    snapshot.forEach((doc) => {
                        const announcement = doc.data();
                        console.log('Processing announcement:', announcement);
                        
                        // Check if announcement is still active
                        const expiresAt = announcement.expiresAt.toDate();
                        const isActive = announcement.isActive && expiresAt > now;
                        
                        if (isActive) {
                            html += displayAnnouncementItem(announcement, doc.id);
                            activeCount++;
                        }
                    });
                    
                    console.log('Active announcements:', activeCount);
                    
                    if (activeCount === 0) {
                        announcementsList.innerHTML = '<p class="annc-body" style="color: #6b7280;">No active announcements.</p>';
                    } else {
                        announcementsList.innerHTML = html;
                    }
                }, (error) => {
                    console.error('Error loading announcements:', error);
                    document.getElementById('announcementsList').innerHTML = '<p class="annc-body" style="color: #dc2626;">Error loading announcements: ' + error.message + '</p>';
                });
        }

        async function archiveExpiredAnnouncements() {
            try {
                const now = firebase.firestore.Timestamp.now();
                const expiredSnapshot = await db.collection('announcements')
                    .where('expiresAt', '<=', now)
                    .where('isActive', '==', true)
                    .get();

                const batch = db.batch();
                const archiveBatch = db.batch();
                
                for (const doc of expiredSnapshot.docs) {
                    const data = doc.data();
                    // Archive the announcement
                    await db.collection('archived_announcements').add({
                        ...data,
                        archivedAt: now,
                        originalId: doc.id
                    });
                    
                    // Update the original to mark as archived
                    batch.update(doc.ref, {
                        isActive: false,
                        archivedAt: now
                    });
                }

                if (!expiredSnapshot.empty) {
                    await batch.commit();
                    console.log(`Archived ${expiredSnapshot.size} expired announcements`);
                }
            } catch (error) {
                console.error('Error archiving expired announcements:', error);
            }
        }

        function cancelAnnouncement() {
            document.getElementById('announcementSection').style.display = 'block';
            document.getElementById('editAnnouncementSection').style.display = 'none';
            currentEditingId = null;
        }

        function viewArchivedAnnouncements() {
            // Create modal for archived announcements
            const modal = document.createElement('div');
            modal.style.cssText = `
                position: fixed;
                top: 0;
                left: 0;
                right: 0;
                bottom: 0;
                background: rgba(0, 0, 0, 0.5);
                display: flex;
                align-items: center;
                justify-content: center;
                z-index: 10000;
            `;
            
            modal.innerHTML = `
                <div style="background: white; border-radius: 12px; padding: 24px; max-width: 600px; width: 90%; max-height: 80vh; overflow-y: auto;">
                    <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 20px;">
                        <h3 style="margin: 0; font-size: 20px; font-weight: 600;">Archived Announcements</h3>
                        <button onclick="this.closest('div[style*='position: fixed']').remove()" style="background: none; border: none; cursor: pointer; padding: 4px;">
                            <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                <line x1="18" y1="6" x2="6" y2="18"></line>
                                <line x1="6" y1="6" x2="18" y2="18"></line>
                            </svg>
                        </button>
                    </div>
                    <div id="archivedAnnouncementsList" style="min-height: 200px;">
                        <div style="text-align: center; padding: 20px; color: #6b7280;">
                            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="margin: 0 auto; animation: spin 1s linear infinite;">
                                <path d="M21 12a9 9 0 11-6.219-8.56"/>
                            </svg>
                            <p style="margin-top: 8px;">Loading archived announcements...</p>
                        </div>
                    </div>
                </div>
            `;
            
            document.body.appendChild(modal);
            
            // Load archived announcements
            db.collection('archived_announcements')
                .orderBy('archivedAt', 'desc')
                .limit(20)
                .get()
                .then((snapshot) => {
                    const listContainer = document.getElementById('archivedAnnouncementsList');
                    
                    if (snapshot.empty) {
                        listContainer.innerHTML = '<p style="text-align: center; color: #6b7280; padding: 20px;">No archived announcements.</p>';
                        return;
                    }
                    
                    let html = '';
                    snapshot.forEach((doc) => {
                        const data = doc.data();
                        const createdAt = data.createdAt.toDate();
                        const archivedAt = data.archivedAt.toDate();
                        
                        html += `
                            <div style="padding: 12px; border: 1px solid #e5e7eb; border-radius: 6px; margin-bottom: 12px; background: #f9fafb;">
                                <p style="margin: 0 0 8px 0; color: #374151;">${data.message}</p>
                                <small style="color: #6b7280; font-size: 12px;">
                                    Created: ${createdAt.toLocaleString()} | Archived: ${archivedAt.toLocaleString()}
                                </small>
                            </div>
                        `;
                    });
                    
                    listContainer.innerHTML = html;
                })
                .catch((error) => {
                    console.error('Error loading archived announcements:', error);
                    document.getElementById('archivedAnnouncementsList').innerHTML = 
                        '<p style="text-align: center; color: #dc2626; padding: 20px;">Error loading archived announcements.</p>';
                });
        }

        let currentEditingId = null;

        function editAnnouncement(id, message) {
            if (typeof id === 'undefined') {
                // This is creating a new announcement
                document.getElementById('announcementSection').style.display = 'none';
                document.getElementById('editAnnouncementSection').style.display = 'block';
                document.getElementById('announcementTextarea').value = "";
                document.getElementById('charCount').textContent = "0";
                currentEditingId = null;
            } else {
                // This is editing an existing announcement
                document.getElementById('announcementSection').style.display = 'none';
                document.getElementById('editAnnouncementSection').style.display = 'block';
                document.getElementById('announcementTextarea').value = message;
                document.getElementById('charCount').textContent = message.length;
                currentEditingId = id;
            }
            
            // Add character counter
            const textarea = document.getElementById('announcementTextarea');
            textarea.removeEventListener('input', updateCharCount); // Remove existing listener
            textarea.addEventListener('input', updateCharCount);
        }

        function updateCharCount() {
            document.getElementById('charCount').textContent = this.value.length;
        }

        async function deleteAnnouncement(id) {
            showConfirm(
                'Are you sure you want to delete this announcement? This action cannot be undone.',
                async () => {
                    try {
                        await db.collection('announcements').doc(id).delete();
                        showSuccess('Announcement deleted successfully!');
                    } catch (error) {
                        console.error('Error deleting announcement:', error);
                        showError('Error deleting announcement. Please try again.');
                    }
                }
            );
        }

        // Load recent reports from Firebase
        function loadRecentReports() {
            console.log('Loading recent reports from Firebase...');
            
            db.collection('reports')
                .orderBy('createdAt', 'desc')
                .limit(5)
                .onSnapshot((snapshot) => {
                    const reportsList = document.getElementById('recentReportsList');
                    
                    if (snapshot.empty) {
                        reportsList.innerHTML = `
                            <div style="text-align: center; padding: 20px; color: #6b7280;">
                                <p>No reports yet.</p>
                            </div>
                        `;
                        document.getElementById('totalReportsCount').textContent = '0';
                        document.getElementById('criticalIssuesCount').textContent = '0';
                        return;
                    }
                    
                    let html = '';
                    let totalReports = 0;
                    let criticalCount = 0;
                    
                    // Get total count and critical issues
                    db.collection('reports').get().then((allSnapshot) => {
                        totalReports = allSnapshot.size;
                        document.getElementById('totalReportsCount').textContent = totalReports;
                        
                        // Count critical issues (high priority pending reports)
                        allSnapshot.forEach((doc) => {
                            const report = doc.data();
                            if (report.status === 'pending' && report.priority === 'high') {
                                criticalCount++;
                            }
                        });
                        document.getElementById('criticalIssuesCount').textContent = criticalCount;
                    });
                    
                    snapshot.forEach((doc) => {
                        const report = doc.data();
                        const createdAt = report.createdAt ? report.createdAt.toDate() : new Date();
                        
                        // Determine status pill color
                        let pillClass = 'pill-pending';
                        if (report.status === 'resolved') {
                            pillClass = 'pill-success';
                        } else if (report.status === 'unresolved') {
                            pillClass = 'pill-danger';
                        }
                        
                        html += `
                            <div class="report-row">
                                <div class="report-main">
                                    <div class="report-title">${report.title || 'Untitled Report'}</div>
                                    <div class="report-sub">
                                        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                            <path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z"></path>
                                            <circle cx="12" cy="10" r="3"></circle>
                                        </svg>
                                        <span>${report.location || 'Unknown Location'}</span>
                                    </div>
                                    <div class="report-date">${createdAt.toLocaleDateString()}</div>
                                </div>
                                <span class="pill ${pillClass}">${report.status ? report.status.charAt(0).toUpperCase() + report.status.slice(1) : 'Pending'}</span>
                            </div>
                        `;
                    });
                    
                    reportsList.innerHTML = html;
                }, (error) => {
                    console.error('Error loading reports:', error);
                    document.getElementById('recentReportsList').innerHTML = `
                        <div style="text-align: center; padding: 20px; color: #dc2626;">
                            <p>Error loading reports</p>
                        </div>
                    `;
                });
        }

        // Initialize map when page loads
        document.addEventListener('DOMContentLoaded', function() {
            initMap();
            loadUserCounts(); // Load user role counts
            loadAllAnnouncements(); // Load all announcements
            loadRecentReports(); // Load recent reports from Firebase
            
            // Setup toggle button event listener
            document.getElementById('toggleUserView').addEventListener('click', toggleUserBreakdown);
            
            // Archive expired announcements on load
            archiveExpiredAnnouncements();
            
            // Set up periodic archiving every hour
            setInterval(archiveExpiredAnnouncements, 60 * 60 * 1000);
        });
    </script>
</body>
</html>
