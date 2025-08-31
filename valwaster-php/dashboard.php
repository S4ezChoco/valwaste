<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Dashboard - ValWaste Admin</title>
    <link rel="stylesheet" href="assets/css/styles.css">
    <script src="https://unpkg.com/maplibre-gl@3.6.2/dist/maplibre-gl.js"></script>
    <link href="https://unpkg.com/maplibre-gl@3.6.2/dist/maplibre-gl.css" rel="stylesheet" />
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
                    <div class="card stats-card">
                        <div class="stats-meta">
                            <p class="stats-label">Total Users</p>
                            <h3 class="stats-value" id="totalUsers">3</h3>
                            <p class="stats-sub">Registered in the system</p>
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
                            <h3 class="stats-value" id="totalReports">0</h3>
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
                            <h3 class="stats-value" id="totalTrucks">0</h3>
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
                            <div class="report-row">
                                <div class="report-main">
                                    <div class="report-title">Garbage overflow at Main Street</div>
                                    <div class="report-sub">
                                        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                            <path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z"></path>
                                            <circle cx="12" cy="10" r="3"></circle>
                                        </svg>
                                        <span>Block 5, Main Street</span>
                                    </div>
                                    <div class="report-date">5/12/2023</div>
                                </div>
                                <span class="pill pill-pending">Pending</span>
                            </div>

                            <div class="report-row">
                                <div class="report-main">
                                    <div class="report-title">Truck missed scheduled collection</div>
                                    <div class="report-sub">
                                        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                            <path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z"></path>
                                            <circle cx="12" cy="10" r="3"></circle>
                                        </svg>
                                        <span>Green Valley Subdivision</span>
                                    </div>
                                    <div class="report-date">5/11/2023</div>
                                </div>
                                <span class="pill pill-pending">Pending</span>
                            </div>

                            <div class="report-row">
                                <div class="report-main">
                                    <div class="report-title">Illegal dumping spotted</div>
                                    <div class="report-sub">
                                        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                            <path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z"></path>
                                            <circle cx="12" cy="10" r="3"></circle>
                                        </svg>
                                        <span>Riverside Park</span>
                                    </div>
                                    <div class="report-date">5/11/2023</div>
                                </div>
                                <span class="pill pill-pending">Pending</span>
                            </div>
                        </div>
                        <button class="btn-outline" type="button" onclick="window.location.href='report-management.php'">
                            View All Reports
                        </button>
                    </aside>
                </section>

                <!-- Latest Announcement -->
                <section class="card annc-card">
                    <h4 class="annc-title">Latest Announcement</h4>
                    <div id="announcementSection">
                        <p class="annc-body" id="announcementText">No announcement yet.</p>
                        <div class="annc-actions">
                            <button type="button" class="btn-outline" onclick="editAnnouncement()">
                                Edit Announcement
                            </button>
                        </div>
                    </div>
                    
                    <div id="editAnnouncementSection" style="display: none;">
                        <textarea class="annc-textarea" id="announcementTextarea" placeholder="Type your announcement..."></textarea>
                        <div class="annc-actions">
                            <button type="button" class="btn-primary" onclick="saveAnnouncement()">Save</button>
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

    <script type="module" src="assets/js/auth.js"></script>
    <script>
        // Initialize map with MapLibre GL JS and MapTiler
        let map;
        let currentAnnouncement = "No announcement yet.";
        let is3DEnabled = false;
        let isTerrainEnabled = false;
        let isBuildingsEnabled = false;
        let isSatelliteEnabled = false;
        let isFullscreenEnabled = false;
        let truckMarkers = [];

        // Fixed truck locations (no randomizer)
        const truckLocations = [
            { id: "Truck-01", position: [120.957, 14.734], status: "idle", note: "Idle" },
            { id: "Truck-02", position: [120.991, 14.716], status: "route", note: "On route" },
            { id: "Truck-03", position: [120.972, 14.751], status: "collecting", note: "Collecting" }
        ];

        // MapTiler API key
        const MAPTILER_KEY = 'Kr1k642bLPyqdCL0A5yM';

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

            // Add navigation control
            map.addControl(new maplibregl.NavigationControl(), 'top-right');

            // Enable right-click drag for 3D rotation
            map.dragRotate.enable();
            map.touchZoomRotate.enableRotation();


            // Add truck markers when map loads
            map.on('load', () => {
                // Add initial truck markers
                addTruckMarkers();

                // Setup 3D buildings layer (initially hidden)
                setupBuildingsLayer();
            });

            // Setup control event listeners
            setupMapControls();
        }

        function addTruckMarkers() {
            // Clear existing markers
            truckMarkers.forEach(marker => marker.remove());
            truckMarkers = [];

            // Add truck markers with fixed positions
            truckLocations.forEach((truck) => {
                const el = document.createElement('div');
                el.className = 'truck-marker';
                el.style.cssText = `
                    width: 20px; height: 20px; border-radius: 50%; 
                    border: 2px solid white; box-shadow: 0 2px 4px rgba(0,0,0,0.3);
                    background: ${truck.status === 'idle' ? '#3AC84D' : truck.status === 'route' ? '#3B82F6' : '#F59E0B'};
                `;

                const popup = new maplibregl.Popup({ offset: 25 })
                    .setHTML(`<strong>${truck.id}</strong><br/>Status: ${truck.status}<br/>${truck.note}`);

                const marker = new maplibregl.Marker(el)
                    .setLngLat(truck.position)
                    .setPopup(popup)
                    .addTo(map);
                    
                truckMarkers.push(marker);
            });
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
                addTruckMarkers();
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
                
                // Re-add markers and buildings after style change
                map.once('styledata', () => {
                    addTruckMarkers();
                    if (isBuildingsEnabled) {
                        setupBuildingsLayer();
                        setTimeout(() => {
                            if (map.getLayer('3d-buildings')) {
                                map.setLayoutProperty('3d-buildings', 'visibility', 'visible');
                            }
                        }, 100);
                    }
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
            document.getElementById('announcementTextarea').value = currentAnnouncement === "No announcement yet." ? "" : currentAnnouncement;
        }

        function saveAnnouncement() {
            const newText = document.getElementById('announcementTextarea').value.trim();
            currentAnnouncement = newText || "No announcement yet.";
            document.getElementById('announcementText').textContent = currentAnnouncement;
            cancelAnnouncement();
        }

        function cancelAnnouncement() {
            document.getElementById('announcementSection').style.display = 'block';
            document.getElementById('editAnnouncementSection').style.display = 'none';
        }

        // Initialize map when page loads
        document.addEventListener('DOMContentLoaded', function() {
            initMap();
        });
    </script>
</body>
</html>
