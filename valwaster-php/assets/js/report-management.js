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
            date: '2024-01-15'
        },
        {
            id: 2,
            title: 'Illegal dumping near park',
            location: 'Barangay Karuhatan',
            reportedBy: 'Maria Santos',
            priority: 'Medium',
            category: 'Illegal Dumping',
            date: '2024-01-14'
        }
    ],
    resolved: [],
    unresolved: []
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
                        ${currentTab === 'pending' ? `<button class="btn-resolve" onclick="resolveReport(${report.id})">Resolve</button>` : ''}
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

// View report details
function viewReport(reportId) {
    console.log('Viewing report:', reportId);
    // In a real application, this would open a modal or navigate to a detail page
}

// Resolve report
function resolveReport(reportId) {
    console.log('Resolving report:', reportId);
    // In a real application, this would update the report status
}
