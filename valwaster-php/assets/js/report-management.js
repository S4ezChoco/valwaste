// Report Management JavaScript

// Current state
let currentTab = 'pending';
let currentPriority = 'All Priorities';
let currentCategory = 'All Categories';
let searchQuery = '';

// Category options per tab
const CATEGORY_OPTIONS = {
    pending: ['All Categories', 'Missed Collection', 'Illegal Dumping', 'Complaint'],
    resolved: ['All Categories', 'Damaged Equipment'],
    unresolved: ['All Categories', 'Other']
};

// Tab subtitles
const TAB_SUBTITLES = {
    pending: 'Reports waiting for review and resolution',
    resolved: 'Reports that have been successfully resolved',
    unresolved: 'Reports that could not be resolved and need attention'
};

// Sample data for demonstration
const sampleReports = {
    pending: [
        {
            id: 1,
            title: 'Missed garbage collection',
            location: 'Barangay Marulas',
            reportedBy: 'Juan Dela Cruz',
            priority: 'High',
            category: 'Missed Collection',
            date: '2024-01-15',
            status: 'Pending',
            description: 'The garbage truck did not arrive at the scheduled time. Residents are complaining about the accumulating waste in the area.',
            images: ['https://via.placeholder.com/300x300/ff6b6b/ffffff?text=Garbage+Overflow', 'https://via.placeholder.com/300x300/4ecdc4/ffffff?text=Street+View']
        },
        {
            id: 2,
            title: 'Illegal dumping near park',
            location: 'Barangay Karuhatan',
            reportedBy: 'Maria Santos',
            priority: 'Medium',
            category: 'Illegal Dumping',
            date: '2024-01-14',
            status: 'Pending',
            description: 'Someone has been dumping construction waste near the children\'s playground. This poses a safety hazard.',
            images: ['https://via.placeholder.com/300x300/45b7d1/ffffff?text=Illegal+Dump']
        },
        {
            id: 3,
            title: 'Broken waste bin',
            location: 'Barangay Gen. T. de Leon',
            reportedBy: 'Pedro Martinez',
            priority: 'Low',
            category: 'Complaint',
            date: '2024-01-13',
            status: 'Pending',
            description: 'The public waste bin on Main Street is damaged and needs replacement.',
            images: []
        }
    ],
    resolved: [
        {
            id: 4,
            title: 'Overflowing dumpster',
            location: 'Barangay Paso de Blas',
            reportedBy: 'Ana Reyes',
            priority: 'High',
            category: 'Missed Collection',
            date: '2024-01-10',
            status: 'Resolved',
            description: 'Dumpster was overflowing for several days. Issue has been resolved.',
            images: ['https://via.placeholder.com/300x300/95e1d3/ffffff?text=Fixed+Dumpster']
        }
    ],
    unresolved: [
        {
            id: 5,
            title: 'Persistent odor issue',
            location: 'Barangay Arkong Bato',
            reportedBy: 'Roberto Cruz',
            priority: 'Medium',
            category: 'Other',
            date: '2024-01-08',
            status: 'Unresolved',
            description: 'Strong odor persists despite multiple attempts to resolve. May require specialized treatment.',
            images: []
        }
    ]
};

// Initialize on page load
document.addEventListener('DOMContentLoaded', function() {
    updateCategoryOptions();
    updateReportCounts();
    displayReports();
});

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
    // In a real application, this would fetch new data from the server
    console.log('Refreshing reports...');
    displayReports();
}

// Update report counts
function updateReportCounts() {
    document.getElementById('pending-count').textContent = sampleReports.pending.length;
    document.getElementById('resolved-count').textContent = sampleReports.resolved.length;
    document.getElementById('unresolved-count').textContent = sampleReports.unresolved.length;
}

// Display reports based on current filters
function displayReports() {
    const tbody = document.getElementById('reports-tbody');
    let reports = sampleReports[currentTab] || [];
    
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
                        <button class="btn-view" onclick="viewReport(${report.id})">View</button>
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
        return `<button class="btn-resolve" onclick="resolveReport(${report.id})">Resolve</button>
                <button class="btn-unresolve" onclick="unresolveReport(${report.id})">Mark Unresolved</button>`;
    } else if (tab === 'resolved') {
        return `<button class="btn-unresolve" onclick="unresolveReport(${report.id})">Mark Unresolved</button>`;
    } else if (tab === 'unresolved') {
        return `<button class="btn-resolve" onclick="resolveReport(${report.id})">Mark Resolved</button>`;
    }
    return '';
}

// Find report by ID across all tabs
function findReportById(reportId) {
    for (const tab in sampleReports) {
        const report = sampleReports[tab].find(r => r.id === reportId);
        if (report) {
            return { report, currentTab: tab };
        }
    }
    return null;
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
function moveReport(reportId, targetStatus) {
    const result = findReportById(reportId);
    if (!result) {
        console.error('Report not found:', reportId);
        return;
    }
    
    const { report, currentTab } = result;
    
    // Remove from current tab
    const currentIndex = sampleReports[currentTab].findIndex(r => r.id === reportId);
    if (currentIndex > -1) {
        sampleReports[currentTab].splice(currentIndex, 1);
    }
    
    // Update status and add to target tab
    report.status = targetStatus.charAt(0).toUpperCase() + targetStatus.slice(1);
    sampleReports[targetStatus].push(report);
    
    // Update UI
    updateReportCounts();
    displayReports();
    
    // Show success message
    console.log(`Report ${reportId} moved to ${targetStatus}`);
}
