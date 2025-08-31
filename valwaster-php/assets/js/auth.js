// Firebase authentication and profile management

import { initializeApp } from 'https://www.gstatic.com/firebasejs/10.7.1/firebase-app.js';
import { getAuth, onAuthStateChanged, updateProfile, sendPasswordResetEmail, signOut } from 'https://www.gstatic.com/firebasejs/10.7.1/firebase-auth.js';
import { getFirestore, doc, updateDoc, getDoc } from 'https://www.gstatic.com/firebasejs/10.7.1/firebase-firestore.js';

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
const app = initializeApp(firebaseConfig);
const auth = getAuth(app);
const db = getFirestore(app);

// Global authentication state
let currentUser = null;

// Initialize authentication
function initAuth() {
    onAuthStateChanged(auth, (user) => {
        currentUser = user;
        if (user) {
            updateUserDisplay(user);
        }
    });
}

// Update user display in sidebar
function updateUserDisplay(user) {
    const adminData = JSON.parse(localStorage.getItem('valwaste_admin') || '{}');
    const adminNameElement = document.getElementById('admin-name');
    const profileNameInput = document.getElementById('profileName');
    const profileEmailInput = document.getElementById('profileEmail');
    
    if (adminNameElement) {
        adminNameElement.textContent = adminData.displayName || 'Admin';
    }
    
    if (profileNameInput) {
        profileNameInput.value = adminData.displayName || 'Admin';
    }
    
    if (profileEmailInput) {
        profileEmailInput.value = user.email || '';
    }
}

// Profile management functions
window.openProfileModal = function() {
    document.getElementById('profileModal').style.display = 'grid';
    loadUserProfile();
}

window.closeProfileModal = function() {
    document.getElementById('profileModal').style.display = 'none';
}

window.loadUserProfile = function() {
    if (currentUser) {
        updateUserDisplay(currentUser);
    }
}

window.resetPassword = async function() {
    if (!currentUser) {
        alert('Please log in first.');
        return;
    }
    
    try {
        await sendPasswordResetEmail(auth, currentUser.email);
        alert('Password reset email sent to ' + currentUser.email);
        closeProfileModal();
    } catch (error) {
        console.error('Error sending password reset email:', error);
        alert('Error sending password reset email. Please try again.');
    }
}

// Handle profile form submission
document.addEventListener('DOMContentLoaded', function() {
    const profileForm = document.getElementById('profileForm');
    
    if (profileForm) {
        profileForm.addEventListener('submit', async function(e) {
            e.preventDefault();
            
            if (!currentUser) {
                alert('Please log in first.');
                return;
            }
            
            const newDisplayName = document.getElementById('profileName').value.trim();
            
            if (!newDisplayName) {
                alert('Please enter a display name.');
                return;
            }
            
            try {
                // Update Firebase Auth profile
                await updateProfile(currentUser, {
                    displayName: newDisplayName
                });
                
                // Update Firestore document
                const userDocRef = doc(db, 'users', currentUser.uid);
                const userDoc = await getDoc(userDocRef);
                
                if (userDoc.exists()) {
                    const userData = userDoc.data();
                    const nameParts = newDisplayName.split(' ');
                    const firstName = nameParts[0] || '';
                    const lastName = nameParts.slice(1).join(' ') || userData.lastName || '';
                    
                    await updateDoc(userDocRef, {
                        firstName: firstName,
                        lastName: lastName
                    });
                }
                
                // Update localStorage
                const adminData = JSON.parse(localStorage.getItem('valwaste_admin') || '{}');
                adminData.displayName = newDisplayName;
                localStorage.setItem('valwaste_admin', JSON.stringify(adminData));
                
                // Update UI
                updateUserDisplay(currentUser);
                
                alert('Profile updated successfully!');
                closeProfileModal();
                
            } catch (error) {
                console.error('Error updating profile:', error);
                alert('Error updating profile. Please try again.');
            }
        });
    }
    
    // Initialize auth when DOM is ready
    initAuth();
});

// Sign out function
window.signOut = async function() {
    try {
        await signOut(auth);
        localStorage.removeItem('valwaste_admin');
        window.location.href = 'login.php';
    } catch (error) {
        console.error('Sign out error:', error);
        // Force redirect even if sign out fails
        localStorage.removeItem('valwaste_admin');
        window.location.href = 'login.php';
    }
}

// Check authentication on page load
window.addEventListener('load', () => {
    const adminData = localStorage.getItem('valwaste_admin');
    const currentPage = window.location.pathname;
    
    // If not on login/register page and not authenticated, redirect to login
    if (!adminData && !currentPage.includes('login.php') && !currentPage.includes('register.php')) {
        window.location.href = 'login.php';
        return;
    }
    
    // If on login/register page and authenticated, redirect to dashboard
    if (adminData && (currentPage.includes('login.php') || currentPage.includes('register.php'))) {
        window.location.href = 'dashboard.php';
        return;
    }
});

export { auth, db, currentUser };
