// Truck Schedule JavaScript

// Current date state
let currentDate = new Date();
let currentMonth = currentDate.getMonth();
let currentYear = currentDate.getFullYear();
let selectedDate = null;

// Month names
const monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
];

// Initialize on page load
document.addEventListener('DOMContentLoaded', function() {
    generateCalendar();
    updateMonthYearDisplay();
    
    // Set today's date as default in the modal
    const today = new Date();
    document.getElementById('schedule-date').value = formatDateForInput(today);
});

// Generate calendar grid
function generateCalendar() {
    const calendarGrid = document.getElementById('calendar-grid');
    calendarGrid.innerHTML = '';
    
    // Get first day of month and number of days
    const firstDay = new Date(currentYear, currentMonth, 1);
    const lastDay = new Date(currentYear, currentMonth + 1, 0);
    const daysInMonth = lastDay.getDate();
    const startingDayOfWeek = firstDay.getDay();
    
    // Get today's date for comparison
    const today = new Date();
    const isCurrentMonth = today.getFullYear() === currentYear && today.getMonth() === currentMonth;
    const todayDate = today.getDate();
    
    // Create empty cells for days before month starts
    for (let i = 0; i < startingDayOfWeek; i++) {
        const emptyCell = document.createElement('div');
        emptyCell.className = 'cal-cell is-empty';
        calendarGrid.appendChild(emptyCell);
    }
    
    // Create cells for each day of the month
    for (let day = 1; day <= daysInMonth; day++) {
        const cell = document.createElement('div');
        cell.className = 'cal-cell';
        
        // Check if this is today
        if (isCurrentMonth && day === todayDate) {
            cell.classList.add('is-today');
        }
        
        // Add day number
        const dayNum = document.createElement('div');
        dayNum.className = 'cal-daynum';
        dayNum.innerHTML = `<span>${day}</span>`;
        cell.appendChild(dayNum);
        
        // Add plus button
        const addBtn = document.createElement('button');
        addBtn.className = 'cal-add';
        addBtn.type = 'button';
        addBtn.textContent = '+';
        addBtn.setAttribute('aria-label', 'Create schedule for this day');
        addBtn.onclick = function() {
            const date = new Date(currentYear, currentMonth, day);
            openCreateModalForDate(date);
        };
        cell.appendChild(addBtn);
        
        calendarGrid.appendChild(cell);
    }
    
    // Fill remaining cells to complete the grid
    const totalCells = calendarGrid.children.length;
    const remainingCells = 42 - totalCells; // 6 rows × 7 days = 42
    for (let i = 0; i < remainingCells; i++) {
        const emptyCell = document.createElement('div');
        emptyCell.className = 'cal-cell is-empty';
        calendarGrid.appendChild(emptyCell);
    }
}

// Update month and year display
function updateMonthYearDisplay() {
    document.getElementById('month-display').textContent = monthNames[currentMonth];
    document.getElementById('month-year-display').textContent = `${monthNames[currentMonth]} ${currentYear}`;
    
    // Update active state in dropdown
    const monthItems = document.querySelectorAll('#month-dropdown .um-menu-item');
    monthItems.forEach((item, index) => {
        if (index === currentMonth) {
            item.classList.add('active');
            item.querySelector('.um-check').classList.add('show');
        } else {
            item.classList.remove('active');
            item.querySelector('.um-check').classList.remove('show');
        }
    });
}

// Navigation functions
function previousMonth() {
    currentMonth--;
    if (currentMonth < 0) {
        currentMonth = 11;
        currentYear--;
    }
    generateCalendar();
    updateMonthYearDisplay();
}

function nextMonth() {
    currentMonth++;
    if (currentMonth > 11) {
        currentMonth = 0;
        currentYear++;
    }
    generateCalendar();
    updateMonthYearDisplay();
}

function goToToday() {
    const today = new Date();
    currentMonth = today.getMonth();
    currentYear = today.getFullYear();
    generateCalendar();
    updateMonthYearDisplay();
}

// Month dropdown functions
function toggleMonthDropdown() {
    const dropdown = document.getElementById('month-dropdown');
    const isVisible = dropdown.style.display !== 'none';
    
    if (isVisible) {
        dropdown.style.display = 'none';
    } else {
        dropdown.style.display = 'block';
    }
}

function selectMonth(monthIndex) {
    currentMonth = monthIndex;
    generateCalendar();
    updateMonthYearDisplay();
    document.getElementById('month-dropdown').style.display = 'none';
}

// Close dropdown when clicking outside
document.addEventListener('click', function(event) {
    const monthDropdown = document.querySelector('.month-dd');
    if (!monthDropdown.contains(event.target)) {
        document.getElementById('month-dropdown').style.display = 'none';
    }
});

// Modal functions
function openCreateModal() {
    document.getElementById('create-schedule-modal').style.display = 'flex';
    document.body.style.overflow = 'hidden';
}

function openCreateModalForDate(date) {
    selectedDate = date;
    document.getElementById('schedule-date').value = formatDateForInput(date);
    openCreateModal();
}

function closeCreateModal() {
    document.getElementById('create-schedule-modal').style.display = 'none';
    document.body.style.overflow = '';
    
    // Reset form
    document.getElementById('createScheduleForm').reset();
    document.getElementById('schedule-date').value = formatDateForInput(new Date());
}

// Close modal when clicking outside
document.addEventListener('click', function(event) {
    const modal = document.getElementById('create-schedule-modal');
    if (event.target === modal) {
        closeCreateModal();
    }
});

// Close modal with Escape key
document.addEventListener('keydown', function(event) {
    if (event.key === 'Escape') {
        const modal = document.getElementById('create-schedule-modal');
        if (modal.style.display === 'flex') {
            closeCreateModal();
        }
    }
});

// Handle form submission
function handleCreateSchedule(event) {
    event.preventDefault();
    
    // Get form values
    const truck = document.getElementById('truck-select').value;
    const date = document.getElementById('schedule-date').value;
    const startTime = document.getElementById('start-time').value;
    const endTime = document.getElementById('end-time').value;
    const driver = document.getElementById('driver-select').value;
    
    // Get selected collectors
    const collectors = [];
    document.querySelectorAll('input[name="collectors"]:checked').forEach(checkbox => {
        collectors.push(checkbox.value);
    });
    
    // Get selected locations
    const locations = [];
    document.querySelectorAll('input[name="locations"]:checked').forEach(checkbox => {
        locations.push(checkbox.value);
    });
    
    // Validate collectors (exactly 3)
    if (collectors.length !== 3) {
        alert('Please select exactly 3 waste collectors.');
        return;
    }
    
    // Validate locations (at least 1)
    if (locations.length < 1) {
        alert('Please select at least 1 location.');
        return;
    }
    
    // Validate time
    if (endTime <= startTime) {
        alert('End time must be later than start time.');
        return;
    }
    
    // Create schedule object
    const schedule = {
        truck,
        date,
        startTime,
        endTime,
        driver,
        collectors,
        locations
    };
    
    console.log('Creating schedule:', schedule);
    
    // In a real application, this would send data to the server
    alert('Schedule created successfully!');
    
    // Close modal
    closeCreateModal();
}

// Format date for input field
function formatDateForInput(date) {
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    return `${year}-${month}-${day}`;
}
