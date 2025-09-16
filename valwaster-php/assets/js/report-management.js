// Report Management JavaScript

// Current state
let currentTab = 'pending';
let currentPriority = 'All Priorities';
let currentCategory = 'All Categories';
let searchQuery = '';

// Category options per tab
const CATEGORY_OPTIONS = {
    pending: ['All Categories', 'Collection Request', 'Missed Collection', 'Illegal Dumping', 'Complaint'],
    resolved: ['All Categories', 'Collection Request', 'Damaged Equipment'],
    unresolved: ['All Categories', 'Collection Request', 'Other']
};

// Tab subtitles
const TAB_SUBTITLES = {
    pending: 'Reports waiting for review and resolution',
    resolved: 'Reports that have been successfully resolved',
    unresolved: 'Reports that could not be resolved and need attention'
};

// Reports data - will be loaded from Firebase/database
const reportData = {
    pending: [],
    resolved: [],
    unresolved: []
};

// Load Firebase SDK
async function loadFirebaseSDK() {
    return new Promise((resolve, reject) => {
        // Load Firebase scripts
        const firebaseScript = document.createElement('script');
        firebaseScript.src = 'https://www.gstatic.com/firebasejs/9.23.0/firebase-app-compat.js';
        firebaseScript.onload = () => {
            const firestoreScript = document.createElement('script');
            firestoreScript.src = 'https://www.gstatic.com/firebasejs/9.23.0/firebase-firestore-compat.js';
            firestoreScript.onload = resolve;
            firestoreScript.onerror = reject;
            document.head.appendChild(firestoreScript);
        };
        firebaseScript.onerror = reject;
        document.head.appendChild(firebaseScript);
    });
}

// Initialize on page load
document.addEventListener('DOMContentLoaded', function() {
    updateCategoryOptions();
    showInitialLoadingState();
    loadCollectionApprovalReports();
    updateReportCounts();
});

// Show initial loading state
function showInitialLoadingState() {
    const tbody = document.getElementById('reports-tbody');
    tbody.innerHTML = `
        <tr class="loading">
            <td colspan="7" style="text-align: center; padding: 40px;">
                <div style="display: flex; align-items: center; justify-content: center; gap: 10px;">
                    <div class="loading-spinner"></div>
                    <span>Loading reports...</span>
                </div>
            </td>
        </tr>
    `;
    
    // Add loading spinner styles if not already present
    if (!document.getElementById('loading-spinner-styles')) {
        const style = document.createElement('style');
        style.id = 'loading-spinner-styles';
        style.textContent = `
            .loading-spinner {
                width: 20px;
                height: 20px;
                border: 2px solid #f3f4f6;
                border-top: 2px solid #3b82f6;
                border-radius: 50%;
                animation: spin 1s linear infinite;
            }
            @keyframes spin {
                0% { transform: rotate(0deg); }
                100% { transform: rotate(360deg); }
            }
            .loading td {
                color: #6b7280;
                font-style: italic;
            }
        `;
        document.head.appendChild(style);
    }
}

// Tab switching
function switchTab(tab) {
    currentTab = tab;
    
    // Update active tab styling
    document.querySelectorAll('.rm-tab').forEach(btn => {
        btn.classList.remove('active');
    });
    document.querySelector(`[data-tab="${tab}"]`).classList.add('active');
    
    // Update panel title and subtitle
    const titleMap = {
        pending: 'Pending Reports',
        resolved: 'Resolved Reports',
        unresolved: 'Unresolved Reports'
    };
    
    document.getElementById('panel-title').textContent = titleMap[tab];
    document.getElementById('panel-subtitle').textContent = TAB_SUBTITLES[tab];
    
    // Reset category filter and update options
    currentCategory = 'All Categories';
    document.getElementById('category-value').textContent = 'All Categories';
    updateCategoryOptions();
    
    // Display reports for the selected tab
    displayReports();
}

// Update category dropdown options based on current tab
function updateCategoryOptions() {
    const categoryOptionsDiv = document.getElementById('category-options');
    const options = CATEGORY_OPTIONS[currentTab];
    
    categoryOptionsDiv.innerHTML = options.map(option => `
        <button type="button" class="um-menu-item" onclick="selectCategory('${option}')">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" class="um-check ${currentCategory === option ? 'show' : ''}">
                <polyline points="20 6 9 17 4 12"></polyline>
            </svg>
            <span>${option}</span>
        </button>
    `).join('');
}

// Toggle dropdown visibility
function toggleDropdown(dropdownId) {
    const dropdown = document.getElementById(dropdownId);
    const isVisible = dropdown.style.display !== 'none';
    
    // Close all dropdowns
    document.querySelectorAll('.um-menu').forEach(menu => {
        menu.style.display = 'none';
    });
    
    // Toggle the clicked dropdown
    if (!isVisible) {
        dropdown.style.display = 'block';
    }
}

// Close dropdowns when clicking outside
document.addEventListener('click', function(event) {
    if (!event.target.closest('.um-filter-wrap')) {
        document.querySelectorAll('.um-menu').forEach(menu => {
            menu.style.display = 'none';
        });
    }
});

// Select priority filter
function selectPriority(priority) {
    currentPriority = priority;
    document.getElementById('priority-value').textContent = priority;
    
    // Update checkmarks
    document.querySelectorAll('#priority-dropdown .um-check').forEach(check => {
        check.classList.remove('show');
    });
    event.target.closest('.um-menu-item').querySelector('.um-check').classList.add('show');
    
    // Close dropdown
    document.getElementById('priority-dropdown').style.display = 'none';
    
    // Apply filter
    displayReports();
}

// Select category filter
function selectCategory(category) {
    currentCategory = category;
    document.getElementById('category-value').textContent = category;
    
    // Update checkmarks
    document.querySelectorAll('#category-dropdown .um-check').forEach(check => {
        check.classList.remove('show');
    });
    event.target.closest('.um-menu-item').querySelector('.um-check').classList.add('show');
    
    // Close dropdown
    document.getElementById('category-dropdown').style.display = 'none';
    
    // Apply filter
    displayReports();
}

// Search reports
function searchReports() {
    searchQuery = document.getElementById('search-input').value.toLowerCase();
    displayReports();
}

// Load collection approval reports from Firebase
async function loadCollectionApprovalReports() {
    try {
        // Show loading indicator
        const tbody = document.getElementById('reports-tbody');
        tbody.innerHTML = '<tr class="loading"><td colspan="7">Loading collection approval reports...</td></tr>';
        
        // Check if Firebase is already initialized
        if (typeof firebase === 'undefined') {
            // Load Firebase SDK
            await loadFirebaseSDK();
        }
        
        // Use the actual Firebase configuration
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
        if (!firebase.apps || firebase.apps.length === 0) {
            firebase.initializeApp(firebaseConfig);
        }
        
        const db = firebase.firestore();
        
        // First, let's check if there are any collections at all
        const allCollectionsSnapshot = await db.collection('collections').limit(5).get();
        console.log('Total collections in database:', allCollectionsSnapshot.size);
        
        if (allCollectionsSnapshot.size > 0) {
            console.log('Sample collection data:');
            allCollectionsSnapshot.docs.forEach(doc => {
                console.log('Collection ID:', doc.id, 'Status:', doc.data().status, 'User ID:', doc.data().user_id);
            });
        }
        
        // Also check users collection structure
        const usersSnapshot = await db.collection('users').limit(3).get();
        console.log('Total users in database:', usersSnapshot.size);
        
        if (usersSnapshot.size > 0) {
            console.log('Sample user data:');
            usersSnapshot.docs.forEach(doc => {
                console.log('User Document ID:', doc.id, 'User Data:', doc.data());
            });
        }
        
        // Query ALL collection requests from residents (not just approved)
        console.log('Querying for all collection requests from residents...');
        const snapshot = await db.collection('collections')
            .orderBy('created_at', 'desc')
            .get();
        
        console.log('Found', snapshot.size, 'total collection requests');
        
        // Clear existing collection reports
        reportData.pending = reportData.pending.filter(report => report.category !== 'Collection Request');
        reportData.resolved = reportData.resolved.filter(report => report.category !== 'Collection Request');
        reportData.unresolved = reportData.unresolved.filter(report => report.category !== 'Collection Request');
        
        // Convert collection requests to reports and categorize by status
        console.log('Processing all collection requests...');
        for (const doc of snapshot.docs) {
            const collectionData = doc.data();
            console.log('Processing collection:', doc.id, 'Status:', collectionData.status);
            console.log('Location data - address:', collectionData.address, 'location:', collectionData.location, 'lat/lng:', collectionData.latitude, collectionData.longitude);
            console.log('All collection fields:', Object.keys(collectionData));
            console.log('Full collection data:', collectionData);
            
            // Get user information
            let userName = 'Unknown User';
            try {
                console.log('Fetching user data for user_id:', collectionData.user_id);
                
                // Try to get user by document ID first
                const userDoc = await db.collection('users').doc(collectionData.user_id).get();
                if (userDoc.exists) {
                    const userData = userDoc.data();
                    console.log('User data found:', userData);
                    userName = `${userData.firstName || ''} ${userData.lastName || ''}`.trim() || userData.email || userData.name || 'Unknown User';
                } else {
                    // If not found by document ID, try by field
                    const userQuery = await db.collection('users').where('id', '==', collectionData.user_id).get();
                    if (!userQuery.empty) {
                        const userData = userQuery.docs[0].data();
                        console.log('User data found by field:', userData);
                        userName = `${userData.firstName || ''} ${userData.lastName || ''}`.trim() || userData.email || userData.name || 'Unknown User';
                    }
                }
                console.log('Final user name:', userName);
            } catch (userError) {
                console.log('Could not fetch user data:', userError);
                // Fallback to showing user ID if we can't get the name
                userName = `User ${collectionData.user_id.substring(0, 8)}`;
            }
            
            // Get barangay official name who approved
            let approvedByName = 'Unknown Official';
            try {
                if (collectionData.approved_by) {
                    console.log('Fetching approver data for approved_by:', collectionData.approved_by);
                    
                    // Try to get approver by document ID first
                    const approverDoc = await db.collection('users').doc(collectionData.approved_by).get();
                    if (approverDoc.exists) {
                        const approverData = approverDoc.data();
                        console.log('Approver data found:', approverData);
                        approvedByName = `${approverData.firstName || ''} ${approverData.lastName || ''}`.trim() || approverData.email || approverData.name || 'Unknown Official';
                    } else {
                        // If not found by document ID, try by field
                        const approverQuery = await db.collection('users').where('id', '==', collectionData.approved_by).get();
                        if (!approverQuery.empty) {
                            const approverData = approverQuery.docs[0].data();
                            console.log('Approver data found by field:', approverData);
                            approvedByName = `${approverData.firstName || ''} ${approverData.lastName || ''}`.trim() || approverData.email || approverData.name || 'Unknown Official';
                        }
                    }
                    console.log('Final approver name:', approvedByName);
                }
            } catch (approverError) {
                console.log('Could not fetch approver data:', approverError);
                // Fallback to showing approver ID if we can't get the name
                if (collectionData.approved_by) {
                    approvedByName = `Official ${collectionData.approved_by.substring(0, 8)}`;
                }
            }
            
            // Determine report status and category based on collection status
            let reportStatus, reportCategory, targetTab;
            
            switch (collectionData.status) {
                case 'pending':
                    reportStatus = 'Pending';
                    reportCategory = 'Collection Request';
                    targetTab = 'pending';
                    break;
                case 'approved':
                    reportStatus = 'Pending';
                    reportCategory = 'Collection Request';
                    targetTab = 'pending';
                    break;
                case 'scheduled':
                    reportStatus = 'Resolved';
                    reportCategory = 'Collection Request';
                    targetTab = 'resolved';
                    break;
                case 'inProgress':
                case 'in_progress':
                    reportStatus = 'Resolved';
                    reportCategory = 'Collection Request';
                    targetTab = 'resolved';
                    break;
                case 'completed':
                    reportStatus = 'Resolved';
                    reportCategory = 'Collection Request';
                    targetTab = 'resolved';
                    break;
                case 'cancelled':
                case 'rejected':
                    reportStatus = 'Unresolved';
                    reportCategory = 'Collection Request';
                    targetTab = 'unresolved';
                    break;
                default:
                    reportStatus = 'Pending';
                    reportCategory = 'Collection Request';
                    targetTab = 'pending';
            }
            
            // Get proper location display - check multiple possible field names
            let locationDisplay = 'Location not specified';
            
            // Check various possible address field names
            const possibleAddressFields = [
                'address', 'location', 'full_address', 'street_address', 
                'pickup_address', 'collection_address', 'user_address',
                'address_line', 'street', 'street_address_line'
            ];
            
            for (const field of possibleAddressFields) {
                if (collectionData[field] && collectionData[field].trim() !== '' && 
                    !collectionData[field].match(/^-?\d+\.?\d*,\s*-?\d+\.?\d*$/)) {
                    // Found a valid address field that's not just coordinates
                    locationDisplay = collectionData[field];
                    console.log(`✅ Using ${field} field for address:`, locationDisplay);
                    break;
                }
            }
            
            // If no address found, check if we have coordinates and try to create a readable format
            if (locationDisplay === 'Location not specified' && collectionData.latitude && collectionData.longitude) {
                // Check if there are other location-related fields
                if (collectionData.barangay) {
                    locationDisplay = `Barangay ${collectionData.barangay}`;
                } else if (collectionData.city || collectionData.municipality) {
                    locationDisplay = `${collectionData.city || collectionData.municipality}`;
                } else {
                    // Try to get a readable address from coordinates
                    try {
                        const readableAddress = await getAddressFromCoordinates(collectionData.latitude, collectionData.longitude);
                        if (readableAddress && readableAddress !== 'Unknown location') {
                            locationDisplay = readableAddress;
                        } else {
                            locationDisplay = 'Location not specified';
                        }
                    } catch (error) {
                        console.log('Could not reverse geocode coordinates:', error);
                        locationDisplay = 'Location not specified';
                    }
                }
                console.log('⚠️ No address found, using readable location:', locationDisplay);
            }
            
            const report = {
                id: `collection_${doc.id}`,
                title: `Collection Request - ${collectionData.waste_type || 'General Waste'}`,
                location: locationDisplay,
                reportedBy: userName,
                priority: getCollectionPriority(collectionData),
                category: reportCategory,
                date: collectionData.created_at || collectionData.approved_at,
                status: reportStatus,
                description: `Waste collection request from resident. Quantity: ${collectionData.quantity || 0} ${collectionData.unit || 'kg'}. ${collectionData.description || ''}`,
                collectionId: doc.id,
                wasteType: collectionData.waste_type,
                quantity: collectionData.quantity,
                unit: collectionData.unit,
                scheduledDate: collectionData.scheduled_date,
                approvedBy: approvedByName,
                approvedAt: collectionData.approved_at,
                barangay: collectionData.barangay,
                originalStatus: collectionData.status,
                // Store raw coordinates for reference
                latitude: collectionData.latitude,
                longitude: collectionData.longitude,
                rawAddress: collectionData.address
            };
            
            // Add to appropriate tab based on status
            reportData[targetTab].push(report);
        }
        
        console.log(`Loaded ${snapshot.size} collection requests from Firebase`);
        
        // Always update counts and display, even if no data
        updateReportCounts();
        displayReports();
        
        if (snapshot.size === 0) {
            console.log('No collection requests found in Firebase');
        }
        
        console.log('Final report data - Pending reports:', reportData.pending.length);
        console.log('Final report data - Resolved reports:', reportData.resolved.length);
        console.log('Final report data - Unresolved reports:', reportData.unresolved.length);
        console.log('Collection request reports:', reportData.pending.filter(r => r.category === 'Collection Request').length + 
                   reportData.resolved.filter(r => r.category === 'Collection Request').length + 
                   reportData.unresolved.filter(r => r.category === 'Collection Request').length);
        
    } catch (error) {
        console.error('Error loading collection approval reports:', error);
        
        // Show user-friendly message with more details
        const tbody = document.getElementById('reports-tbody');
        let errorMessage = 'Unable to load collection approval reports. ';
        
        if (error.message.includes('permission')) {
            errorMessage += 'Permission denied. Check Firebase security rules.';
        } else if (error.message.includes('network')) {
            errorMessage += 'Network error. Check your internet connection.';
        } else if (error.message.includes('firebase')) {
            errorMessage += 'Firebase connection error. Check configuration.';
        } else {
            errorMessage += 'Error: ' + error.message;
        }
        
        tbody.innerHTML = '<tr class="empty"><td colspan="7">' + errorMessage + '</td></tr>';
        
        // Also show in console for debugging
        console.log('Full error details:', error);
        console.log('Error type:', typeof error);
        console.log('Error message:', error.message);
    }
}

// Get priority based on collection data
function getCollectionPriority(collectionData) {
    const wasteType = collectionData.waste_type;
    const quantity = parseFloat(collectionData.quantity) || 0;
    
    if (wasteType === 'hazardous' || wasteType === 'electronic') {
        return 'High';
    } else if (quantity > 50 || wasteType === 'organic') {
        return 'Medium';
    } else {
        return 'Low';
    }
}

// Get readable address from coordinates using reverse geocoding
async function getAddressFromCoordinates(latitude, longitude) {
    try {
        // Use a free reverse geocoding service
        const response = await fetch(`https://api.bigdatacloud.net/data/reverse-geocode-client?latitude=${latitude}&longitude=${longitude}&localityLanguage=en`);
        const data = await response.json();
        
        if (data && data.localityInfo && data.localityInfo.administrative) {
            const admin = data.localityInfo.administrative;
            const parts = [];
            
            // Build address from available parts (skip country, focus on local areas)
            if (admin[3] && admin[3].name) parts.push(admin[3].name); // Barangay/District
            if (admin[2] && admin[2].name) parts.push(admin[2].name); // City/Municipality
            if (admin[1] && admin[1].name) parts.push(admin[1].name); // State/Province
            
            if (parts.length > 0) {
                return parts.join(', ');
            }
        }
        
        // Fallback to basic location info
        if (data && data.locality) {
            return data.locality;
        }
        
        // If we have coordinates but can't get address, return a generic location
        return 'Valenzuela City';
    } catch (error) {
        console.log('Reverse geocoding error:', error);
        return 'Valenzuela City';
    }
}


// Refresh reports
function refreshReports() {
    console.log('Refreshing reports...');
    showRefreshLoadingState();
    loadCollectionApprovalReports();
}

// Show loading state for refresh
function showRefreshLoadingState() {
    const tbody = document.getElementById('reports-tbody');
    tbody.innerHTML = `
        <tr class="loading">
            <td colspan="7" style="text-align: center; padding: 30px;">
                <div style="display: flex; align-items: center; justify-content: center; gap: 10px;">
                    <div class="loading-spinner"></div>
                    <span>Refreshing reports...</span>
                </div>
            </td>
        </tr>
    `;
}

// Test function to create a sample approved collection (for testing only)
async function createTestApprovedCollection() {
    try {
        if (typeof firebase === 'undefined') {
            await loadFirebaseSDK();
        }
        
        const firebaseConfig = {
            apiKey: "AIzaSyAr5KSpYvShZrCEJLMGf7ckrbfedta3W_M",
            authDomain: "valwaste-89930.firebaseapp.com",
            projectId: "valwaste-89930",
            storageBucket: "valwaste-89930.firebasestorage.app",
            messagingSenderId: "301491189774",
            appId: "1:301491189774:web:23f0fa68d2b264946b245f",
            measurementId: "G-C70DHXP9FW"
        };
        
        if (!firebase.apps || firebase.apps.length === 0) {
            firebase.initializeApp(firebaseConfig);
        }
        
        const db = firebase.firestore();
        
        // Create a test approved collection
        const testCollection = {
            user_id: 'test_user_123',
            waste_type: 'organic',
            quantity: 25,
            unit: 'kg',
            description: 'Test organic waste collection',
            address: '123 Test Street, Barangay Test',
            status: 'approved',
            created_at: new Date().toISO8601String(),
            approved_at: new Date().toISO8601String(),
            approved_by: 'test_barangay_official',
            barangay: 'Barangay Test',
            scheduled_date: new Date().toISO8601String()
        };
        
        await db.collection('collections').add(testCollection);
        console.log('Test approved collection created successfully!');
        window.notifications.success('Test approved collection created! Refresh the page to see it.');
        
    } catch (error) {
        console.error('Error creating test collection:', error);
        window.notifications.error('Error creating test collection: ' + error.message);
    }
}

// Update report counts
function updateReportCounts() {
    document.getElementById('pending-count').textContent = reportData.pending.length;
    document.getElementById('resolved-count').textContent = reportData.resolved.length;
    document.getElementById('unresolved-count').textContent = reportData.unresolved.length;
}

// Display reports based on current filters
function displayReports() {
    const tbody = document.getElementById('reports-tbody');
    let reports = reportData[currentTab] || [];
    
    // Apply filters
    if (currentPriority !== 'All Priorities') {
        reports = reports.filter(report => report.priority === currentPriority);
    }
    
    if (currentCategory !== 'All Categories') {
        reports = reports.filter(report => report.category === currentCategory);
    }
    
    if (searchQuery) {
        reports = reports.filter(report => 
            report.title.toLowerCase().includes(searchQuery) ||
            report.location.toLowerCase().includes(searchQuery) ||
            report.reportedBy.toLowerCase().includes(searchQuery)
        );
    }
    
    // Generate table rows
    if (reports.length === 0) {
        tbody.innerHTML = '<tr class="empty"><td colspan="7">No reports found</td></tr>';
    } else {
        tbody.innerHTML = reports.map(report => `
            <tr>
                <td>${report.title}</td>
                <td>${report.location}</td>
                <td>${report.reportedBy}</td>
                <td><span class="priority-badge priority-${report.priority.toLowerCase()}">${report.priority}</span></td>
                <td><span class="category-badge">${report.category}</span></td>
                <td>${formatDate(report.date)}</td>
                <td class="col-actions">
                    <div class="action-buttons">
                        <button class="btn-view" onclick="viewReport('${report.id}')">View</button>
                        ${getActionButtons(report, currentTab)}
                    </div>
                </td>
            </tr>
        `).join('');
    }
}

// Format date
function formatDate(dateString) {
    const date = new Date(dateString);
    return date.toLocaleDateString('en-US', { 
        year: 'numeric', 
        month: 'short', 
        day: 'numeric' 
    });
}

// Get action buttons based on report status and current tab
function getActionButtons(report, tab) {
    if (tab === 'pending') {
        if (report.status === 'Scheduled') {
            return `<button class="btn-info" disabled>Collection Scheduled</button>
                    <button class="btn-resolve" onclick="resolveReport('${report.id}')">Mark Completed</button>
                    <button class="btn-unresolve" onclick="unresolveReport('${report.id}')">Mark Unresolved</button>`;
        } else {
            return `<button class="btn-resolve" onclick="resolveReport('${report.id}')">Resolve</button>
                    <button class="btn-unresolve" onclick="unresolveReport('${report.id}')">Mark Unresolved</button>`;
        }
    } else if (tab === 'resolved') {
        return `<button class="btn-unresolve" onclick="unresolveReport('${report.id}')">Mark Unresolved</button>`;
    } else if (tab === 'unresolved') {
        return `<button class="btn-resolve" onclick="resolveReport('${report.id}')">Mark Resolved</button>`;
    }
    return '';
}

// Find report by ID across all tabs
function findReportById(reportId) {
    for (const tab in reportData) {
        const report = reportData[tab].find(r => r.id === reportId);
        if (report) {
            return { report, currentTab: tab };
        }
    }
    return null;
}

// View report details
function viewReport(reportId) {
    console.log('🔄 viewReport called with ID:', reportId);
    const result = findReportById(reportId);
    if (!result) {
        console.error('❌ Report not found:', reportId);
        window.notifications.error('Report not found: ' + reportId);
        return;
    }
    
    const { report } = result;
    console.log('✅ Found report:', report);
    
    // Populate modal with report data
    document.getElementById('modal-report-title').textContent = report.title;
    document.getElementById('detail-title').textContent = report.title;
    document.getElementById('detail-location').textContent = report.location;
    document.getElementById('detail-reporter').textContent = report.reportedBy;
    document.getElementById('detail-date').textContent = formatDate(report.date);
    document.getElementById('detail-priority').innerHTML = `<span class="priority-badge priority-${report.priority.toLowerCase()}">${report.priority}</span>`;
    document.getElementById('detail-category').innerHTML = `<span class="category-badge">${report.category}</span>`;
    document.getElementById('detail-status').textContent = report.status;
    document.getElementById('detail-description').textContent = report.description || 'No description provided.';
    
    // Show collection-specific details if it's a collection request report
    if (report.category === 'Collection Request') {
        showCollectionDetails(report);
    } else {
        hideCollectionDetails();
    }
    
    // Populate images
    const imagesContainer = document.getElementById('report-images');
    if (report.images && report.images.length > 0) {
        imagesContainer.innerHTML = report.images.map(imageUrl => `
            <div class="report-image">
                <img src="${imageUrl}" alt="Report image" onclick="openImageModal('${imageUrl}')">
            </div>
        `).join('');
    } else {
        imagesContainer.innerHTML = '<div class="no-images">No images attached</div>';
    }
    
    // Populate action buttons
    const actionsContainer = document.getElementById('report-modal-actions');
    const actionButtons = getModalActionButtons(report);
    actionsContainer.innerHTML = `
        <button type="button" class="btn-ghost" onclick="closeReportDetailsModal()">Close</button>
        ${actionButtons}
    `;
    
    // Show modal
    document.getElementById('reportDetailsModal').style.display = 'flex';
}

// Show collection-specific details in modal
function showCollectionDetails(report) {
    // Add collection details section if it doesn't exist
    let collectionDetailsSection = document.getElementById('collection-details-section');
    if (!collectionDetailsSection) {
        collectionDetailsSection = document.createElement('div');
        collectionDetailsSection.id = 'collection-details-section';
        collectionDetailsSection.className = 'detail-section';
        collectionDetailsSection.innerHTML = `
            <h4 class="detail-label">Collection Details</h4>
            <div class="detail-item">
                <span class="detail-key">Waste Type:</span>
                <span class="detail-value" id="detail-waste-type">-</span>
            </div>
            <div class="detail-item">
                <span class="detail-key">Quantity:</span>
                <span class="detail-value" id="detail-quantity">-</span>
            </div>
            <div class="detail-item">
                <span class="detail-key">Address:</span>
                <span class="detail-value" id="detail-address">-</span>
            </div>
            <div class="detail-item">
                <span class="detail-key">Coordinates:</span>
                <span class="detail-value" id="detail-coordinates">-</span>
            </div>
            <div class="detail-item">
                <span class="detail-key">Barangay:</span>
                <span class="detail-value" id="detail-barangay">-</span>
            </div>
            <div class="detail-item">
                <span class="detail-key">Approved By:</span>
                <span class="detail-value" id="detail-approved-by">-</span>
            </div>
            <div class="detail-item">
                <span class="detail-key">Approved At:</span>
                <span class="detail-value" id="detail-approved-at">-</span>
            </div>
        `;
        
        // Insert after the first detail section
        const firstSection = document.querySelector('.detail-section');
        firstSection.parentNode.insertBefore(collectionDetailsSection, firstSection.nextSibling);
    }
    
    // Populate collection details
    document.getElementById('detail-waste-type').textContent = report.wasteType || 'General';
    document.getElementById('detail-quantity').textContent = `${report.quantity || 0} ${report.unit || 'kg'}`;
    
    // Show clean address without coordinates
    let cleanAddress = report.rawAddress || report.location || 'Not specified';
    // Remove coordinates from address if they exist
    cleanAddress = cleanAddress.replace(/\s*\([^)]*\)\s*$/, '').trim();
    document.getElementById('detail-address').textContent = cleanAddress;
    
    document.getElementById('detail-coordinates').textContent = report.latitude && report.longitude ? 
        `${report.latitude}, ${report.longitude}` : 'Not specified';
    document.getElementById('detail-barangay').textContent = report.barangay || 'Not specified';
    document.getElementById('detail-approved-by').textContent = report.approvedBy || 'Unknown';
    document.getElementById('detail-approved-at').textContent = report.approvedAt ? formatDate(report.approvedAt) : 'Not specified';
    
    collectionDetailsSection.style.display = 'block';
}

// Hide collection-specific details
function hideCollectionDetails() {
    const collectionDetailsSection = document.getElementById('collection-details-section');
    if (collectionDetailsSection) {
        collectionDetailsSection.style.display = 'none';
    }
}

// Get action buttons for modal
function getModalActionButtons(report) {
    if (report.category === 'Collection Request') {
        if (report.status === 'Pending') {
            return `
                <button type="button" class="btn-primary" onclick="scheduleCollection('${report.collectionId}')">Schedule Collection</button>
                <button type="button" class="btn-resolve" onclick="resolveReportFromModal('${report.id}')">Mark as Resolved</button>
                <button type="button" class="btn-unresolve" onclick="unresolveReportFromModal('${report.id}')">Mark as Unresolved</button>
            `;
        } else if (report.status === 'Scheduled') {
            return `
                <button type="button" class="btn-info" disabled>Collection Scheduled</button>
                <button type="button" class="btn-resolve" onclick="resolveReportFromModal('${report.id}')">Mark as Completed</button>
                <button type="button" class="btn-unresolve" onclick="unresolveReportFromModal('${report.id}')">Mark as Unresolved</button>
            `;
        } else if (report.status === 'Resolved') {
            return `<button type="button" class="btn-unresolve" onclick="unresolveReportFromModal('${report.id}')">Mark as Unresolved</button>`;
        } else if (report.status === 'Unresolved') {
            return `<button type="button" class="btn-primary" onclick="resolveReportFromModal('${report.id}')">Mark as Resolved</button>`;
        }
    } else {
        if (report.status === 'Pending') {
            return `
                <button type="button" class="btn-primary" onclick="resolveReportFromModal('${report.id}')">Mark as Resolved</button>
                <button type="button" class="btn-unresolve" onclick="unresolveReportFromModal('${report.id}')">Mark as Unresolved</button>
            `;
        } else if (report.status === 'Resolved') {
            return `<button type="button" class="btn-unresolve" onclick="unresolveReportFromModal('${report.id}')">Mark as Unresolved</button>`;
        } else if (report.status === 'Unresolved') {
            return `<button type="button" class="btn-primary" onclick="resolveReportFromModal('${report.id}')">Mark as Resolved</button>`;
        }
    }
    return '';
}

// Close report details modal
function closeReportDetailsModal() {
    document.getElementById('reportDetailsModal').style.display = 'none';
}

// Close modal when clicking outside
function closeModal(event, modalId) {
    if (event.target.id === modalId) {
        document.getElementById(modalId).style.display = 'none';
    }
}

// Open image in larger view (placeholder function)
function openImageModal(imageUrl) {
    // Create a simple image overlay
    const overlay = document.createElement('div');
    const rmStyles = `
    .rm-panel { padding: 20px; }
    .rm-title { margin: 0 0 6px; font-size: 20px; font-weight: 700; }
    .rm-sub { margin: 0 0 16px; color: #6b7280; }
    .rm-row { display: flex; align-items: center; justify-content: space-between; margin-bottom: 16px; }
    .rm-search { position: relative; flex: 1; max-width: 320px; }
    .rm-search svg { position: absolute; left: 12px; top: 50%; transform: translateY(-50%); color: #9ca3af; }
    .rm-search input { width: 100%; height: 38px; padding: 0 12px 0 40px; border: 1px solid #e5e7eb; border-radius: 8px; outline: none; }
    .rm-filters { display: flex; gap: 12px; }
    `;
    const styleSheet = document.createElement('style');
    styleSheet.textContent = rmStyles;
    document.head.appendChild(styleSheet);
    overlay.style.cssText = `
        position: fixed; top: 0; left: 0; width: 100%; height: 100%;
        background: rgba(0,0,0,0.8); display: flex; align-items: center;
        justify-content: center; z-index: 10000; cursor: pointer;
    `;
    
    const img = document.createElement('img');
    img.src = imageUrl;
    img.style.cssText = 'max-width: 90%; max-height: 90%; border-radius: 8px;';
    
    overlay.appendChild(img);
    overlay.onclick = () => document.body.removeChild(overlay);
    document.body.appendChild(overlay);
}

// Resolve report
function resolveReport(reportId) {
    console.log('🔄 resolveReport called with ID:', reportId);
    moveReport(reportId, 'resolved');
}

// Resolve report from modal
function resolveReportFromModal(reportId) {
    moveReport(reportId, 'resolved');
    closeReportDetailsModal();
}

// Unresolve report
function unresolveReport(reportId) {
    console.log('🔄 unresolveReport called with ID:', reportId);
    moveReport(reportId, 'unresolved');
}

// Unresolve report from modal
function unresolveReportFromModal(reportId) {
    moveReport(reportId, 'unresolved');
    closeReportDetailsModal();
}

// Schedule collection for approved request
async function scheduleCollection(collectionId) {
    try {
        // Store the collection ID for later use
        window.currentSchedulingCollectionId = collectionId;
        
        // Show the existing Create Schedule modal
        const modal = document.getElementById('create-schedule-modal');
        if (modal) {
            modal.style.display = 'flex';
            
            // Set minimum date to today
            const today = new Date().toISOString().split('T')[0];
            const dateInput = document.getElementById('schedule-date');
            if (dateInput) {
                dateInput.min = today;
            }
            
            // Load trucks and drivers
            await loadTrucksForScheduling();
            await loadDriversForScheduling();
            
            // Override the form submission to handle collection scheduling
            const form = document.getElementById('createScheduleForm');
            if (form) {
                form.onsubmit = handleCollectionSchedule;
            }
        } else {
            // Fallback to simple modal if the main modal doesn't exist
            showSimpleSchedulingModal(collectionId);
        }
        
    } catch (error) {
        console.error('Error showing scheduling modal:', error);
        window.notifications.error('Error showing scheduling form. Please try again.');
    }
}

async function confirmScheduleCollection(collectionId) {
    try {
        const scheduledDate = document.getElementById('scheduledDate').value;
        const truckId = document.getElementById('truckId').value;
        const driverId = document.getElementById('driverId').value;
        
        if (!scheduledDate || !truckId || !driverId) {
            window.notifications.warning('Please fill in all fields.');
            return;
        }
        
        // Validate date format
        const date = new Date(scheduledDate);
        if (isNaN(date.getTime())) {
            window.notifications.error('Invalid date format.');
            return;
        }
        
        // Update the collection in Firebase
        if (typeof firebase === 'undefined') {
            await loadFirebaseSDK();
        }
        
        const firebaseConfig = {
            apiKey: "AIzaSyAr5KSpYvShZrCEJLMGf7ckrbfedta3W_M",
            authDomain: "valwaste-89930.firebaseapp.com",
            projectId: "valwaste-89930",
            storageBucket: "valwaste-89930.firebasestorage.app",
            messagingSenderId: "301491189774",
            appId: "1:301491189774:web:23f0fa68d2b264946b245f",
            measurementId: "G-C70DHXP9FW"
        };
        
        if (!firebase.apps || firebase.apps.length === 0) {
            firebase.initializeApp(firebaseConfig);
        }
        
        const db = firebase.firestore();
        
        // Update collection status to scheduled with truck and driver assignment
        await db.collection('collections').doc(collectionId).update({
            status: 'scheduled',
            scheduled_date: scheduledDate,
            scheduled_at: new Date().toISOString(),
            scheduled_by: 'admin',
            assigned_to: driverId,
            assigned_role: 'driver',
            assigned_at: new Date().toISOString(),
            truck_id: truckId
        });
        
        console.log(`Collection ${collectionId} scheduled for ${scheduledDate} with truck ${truckId} and driver ${driverId}`);
        
        // Send notification to the driver
        try {
            await db.collection('notifications').add({
                user_id: driverId,
                title: 'New Collection Assignment',
                message: `You have been assigned a new collection for ${scheduledDate}`,
                type: 'collection_assigned',
                data: {
                    collection_id: collectionId,
                    scheduled_date: scheduledDate,
                    truck_id: truckId
                },
                created_at: new Date().toISOString(),
                read: false
            });
            console.log('Notification sent to driver');
        } catch (notificationError) {
            console.log('Could not send notification to driver:', notificationError);
        }
        
        // Update the report status to scheduled (not resolved yet - driver still needs to complete)
        const result = findReportById(`collection_${collectionId}`);
        if (result) {
            const { report } = result;
            report.status = 'Scheduled';
            report.scheduledDate = scheduledDate;
            
            // Keep in pending tab until driver actually completes the collection
            // Don't move to resolved tab yet - driver needs to complete it first
            
            window.notifications.success('Collection scheduled successfully! Driver will complete the collection.');
        }
        
        closeSchedulingModal();
        closeReportDetailsModal();
        
    } catch (error) {
        console.error('Error scheduling collection:', error);
        window.notifications.error('Error scheduling collection. Please try again.');
    }
}

function closeSchedulingModal() {
    const modal = document.querySelector('.modal-overlay');
    if (modal) {
        modal.remove();
    }
}

// Close the Create Schedule modal
function closeCreateModal() {
    const modal = document.getElementById('create-schedule-modal');
    if (modal) {
        modal.style.display = 'none';
    }
    
    // Reset the form
    const form = document.getElementById('createScheduleForm');
    if (form) {
        form.reset();
    }
    
    // Clear the stored collection ID
    window.currentSchedulingCollectionId = null;
}

// Load trucks for scheduling
async function loadTrucksForScheduling() {
    try {
        if (typeof firebase === 'undefined') {
            await loadFirebaseSDK();
        }
        
        const firebaseConfig = {
            apiKey: "AIzaSyAr5KSpYvShZrCEJLMGf7ckrbfedta3W_M",
            authDomain: "valwaste-89930.firebaseapp.com",
            projectId: "valwaste-89930",
            storageBucket: "valwaste-89930.firebasestorage.app",
            messagingSenderId: "301491189774",
            appId: "1:301491189774:web:23f0fa68d2b264946b245f",
            measurementId: "G-C70DHXP9FW"
        };
        
        if (!firebase.apps || firebase.apps.length === 0) {
            firebase.initializeApp(firebaseConfig);
        }
        
        const db = firebase.firestore();
        
        // Get all trucks
        const trucksSnapshot = await db.collection('trucks').get();
        const truckSelect = document.getElementById('truck-select');
        
        if (truckSelect) {
            truckSelect.innerHTML = '<option value="" disabled selected>Select Truck</option>';
            
            trucksSnapshot.docs.forEach(doc => {
                const truckData = doc.data();
                const option = document.createElement('option');
                option.value = doc.id;
                option.textContent = `${truckData.name || truckData.id || doc.id} - ${truckData.type || 'General'}`;
                truckSelect.appendChild(option);
            });
        }
        
    } catch (error) {
        console.error('Error loading trucks:', error);
    }
}

// Load drivers for scheduling
async function loadDriversForScheduling() {
    try {
        if (typeof firebase === 'undefined') {
            await loadFirebaseSDK();
        }
        
        const firebaseConfig = {
            apiKey: "AIzaSyAr5KSpYvShZrCEJLMGf7ckrbfedta3W_M",
            authDomain: "valwaste-89930.firebaseapp.com",
            projectId: "valwaste-89930",
            storageBucket: "valwaste-89930.firebasestorage.app",
            messagingSenderId: "301491189774",
            appId: "1:301491189774:web:23f0fa68d2b264946b245f",
            measurementId: "G-C70DHXP9FW"
        };
        
        if (!firebase.apps || firebase.apps.length === 0) {
            firebase.initializeApp(firebaseConfig);
        }
        
        const db = firebase.firestore();
        
        // Get all drivers
        const driversSnapshot = await db.collection('users')
            .where('role', '==', 'driver')
            .get();
        
        const driverSelect = document.getElementById('driver-select');
        
        if (driverSelect) {
            driverSelect.innerHTML = '<option value="" disabled selected>Select Driver</option>';
            
            driversSnapshot.docs.forEach(doc => {
                const driverData = doc.data();
                const option = document.createElement('option');
                option.value = doc.id;
                option.textContent = `${driverData.firstName || ''} ${driverData.lastName || ''}`.trim() || driverData.email || doc.id;
                driverSelect.appendChild(option);
            });
        }
        
    } catch (error) {
        console.error('Error loading drivers:', error);
    }
}

// Handle collection scheduling
async function handleCollectionSchedule(event) {
    event.preventDefault();
    
    try {
        const collectionId = window.currentSchedulingCollectionId;
        if (!collectionId) {
            window.notifications.warning('No collection selected for scheduling.');
            return;
        }
        
        const truckId = document.getElementById('truck-select').value;
        const scheduledDate = document.getElementById('schedule-date').value;
        const startTime = document.getElementById('start-time').value;
        const endTime = document.getElementById('end-time').value;
        const driverId = document.getElementById('driver-select').value;
        
        if (!truckId || !scheduledDate || !startTime || !endTime || !driverId) {
            window.notifications.warning('Please fill in all required fields.');
            return;
        }
        
        // Update the collection in Firebase
        if (typeof firebase === 'undefined') {
            await loadFirebaseSDK();
        }
        
        const firebaseConfig = {
            apiKey: "AIzaSyAr5KSpYvShZrCEJLMGf7ckrbfedta3W_M",
            authDomain: "valwaste-89930.firebaseapp.com",
            projectId: "valwaste-89930",
            storageBucket: "valwaste-89930.firebasestorage.app",
            messagingSenderId: "301491189774",
            appId: "1:301491189774:web:23f0fa68d2b264946b245f",
            measurementId: "G-C70DHXP9FW"
        };
        
        if (!firebase.apps || firebase.apps.length === 0) {
            firebase.initializeApp(firebaseConfig);
        }
        
        const db = firebase.firestore();
        
        // Update collection status to scheduled with truck and driver assignment
        await db.collection('collections').doc(collectionId).update({
            status: 'scheduled',
            scheduled_date: scheduledDate,
            scheduled_at: new Date().toISOString(),
            scheduled_by: 'admin',
            assigned_to: driverId,
            assigned_role: 'driver',
            assigned_at: new Date().toISOString(),
            truck_id: truckId,
            start_time: startTime,
            end_time: endTime
        });
        
        console.log(`Collection ${collectionId} scheduled for ${scheduledDate} with truck ${truckId} and driver ${driverId}`);
        
        // Send notification to the driver
        try {
            await db.collection('notifications').add({
                user_id: driverId,
                title: 'New Collection Assignment',
                message: `You have been assigned a new collection for ${scheduledDate} from ${startTime} to ${endTime}`,
                type: 'collection_assigned',
                data: {
                    collection_id: collectionId,
                    scheduled_date: scheduledDate,
                    truck_id: truckId,
                    start_time: startTime,
                    end_time: endTime
                },
                created_at: new Date().toISOString(),
                read: false
            });
            console.log('Notification sent to driver');
        } catch (notificationError) {
            console.log('Could not send notification to driver:', notificationError);
        }
        
        // Update the report status to resolved
        const result = findReportById(`collection_${collectionId}`);
        if (result) {
            const { report } = result;
            report.status = 'Resolved';
            report.scheduledDate = scheduledDate;
            
            // Move to resolved tab
            moveReport(`collection_${collectionId}`, 'resolved');
            
            window.notifications.success('Collection scheduled successfully!');
        }
        
        // Close the modal
        const modal = document.getElementById('create-schedule-modal');
        if (modal) {
            modal.style.display = 'none';
        }
        
        // Close report details modal
        closeReportDetailsModal();
        
    } catch (error) {
        console.error('Error scheduling collection:', error);
        window.notifications.error('Error scheduling collection. Please try again.');
    }
}

// Fallback simple scheduling modal
function showSimpleSchedulingModal(collectionId) {
    const schedulingModal = document.createElement('div');
    schedulingModal.className = 'modal-overlay';
    schedulingModal.innerHTML = `
        <div class="modal-content" style="max-width: 500px;">
            <div class="modal-header">
                <h3>Schedule Collection</h3>
                <button type="button" class="close-btn" onclick="closeSchedulingModal()">&times;</button>
            </div>
            <div class="modal-body">
                <div class="form-group">
                    <label for="scheduledDate">Scheduled Date:</label>
                    <input type="date" id="scheduledDate" required>
                </div>
                <div class="form-group">
                    <label for="truckId">Truck ID:</label>
                    <input type="text" id="truckId" placeholder="e.g., TRUCK-001" required>
                </div>
                <div class="form-group">
                    <label for="driverId">Driver ID:</label>
                    <input type="text" id="driverId" placeholder="Driver's user ID" required>
                </div>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn-secondary" onclick="closeSchedulingModal()">Cancel</button>
                <button type="button" class="btn-primary" onclick="confirmScheduleCollection('${collectionId}')">Schedule Collection</button>
            </div>
        </div>
    `;
    
    document.body.appendChild(schedulingModal);
    
    // Set minimum date to today
    const today = new Date().toISOString().split('T')[0];
    document.getElementById('scheduledDate').min = today;
}

// Update collection status in Firebase
async function updateCollectionStatusInFirebase(collectionId, targetStatus) {
    try {
        if (typeof firebase === 'undefined') {
            await loadFirebaseSDK();
        }
        
        const firebaseConfig = {
            apiKey: "AIzaSyAr5KSpYvShZrCEJLMGf7ckrbfedta3W_M",
            authDomain: "valwaste-89930.firebaseapp.com",
            projectId: "valwaste-89930",
            storageBucket: "valwaste-89930.firebasestorage.app",
            messagingSenderId: "301491189774",
            appId: "1:301491189774:web:23f0fa68d2b264946b245f",
            measurementId: "G-C70DHXP9FW"
        };
        
        if (!firebase.apps || firebase.apps.length === 0) {
            firebase.initializeApp(firebaseConfig);
        }
        
        const db = firebase.firestore();
        
        // Map target status to Firebase status
        let firebaseStatus;
        switch (targetStatus) {
            case 'resolved':
                firebaseStatus = 'completed';
                break;
            case 'unresolved':
                firebaseStatus = 'cancelled';
                break;
            case 'pending':
                firebaseStatus = 'pending';
                break;
            default:
                firebaseStatus = targetStatus;
        }
        
        // Update the collection document
        await db.collection('collections').doc(collectionId).update({
            status: firebaseStatus,
            updated_at: new Date().toISOString(),
            updated_by: 'admin'
        });
        
        console.log(`✅ Collection ${collectionId} status updated to ${firebaseStatus} in Firebase`);
        
    } catch (error) {
        console.error('Error updating collection status in Firebase:', error);
        throw error;
    }
}

// Move report between tabs with Firebase update
async function moveReport(reportId, targetStatus) {
    console.log('🔄 moveReport called with ID:', reportId, 'targetStatus:', targetStatus);
    const result = findReportById(reportId);
    if (!result) {
        console.error('❌ Report not found:', reportId);
        window.notifications.error('Report not found: ' + reportId);
        return;
    }
    
    const { report, currentTab } = result;
    console.log('✅ Found report in tab:', currentTab, 'moving to:', targetStatus);
    
    try {
        // Update Firebase if this is a collection request
        if (report.category === 'Collection Request' && report.collectionId) {
            await updateCollectionStatusInFirebase(report.collectionId, targetStatus);
        }
        
        // Remove from current tab
        const currentIndex = reportData[currentTab].findIndex(r => r.id === reportId);
        if (currentIndex > -1) {
            reportData[currentTab].splice(currentIndex, 1);
        }
        
        // Update status and add to target tab
        report.status = targetStatus.charAt(0).toUpperCase() + targetStatus.slice(1);
        reportData[targetStatus].push(report);
        
        // Update UI
        updateReportCounts();
        displayReports();
        
        // Show success message
        console.log(`✅ Report ${reportId} moved to ${targetStatus}`);
        window.notifications.success(`Report moved to ${targetStatus} tab successfully!`);
        
    } catch (error) {
        console.error('Error updating report status:', error);
        window.notifications.error('Failed to update report status. Please try again.');
    }
}
