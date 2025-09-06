<?php
// Get current page for active navigation
$current_page = basename($_SERVER['PHP_SELF'], '.php');
?>

<aside class="sidebar" id="sidebar">
  <div class="sidebar-mobile-header">
    <div class="brand">
      <div class="brand-circle">V</div>
      <div class="brand-name">ValWaste</div>
    </div>
    <button class="closebtn" aria-label="Close sidebar" onclick="closeSidebar()">
      <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
        <line x1="18" y1="6" x2="6" y2="18"></line>
        <line x1="6" y1="6" x2="18" y2="18"></line>
      </svg>
    </button>
  </div>

  <nav class="nav" onclick="closeSidebar()">
    <a href="dashboard.php" class="nav-item <?php echo $current_page === 'dashboard' ? 'active' : ''; ?>">
      <span class="icon-left">
        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <rect x="3" y="3" width="7" height="7"></rect>
          <rect x="14" y="3" width="7" height="7"></rect>
          <rect x="14" y="14" width="7" height="7"></rect>
          <rect x="3" y="14" width="7" height="7"></rect>
        </svg>
      </span>
      <span class="label">Dashboard</span>
    </a>
    
    <a href="user-management.php" class="nav-item <?php echo $current_page === 'user-management' ? 'active' : ''; ?>">
      <span class="icon-left">
        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"></path>
          <circle cx="9" cy="7" r="4"></circle>
          <path d="M23 21v-2a4 4 0 0 0-3-3.87"></path>
          <path d="M16 3.13a4 4 0 0 1 0 7.75"></path>
        </svg>
      </span>
      <span class="label">User Management</span>
    </a>
    
    <a href="report-management.php" class="nav-item <?php echo $current_page === 'report-management' ? 'active' : ''; ?>">
      <span class="icon-left">
        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path>
          <polyline points="14,2 14,8 20,8"></polyline>
          <line x1="16" y1="13" x2="8" y2="13"></line>
          <line x1="16" y1="17" x2="8" y2="17"></line>
          <polyline points="10,9 9,9 8,9"></polyline>
        </svg>
      </span>
      <span class="label">Report Management</span>
    </a>
    
    <a href="truck-management.php" class="nav-item <?php echo $current_page === 'truck-management' ? 'active' : ''; ?>">
      <span class="icon-left">
        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <rect x="1" y="3" width="15" height="13"></rect>
          <polygon points="16 8 20 8 23 11 23 16 16 16 16 8"></polygon>
          <circle cx="5.5" cy="18.5" r="2.5"></circle>
          <circle cx="18.5" cy="18.5" r="2.5"></circle>
        </svg>
      </span>
      <span class="label">Truck Management</span>
    </a>
    
    <a href="truck-schedule.php" class="nav-item <?php echo $current_page === 'truck-schedule' ? 'active' : ''; ?>">
      <span class="icon-left">
        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <rect x="1" y="3" width="15" height="13"></rect>
          <polygon points="16 8 20 8 23 11 23 16 16 16 16 8"></polygon>
          <circle cx="5.5" cy="18.5" r="2.5"></circle>
          <circle cx="18.5" cy="18.5" r="2.5"></circle>
        </svg>
      </span>
      <span class="label">Truck Schedule</span>
    </a>
    
    <a href="attendance.php" class="nav-item <?php echo $current_page === 'attendance' ? 'active' : ''; ?>">
      <span class="icon-left">
        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <path d="M9 11H5a2 2 0 0 0-2 2v3c0 1.1.9 2 2 2h4m6-6h4a2 2 0 0 1 2 2v3a2 2 0 0 1-2 2h-4m-6-6V9a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2m-6 6v-2a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"></path>
        </svg>
      </span>
      <span class="label">Attendance</span>
    </a>
  </nav>

  <div class="sidebar-footer">
    <div class="account">
      <div class="account-circle" aria-hidden="true">
        <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2" />
          <circle cx="12" cy="7" r="4" />
        </svg>
      </div>
      <div class="account-name" id="admin-name">Admin</div>
    </div>

    <button class="signout" type="button" onclick="signOut()">
      <svg class="icon" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
        <path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"></path>
        <polyline points="16 17 21 12 16 7"></polyline>
        <line x1="21" y1="12" x2="9" y2="12"></line>
      </svg>
      <span>Sign Out</span>
    </button>
  </div>
</aside>

<div class="backdrop" id="backdrop" onclick="closeSidebar()"></div>


<script>
function openSidebar() {
  document.getElementById('sidebar').classList.add('is-open');
  document.getElementById('backdrop').style.display = 'block';
}

function closeSidebar() {
  document.getElementById('sidebar').classList.remove('is-open');
  document.getElementById('backdrop').style.display = 'none';
}


async function signOut() {
  try {
    // Firebase sign out will be implemented here
    window.location.href = 'login.php';
  } catch (error) {
    console.error('Sign out error:', error);
  }
}

// Handle window resize
window.addEventListener('resize', function() {
  if (window.innerWidth >= 1025) {
    closeSidebar();
  }
});
</script>
