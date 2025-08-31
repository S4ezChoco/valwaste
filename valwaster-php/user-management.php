<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>User Management - ValWaste Admin</title>
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
            <h1 class="page-title">User Management</h1>
        </div>

        <?php include 'components/sidebar.php'; ?>

        <main class="content">
            <div class="page-container">
                <!-- Header row -->
                <div class="um-headrow">
                    <h2 class="um-title">User Management</h2>
                    <div style="display: flex; gap: 8px;">
                        <button type="button" onclick="forceRefreshUsers()" title="Refresh Users" style="
                            background: none; 
                            border: 1px solid #d1d5db; 
                            border-radius: 6px; 
                            padding: 8px; 
                            cursor: pointer; 
                            color: #6b7280; 
                            transition: all 0.2s;
                            display: flex;
                            align-items: center;
                            justify-content: center;
                        " onmouseover="this.style.background='#f9fafb'; this.style.color='#374151'" onmouseout="this.style.background='none'; this.style.color='#6b7280'">
                            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                <path d="M3 12a9 9 0 0 1 9-9 9.75 9.75 0 0 1 6.74 2.74L21 8"></path>
                                <path d="M21 3v5h-5"></path>
                                <path d="M21 12a9 9 0 0 1-9 9 9.75 9.75 0 0 1-6.74-2.74L3 16"></path>
                                <path d="M3 21v-5h5"></path>
                            </svg>
                        </button>
                        <button type="button" class="btn-primary btn-icon" onclick="openCreateUserModal()">
                            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                <path d="M16 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"></path>
                                <circle cx="9" cy="7" r="4"></circle>
                                <line x1="19" y1="8" x2="19" y2="14"></line>
                                <line x1="22" y1="11" x2="16" y2="11"></line>
                            </svg>
                            <span>Add New User</span>
                        </button>
                    </div>
                </div>

                <!-- Toolbar -->
                <div class="um-toolbar">
                    <div class="um-search">
                        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                            <circle cx="11" cy="11" r="8"></circle>
                            <path d="m21 21-4.35-4.35"></path>
                        </svg>
                        <input id="searchUsers" placeholder="Search users..." />
                    </div>
                    <div class="um-filter-wrap">
                        <button type="button" class="um-filter" id="roleFilterButton">
                            <span>All Roles</span>
                            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                <polyline points="6 9 12 15 18 9"></polyline>
                            </svg>
                        </button>
                        <div class="um-menu" id="roleFilterMenu" style="display: none;">
                            <!-- Will be populated by JavaScript -->
                        </div>
                    </div>
                </div>

                <!-- Table -->
                <div class="card um-table-card">
                    <table class="um-table">
                        <thead>
                            <tr>
                                <th>Name</th>
                                <th>Email</th>
                                <th>Role</th>
                                <th>Status</th>
                                <th>Created At</th>
                                <th class="col-actions">Actions</th>
                            </tr>
                        </thead>
                        <tbody id="userTableBody">
                            <tr class="empty">
                                <td colspan="6" style="text-align: center; padding: 40px 12px; color: #6b7280;">
                                    Loading users...
                                </td>
                            </tr>
                        </tbody>
                    </table>
                </div>
            </div>
        </main>

        <!-- Create User Modal - Compact Design -->
        <div class="um-modal" id="createUserModal" style="display: none;">
            <div class="um-modal-card compact">
                <button class="um-modal-close" data-close-modal>
                    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                        <line x1="18" y1="6" x2="6" y2="18"></line>
                        <line x1="6" y1="6" x2="18" y2="18"></line>
                    </svg>
                </button>
                <h2 class="um-modal-title">Create New User</h2>
                <p class="um-modal-sub">Add a new user to the system</p>
                
                <form class="um-form compact" id="createUserForm">
                    <div class="form-row">
                        <div class="um-field">
                            <label class="um-label">First Name *</label>
                            <input type="text" class="um-input" name="firstName" placeholder="First Name" required>
                        </div>
                        
                        <div class="um-field">
                            <label class="um-label">Last Name *</label>
                            <input type="text" class="um-input" name="lastName" placeholder="Last Name" required>
                        </div>
                    </div>
                    
                    <div class="form-row">
                        <div class="um-field">
                            <label class="um-label">Date of Birth</label>
                            <input type="date" class="um-input" name="dateOfBirth">
                        </div>
                        
                        <div class="um-field">
                            <label class="um-label">Barangay</label>
                            <div class="um-select-wrap">
                                <select class="um-select" name="barangay" id="userBarangay">
                                    <option value="">Select Barangay</option>
                                </select>
                                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" class="um-select-caret">
                                    <polyline points="6 9 12 15 18 9"></polyline>
                                </svg>
                            </div>
                        </div>
                    </div>
                    
                    <div class="um-field">
                        <label class="um-label">Email *</label>
                        <input type="email" class="um-input" name="email" placeholder="Enter email address" required>
                    </div>
                    
                    <div class="form-row">
                        <div class="um-field">
                            <label class="um-label">Password *</label>
                            <input type="password" class="um-input" name="password" placeholder="Min. 6 characters" required minlength="6">
                        </div>
                        
                        <div class="um-field">
                            <label class="um-label">Role *</label>
                            <div class="um-select-wrap">
                                <select class="um-select" name="role" id="userRole" required>
                                    <!-- Will be populated by JavaScript -->
                                </select>
                                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" class="um-select-caret">
                                    <polyline points="6 9 12 15 18 9"></polyline>
                                </svg>
                            </div>
                        </div>
                    </div>
                    
                    <div class="um-modal-actions">
                        <button type="button" class="btn-ghost" data-close-modal>Cancel</button>
                        <button type="submit" class="btn-primary">Create User</button>
                    </div>
                </form>
            </div>
        </div>

        <!-- Edit User Modal - Compact Design -->
        <div class="um-modal" id="editUserModal" style="display: none;">
            <div class="um-modal-card compact">
                <button class="um-modal-close" data-close-edit-modal>
                    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                        <line x1="18" y1="6" x2="6" y2="18"></line>
                        <line x1="6" y1="6" x2="18" y2="18"></line>
                    </svg>
                </button>
                <h2 class="um-modal-title">Edit User</h2>
                <p class="um-modal-sub">Update user information</p>
                
                <form class="um-form compact" id="editUserForm">
                    <input type="hidden" id="editUserId" name="userId">
                    
                    <div class="form-row">
                        <div class="um-field">
                            <label class="um-label">First Name *</label>
                            <input type="text" class="um-input" id="editFirstName" name="firstName" placeholder="First Name" required>
                        </div>
                        
                        <div class="um-field">
                            <label class="um-label">Last Name *</label>
                            <input type="text" class="um-input" id="editLastName" name="lastName" placeholder="Last Name" required>
                        </div>
                    </div>
                    
                    <div class="form-row">
                        <div class="um-field">
                            <label class="um-label">Date of Birth</label>
                            <input type="date" class="um-input" id="editDateOfBirth" name="dateOfBirth">
                        </div>
                        
                        <div class="um-field">
                            <label class="um-label">Barangay</label>
                            <div class="um-select-wrap">
                                <select class="um-select" id="editBarangay" name="barangay">
                                    <option value="">Select Barangay</option>
                                </select>
                                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" class="um-select-caret">
                                    <polyline points="6 9 12 15 18 9"></polyline>
                                </svg>
                            </div>
                        </div>
                    </div>
                    
                    <div class="um-field">
                        <label class="um-label">Email *</label>
                        <input type="email" class="um-input" id="editEmail" name="email" placeholder="Enter email address" required>
                    </div>
                    
                    <div class="form-row">
                        <div class="um-field">
                            <label class="um-label">Role *</label>
                            <div class="um-select-wrap">
                                <select class="um-select" id="editRole" name="role" required>
                                    <!-- Will be populated by JavaScript -->
                                </select>
                                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" class="um-select-caret">
                                    <polyline points="6 9 12 15 18 9"></polyline>
                                </svg>
                            </div>
                        </div>
                        
                        <div class="um-field">
                            <label class="um-label">Status</label>
                            <div class="um-select-wrap">
                                <select class="um-select" id="editStatus" name="status">
                                    <option value="true">Active</option>
                                    <option value="false">Inactive</option>
                                </select>
                                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" class="um-select-caret">
                                    <polyline points="6 9 12 15 18 9"></polyline>
                                </svg>
                            </div>
                        </div>
                    </div>
                    
                    <div class="um-modal-actions">
                        <button type="button" class="btn-ghost" data-close-edit-modal>Cancel</button>
                        <button type="submit" class="btn-primary">Update User</button>
                    </div>
                </form>
            </div>
        </div>
    </div>

    <!-- Firebase CDN -->
    <script src="https://www.gstatic.com/firebasejs/9.23.0/firebase-app-compat.js"></script>
    <script src="https://www.gstatic.com/firebasejs/9.23.0/firebase-auth-compat.js"></script>
    <script src="https://www.gstatic.com/firebasejs/9.23.0/firebase-firestore-compat.js"></script>
    
    <!-- Notification System -->
    <script src="assets/js/notifications.js"></script>
    
    <!-- User Management Script (no auth.js conflict) -->
    <script src="assets/js/user-management.js?v=20250831-1"></script>
    
    <script>
        // Authentication check for user management
        window.addEventListener('load', () => {
            const adminData = localStorage.getItem('valwaste_admin');
            if (!adminData) {
                window.location.href = 'login.php';
                return;
            }
            
            // Update admin name in sidebar without conflict
            try {
                const admin = JSON.parse(adminData);
                const adminNameElement = document.querySelector('.account-name');
                if (adminNameElement && admin.displayName) {
                    adminNameElement.textContent = admin.displayName;
                }
            } catch (e) {
                console.error('Error parsing admin data:', e);
            }
        });
    </script>
</body>
</html>
