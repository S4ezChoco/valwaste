<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Report Management - ValWaste Admin</title>
    <link rel="stylesheet" href="assets/css/styles.css">
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
            <h1 class="page-title">Report Management</h1>
        </div>

        <?php include 'components/sidebar.php'; ?>

        <main class="content">
            <div class="page-container">

                <!-- Tabs -->
                <div class="rm-tabs">
                    <div class="rm-seg">
                        <button type="button" class="rm-tab active" onclick="switchTab('pending')" data-tab="pending">
                            <span>Pending</span>
                            <span class="count-dot count-gray" id="pending-count">0</span>
                        </button>
                        <button type="button" class="rm-tab" onclick="switchTab('resolved')" data-tab="resolved">
                            <span>Resolved</span>
                            <span class="count-dot count-green" id="resolved-count">0</span>
                        </button>
                        <button type="button" class="rm-tab" onclick="switchTab('unresolved')" data-tab="unresolved">
                            <span>Unresolved</span>
                            <span class="count-dot count-red" id="unresolved-count">0</span>
                        </button>
                    </div>
                </div>

                <!-- Panel -->
                <section class="card rm-panel">
                    <h3 class="rm-title" id="panel-title">Pending Reports</h3>
                    <p class="rm-sub" id="panel-subtitle">Reports waiting for review and resolution</p>

                    <div class="rm-row">
                        <div class="rm-search">
                            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                <circle cx="11" cy="11" r="8"></circle>
                                <path d="m21 21-4.35-4.35"></path>
                            </svg>
                            <input type="text" placeholder="Search reports..." id="search-input" onkeyup="searchReports()">
                        </div>

                        <div class="rm-filters">
                            <!-- Priority Filter -->
                            <div class="um-filter-wrap" style="width: 160px;">
                                <button type="button" class="um-filter" style="width: 100%;" onclick="toggleDropdown('priority-dropdown')">
                                    <span id="priority-value">All Priorities</span>
                                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                        <polyline points="6 9 12 15 18 9"></polyline>
                                    </svg>
                                </button>
                                <div class="um-menu" id="priority-dropdown" style="width: 100%; display: none;">
                                    <button type="button" class="um-menu-item" onclick="selectPriority('All Priorities')">
                                        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" class="um-check">
                                            <polyline points="20 6 9 17 4 12"></polyline>
                                        </svg>
                                        <span>All Priorities</span>
                                    </button>
                                    <button type="button" class="um-menu-item" onclick="selectPriority('High')">
                                        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" class="um-check">
                                            <polyline points="20 6 9 17 4 12"></polyline>
                                        </svg>
                                        <span>High</span>
                                    </button>
                                    <button type="button" class="um-menu-item" onclick="selectPriority('Medium')">
                                        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" class="um-check">
                                            <polyline points="20 6 9 17 4 12"></polyline>
                                        </svg>
                                        <span>Medium</span>
                                    </button>
                                    <button type="button" class="um-menu-item" onclick="selectPriority('Low')">
                                        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" class="um-check">
                                            <polyline points="20 6 9 17 4 12"></polyline>
                                        </svg>
                                        <span>Low</span>
                                    </button>
                                </div>
                            </div>

                            <!-- Category Filter -->
                            <div class="um-filter-wrap" style="width: 160px;">
                                <button type="button" class="um-filter" style="width: 100%;" onclick="toggleDropdown('category-dropdown')">
                                    <span id="category-value">All Categories</span>
                                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                        <polyline points="6 9 12 15 18 9"></polyline>
                                    </svg>
                                </button>
                                <div class="um-menu" id="category-dropdown" style="width: 100%; display: none;">
                                    <div id="category-options">
                                        <!-- Category options will be populated dynamically based on tab -->
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>

                    <div class="card um-table-card">
                        <table class="um-table">
                            <thead>
                                <tr>
                                    <th>Title</th>
                                    <th>Location</th>
                                    <th>Reported By</th>
                                    <th>Priority</th>
                                    <th>Category</th>
                                    <th>Date</th>
                                    <th class="col-actions">
                                        Actions
                                        <button class="refresh-icon-btn" onclick="refreshReports()" title="Refresh Reports">
                                            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                                <polyline points="23 4 23 10 17 10"></polyline>
                                                <polyline points="1 20 1 14 7 14"></polyline>
                                                <path d="M20.49 9A9 9 0 0 0 5.64 5.64L1 10m22 4l-4.64 4.36A9 9 0 0 1 3.51 15"></path>
                                            </svg>
                                        </button>
                                        <button class="refresh-icon-btn" onclick="createTestApprovedCollection()" title="Create Test Collection" style="margin-left: 5px; background: #28a745; color: white;">
                                            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                                <line x1="12" y1="5" x2="12" y2="19"></line>
                                                <line x1="5" y1="12" x2="19" y2="12"></line>
                                            </svg>
                                        </button>
                                    </th>
                                </tr>
                            </thead>
                            <tbody id="reports-tbody">
                                <tr class="empty">
                                    <td colspan="7">No reports found</td>
                                </tr>
                            </tbody>
                        </table>
                    </div>
                </section>
            </div>
        </main>
    </div>

    <!-- Report Details Modal -->
    <div id="reportDetailsModal" class="um-modal" style="display: none;" onclick="closeModal(event, 'reportDetailsModal')">
        <div class="um-modal-card large" role="dialog" aria-modal="true">
            <button class="um-modal-close" aria-label="Close" onclick="closeReportDetailsModal()">
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <line x1="18" y1="6" x2="6" y2="18"></line>
                    <line x1="6" y1="6" x2="18" y2="18"></line>
                </svg>
            </button>

            <h3 class="um-modal-title" id="modal-report-title">Report Details</h3>
            <p class="um-modal-sub">Complete information about this report</p>

            <div class="report-details-content">
                <div class="report-details-grid">
                    <div class="report-details-left">
                        <div class="detail-section">
                            <h4 class="detail-label">Report Information</h4>
                            <div class="detail-item">
                                <span class="detail-key">Title:</span>
                                <span class="detail-value" id="detail-title">-</span>
                            </div>
                            <div class="detail-item">
                                <span class="detail-key">Location:</span>
                                <span class="detail-value" id="detail-location">-</span>
                            </div>
                            <div class="detail-item">
                                <span class="detail-key">Reported By:</span>
                                <span class="detail-value" id="detail-reporter">-</span>
                            </div>
                            <div class="detail-item">
                                <span class="detail-key">Date Reported:</span>
                                <span class="detail-value" id="detail-date">-</span>
                            </div>
                            <div class="detail-item">
                                <span class="detail-key">Priority:</span>
                                <span class="detail-value" id="detail-priority">-</span>
                            </div>
                            <div class="detail-item">
                                <span class="detail-key">Category:</span>
                                <span class="detail-value" id="detail-category">-</span>
                            </div>
                            <div class="detail-item">
                                <span class="detail-key">Status:</span>
                                <span class="detail-value" id="detail-status">-</span>
                            </div>
                        </div>

                        <div class="detail-section">
                            <h4 class="detail-label">Description</h4>
                            <div class="detail-description" id="detail-description">
                                No description provided.
                            </div>
                        </div>
                    </div>

                    <div class="report-details-right">
                        <div class="detail-section">
                            <h4 class="detail-label">Attached Images</h4>
                            <div class="report-images" id="report-images">
                                <div class="no-images">No images attached</div>
                            </div>
                        </div>
                    </div>
                </div>

                <div class="um-modal-actions report-actions" id="report-modal-actions">
                    <!-- Actions will be populated based on report status -->
                </div>
            </div>
        </div>
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

            <h3 id="sched-title" class="um-modal-title">Schedule Collection</h3>
            <p class="um-modal-sub">Fill details to schedule the collection</p>

            <form id="createScheduleForm" class="um-form sched-modal-scroll">
                <label class="um-field">
                    <span class="um-label">Select Truck</span>
                    <div class="um-select-wrap">
                        <select class="um-select" id="truck-select" required>
                            <option value="" disabled selected>Select Truck</option>
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
                        <input type="time" class="um-input" id="start-time" value="08:00" required>
                    </label>
                    <label class="um-field">
                        <span class="um-label">End</span>
                        <input type="time" class="um-input" id="end-time" value="16:00" required>
                    </label>
                </div>

                <label class="um-field">
                    <span class="um-label">Driver</span>
                    <div class="um-select-wrap">
                        <select class="um-select" id="driver-select" required>
                            <option value="" disabled selected>Select Driver</option>
                            <!-- Drivers will be loaded from Firebase -->
                        </select>
                        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" class="um-select-caret">
                            <polyline points="6 9 12 15 18 9"></polyline>
                        </svg>
                    </div>
                </label>
            </form>

            <div class="sched-modal-actions">
                <button type="button" class="btn-ghost" onclick="closeCreateModal()">Cancel</button>
                <button type="submit" form="createScheduleForm" class="btn-primary">Schedule Collection</button>
            </div>
        </div>
    </div>

    <script type="module" src="assets/js/auth.js"></script>
    <script src="assets/js/notifications.js"></script>
    <script src="assets/js/report-management.js"></script>
</body>
</html>
