// User Management JavaScript - Fixed for Firebase CDN

// Embedded data to avoid import issues
const valenzuelaBarangays = [
    "Arkong Bato", "Bagbaguin", "Balangkas", "Bignay", "Bisig",
    "Canumay East", "Canumay West", "Coloong", "Dalandanan",
    "Gen. T. De Leon", "Hen. T. De Leon", "Isla", "Karuhatan",
    "Lawang Bato", "Lingunan", "Mabolo", "Malanday", "Malinta",
    "Mapulang Lupa", "Marulas", "Maysan", "Palasan", "Parada",
    "Pariancillo Villa", "Paso de Blas", "Pasolo", "Poblacion",
    "Polo", "Punturin", "Rincon", "Tagalag", "Ugong",
    "Viente Reales", "Wawang Pulo"
];

// All roles that can exist in the system (for reading/displaying)
const allUserRoles = ["Resident", "Barangay Official", "Driver", "Waste Collector"];

// Roles that can be created through admin panel (excluding Resident - mobile app only)
const adminCreatableRoles = ["Barangay Official", "Driver", "Waste Collector"];

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
const auth = firebase.auth();
const db = firebase.firestore();

// Global variables
let allUsers = [];
let filteredUsers = [];
let currentFilter = "All Roles";

// DOM Elements
let userTableBody;
let searchInput;
let roleFilterButton;
let roleFilterMenu;
let createUserModal;
let createUserForm;
let editUserModal;
let editUserForm;

// Initialize when DOM is ready
document.addEventListener('DOMContentLoaded', function() {
    initializeUserManagement();
});

// Also initialize when page becomes visible (for tab switching)
document.addEventListener('visibilitychange', function() {
    if (!document.hidden && userTableBody) {
        console.log('Page became visible, checking user data...');
        // If we have no users loaded, try to load them
        if (allUsers.length === 0) {
            console.log('No users loaded, reinitializing...');
            loadUsers();
        }
    }
});

// Add a manual refresh function that can be called when switching tabs
window.refreshUserManagement = function() {
    console.log('Manual refresh triggered...');
    // Always try to load if no data or force if data seems stale
    if (!userDataLoaded || allUsers.length === 0) {
        loadUsers(true); // Force reload
    } else {
        // Just re-filter and render existing data
        filterUsers();
        renderUsers();
        updateUserCount();
    }
};

// Retry function for failed loads
window.retryLoadUsers = function() {
    console.log('Retrying user load...');
    loadUsers(true); // Force reload
};

// Force refresh function - completely reloads everything
window.forceRefreshUsers = function() {
    console.log('Force refreshing users...');
    loadUsers(true); // Force reload
};

// Add a function to check and fix filter state
window.checkAndFixUserFilter = function() {
    console.log('Checking filter state... currentFilter:', currentFilter, 'allUsers:', allUsers.length);
    
    // If we have users but none are showing, there might be a filter issue
    if (allUsers.length > 0 && filteredUsers.length === 0 && currentFilter === 'All Roles') {
        console.log('Filter issue detected, forcing re-filter...');
        filterUsers();
        renderUsers();
    }
};

// Debug function to check user roles
window.debugUserRoles = function() {
    console.log('=== USER ROLES DEBUG ===');
    console.log('Total users:', allUsers.length);
    console.log('Current filter:', currentFilter);
    console.log('Filtered users:', filteredUsers.length);
    
    const validRoles = ["Resident", "Barangay Official", "Driver"];
    console.log('Valid roles:', validRoles);
    
    // Group users by role
    const roleGroups = {};
    allUsers.forEach(user => {
        const role = user.role || 'No Role';
        if (!roleGroups[role]) {
            roleGroups[role] = [];
        }
        roleGroups[role].push(`${user.firstName} ${user.lastName}`);
    });
    
    console.log('Users by role:');
    Object.keys(roleGroups).forEach(role => {
        console.log(`  ${role}: ${roleGroups[role].length} users`);
        console.log(`    ${roleGroups[role].join(', ')}`);
    });
    
    // Check for users with invalid roles
    const invalidRoleUsers = allUsers.filter(user => !validRoles.includes(user.role));
    if (invalidRoleUsers.length > 0) {
        console.warn('Users with invalid roles:');
        invalidRoleUsers.forEach(user => {
            console.warn(`  ${user.firstName} ${user.lastName}: "${user.role}"`);
        });
    }
    
    console.log('=== END DEBUG ===');
};

function initializeUserManagement() {
    console.log('Initializing user management...');
    
    // Get DOM elements
    userTableBody = document.getElementById('userTableBody');
    searchInput = document.getElementById('searchUsers');
    roleFilterButton = document.getElementById('roleFilterButton');
    roleFilterMenu = document.getElementById('roleFilterMenu');
    createUserModal = document.getElementById('createUserModal');
    createUserForm = document.getElementById('createUserForm');
    editUserModal = document.getElementById('editUserModal');
    editUserForm = document.getElementById('editUserForm');

    console.log('DOM elements found:', {
        userTableBody: !!userTableBody,
        searchInput: !!searchInput,
        roleFilterButton: !!roleFilterButton,
        roleFilterMenu: !!roleFilterMenu,
        createUserModal: !!createUserModal,
        createUserForm: !!createUserForm
    });

    // Check if Firebase is available
    if (typeof firebase === 'undefined') {
        console.error('Firebase is not loaded!');
        userTableBody.innerHTML = `
            <tr class="empty">
                <td colspan="6" style="text-align: center; padding: 40px 12px; color: #dc2626;">
                    Firebase is not loaded. Please refresh the page.
                </td>
            </tr>
        `;
        return;
    }

    console.log('Firebase is available');
    
    try {
        // Initialize Firebase if not already initialized
        if (!window.firebaseApp) {
            window.firebaseApp = firebase.app();
        }
    } catch (error) {
        console.error('Error initializing Firebase:', error);
        userTableBody.innerHTML = `
            <tr class="empty">
                <td colspan="6" style="text-align: center; padding: 40px 12px; color: #dc2626;">
                    Error initializing Firebase: ${error.message}
                </td>
            </tr>
        `;
        return;
    }

    // Populate dropdowns
    populateBarangayDropdown();
    populateRoleDropdowns();
    populateEditDropdowns();
    
    // Set up event listeners
    setupEventListeners();
    
    // Load users from Firebase
    loadUsers();
    
    // Set up a timeout to check if users loaded after 5 seconds
    setTimeout(() => {
        if (!userDataLoaded || allUsers.length === 0) {
            console.warn('Users not loaded after 5 seconds, trying force reload...');
            loadUsers(true);
        }
    }, 5000);
    
    // Set up periodic check every 10 seconds for the first minute
    let checkCount = 0;
    const periodicCheck = setInterval(() => {
        checkCount++;
        console.log('Periodic check', checkCount, '- Users loaded:', userDataLoaded, 'Count:', allUsers.length);
        
        if (!userDataLoaded && checkCount < 6) { // Check for first minute only
            console.log('Attempting to reload users (periodic check)...');
            loadUsers(true);
        } else {
            clearInterval(periodicCheck);
        }
    }, 10000);
    
    console.log('User management initialization complete');
}

function populateBarangayDropdown() {
    const barangaySelect = document.getElementById('userBarangay');
    if (barangaySelect) {
        barangaySelect.innerHTML = '<option value="">Select Barangay</option>';
        valenzuelaBarangays.forEach(barangay => {
            const option = document.createElement('option');
            option.value = barangay;
            option.textContent = barangay;
            barangaySelect.appendChild(option);
        });
    }
}

function populateRoleDropdowns() {
    // Populate create user role dropdown - only admin-creatable roles
    const roleSelect = document.getElementById('userRole');
    if (roleSelect) {
        roleSelect.innerHTML = '';
        adminCreatableRoles.forEach(role => {
            const option = document.createElement('option');
            option.value = role;
            option.textContent = role;
            roleSelect.appendChild(option);
        });
    }

    // Populate filter dropdown - show all roles for filtering/viewing
    const filterMenu = document.getElementById('roleFilterMenu');
    if (filterMenu) {
        filterMenu.innerHTML = '';
        const allRolesOption = createFilterOption('All Roles');
        filterMenu.appendChild(allRolesOption);
        
        allUserRoles.forEach(role => {
            const option = createFilterOption(role);
            filterMenu.appendChild(option);
        });
    }
}

function createFilterOption(role) {
    const button = document.createElement('button');
    button.type = 'button';
    button.className = 'um-menu-item';
    button.onclick = () => setRoleFilter(role);
    
    button.innerHTML = `
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" class="um-check ${currentFilter === role ? 'show' : ''}">
            <polyline points="20 6 9 17 4 12"></polyline>
        </svg>
        <span>${role}</span>
    `;
    
    return button;
}

function populateEditDropdowns() {
    // Populate edit barangay dropdown
    const editBarangaySelect = document.getElementById('editBarangay');
    if (editBarangaySelect) {
        editBarangaySelect.innerHTML = '<option value="">Select Barangay</option>';
        valenzuelaBarangays.forEach(barangay => {
            const option = document.createElement('option');
            option.value = barangay;
            option.textContent = barangay;
            editBarangaySelect.appendChild(option);
        });
    }

    // Populate edit role dropdown - show all roles for editing existing users
    const editRoleSelect = document.getElementById('editRole');
    if (editRoleSelect) {
        editRoleSelect.innerHTML = '';
        allUserRoles.forEach(role => {
            const option = document.createElement('option');
            option.value = role;
            option.textContent = role;
            editRoleSelect.appendChild(option);
        });
    }
}

function setupEventListeners() {
    // Search functionality
    if (searchInput) {
        searchInput.addEventListener('input', handleSearch);
    }

    // Role filter toggle
    if (roleFilterButton) {
        roleFilterButton.addEventListener('click', toggleRoleFilter);
    }
    
    // Role selection change handler for barangay requirement
    const roleSelect = document.getElementById('userRole');
    if (roleSelect) {
        roleSelect.addEventListener('change', function() {
            updateBarangayRequirement(this.value);
        });
        // Set initial state
        updateBarangayRequirement(roleSelect.value);
    }

    // Close filter when clicking outside
    document.addEventListener('click', function(e) {
        if (roleFilterMenu && !roleFilterButton.contains(e.target) && !roleFilterMenu.contains(e.target)) {
            roleFilterMenu.style.display = 'none';
        }
    });

    // Create user form submission
    if (createUserForm) {
        createUserForm.addEventListener('submit', handleCreateUser);
    }

    // Edit user form submission
    if (editUserForm) {
        editUserForm.addEventListener('submit', handleEditUser);
    }

    // Modal close handlers
    const modalCloseButtons = document.querySelectorAll('[data-close-modal]');
    modalCloseButtons.forEach(button => {
        button.addEventListener('click', closeCreateUserModal);
    });

    const editModalCloseButtons = document.querySelectorAll('[data-close-edit-modal]');
    editModalCloseButtons.forEach(button => {
        button.addEventListener('click', closeEditUserModal);
    });

    // Close modal when clicking backdrop
    if (createUserModal) {
        createUserModal.addEventListener('click', function(e) {
            if (e.target === createUserModal) {
                closeCreateUserModal();
            }
        });
    }

    if (editUserModal) {
        editUserModal.addEventListener('click', function(e) {
            if (e.target === editUserModal) {
                closeEditUserModal();
            }
        });
    }
}

// Variable to track if listener is already set up
let userListenerActive = false;
let userDataLoaded = false;

function loadUsers(forceReload = false) {
    console.log('Loading users... forceReload:', forceReload, 'userListenerActive:', userListenerActive, 'userDataLoaded:', userDataLoaded);
    
    // If data is already loaded and not forcing reload, just re-render
    if (userDataLoaded && !forceReload && allUsers.length > 0) {
        console.log('Users already loaded, re-rendering...');
        filterUsers();
        renderUsers();
        updateUserCount();
        return;
    }
    
    // Reset state if forcing reload
    if (forceReload) {
        userListenerActive = false;
        userDataLoaded = false;
        allUsers = [];
        if (window.userListenerUnsubscribe) {
            window.userListenerUnsubscribe();
            window.userListenerUnsubscribe = null;
        }
    }
    
    // Prevent multiple listeners
    if (userListenerActive) {
        console.log('User listener already active, skipping...');
        return;
    }
    
    // Show loading state
    showLoadingState();
    
    // Listen for real-time updates using Firebase v9 compat
    const unsubscribe = db.collection('users').onSnapshot((snapshot) => {
        console.log('Firebase snapshot received with', snapshot.size, 'documents');
        userListenerActive = true;
        userDataLoaded = true;
        allUsers = [];
        
        snapshot.forEach((doc) => {
            const userData = doc.data();
            allUsers.push({
                id: doc.id,
                ...userData
            });
        });
        
        // Sort manually to handle missing createdAt fields
        allUsers.sort((a, b) => {
            const dateA = a.createdAt ? new Date(a.createdAt) : new Date(0);
            const dateB = b.createdAt ? new Date(b.createdAt) : new Date(0);
            return dateB - dateA; // desc order
        });
        
        console.log('Users loaded successfully:', allUsers.length, 'users');
        console.log('Current filter:', currentFilter);
        
        // Always re-filter and render after loading
        filterUsers();
        renderUsers();
        updateUserCount();
        
        // Auto-debug if no users are showing after load
        setTimeout(() => {
            if (allUsers.length > 0 && filteredUsers.length === 0) {
                console.warn('Auto-debugging: Users loaded but none visible');
                debugUserRoles();
            }
        }, 1000);
        
    }, (error) => {
        console.error('Firebase error loading users:', error);
        userListenerActive = false;
        userDataLoaded = false;
        showError('Error loading users: ' + error.message);
        showErrorState(error.message);
    });
    
    // Store unsubscribe function for cleanup
    window.userListenerUnsubscribe = unsubscribe;
}

function showLoadingState() {
    if (!userTableBody) return;
    
    // Add spinner animation if not already added
    if (!document.querySelector('#user-spinner-style')) {
        const style = document.createElement('style');
        style.id = 'user-spinner-style';
        style.textContent = `
            @keyframes spin {
                0% { transform: rotate(0deg); }
                100% { transform: rotate(360deg); }
            }
        `;
        document.head.appendChild(style);
    }
    
    userTableBody.innerHTML = `
        <tr class="empty">
            <td colspan="6" style="text-align: center; padding: 40px 12px; color: #6b7280;">
                <div style="display: flex; align-items: center; justify-content: center; gap: 8px;">
                    <div style="width: 16px; height: 16px; border: 2px solid #e5e7eb; border-top: 2px solid #3b82f6; border-radius: 50%; animation: spin 1s linear infinite;"></div>
                    Loading users...
                </div>
            </td>
        </tr>
    `;
}

function showErrorState(errorMessage) {
    if (!userTableBody) return;
    
    userTableBody.innerHTML = `
        <tr class="empty">
            <td colspan="6" style="text-align: center; padding: 40px 12px; color: #dc2626;">
                Error loading users: ${errorMessage}
                <br><br>
                <button onclick="retryLoadUsers()" style="background: #dc2626; color: white; padding: 8px 16px; border: none; border-radius: 4px; cursor: pointer; margin-right: 8px;">
                    Retry
                </button>
                <button onclick="forceRefreshUsers()" style="background: #3b82f6; color: white; padding: 8px 16px; border: none; border-radius: 4px; cursor: pointer; margin-right: 8px;">
                    Force Refresh
                </button>
                <button onclick="debugUserRoles()" style="background: #f59e0b; color: white; padding: 8px 16px; border: none; border-radius: 4px; cursor: pointer;">
                    Debug Roles
                </button>
            </td>
        </tr>
    `;
}

function filterUsers() {
    console.log('Filtering users... Total users:', allUsers.length, 'Current filter:', currentFilter);
    
    // Define valid roles for All Roles filter - use all possible user roles
    const validRoles = allUserRoles;
    
    // Start with all users
    let filtered = [...allUsers];
    console.log('Starting with', filtered.length, 'users');
    
    // Log all user roles for debugging
    const userRolesInData = [...new Set(allUsers.map(user => user.role))];
    console.log('User roles found in data:', userRolesInData);
    console.log('Valid roles for All Roles filter:', validRoles);
    
    // Apply role filter
    if (currentFilter && currentFilter !== 'All Roles') {
        // Filter for specific role
        const beforeFilter = filtered.length;
        filtered = filtered.filter(user => {
            const matches = user.role === currentFilter;
            if (!matches) {
                console.log('User filtered out by role:', user.firstName, user.lastName, 'has role:', user.role, 'filter is:', currentFilter);
            }
            return matches;
        });
        console.log('After role filter:', filtered.length, 'users (filtered out', beforeFilter - filtered.length, ')');
    } else {
        // "All Roles" filter - only show users with valid roles
        const beforeFilter = filtered.length;
        filtered = filtered.filter(user => {
            const hasValidRole = validRoles.includes(user.role);
            if (!hasValidRole) {
                console.log('User filtered out (invalid role):', user.firstName, user.lastName, 'has role:', user.role);
            }
            return hasValidRole;
        });
        console.log('After All Roles filter:', filtered.length, 'users (filtered out', beforeFilter - filtered.length, 'with invalid roles)');
        console.log('Showing users with roles:', validRoles.join(', '));
    }
    
    // Apply search filter
    const searchTerm = searchInput?.value?.toLowerCase()?.trim() || '';
    if (searchTerm) {
        const beforeSearch = filtered.length;
        filtered = filtered.filter(user => {
            const fullName = `${user.firstName || ''} ${user.lastName || ''}`.toLowerCase();
            const email = (user.email || '').toLowerCase();
            const barangay = (user.barangay || '').toLowerCase();
            
            const matches = fullName.includes(searchTerm) || 
                           email.includes(searchTerm) ||
                           barangay.includes(searchTerm);
            
            return matches;
        });
        console.log('After search filter:', filtered.length, 'users (filtered out', beforeSearch - filtered.length, ')');
    } else {
        console.log('No search filter applied');
    }
    
    filteredUsers = filtered;
    console.log('Final filtered users count:', filteredUsers.length);
    
    // If we have users with valid roles but none are showing with "All Roles", there might be an issue
    const usersWithValidRoles = allUsers.filter(user => validRoles.includes(user.role));
    if (usersWithValidRoles.length > 0 && filteredUsers.length === 0 && currentFilter === 'All Roles' && !searchTerm) {
        console.warn('Filter issue detected: Have', usersWithValidRoles.length, 'users with valid roles but none showing');
        // Reset filter and show users with valid roles
        filteredUsers = usersWithValidRoles;
        console.log('Reset filter - now showing', filteredUsers.length, 'users with valid roles');
    }
}

function renderUsers() {
    console.log('Rendering users. Filtered count:', filteredUsers.length, 'All count:', allUsers.length);
    
    if (!userTableBody) {
        console.error('User table body not found!');
        return;
    }
    
    if (filteredUsers.length === 0) {
        userTableBody.innerHTML = `
            <tr class="empty">
                <td colspan="6" style="text-align: center; padding: 40px 12px; color: #6b7280;">
                    ${allUsers.length === 0 ? 'No users found. Create your first user!' : 'No users match your search criteria.'}
                </td>
            </tr>
        `;
        return;
    }
    
    userTableBody.innerHTML = filteredUsers.map(user => `
        <tr>
            <td>
                <div style="display: flex; align-items: center; gap: 8px;">
                    <div style="width: 32px; height: 32px; border-radius: 50%; background: #ecfdf5; display: flex; align-items: center; justify-content: center; color: #166534; font-weight: 600;">
                        ${(user.firstName[0] + user.lastName[0]).toUpperCase()}
                    </div>
                    <div>
                        <div style="font-weight: 600; color: #111827;">${user.firstName} ${user.lastName}</div>
                        ${user.barangay ? `<div style="font-size: 12px; color: #6b7280;">${user.barangay}</div>` : ''}
                    </div>
                </div>
            </td>
            <td style="color: #374151;">${user.email}</td>
            <td>
                <span class="role-badge role-${user.role.toLowerCase().replace(' ', '-')}">${user.role}</span>
            </td>
            <td>
                <span class="status-badge ${user.isActive !== false ? 'active' : 'inactive'}">
                    ${user.isActive !== false ? 'Active' : 'Inactive'}
                </span>
            </td>
            <td style="color: #6b7280;">
                ${user.createdAt ? formatDate(user.createdAt) : 'N/A'}
            </td>
            <td class="col-actions">
                <div style="display: flex; gap: 8px; justify-content: center;">
                    <button class="btn-soft-sm" onclick="editUser('${user.id}')" title="Edit User">
                        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                            <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"></path>
                            <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"></path>
                        </svg>
                    </button>
                    <button class="btn-danger-sm" onclick="deleteUser('${user.id}', '${user.firstName} ${user.lastName}')" title="Delete User">
                        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                            <polyline points="3 6 5 6 21 6"></polyline>
                            <path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"></path>
                        </svg>
                    </button>
                </div>
            </td>
        </tr>
    `).join('');
}

function handleSearch() {
    filterUsers();
    renderUsers();
}

function toggleRoleFilter() {
    const isVisible = roleFilterMenu.style.display === 'block';
    roleFilterMenu.style.display = isVisible ? 'none' : 'block';
}

function setRoleFilter(role) {
    currentFilter = role;
    roleFilterButton.querySelector('span').textContent = role;
    roleFilterMenu.style.display = 'none';
    
    // Update check marks
    roleFilterMenu.querySelectorAll('.um-check').forEach(check => {
        check.classList.remove('show');
    });
    
    const selectedOption = Array.from(roleFilterMenu.querySelectorAll('.um-menu-item')).find(item => 
        item.querySelector('span').textContent === role
    );
    if (selectedOption) {
        selectedOption.querySelector('.um-check').classList.add('show');
    }
    
    filterUsers();
    renderUsers();
}

async function handleCreateUser(e) {
    e.preventDefault();
    
    const formData = new FormData(e.target);
    const userData = {
        firstName: formData.get('firstName').trim(),
        lastName: formData.get('lastName').trim(),
        email: formData.get('email').trim(),
        dateOfBirth: formData.get('dateOfBirth'),
        barangay: formData.get('barangay'),
        role: formData.get('role'),
        password: formData.get('password')
    };
    
    // Validation
    if (!userData.firstName || !userData.lastName || !userData.email || !userData.password) {
        showError('Please fill in all required fields.');
        return;
    }
    
    // Check if barangay is required for Driver and Palero (Waste Collector) roles
    if ((userData.role === 'Driver' || userData.role === 'Waste Collector') && !userData.barangay) {
        showError(`Barangay is required for ${userData.role} role.`);
        return;
    }
    
    if (userData.password.length < 6) {
        showError('Password must be at least 6 characters long.');
        return;
    }
    
    // Debug: Log the user data being processed
    console.log('Processing user creation for:', {
        name: `${userData.firstName} ${userData.lastName}`,
        email: userData.email,
        role: userData.role,
        barangay: userData.barangay
    });
    
    // Prepare submit button state outside try so finally can restore it
    let submitButton = e.target.querySelector('button[type="submit"]');
    let originalText = submitButton ? submitButton.textContent : 'Create User';
    let authUserId = null;
    
    try {
        // Show loading state
        if (submitButton) {
            submitButton.textContent = 'Creating...';
            submitButton.disabled = true;
        }
        
        // Create user in Firebase Authentication for ALL roles
        console.log('Creating user with role:', userData.role, 'Email:', userData.email);
        console.log('Firebase Auth available:', typeof firebase !== 'undefined' && typeof firebase.auth !== 'undefined');
        
        try {
            console.log('Attempting Firebase Auth creation...');
            
            // Store current admin user before creating new user
            const currentAdmin = firebase.auth().currentUser;
            
            const userCredential = await firebase.auth().createUserWithEmailAndPassword(userData.email, userData.password);
            authUserId = userCredential.user.uid;
            console.log('✅ SUCCESS: User created in Firebase Auth with UID:', authUserId, 'Role:', userData.role);
            
            // Update the user's display name in Firebase Auth
            await userCredential.user.updateProfile({
                displayName: `${userData.firstName} ${userData.lastName}`
            });
            console.log('✅ SUCCESS: Display name updated for', userData.role, 'user');
            
            // Sign out the newly created user and restore admin session
            await firebase.auth().signOut();
            if (currentAdmin) {
                // Re-authenticate the admin user
                await firebase.auth().updateCurrentUser(currentAdmin);
                console.log('✅ SUCCESS: Admin session restored');
            }
            
        } catch (authError) {
            console.error('❌ FAILED: Firebase Auth creation failed for role:', userData.role);
            console.error('Auth Error Details:', {
                code: authError.code,
                message: authError.message,
                email: userData.email,
                role: userData.role
            });
            // If auth creation fails, we should not proceed with Firestore creation
            throw new Error(`Failed to create user account: ${authError.message}`);
        }
        
        // Create user document in Firestore
        const userDoc = {
            firstName: userData.firstName,
            lastName: userData.lastName,
            email: userData.email,
            dateOfBirth: userData.dateOfBirth || null,
            barangay: userData.barangay || null,
            role: userData.role,
            isActive: true,
            createdAt: new Date().toISOString(),
            authUserId: authUserId
        };
        
        console.log('Creating user document in Firestore:', userDoc);
        const docRef = await db.collection('users').add(userDoc);
        console.log('User document created with ID:', docRef.id);
        
        // Reset form and close modal
        createUserForm.reset();
        closeCreateUserModal();
        showSuccess('User created successfully in both Authentication and Database!');
        
    } catch (error) {
        console.error('Error creating user:', error);
        
        // If Firestore creation failed but Auth succeeded, clean up Auth user
        if (authUserId && error.message.includes('Firestore')) {
            try {
                const user = firebase.auth().currentUser;
                if (user && user.uid === authUserId) {
                    await user.delete();
                    console.log('Cleaned up Auth user after Firestore failure');
                }
            } catch (cleanupError) {
                console.error('Failed to cleanup Auth user:', cleanupError);
            }
        }
        
        showError(error.message || 'Error creating user. Please try again.');
    } finally {
        // Reset button state (safely)
        try {
            submitButton = e.target.querySelector('button[type="submit"]') || submitButton;
            if (submitButton) {
                submitButton.textContent = originalText;
                submitButton.disabled = false;
            }
        } catch (e) {
            console.error('Failed to reset submit button state:', e);
        }
    }
}

function updateUserCount() {
    const totalUsersElement = document.getElementById('totalUsers');
    if (totalUsersElement) {
        totalUsersElement.textContent = allUsers.length;
    }
    
    // Also update dashboard total users if on dashboard page
    const dashboardTotalUsers = document.querySelector('#totalUsers');
    if (dashboardTotalUsers && window.location.pathname.includes('dashboard')) {
        dashboardTotalUsers.textContent = allUsers.length;
    }
}

function formatDate(dateString) {
    if (!dateString) return 'N/A';
    try {
        const date = new Date(dateString);
        return date.toLocaleDateString('en-US', {
            year: 'numeric',
            month: 'short',
            day: 'numeric'
        });
    } catch (error) {
        return 'N/A';
    }
}

function showError(message) {
    console.error('Error:', message);
    // Use modern notification if available, fallback to alert
    if (window.notifications && window.notifications.error) {
        window.notifications.error(message);
    } else if (typeof window.showError === 'function') {
        window.showError(message);
    } else {
        alert('Error: ' + message);
    }
}

function updateBarangayRequirement(role) {
    const barangayRequired = document.getElementById('barangayRequired');
    const barangaySelect = document.getElementById('userBarangay');
    
    if (role === 'Driver' || role === 'Waste Collector') {
        // Show required indicator
        if (barangayRequired) {
            barangayRequired.style.display = 'inline';
        }
        if (barangaySelect) {
            barangaySelect.setAttribute('required', 'required');
        }
    } else {
        // Hide required indicator
        if (barangayRequired) {
            barangayRequired.style.display = 'none';
        }
        if (barangaySelect) {
            barangaySelect.removeAttribute('required');
        }
    }
}

function showSuccess(message) {
    console.log('Success:', message);
    // Use modern notification if available, fallback to alert
    if (window.notifications && window.notifications.success) {
        window.notifications.success(message);
    } else if (typeof window.showSuccess === 'function') {
        window.showSuccess(message);
    } else {
        alert('Success: ' + message);
    }
}

// Global functions for button actions
window.openCreateUserModal = function() {
    createUserModal.style.display = 'grid';
    // Focus first input
    setTimeout(() => {
        const firstInput = createUserModal.querySelector('input');
        if (firstInput) firstInput.focus();
    }, 100);
}

window.closeCreateUserModal = function() {
    createUserModal.style.display = 'none';
    createUserForm.reset();
}

window.editUser = function(userId) {
    const user = allUsers.find(u => u.id === userId);
    if (!user) {
        showError('User not found.');
        return;
    }
    
    // Populate edit form
    document.getElementById('editUserId').value = userId;
    document.getElementById('editFirstName').value = user.firstName || '';
    document.getElementById('editLastName').value = user.lastName || '';
    document.getElementById('editEmail').value = user.email || '';
    document.getElementById('editDateOfBirth').value = user.dateOfBirth || '';
    document.getElementById('editBarangay').value = user.barangay || '';
    document.getElementById('editRole').value = user.role || '';
    document.getElementById('editStatus').value = user.isActive !== false ? 'true' : 'false';
    
    // Show modal
    editUserModal.style.display = 'grid';
    
    // Focus first input
    setTimeout(() => {
        document.getElementById('editFirstName').focus();
    }, 100);
}

window.deleteUser = async function(userId, userName) {
    const performDelete = async () => {
        try {
            // First get the user document to find the authUserId
            const userDoc = await db.collection('users').doc(userId).get();
            const userData = userDoc.data();
            const authUserId = userData?.authUserId;
            
            // Delete from Firestore first
            await db.collection('users').doc(userId).delete();
            console.log('User deleted from Firestore');
            
            // If user has an authUserId, try to delete from Firebase Auth
            if (authUserId) {
                try {
                    // Note: Deleting other users from Firebase Auth requires Admin SDK
                    // This is a limitation of client-side Firebase Auth
                    // For now, we'll log this and handle it server-side if needed
                    console.log('User has authUserId:', authUserId, '- Auth deletion requires server-side implementation');
                    showSuccess(`User ${userName} deleted from database. Note: Authentication account may need manual cleanup.`);
                } catch (authError) {
                    console.error('Could not delete from Firebase Auth (requires Admin SDK):', authError);
                    showSuccess(`User ${userName} deleted from database. Authentication account requires manual cleanup.`);
                }
            } else {
                showSuccess(`User ${userName} deleted successfully!`);
            }
            
        } catch (error) {
            console.error('Error deleting user:', error);
            showError('Error deleting user. Please try again.');
        }
    };

    // Use modern confirm if available, fallback to browser confirm
    if (window.notifications && window.notifications.confirm) {
        window.notifications.confirm(
            `Are you sure you want to delete ${userName}? This action cannot be undone.`,
            performDelete
        );
    } else if (typeof window.showConfirm === 'function') {
        window.showConfirm(
            `Are you sure you want to delete ${userName}? This action cannot be undone.`,
            performDelete
        );
    } else {
        if (confirm(`Are you sure you want to delete ${userName}? This action cannot be undone.`)) {
            await performDelete();
        }
    }
}

window.closeEditUserModal = function() {
    if (!editUserModal || !editUserForm) return;
    editUserModal.style.display = 'none';
    editUserForm.reset();
}

async function handleEditUser(e) {
    e.preventDefault();
    
    const formData = new FormData(e.target);
    const userId = formData.get('userId');
    const userData = {
        firstName: formData.get('firstName')?.trim() || '',
        lastName: formData.get('lastName')?.trim() || '',
        email: formData.get('email')?.trim() || '',
        dateOfBirth: formData.get('dateOfBirth') || null,
        barangay: formData.get('barangay') || null,
        role: formData.get('role') || '',
        isActive: formData.get('status') === 'true'
    };
    
    // Validation
    if (!userData.firstName || !userData.lastName || !userData.email) {
        showError('Please fill in all required fields.');
        return;
    }
    
    try {
        // Show loading state
        const submitButton = e.target.querySelector('button[type="submit"]');
        const originalText = submitButton.textContent;
        submitButton.textContent = 'Updating...';
        submitButton.disabled = true;
        
        // Update user document in Firestore
        await db.collection('users').doc(userId).update(userData);
        
        // Close modal and show success
        closeEditUserModal();
        showSuccess('User updated successfully!');
        
    } catch (error) {
        console.error('Error updating user:', error);
        showError(error.message || 'Error updating user. Please try again.');
    } finally {
        // Reset button state
        const submitButton = e.target.querySelector('button[type="submit"]');
        if (submitButton) {
            submitButton.textContent = 'Update User';
            submitButton.disabled = false;
        }
    }
}

// No exports needed for non-module script
