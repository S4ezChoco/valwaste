<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Truck Management - ValWaste Admin</title>
    <link rel="stylesheet" href="assets/css/styles.css">
    <style>
        .truck-grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(320px, 1fr));
            gap: 24px;
            margin-top: 20px;
        }

        .truck-card {
            background: white;
            border: 1px solid #e5e7eb;
            border-radius: 12px;
            padding: 20px;
            transition: all 0.2s;
            position: relative;
        }

        .truck-card:hover {
            box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
            border-color: #d1d5db;
        }

        .truck-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 16px;
        }

        .truck-name {
            font-size: 18px;
            font-weight: 600;
            color: #1f2937;
        }

        .truck-status {
            padding: 4px 8px;
            border-radius: 6px;
            font-size: 12px;
            font-weight: 500;
            text-transform: uppercase;
        }

        .truck-status.available {
            background: #d1fae5;
            color: #059669;
        }

        .truck-status.in-use {
            background: #fef3c7;
            color: #d97706;
        }

        .truck-status.maintenance {
            background: #fee2e2;
            color: #dc2626;
        }

        .truck-details {
            display: flex;
            flex-direction: column;
            gap: 8px;
            margin-bottom: 16px;
        }

        .truck-detail {
            display: flex;
            justify-content: space-between;
            align-items: center;
            font-size: 14px;
        }

        .truck-detail .label {
            color: #6b7280;
        }

        .truck-detail .value {
            color: #1f2937;
            font-weight: 500;
        }

        .truck-actions {
            display: flex;
            gap: 8px;
            padding-top: 16px;
            border-top: 1px solid #f3f4f6;
        }

        .btn-mini {
            padding: 6px 12px;
            font-size: 12px;
            border-radius: 6px;
            border: 1px solid #d1d5db;
            background: white;
            cursor: pointer;
            transition: all 0.2s;
        }

        .btn-mini:hover {
            background: #f9fafb;
        }

        .btn-mini.primary {
            background: #3b82f6;
            color: white;
            border-color: #3b82f6;
        }

        .btn-mini.primary:hover {
            background: #2563eb;
        }

        .truck-schedule-item {
            background: #f8fafc;
            border: 1px solid #e2e8f0;
            border-radius: 6px;
            padding: 8px 12px;
            margin-top: 8px;
            font-size: 12px;
        }

        .schedule-date {
            font-weight: 600;
            color: #1e293b;
        }

        .schedule-time {
            color: #64748b;
        }

        .empty-state {
            text-align: center;
            padding: 60px 20px;
            color: #6b7280;
        }

        .empty-state svg {
            margin: 0 auto 16px;
            opacity: 0.5;
        }

        .truck-tabs {
            display: flex;
            gap: 4px;
            margin-bottom: 24px;
            background: #f1f5f9;
            padding: 4px;
            border-radius: 8px;
        }

        .truck-tab {
            padding: 8px 16px;
            border-radius: 6px;
            background: transparent;
            border: none;
            cursor: pointer;
            font-size: 14px;
            font-weight: 500;
            color: #64748b;
            transition: all 0.2s;
        }

        .truck-tab.active {
            background: white;
            color: #1e293b;
            box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
        }

        .truck-filter-bar {
            display: flex;
            justify-content: between;
            align-items: center;
            gap: 16px;
            margin-bottom: 20px;
            flex-wrap: wrap;
        }

        .truck-search {
            position: relative;
            flex: 1;
            min-width: 250px;
        }

        .truck-search input {
            width: 100%;
            padding: 8px 12px 8px 36px;
            border: 1px solid #d1d5db;
            border-radius: 6px;
            font-size: 14px;
        }

        .truck-search svg {
            position: absolute;
            left: 10px;
            top: 50%;
            transform: translateY(-50%);
            color: #9ca3af;
        }

        .status-filter {
            display: flex;
            gap: 8px;
            flex-wrap: wrap;
        }

        .status-filter button {
            padding: 6px 12px;
            border: 1px solid #d1d5db;
            border-radius: 6px;
            background: white;
            cursor: pointer;
            font-size: 12px;
            color: #6b7280;
            transition: all 0.2s;
        }

        .status-filter button.active {
            background: #3b82f6;
            color: white;
            border-color: #3b82f6;
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
            <h1 class="page-title">Truck Management</h1>
        </div>

        <?php include 'components/sidebar.php'; ?>

        <main class="content">
            <div class="page-container">
                <!-- Header row -->
                <div class="um-headrow">
                    <h2 class="um-title">Truck Management</h2>
                    <button type="button" class="btn-primary btn-icon" onclick="openAddTruckModal()">
                        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                            <rect x="1" y="3" width="15" height="13"></rect>
                            <polygon points="16 8 20 8 23 11 23 16 16 16 16 8"></polygon>
                            <circle cx="5.5" cy="18.5" r="2.5"></circle>
                            <circle cx="18.5" cy="18.5" r="2.5"></circle>
                        </svg>
                        <span>Add New Truck</span>
                    </button>
                </div>

                <!-- Tabs -->
                <div class="truck-tabs">
                    <button class="truck-tab active" data-tab="inventory" onclick="switchTab('inventory')">
                        Truck Inventory
                    </button>
                    <button class="truck-tab" data-tab="schedule" onclick="switchTab('schedule')">
                        Truck Schedules
                    </button>
                </div>

                <!-- Inventory Tab -->
                <div id="inventory-tab" class="tab-content">
                    <div class="truck-filter-bar">
                        <div class="truck-search">
                            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                <circle cx="11" cy="11" r="8"></circle>
                                <path d="m21 21-4.35-4.35"></path>
                            </svg>
                            <input type="text" placeholder="Search trucks..." id="truck-search" oninput="filterTrucks()">
                        </div>
                        <div class="status-filter">
                            <button class="active" data-status="all" onclick="filterByStatus('all')">All</button>
                            <button data-status="available" onclick="filterByStatus('available')">Available</button>
                            <button data-status="in-use" onclick="filterByStatus('in-use')">In Use</button>
                            <button data-status="maintenance" onclick="filterByStatus('maintenance')">Maintenance</button>
                        </div>
                    </div>

                    <div class="truck-grid" id="truck-grid">
                        <!-- Trucks will be loaded here -->
                    </div>
                </div>

                <!-- Schedule Tab -->
                <div id="schedule-tab" class="tab-content" style="display: none;">
                    <div class="card">
                        <div style="padding: 20px;">
                            <h3>Truck Schedule Overview</h3>
                            <p>View and manage truck schedules across all vehicles</p>
                            <div id="truck-schedule-calendar">
                                <!-- Schedule calendar will be loaded here -->
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </main>
    </div>

    <!-- Add Truck Modal -->
    <div class="um-modal" id="add-truck-modal" style="display: none;">
        <div class="um-modal-card">
            <button class="um-modal-close" onclick="closeAddTruckModal()">
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <line x1="18" y1="6" x2="6" y2="18"></line>
                    <line x1="6" y1="6" x2="18" y2="18"></line>
                </svg>
            </button>

            <h3 class="um-modal-title">Add New Truck</h3>
            <p class="um-modal-sub">Enter truck details</p>

            <form id="add-truck-form" class="um-form" onsubmit="handleAddTruck(event)">
                <label class="um-field">
                    <span class="um-label">Truck Name/ID *</span>
                    <input type="text" class="um-input" id="truck-name" placeholder="e.g., Truck-04" required>
                </label>

                <div class="um-row-2">
                    <label class="um-field">
                        <span class="um-label">License Plate *</span>
                        <input type="text" class="um-input" id="truck-plate" placeholder="e.g., ABC-1234" required>
                    </label>
                    <label class="um-field">
                        <span class="um-label">Capacity (tons) *</span>
                        <input type="number" class="um-input" id="truck-capacity" placeholder="e.g., 5" step="0.1" required>
                    </label>
                </div>

                <div class="um-row-2">
                    <label class="um-field">
                        <span class="um-label">Model/Year</span>
                        <input type="text" class="um-input" id="truck-model" placeholder="e.g., Isuzu 2020">
                    </label>
                    <label class="um-field">
                        <span class="um-label">Status *</span>
                        <div class="um-select-wrap">
                            <select class="um-select" id="truck-status" required>
                                <option value="available">Available</option>
                                <option value="maintenance">Maintenance</option>
                            </select>
                            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" class="um-select-caret">
                                <polyline points="6 9 12 15 18 9"></polyline>
                            </svg>
                        </div>
                    </label>
                </div>

                <label class="um-field">
                    <span class="um-label">Notes</span>
                    <textarea class="um-input" id="truck-notes" rows="3" placeholder="Additional notes about the truck..."></textarea>
                </label>

                <div class="um-modal-actions">
                    <button type="button" class="btn-ghost" onclick="closeAddTruckModal()">Cancel</button>
                    <button type="submit" class="btn-primary">Add Truck</button>
                </div>
            </form>
        </div>
    </div>

    <!-- Edit Truck Modal -->
    <div class="um-modal" id="edit-truck-modal" style="display: none;">
        <div class="um-modal-card">
            <button class="um-modal-close" onclick="closeEditTruckModal()">
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <line x1="18" y1="6" x2="6" y2="18"></line>
                    <line x1="6" y1="6" x2="18" y2="18"></line>
                </svg>
            </button>

            <h3 class="um-modal-title">Edit Truck</h3>
            <p class="um-modal-sub">Update truck details</p>

            <form id="edit-truck-form" class="um-form" onsubmit="handleEditTruck(event)">
                <input type="hidden" id="edit-truck-id">

                <label class="um-field">
                    <span class="um-label">Truck Name/ID *</span>
                    <input type="text" class="um-input" id="edit-truck-name" required>
                </label>

                <div class="um-row-2">
                    <label class="um-field">
                        <span class="um-label">License Plate *</span>
                        <input type="text" class="um-input" id="edit-truck-plate" required>
                    </label>
                    <label class="um-field">
                        <span class="um-label">Capacity (tons) *</span>
                        <input type="number" class="um-input" id="edit-truck-capacity" step="0.1" required>
                    </label>
                </div>

                <div class="um-row-2">
                    <label class="um-field">
                        <span class="um-label">Model/Year</span>
                        <input type="text" class="um-input" id="edit-truck-model">
                    </label>
                    <label class="um-field">
                        <span class="um-label">Status *</span>
                        <div class="um-select-wrap">
                            <select class="um-select" id="edit-truck-status" required>
                                <option value="available">Available</option>
                                <option value="in-use">In Use</option>
                                <option value="maintenance">Maintenance</option>
                            </select>
                            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" class="um-select-caret">
                                <polyline points="6 9 12 15 18 9"></polyline>
                            </svg>
                        </div>
                    </label>
                </div>

                <label class="um-field">
                    <span class="um-label">Notes</span>
                    <textarea class="um-input" id="edit-truck-notes" rows="3"></textarea>
                </label>

                <div class="um-modal-actions">
                    <button type="button" class="btn-ghost" onclick="closeEditTruckModal()">Cancel</button>
                    <button type="submit" class="btn-primary">Update Truck</button>
                </div>
            </form>
        </div>
    </div>

    <!-- Firebase CDN -->
    <script src="https://www.gstatic.com/firebasejs/9.23.0/firebase-app-compat.js"></script>
    <script src="https://www.gstatic.com/firebasejs/9.23.0/firebase-auth-compat.js"></script>
    <script src="https://www.gstatic.com/firebasejs/9.23.0/firebase-firestore-compat.js"></script>
    
    <script type="module" src="assets/js/auth.js"></script>
    <script src="assets/js/notifications.js"></script>
    <script src="assets/js/truck-management.js"></script>
</body>
</html>
