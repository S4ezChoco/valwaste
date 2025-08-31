<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Truck Schedule - ValWaste Admin</title>
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
            <h1 class="page-title">Truck Schedule</h1>
        </div>

        <?php include 'components/sidebar.php'; ?>

        <main class="content">
            <div class="page-container">
                <div class="sched-topbar">
                    <button type="button" class="btn-primary" onclick="openCreateModal()">Create Schedule</button>
                </div>

                <section class="card sched-card">
                    <div class="sched-head">
                        <div>
                            <h3 class="sched-title">Truck Schedule</h3>
                            <p class="sched-sub">Manage truck collection schedules</p>
                        </div>
                        <div class="um-filter-wrap month-dd">
                            <button type="button" class="um-filter" onclick="toggleMonthDropdown()">
                                <span id="month-display">August</span>
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
                                <button type="button" class="um-menu-item active" onclick="selectMonth(7)">
                                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" class="um-check show">
                                        <polyline points="20 6 9 17 4 12"></polyline>
                                    </svg>
                                    <span>August</span>
                                </button>
                                <button type="button" class="um-menu-item" onclick="selectMonth(8)">
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
                    </div>

                    <div class="sched-monthrow">
                        <h4 class="sched-month" id="month-year-display">August 2025</h4>
                        <div class="sched-nav">
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
                    <span class="um-label">Select Truck</span>
                    <div class="um-select-wrap">
                        <select class="um-select" id="truck-select" required>
                            <option value="" disabled selected>Truck</option>
                            <option value="Truck 01">Truck 01</option>
                            <option value="Truck 02">Truck 02</option>
                            <option value="Truck 03">Truck 03</option>
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
                    <div class="um-select-wrap">
                        <select class="um-select" id="driver-select" required>
                            <option value="" disabled selected>Select driver</option>
                            <option value="Juan Dela Cruz">Juan Dela Cruz</option>
                            <option value="Maria Santos">Maria Santos</option>
                            <option value="Pedro Reyes">Pedro Reyes</option>
                        </select>
                        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" class="um-select-caret">
                            <polyline points="6 9 12 15 18 9"></polyline>
                        </svg>
                    </div>
                </label>

                <label class="um-field">
                    <span class="um-label">Waste Collectors (Select exactly 3)</span>
                    <div class="um-menu" style="width: 100%; position: relative;">
                        <label class="um-menu-item" style="cursor: pointer;">
                            <input type="checkbox" name="collectors" value="Alex">
                            <span>Alex</span>
                        </label>
                        <label class="um-menu-item" style="cursor: pointer;">
                            <input type="checkbox" name="collectors" value="Bea">
                            <span>Bea</span>
                        </label>
                        <label class="um-menu-item" style="cursor: pointer;">
                            <input type="checkbox" name="collectors" value="Carl">
                            <span>Carl</span>
                        </label>
                        <label class="um-menu-item" style="cursor: pointer;">
                            <input type="checkbox" name="collectors" value="Dina">
                            <span>Dina</span>
                        </label>
                        <label class="um-menu-item" style="cursor: pointer;">
                            <input type="checkbox" name="collectors" value="Evan">
                            <span>Evan</span>
                        </label>
                    </div>
                </label>

                <div class="um-field">
                    <span class="um-label">Locations (Select at least 1)</span>
                    <div class="um-boxlist">
                        <label class="um-checkrow">
                            <input type="checkbox" name="locations" value="Isla Street 1">
                            <span>Isla Street 1</span>
                        </label>
                        <label class="um-checkrow">
                            <input type="checkbox" name="locations" value="Isla Street 2">
                            <span>Isla Street 2</span>
                        </label>
                        <label class="um-checkrow">
                            <input type="checkbox" name="locations" value="Isla Market">
                            <span>Isla Market</span>
                        </label>
                        <label class="um-checkrow">
                            <input type="checkbox" name="locations" value="Isla Plaza">
                            <span>Isla Plaza</span>
                        </label>
                    </div>
                </div>
            </form>

            <div class="sched-modal-actions">
                <button type="button" class="btn-ghost" onclick="closeCreateModal()">Cancel</button>
                <button type="submit" form="createScheduleForm" class="btn-primary">Create</button>
            </div>
        </div>
    </div>

    <script type="module" src="assets/js/auth.js"></script>
    <script src="assets/js/truck-schedule.js"></script>
</body>
</html>
