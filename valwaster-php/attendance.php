<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Attendance - ValWaste Admin</title>
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
            <h1 class="page-title">Attendance</h1>
        </div>

        <?php include 'components/sidebar.php'; ?>

        <main class="content">
            <div class="page-container">
                <div class="att-pagehead">
                    <div>
                        <h2 class="att-h2">Team Attendance Management</h2>
                        <p class="att-sub">Track attendance for waste collection teams</p>
                    </div>
                    <div class="att-ctas">
                        <button class="btn-soft" onclick="openCheckOutModal()">
                            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                <circle cx="12" cy="12" r="10"></circle>
                                <polyline points="12,6 12,12 16,14"></polyline>
                            </svg>
                            Record Check-Out
                        </button>
                        <button class="btn-primary" onclick="openCheckInModal()">
                            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                <circle cx="12" cy="12" r="10"></circle>
                                <polyline points="12,6 12,12 16,14"></polyline>
                            </svg>
                            Record Check-In
                        </button>
                    </div>
                </div>

                <div class="rm-tabs">
                    <div class="rm-seg">
                        <button type="button" class="rm-tab active" onclick="switchTab('team-records')">
                            <span>Team Records</span>
                        </button>
                        <button type="button" class="rm-tab" onclick="switchTab('pending-verification')">
                            <span>Pending Verification</span>
                            <span class="count-dot count-red">1</span>
                        </button>
                    </div>
                </div>

                <section class="card att-card">
                    <div class="att-head">
                        <h3 class="att-title">Team Attendance Records</h3>
                        <p class="att-sub2">View all team attendance records for drivers, waste collectors, and paleros</p>
                    </div>

                    <div class="card um-table-card">
                        <table class="um-table att-table">
                            <thead>
                                <tr>
                                    <th>Driver</th>
                                    <th>Team</th>
                                    <th>Check-In</th>
                                    <th>Check-Out</th>
                                    <th>Status</th>
                                    <th class="col-actions">Actions</th>
                                </tr>
                            </thead>
                            <tbody id="attendance-table-body">
                                <!-- Data will be populated from Firebase/database -->
                            </tbody>
                        </table>
                    </div>
                </section>
            </div>
        </main>
    </div>

    <!-- Team Attendance Details Modal -->
    <div id="detailsModal" class="um-modal" style="display: none;" onclick="closeModal(event, 'detailsModal')">
        <div class="um-modal-card large" role="dialog" aria-modal="true">
            <button class="um-modal-close" aria-label="Close" onclick="closeDetailsModal()">
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <line x1="18" y1="6" x2="6" y2="18"></line>
                    <line x1="6" y1="6" x2="18" y2="18"></line>
                </svg>
            </button>

            <h3 class="um-modal-title">Team Attendance Details</h3>
            <p class="um-modal-sub">Detailed information about the team's attendance record.</p>

            <div style="display: grid; grid-template-columns: repeat(2,minmax(0,1fr)); gap: 16px; margin-top: 8px;">
                <div class="card" style="padding: 12px;">
                    <div style="font-weight: 600; margin-bottom: 8px;">Check-In Photo</div>
                    <div style="background: #eef2f7; border: 1px solid var(--border); border-radius: 12px; height: 220px; display: grid; place-items: center; color: #64748b; margin-bottom: 8px;">
                        <div>Photo placeholder</div>
                    </div>
                    <div style="color: #475569; font-size: 14px;" id="checkin-time">Check-in time: —</div>
                </div>

                <div class="card" style="padding: 12px;">
                    <div style="font-weight: 600; margin-bottom: 8px;">Check-Out Photo</div>
                    <div style="background: #eef2f7; border: 1px solid var(--border); border-radius: 12px; height: 220px; display: grid; place-items: center; color: #64748b; margin-bottom: 8px;">
                        <div>Photo placeholder</div>
                    </div>
                    <div style="color: #475569; font-size: 14px;" id="checkout-time">Check-out time: —</div>
                </div>
            </div>

            <div class="card" style="margin-top: 16px; padding: 16px;">
                <div style="font-weight: 700; margin-bottom: 12px;">Team Members</div>
                <div id="team-members-list" style="display: grid; gap: 8px;">
                    <!-- Team members will be populated here -->
                </div>
            </div>

            <div class="card" style="margin-top: 12px; padding: 16px;">
                <div style="font-weight: 700; margin-bottom: 10px;">Additional Information</div>
                <div style="display: flex; gap: 6px; margin-bottom: 6px;">
                    <span style="font-weight: 700;">Location:</span>
                    <span id="location-info">—</span>
                </div>
                <div style="color: #111827;" id="notes-info">—</div>
            </div>

            <div class="um-modal-actions att-actions-row" id="pending-actions" style="display: none;">
                <button type="button" class="att-cta att-reject" onclick="rejectRecord()">
                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                        <circle cx="12" cy="12" r="10"></circle>
                        <line x1="15" y1="9" x2="9" y2="15"></line>
                        <line x1="9" y1="9" x2="15" y2="15"></line>
                    </svg>
                    Reject
                </button>
                <button type="button" class="att-cta att-verify" onclick="verifyRecord()">
                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                        <path d="m9 12 2 2 4-4"></path>
                        <path d="M21 12c.552 0 1-.448 1-1V5a2 2 0 0 0-2-2H4a2 2 0 0 0-2 2v6c0 .552.448 1 1 1"></path>
                    </svg>
                    Verify
                </button>
            </div>
        </div>
    </div>

    <!-- Record Check-In Modal -->
    <div id="checkInModal" class="um-modal" style="display: none;" onclick="closeModal(event, 'checkInModal')">
        <div class="um-modal-card large" role="dialog" aria-modal="true">
            <button class="um-modal-close" aria-label="Close" onclick="closeCheckInModal()">
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <line x1="18" y1="6" x2="6" y2="18"></line>
                    <line x1="6" y1="6" x2="18" y2="18"></line>
                </svg>
            </button>

            <h3 class="um-modal-title">Record Team Check-In</h3>
            <p class="um-modal-sub">Take a team photo and record check-in time for your waste collection team.</p>

            <form class="um-form" onsubmit="submitCheckIn(event)">
                <label class="um-field">
                    <span class="um-label">Team Type</span>
                    <div class="checkin-seg">
                        <button type="button" class="seg active" onclick="setTeamType('Waste Collection')">Waste Collection</button>
                        <button type="button" class="seg" onclick="setTeamType('Special Operations')">Special Operations</button>
                    </div>
                </label>

                <label class="um-field">
                    <span class="um-label">Select Driver</span>
                    <div class="um-select-wrap">
                        <select class="um-select" id="driver-select" required>
                            <option value="" disabled selected>Select a driver</option>
                            <!-- Options will be populated from Firebase/database -->
                        </select>
                        <svg width="16" height="16" class="um-select-caret" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                            <polyline points="6,9 12,15 18,9"></polyline>
                        </svg>
                    </div>
                </label>

                <label class="um-field">
                    <span class="um-label">Team Members</span>
                    <div class="checkin-row">
                        <div class="um-select-wrap">
                            <select class="um-select" id="member-select">
                                <option value="" disabled selected>Select team member</option>
                                <!-- Options will be populated from Firebase/database -->
                            </select>
                            <svg width="16" height="16" class="um-select-caret" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                <polyline points="6,9 12,15 18,9"></polyline>
                            </svg>
                        </div>
                        <button type="button" class="checkin-plus" onclick="addTeamMember()" title="Add member">
                            Add
                        </button>
                    </div>

                    <div id="team-members-empty" class="checkin-empty">No team members selected</div>
                    <div id="team-members-chips" class="checkin-chips" style="display: none;"></div>
                </label>

                <label class="um-field">
                    <span class="um-label">Check-In Photo</span>
                    <button type="button" class="checkin-photo-btn" onclick="capturePhoto('checkin')">
                        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                            <path d="M14.5 4h-5L7 7H4a2 2 0 0 0-2 2v9a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2V9a2 2 0 0 0-2-2h-3l-2.5-3z"></path>
                            <circle cx="12" cy="13" r="3"></circle>
                        </svg>
                        <span id="photo-text">Capture Team Photo</span>
                    </button>
                </label>

                <label class="um-field">
                    <span class="um-label">Location</span>
                    <input class="um-input" id="location-input" placeholder="Enter location or route" />
                </label>

                <label class="um-field">
                    <span class="um-label">Additional Information</span>
                    <textarea class="um-input" id="notes-input" rows="4" placeholder="Enter any additional information"></textarea>
                </label>

                <div class="um-modal-actions" style="justify-content: flex-end;">
                    <button type="submit" class="btn-primary">
                        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                            <circle cx="12" cy="12" r="10"></circle>
                            <polyline points="12,6 12,12 16,14"></polyline>
                        </svg>
                        Record Check-In
                    </button>
                </div>
            </form>
        </div>
    </div>

    <!-- Record Check-Out Modal -->
    <div id="checkOutModal" class="um-modal" style="display: none;" onclick="closeModal(event, 'checkOutModal')">
        <div class="um-modal-card large" role="dialog" aria-modal="true">
            <button class="um-modal-close" aria-label="Close" onclick="closeCheckOutModal()">
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <line x1="18" y1="6" x2="6" y2="18"></line>
                    <line x1="6" y1="6" x2="18" y2="18"></line>
                </svg>
            </button>

            <h3 class="um-modal-title">Record Team Check-Out</h3>
            <p class="um-modal-sub">Pick a checked-in team, capture a photo, and record their check-out time.</p>

            <form class="um-form" onsubmit="submitCheckOut(event)">
                <label class="um-field">
                    <span class="um-label">Select Team</span>
                    <div class="um-select-wrap">
                        <select class="um-select" id="checkout-team-select" required>
                            <option value="" disabled selected>Select driver/team to check out</option>
                        </select>
                        <svg width="16" height="16" class="um-select-caret" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                            <polyline points="6,9 12,15 18,9"></polyline>
                        </svg>
                    </div>
                </label>

                <div class="card" id="checkout-team-preview" style="padding: 12px; display: none;">
                    <div style="font-weight: 700; margin-bottom: 8px;">Team Members</div>
                    <ul class="att-member-list" id="checkout-members-list">
                        <!-- Team members will be populated here -->
                    </ul>
                </div>

                <label class="um-field">
                    <span class="um-label">Check-Out Photo</span>
                    <button type="button" class="checkin-photo-btn" onclick="capturePhoto('checkout')">
                        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                            <path d="M14.5 4h-5L7 7H4a2 2 0 0 0-2 2v9a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2V9a2 2 0 0 0-2-2h-3l-2.5-3z"></path>
                            <circle cx="12" cy="13" r="3"></circle>
                        </svg>
                        <span id="checkout-photo-text">Capture Team Photo</span>
                    </button>
                </label>

                <label class="um-field">
                    <span class="um-label">Additional Information</span>
                    <textarea class="um-input" id="checkout-notes" rows="4" placeholder="Enter any additional information"></textarea>
                </label>

                <div class="um-modal-actions" style="justify-content: flex-end;">
                    <button type="submit" class="btn-soft">
                        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                            <circle cx="12" cy="12" r="10"></circle>
                            <polyline points="12,6 12,12 16,14"></polyline>
                        </svg>
                        Record Check-Out
                    </button>
                </div>
            </form>
        </div>
    </div>

    <!-- Firebase SDK -->
    <script src="https://www.gstatic.com/firebasejs/9.23.0/firebase-app-compat.js"></script>
    <script src="https://www.gstatic.com/firebasejs/9.23.0/firebase-firestore-compat.js"></script>
    <script src="https://www.gstatic.com/firebasejs/9.23.0/firebase-auth-compat.js"></script>
    
    <script type="module" src="assets/js/auth.js"></script>
    <script src="assets/js/attendance.js"></script>
</body>
</html>
