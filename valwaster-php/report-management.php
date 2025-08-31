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
                <!-- Top controls -->
                <div class="rm-controls">
                    <button type="button" class="btn-soft" onclick="refreshReports()">Refresh Reports</button>
                </div>

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
                                    <th class="col-actions">Actions</th>
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

    <script type="module" src="assets/js/auth.js"></script>
    <script src="assets/js/report-management.js"></script>
</body>
</html>
