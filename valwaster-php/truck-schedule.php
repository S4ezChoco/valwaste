<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Truck Schedule - ValWaste Admin</title>
    <link rel="stylesheet" href="assets/css/styles.css">
    <script src="https://unpkg.com/maplibre-gl@3.6.2/dist/maplibre-gl.js"></script>
    <link href="https://unpkg.com/maplibre-gl@3.6.2/dist/maplibre-gl.css" rel="stylesheet" />
    <style>
        .dropdown-container {
            position: relative;
            width: 100%;
        }
        
        /* Resident Location Styling */
        .street-item[data-street="Resident Location"] {
            background: linear-gradient(135deg, #f0f9ff 0%, #e0f2fe 100%);
            border: 2px solid #0ea5e9;
            border-radius: 8px;
            margin-bottom: 8px;
            padding: 8px;
        }
        
        .street-item[data-street="Resident Location"] .street-name {
            font-weight: bold;
            color: #0369a1;
        }
        
        .street-item[data-street="Resident Location"] .street-address {
            color: #0c4a6e;
            font-size: 0.9em;
        }
        
        .street-item[data-street="Resident Location"] input[type="checkbox"]:checked + .checkmark {
            background-color: #0ea5e9;
            border-color: #0ea5e9;
        }
        
        /* Resident Location Marker Styling */
        .resident-location-marker {
            background: none !important;
            border: none !important;
        }
        
        .resident-location-marker div {
            animation: pulse 2s infinite;
        }
        
        @keyframes pulse {
            0% {
                transform: scale(1);
                opacity: 1;
            }
            50% {
                transform: scale(1.1);
                opacity: 0.8;
            }
            100% {
                transform: scale(1);
                opacity: 1;
            }
        }
        .dropdown-button {
            width: 100%;
            padding: 12px 16px;
            border: 1px solid #d1d5db;
            border-radius: 8px;
            background: white;
            text-align: left;
            cursor: pointer;
            display: flex;
            justify-content: space-between;
            align-items: center;
            font-size: 14px;
            color: #374151;
        }
        .dropdown-button:hover {
            border-color: #9ca3af;
        }
        .dropdown-button.active {
            border-color: #3b82f6;
            box-shadow: 0 0 0 3px rgba(59, 130, 246, 0.1);
        }
        .dropdown-menu {
            position: absolute;
            top: 100%;
            left: 0;
            right: 0;
            background: white;
            border: 1px solid #d1d5db;
            border-radius: 8px;
            box-shadow: 0 10px 25px rgba(0, 0, 0, 0.1);
            z-index: 2000;
            max-height: 200px;
            overflow-y: auto;
            display: none;
        }
        .dropdown-menu.show {
            display: block;
        }
        .dropdown-item {
            padding: 10px 16px;
            cursor: pointer;
            border-bottom: 1px solid #f3f4f6;
            display: flex;
            align-items: center;
            gap: 8px;
        }
        .dropdown-item:last-child {
            border-bottom: none;
        }
        .dropdown-item:hover {
            background: #f9fafb;
        }
        .dropdown-item.selected {
            background: #eff6ff;
            color: #1d4ed8;
        }
        .dropdown-item input[type="checkbox"] {
            margin: 0;
        }
        .location-map-container {
            height: 400px;
            min-height: 300px;
            border: 1px solid #d1d5db;
            border-radius: 8px;
            margin-top: 8px;
            position: relative;
            overflow: hidden;
            background: #f3f4f6;
            display: flex;
            flex-direction: column;
        }
        
        #location-map {
            flex: 1;
            width: 100%;
            min-height: 300px;
            position: relative;
            z-index: 1;
        }
        
        .mapboxgl-canvas-container {
            position: absolute !important;
            top: 0;
            left: 0;
            right: 0;
            bottom: 0;
        }
        .map-search-container {
            position: absolute;
            top: 10px;
            left: 10px;
            right: 60px;
            z-index: 1000;
        }
        .map-search-input {
            width: 100%;
            padding: 10px 40px 10px 12px;
            border: 1px solid #d1d5db;
            border-radius: 6px;
            background: white;
            font-size: 14px;
        }
        .map-search-btn {
            position: absolute;
            right: 8px;
            top: 50%;
            transform: translateY(-50%);
            background: none;
            border: none;
            cursor: pointer;
            color: #6b7280;
        }
        .streets-checklist {
            max-height: 200px;
            overflow-y: auto;
            border: 1px solid #e5e7eb;
            border-radius: 6px;
            margin-top: 8px;
        }
        .street-item {
            padding: 8px 12px;
            border-bottom: 1px solid #f3f4f6;
            display: flex;
            align-items: center;
            gap: 8px;
        }
        .street-item:last-child {
            border-bottom: none;
        }
        .street-item:hover {
            background: #f9fafb;
        }
        .coordinates-display {
            margin-top: 8px;
            padding: 8px 12px;
            background: #f9fafb;
            border-radius: 6px;
            font-size: 12px;
            color: #6b7280;
        }
        .schedule-event {
            background: #3b82f6;
            color: white;
            padding: 2px 6px;
            border-radius: 3px;
            font-size: 10px;
            margin-top: 28px;
            cursor: pointer;
            position: absolute;
            left: 8px;
            right: 8px;
            top: 8px;
        }
        .schedule-event:hover {
            background: #2563eb;
        }
        .schedule-details-content {
            display: flex;
            flex-direction: column;
            gap: 16px;
        }
        .detail-row {
            display: flex;
            align-items: flex-start;
            gap: 12px;
        }
        .detail-label {
            font-weight: 600;
            color: #374151;
            min-width: 120px;
            flex-shrink: 0;
        }
        .detail-value {
            color: #6b7280;
            flex: 1;
        }
        .status-badge {
            display: inline-block;
            padding: 4px 8px;
            border-radius: 12px;
            font-size: 12px;
            font-weight: 500;
            text-transform: capitalize;
        }
        .status-badge.scheduled {
            background: #dbeafe;
            color: #1d4ed8;
        }
        .status-badge.in-progress {
            background: #fef3c7;
            color: #d97706;
        }
        .status-badge.completed {
            background: #d1fae5;
            color: #059669;
        }
        .schedule-more-btn {
            background: #6b7280;
            color: white;
            padding: 2px 6px;
            border-radius: 3px;
            font-size: 9px;
            cursor: pointer;
            position: absolute;
            left: 8px;
            right: 8px;
            border: none;
            text-align: center;
        }
        .schedule-more-btn:hover {
            background: #4b5563;
        }
        .day-schedules-container {
            display: flex;
            flex-direction: column;
            gap: 12px;
        }
        .day-schedule-item {
            border: 1px solid #e5e7eb;
            border-radius: 8px;
            padding: 16px;
            background: #f9fafb;
            cursor: pointer;
            transition: all 0.2s;
        }
        .day-schedule-item:hover {
            background: #f3f4f6;
            border-color: #d1d5db;
        }
        .day-schedule-header {
            display: flex;
            justify-content: between;
            align-items: center;
            margin-bottom: 8px;
        }
        .day-schedule-truck {
            font-weight: 600;
            color: #1f2937;
            font-size: 16px;
        }
        .day-schedule-time {
            color: #6b7280;
            font-size: 14px;
        }
        .day-schedule-details {
            display: flex;
            flex-direction: column;
            gap: 4px;
            font-size: 14px;
            color: #6b7280;
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
            <h1 class="page-title">Truck Schedule</h1>
        </div>

        <?php include 'components/sidebar.php'; ?>

        <main class="content">
            <div class="page-container">
                <section class="card sched-card">
                    <div class="sched-head">
                        <div>
                            <h3 class="sched-title">Truck Schedule</h3>
                            <p class="sched-sub">Manage truck collection schedules</p>
                        </div>
                        <div style="display: flex; align-items: center; gap: 12px;">
                            <button type="button" class="btn-outline" onclick="loadApprovedRequests()">
                                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="margin-right: 6px;">
                                    <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path>
                                    <polyline points="14,2 14,8 20,8"></polyline>
                                    <line x1="16" y1="13" x2="8" y2="13"></line>
                                    <line x1="16" y1="17" x2="8" y2="17"></line>
                                </svg>
                                Approved Requests
                            </button>
                            <button type="button" class="btn-primary" onclick="openCreateModal()">Create Schedule</button>
                        </div>
                    </div>

                    <div class="sched-monthrow">
                        <h4 class="sched-month" id="month-year-display">September 2025</h4>
                        <div class="sched-nav">
                            <div class="um-filter-wrap month-dd">
                                <button type="button" class="um-filter" onclick="toggleMonthDropdown()">
                                    <span id="month-display">September</span>
                                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                        <polyline points="6 9 12 15 18 9"></polyline>
                                    </svg>
                                </button>
                                <div class="um-menu month-dd-menu" id="month-dropdown" style="display: none;">
                                    <button type="button" class="um-menu-item" onclick="selectMonth(0)">
                                        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" class="um-check">
                                            <polyline points="20 6 9 17 4 12"></polyline>
                                        </svg>
                                        <span>January</span>
                                    </button>
                                    <button type="button" class="um-menu-item" onclick="selectMonth(1)">
                                        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" class="um-check">
                                            <polyline points="20 6 9 17 4 12"></polyline>
                                        </svg>
                                        <span>February</span>
                                    </button>
                                    <button type="button" class="um-menu-item" onclick="selectMonth(2)">
                                        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" class="um-check">
                                            <polyline points="20 6 9 17 4 12"></polyline>
                                        </svg>
                                        <span>March</span>
                                    </button>
                                    <button type="button" class="um-menu-item" onclick="selectMonth(3)">
                                        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" class="um-check">
                                            <polyline points="20 6 9 17 4 12"></polyline>
                                        </svg>
                                        <span>April</span>
                                    </button>
                                    <button type="button" class="um-menu-item" onclick="selectMonth(4)">
                                        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" class="um-check">
                                            <polyline points="20 6 9 17 4 12"></polyline>
                                        </svg>
                                        <span>May</span>
                                    </button>
                                    <button type="button" class="um-menu-item" onclick="selectMonth(5)">
                                        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" class="um-check">
                                            <polyline points="20 6 9 17 4 12"></polyline>
                                        </svg>
                                        <span>June</span>
                                    </button>
                                    <button type="button" class="um-menu-item" onclick="selectMonth(6)">
                                        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" class="um-check">
                                            <polyline points="20 6 9 17 4 12"></polyline>
                                        </svg>
                                        <span>July</span>
                                    </button>
                                    <button type="button" class="um-menu-item" onclick="selectMonth(7)">
                                        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" class="um-check">
                                            <polyline points="20 6 9 17 4 12"></polyline>
                                        </svg>
                                        <span>August</span>
                                    </button>
                                    <button type="button" class="um-menu-item active" onclick="selectMonth(8)">
                                        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" class="um-check">
                                            <polyline points="20 6 9 17 4 12"></polyline>
                                        </svg>
                                        <span>September</span>
                                    </button>
                                    <button type="button" class="um-menu-item" onclick="selectMonth(9)">
                                        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" class="um-check">
                                            <polyline points="20 6 9 17 4 12"></polyline>
                                        </svg>
                                        <span>October</span>
                                    </button>
                                    <button type="button" class="um-menu-item" onclick="selectMonth(10)">
                                        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" class="um-check">
                                            <polyline points="20 6 9 17 4 12"></polyline>
                                        </svg>
                                        <span>November</span>
                                    </button>
                                    <button type="button" class="um-menu-item" onclick="selectMonth(11)">
                                        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" class="um-check">
                                            <polyline points="20 6 9 17 4 12"></polyline>
                                        </svg>
                                        <span>December</span>
                                    </button>
                                </div>
                            </div>
                            <button class="btn-ghost-mini" onclick="previousMonth()">&lt;</button>
                            <button class="btn-soft-mini" onclick="goToToday()">Today</button>
                            <button class="btn-ghost-mini" onclick="nextMonth()">&gt;</button>
                        </div>
                    </div>

                    <div class="cal-grid cal-dow">
                        <div class="cal-dow-cell">Sun</div>
                        <div class="cal-dow-cell">Mon</div>
                        <div class="cal-dow-cell">Tue</div>
                        <div class="cal-dow-cell">Wed</div>
                        <div class="cal-dow-cell">Thu</div>
                        <div class="cal-dow-cell">Fri</div>
                        <div class="cal-dow-cell">Sat</div>
                    </div>

                    <div class="cal-grid" id="calendar-grid">
                        <!-- Calendar cells will be generated by JavaScript -->
                    </div>
                </section>
            </div>
        </main>
    </div>

    <!-- Create Schedule Modal -->
    <div class="um-modal sched-modal" id="create-schedule-modal" style="display: none;">
        <div class="um-modal-card large sched-modal-card" role="dialog" aria-modal="true" aria-labelledby="sched-title">
            <button class="um-modal-close" aria-label="Close" onclick="closeCreateModal()">
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <line x1="18" y1="6" x2="6" y2="18"></line>
                    <line x1="6" y1="6" x2="18" y2="18"></line>
                </svg>
            </button>

            <h3 id="sched-title" class="um-modal-title">Create Schedule</h3>
            <p class="um-modal-sub">Fill details</p>

            <form id="createScheduleForm" class="um-form sched-modal-scroll" onsubmit="handleCreateSchedule(event)">
                <label class="um-field">
                    <span class="um-label">Select Approved Request</span>
                    <div class="um-select-wrap">
                        <select class="um-select" id="approved-request-select" onchange="loadApprovedRequestDetails()">
                            <option value="" disabled selected>Select approved collection request</option>
                            <!-- Approved requests will be loaded from Firebase -->
                        </select>
                        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" class="um-select-caret">
                            <polyline points="6 9 12 15 18 9"></polyline>
                        </svg>
                    </div>
                </label>

                <label class="um-field">
                    <span class="um-label">Select Truck</span>
                    <div class="um-select-wrap">
                        <select class="um-select" id="truck-select" required>
                            <option value="" disabled selected>Truck</option>
                            <!-- Trucks will be loaded from Firebase -->
                        </select>
                        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" class="um-select-caret">
                            <polyline points="6 9 12 15 18 9"></polyline>
                        </svg>
                    </div>
                </label>

                <label class="um-field">
                    <span class="um-label">Date</span>
                    <input type="date" class="um-input" id="schedule-date" required>
                </label>

                <div class="um-row-2">
                    <label class="um-field">
                        <span class="um-label">Start</span>
                        <input type="time" step="900" class="um-input" id="start-time" value="08:00" required>
                    </label>
                    <label class="um-field">
                        <span class="um-label">End</span>
                        <input type="time" step="900" class="um-input" id="end-time" value="16:00" required>
                    </label>
                </div>

                <label class="um-field">
                    <span class="um-label">Driver</span>
                    <div class="dropdown-container">
                        <button type="button" class="dropdown-button" id="driver-dropdown-btn">
                            <span id="driver-selected-text">Select driver</span>
                            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                <polyline points="6 9 12 15 18 9"></polyline>
                            </svg>
                        </button>
                        <div class="dropdown-menu" id="driver-dropdown-menu">
                            <!-- Drivers will be loaded from Firebase -->
                        </div>
                    </div>
                    <input type="hidden" id="selected-driver" required>
                </label>

                <label class="um-field">
                    <span class="um-label">Waste Collectors (Select exactly 3)</span>
                    <div class="dropdown-container">
                        <button type="button" class="dropdown-button" id="collectors-dropdown-btn">
                            <span id="collectors-selected-text">Select waste collectors</span>
                            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                <polyline points="6 9 12 15 18 9"></polyline>
                            </svg>
                        </button>
                        <div class="dropdown-menu" id="collectors-dropdown-menu">
                            <!-- Waste collectors will be loaded from Firebase -->
                        </div>
                    </div>
                </label>

                <div class="um-field">
                    <span class="um-label">Location Selection</span>
                    <div class="location-map-container">
                        <div class="map-search-container">
                            <input type="text" class="map-search-input" id="street-search" placeholder="Search streets in Valenzuela...">
                            <button type="button" class="map-search-btn" onclick="searchStreets()">
                                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                    <circle cx="11" cy="11" r="8"></circle>
                                    <path d="m21 21-4.35-4.35"></path>
                                </svg>
                            </button>
                        </div>
                        <div id="location-map"></div>
                    </div>
                    <div class="coordinates-display" id="coordinates-display">
                        Click on the map to select a location
                    </div>
                </div>

                <div class="um-field">
                    <span class="um-label">Streets Checklist</span>
                    <div class="streets-checklist" id="streets-checklist">
                        <!-- Streets will be populated based on selected location -->
                    </div>
                </div>
            </form>

            <div class="sched-modal-actions">
                <button type="button" class="btn-ghost" onclick="closeCreateModal()">Cancel</button>
                <button type="submit" form="createScheduleForm" class="btn-primary">Create</button>
            </div>
        </div>
    </div>

    <!-- Schedule Details Modal -->
    <div class="um-modal sched-modal" id="schedule-details-modal" style="display: none;">
        <div class="um-modal-card large sched-modal-card" role="dialog" aria-modal="true" aria-labelledby="details-title">
            <button class="um-modal-close" aria-label="Close" onclick="closeDetailsModal()">
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <line x1="18" y1="6" x2="6" y2="18"></line>
                    <line x1="6" y1="6" x2="18" y2="18"></line>
                </svg>
            </button>

            <h3 id="details-title" class="um-modal-title">Schedule Details</h3>
            <p class="um-modal-sub">View schedule information</p>

            <div class="um-form sched-modal-scroll">
                <div class="schedule-details-content">
                    <div class="detail-row">
                        <span class="detail-label">Truck:</span>
                        <span class="detail-value" id="detail-truck"></span>
                    </div>
                    <div class="detail-row">
                        <span class="detail-label">Date:</span>
                        <span class="detail-value" id="detail-date"></span>
                    </div>
                    <div class="detail-row">
                        <span class="detail-label">Time:</span>
                        <span class="detail-value" id="detail-time"></span>
                    </div>
                    <div class="detail-row">
                        <span class="detail-label">Driver:</span>
                        <span class="detail-value" id="detail-driver"></span>
                    </div>
                    <div class="detail-row">
                        <span class="detail-label">Waste Collectors:</span>
                        <div class="detail-value" id="detail-collectors"></div>
                    </div>
                    <div class="detail-row">
                        <span class="detail-label">Location:</span>
                        <span class="detail-value" id="detail-location"></span>
                    </div>
                    <div class="detail-row">
                        <span class="detail-label">Streets:</span>
                        <div class="detail-value" id="detail-streets"></div>
                    </div>
                    <div class="detail-row">
                        <span class="detail-label">Status:</span>
                        <span class="detail-value status-badge" id="detail-status"></span>
                    </div>
                </div>
            </div>

            <div class="sched-modal-actions">
                <button type="button" class="btn-ghost" onclick="closeDetailsModal()">Close</button>
                <button type="button" class="btn-primary" onclick="editSchedule()">Edit</button>
            </div>
        </div>
    </div>

    <!-- Day Schedules Modal -->
    <div class="um-modal sched-modal" id="day-schedules-modal" style="display: none;">
        <div class="um-modal-card large sched-modal-card" role="dialog" aria-modal="true" aria-labelledby="day-schedules-title">
            <button class="um-modal-close" aria-label="Close" onclick="closeDaySchedulesModal()">
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <line x1="18" y1="6" x2="6" y2="18"></line>
                    <line x1="6" y1="6" x2="18" y2="18"></line>
                </svg>
            </button>

            <h3 id="day-schedules-title" class="um-modal-title">Schedules for <span id="selected-day-date"></span></h3>
            <p class="um-modal-sub">All schedules for this day</p>

            <div class="um-form sched-modal-scroll">
                <div id="day-schedules-list" class="day-schedules-container">
                    <!-- Schedules will be populated here -->
                </div>
            </div>

            <div class="sched-modal-actions">
                <button type="button" class="btn-ghost" onclick="closeDaySchedulesModal()">Close</button>
                <button type="button" class="btn-primary" onclick="createNewScheduleForDay()">Add New Schedule</button>
            </div>
        </div>
    </div>

    <!-- Approved Requests Modal -->
    <div class="um-modal" id="approved-requests-modal" style="display: none;">
        <div class="um-modal-card large" role="dialog" aria-modal="true">
            <button class="um-modal-close" aria-label="Close" onclick="closeApprovedRequestsModal()">
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <line x1="18" y1="6" x2="6" y2="18"></line>
                    <line x1="6" y1="6" x2="18" y2="18"></line>
                </svg>
            </button>

            <h3 class="um-modal-title">Approved Collection Requests</h3>
            <p class="um-modal-sub">Schedule approved requests for collection</p>

            <div class="approved-requests-container" style="max-height: 500px; overflow-y: auto; margin-top: 16px;">
                <div id="approved-requests-list">
                    <!-- Approved requests will be loaded here -->
                </div>
            </div>

            <div class="um-modal-actions">
                <button type="button" class="btn-ghost" onclick="closeApprovedRequestsModal()">Close</button>
            </div>
        </div>
    </div>

    <!-- Firebase CDN -->
    <script src="https://www.gstatic.com/firebasejs/9.23.0/firebase-app-compat.js"></script>
    <script src="https://www.gstatic.com/firebasejs/9.23.0/firebase-auth-compat.js"></script>
    <script src="https://www.gstatic.com/firebasejs/9.23.0/firebase-firestore-compat.js"></script>
    
    <script type="module" src="assets/js/auth.js"></script>
    <script src="assets/js/notifications.js"></script>
    <script src="assets/js/truck-schedule.js"></script>
</body>
</html>
