// Report Management JavaScript

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

// Initialize Firebase if not already initialized
if (!firebase.apps.length) {
    firebase.initializeApp(firebaseConfig);
}
const db = firebase.firestore();

// Current state
let currentTab = 'pending';
let currentPriority = 'All Priorities';
let currentCategory = 'All Categories';
let searchQuery = '';
let reportsData = [];

// Category options per tab
const CATEGORY_OPTIONS = {
    pending: ['All Categories', 'Missed Collection', 'Illegal Dumping', 'Complaint', 'Other'],
    resolved: ['All Categories', 'Missed Collection', 'Illegal Dumping', 'Complaint', 'Other'],
    unresolved: ['All Categories', 'Missed Collection', 'Illegal Dumping', 'Complaint', 'Other']
};

// Tab subtitles
const TAB_SUBTITLES = {
    pending: 'Reports waiting for review and resolution',
    resolved: 'Reports that have been successfully resolved',
    unresolved: 'Reports that could not be resolved and need attention'
};

// Initialize on page load
document.addEventListener('DOMContentLoaded', function() {
    updateCategoryOptions();
    loadReportsFromFirebase();
});

// Load reports from Firebase
function loadReportsFromFirebase() {
    console.log('Loading reports from Firebase...');
    
    db.collection('reports').onSnapshot((snapshot) => {
        reportsData = [];
        snapshot.forEach((doc) => {
            const report = { id: doc.id, ...doc.data() };
            // Convert Firebase timestamp to Date string
            if (report.createdAt) {
                report.date = report.createdAt.toDate().toISOString().split('T')[0];
            }
            reportsData.push(report);
        });
        
        console.log('Loaded reports:', reportsData.length);
        updateReportCounts();
        displayReports();
    }, (error) => {
        console.error('Error loading reports:', error);
        showError('Failed to load reports from server');
    });
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

// Refresh reports
function refreshReports() {
    console.log('Refreshing reports...');
    loadReportsFromFirebase();
}

// Update report counts
function updateReportCounts() {
    const pending = reportsData.filter(r => r.status === 'pending').length;
    const resolved = reportsData.filter(r => r.status === 'resolved').length;
    const unresolved = reportsData.filter(r => r.status === 'unresolved').length;
    
    document.getElementById('pending-count').textContent = pending;
    document.getElementById('resolved-count').textContent = resolved;
    document.getElementById('unresolved-count').textContent = unresolved;
}

// Display reports based on current filters
function displayReports() {
    const tbody = document.getElementById('reports-tbody');
    let reports = reportsData.filter(r => r.status === currentTab);
    
    // Apply filters
    if (currentPriority !== 'All Priorities') {
        reports = reports.filter(report => report.priority && report.priority.toLowerCase() === currentPriority.toLowerCase());
    }
    
    if (currentCategory !== 'All Categories') {
        reports = reports.filter(report => report.category === currentCategory);
    }
    
    if (searchQuery) {
        reports = reports.filter(report => 
            (report.title && report.title.toLowerCase().includes(searchQuery)) ||
            (report.location && report.location.toLowerCase().includes(searchQuery)) ||
            (report.reportedBy && report.reportedBy.toLowerCase().includes(searchQuery))
        );
    }
    
    // Generate table rows
    if (reports.length === 0) {
        tbody.innerHTML = '<tr class="empty"><td colspan="7">No reports found</td></tr>';
    } else {
        tbody.innerHTML = reports.map(report => `
            <tr>
                <td>${report.title || 'Untitled'}</td>
                <td>${report.location || 'Unknown'}</td>
                <td>${report.reportedBy || 'Anonymous'}</td>
                <td><span class="priority-badge priority-${(report.priority || 'low').toLowerCase()}">${report.priority || 'Low'}</span></td>
                <td><span class="category-badge">${report.category || 'Other'}</span></td>
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
        return `<button class="btn-resolve" onclick="resolveReport('${report.id}')">Resolve</button>
                <button class="btn-unresolve" onclick="unresolveReport('${report.id}')">Mark Unresolved</button>`;
    } else if (tab === 'resolved') {
        return `<button class="btn-unresolve" onclick="unresolveReport('${report.id}')">Mark Unresolved</button>`;
    } else if (tab === 'unresolved') {
        return `<button class="btn-resolve" onclick="resolveReport('${report.id}')">Mark Resolved</button>`;
    }
    return '';
}

// Find report by ID
function findReportById(reportId) {
    const report = reportsData.find(r => r.id === reportId);
    return report ? { report, currentTab: report.status } : null;
}

// View report details
function viewReport(reportId) {
    const result = findReportById(reportId);
    if (!result) {
        console.error('Report not found:', reportId);
        return;
    }
    
    const { report } = result;
    
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

// Get action buttons for modal
function getModalActionButtons(report) {
    if (report.status === 'Pending') {
        return `
            <button type="button" class="btn-primary" onclick="resolveReportFromModal(${report.id})">Mark as Resolved</button>
            <button type="button" class="btn-unresolve" onclick="unresolveReportFromModal(${report.id})">Mark as Unresolved</button>
        `;
    } else if (report.status === 'Resolved') {
        return `<button type="button" class="btn-unresolve" onclick="unresolveReportFromModal(${report.id})">Mark as Unresolved</button>`;
    } else if (report.status === 'Unresolved') {
        return `<button type="button" class="btn-primary" onclick="resolveReportFromModal(${report.id})">Mark as Resolved</button>`;
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
    moveReport(reportId, 'resolved');
}

// Resolve report from modal
function resolveReportFromModal(reportId) {
    moveReport(reportId, 'resolved');
    closeReportDetailsModal();
}

// Unresolve report
function unresolveReport(reportId) {
    moveReport(reportId, 'unresolved');
}

// Unresolve report from modal
function unresolveReportFromModal(reportId) {
    moveReport(reportId, 'unresolved');
    closeReportDetailsModal();
}

// Move report between tabs
async function moveReport(reportId, targetStatus) {
    const result = findReportById(reportId);
    if (!result) {
        console.error('Report not found:', reportId);
        return;
    }
    
    try {
        // Update in Firebase
        await db.collection('reports').doc(reportId).update({
            status: targetStatus,
            updatedAt: firebase.firestore.Timestamp.now()
        });
        
        // Update local data
        const report = reportsData.find(r => r.id === reportId);
        if (report) {
            report.status = targetStatus;
        }
        
        // Update UI
        updateReportCounts();
        displayReports();
        
        // Show success message
        showSuccess(`Report ${targetStatus === 'resolved' ? 'resolved' : targetStatus === 'unresolved' ? 'marked as unresolved' : 'updated'} successfully`);
    } catch (error) {
        console.error('Error updating report:', error);
        showError('Failed to update report status');
    }
}

// Show success message
function showSuccess(message) {
    if (typeof window.showNotification === 'function') {
        window.showNotification(message, 'success');
    } else {
        console.log('Success:', message);
    }
}

// Show error message
function showError(message) {
    if (typeof window.showNotification === 'function') {
        window.showNotification(message, 'error');
    } else {
        console.error('Error:', message);
    }
}
