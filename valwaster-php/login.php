<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Login - ValWaste Admin</title>
    <link rel="stylesheet" href="assets/css/styles.css">
</head>
<body>
    <div class="login-container">
        <div class="left-panel">
            <div class="left-content">
                <div class="login-brand">
                    <div class="brand-logo">V</div>
                    <h1 class="brand-title">ValWaste Admin</h1>
                </div>

                <div class="welcome">
                    <h2>Welcome back</h2>
                    <p>Please sign in to your account to continue</p>
                </div>

                <form class="login-form" id="loginForm" novalidate>
                    <label>
                        <span>Email</span>
                        <input
                            name="email"
                            type="email"
                            inputmode="email"
                            autocomplete="username"
                            required
                            placeholder="admin@valwaste.com"
                        />
                    </label>

                    <label>
                        <span>Password</span>
                        <input
                            name="password"
                            type="password"
                            autocomplete="current-password"
                            required
                            minlength="6"
                            placeholder="********"
                        />
                    </label>

                    <div id="loginError" class="form-error" style="display: none;" role="alert"></div>

                    <button type="submit" id="loginBtn">
                        Sign In
                    </button>
                </form>

            </div>
        </div>

        <div class="right-panel">
            <div class="right-content">
                <h2>ValWaste Administration Portal</h2>
                <p>
                    Manage users, reports, and truck schedules all from a single dashboard.
                    Monitor waste collection activities and improve community cleanliness.
                </p>
            </div>
        </div>
    </div>

    <script type="module">
        import { initializeApp } from 'https://www.gstatic.com/firebasejs/10.7.1/firebase-app.js';
        import { getAuth, signInWithEmailAndPassword } from 'https://www.gstatic.com/firebasejs/10.7.1/firebase-auth.js';
        import { getFirestore, doc, getDoc } from 'https://www.gstatic.com/firebasejs/10.7.1/firebase-firestore.js';

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

        const loginForm = document.getElementById('loginForm');
        const loginBtn = document.getElementById('loginBtn');
        const loginError = document.getElementById('loginError');

        function showError(message) {
            loginError.textContent = message;
            loginError.style.display = 'block';
        }

        function hideError() {
            loginError.style.display = 'none';
        }

        function setLoading(loading) {
            loginBtn.disabled = loading;
            loginBtn.textContent = loading ? 'Signing in...' : 'Sign In';
        }

        loginForm.addEventListener('submit', async (e) => {
            e.preventDefault();
            hideError();
            setLoading(true);

            const formData = new FormData(e.target);
            const email = formData.get('email').trim();
            const password = formData.get('password');

            if (!email || !password) {
                showError('Please enter your email and password.');
                setLoading(false);
                return;
            }

            try {
                const userCredential = await signInWithEmailAndPassword(auth, email, password);
                const user = userCredential.user;

                // Check if user has Administrator role
                const userDoc = await getDoc(doc(db, 'users', user.uid));
                
                if (!userDoc.exists()) {
                    showError('User profile not found. Please contact administrator.');
                    setLoading(false);
                    return;
                }

                const userData = userDoc.data();
                if (userData.role !== 'Administrator') {
                    showError('Access denied. Administrator privileges required.');
                    setLoading(false);
                    return;
                }

                // Store user data in localStorage for session management
                localStorage.setItem('valwaste_admin', JSON.stringify({
                    uid: user.uid,
                    email: user.email,
                    displayName: userData.firstName + ' ' + userData.lastName,
                    role: userData.role
                }));

                // Redirect to dashboard
                window.location.href = 'dashboard.php';

            } catch (error) {
                console.error('Login error:', error);
                
                let errorMessage = 'Invalid email or password. Please try again.';
                
                switch (error.code) {
                    case 'auth/user-not-found':
                    case 'auth/wrong-password':
                    case 'auth/invalid-credential':
                        errorMessage = 'Invalid email or password. Please try again.';
                        break;
                    case 'auth/too-many-requests':
                        errorMessage = 'Too many failed login attempts. Please try again later.';
                        break;
                    case 'auth/network-request-failed':
                        errorMessage = 'Network error. Please check your connection and try again.';
                        break;
                    default:
                        errorMessage = error.message || 'An error occurred during login.';
                }
                
                showError(errorMessage);
                setLoading(false);
            }
        });

        // Check if user is already logged in
        window.addEventListener('load', () => {
            const adminData = localStorage.getItem('valwaste_admin');
            if (adminData) {
                // User might already be logged in, redirect to dashboard
                window.location.href = 'dashboard.php';
            }
        });
    </script>
</body>
</html>
