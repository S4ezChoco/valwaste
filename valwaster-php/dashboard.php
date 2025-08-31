<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Dashboard - ValWaste Admin</title>
    <link rel="stylesheet" href="assets/css/styles.css">
    <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" />
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

    <script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
    <script type="module" src="assets/js/auth.js"></script>
    <script>
        // Initialize map
        let map;
        let currentAnnouncement = "No announcement yet.";

        function initMap() {
            // Valenzuela City center coordinates
            const center = [14.72, 120.97];
            
            map = L.map('map').setView(center, 12);
            
            L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
                attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
            }).addTo(map);

            // Sample truck markers
            const trucks = [
                { id: "Truck-01", position: [14.734, 120.957], status: "idle", note: "Idle" },
                { id: "Truck-02", position: [14.716, 120.991], status: "route", note: "On route" },
                { id: "Truck-03", position: [14.751, 120.972], status: "collecting", note: "Collecting" }
            ];

            // Create custom icons
            const createIcon = (color) => L.divIcon({
                html: `<div style="background: ${color}; width: 20px; height: 20px; border-radius: 50%; border: 2px solid white; box-shadow: 0 2px 4px rgba(0,0,0,0.3);"></div>`,
                iconSize: [20, 20],
                iconAnchor: [10, 10]
            });

            const icons = {
                idle: createIcon('#3AC84D'),
                route: createIcon('#3B82F6'),
                collecting: createIcon('#F59E0B')
            };

            // Add truck markers
            trucks.forEach(truck => {
                L.marker(truck.position, { icon: icons[truck.status] })
                    .bindPopup(`<strong>${truck.id}</strong><br/>Status: ${truck.status}<br/>${truck.note}`)
                    .addTo(map);
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
