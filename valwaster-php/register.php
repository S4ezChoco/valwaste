<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Register - ValWaste Admin</title>
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
                    <h2>Create Admin Account</h2>
                    <p>Register a new administrator account</p>
                </div>

                <form class="register-form" id="registerForm" novalidate>
                    <div class="name-row">
                        <label>
                            <span>First Name</span>
                            <input
                                name="firstName"
                                type="text"
                                required
                                placeholder="John"
                            />
                        </label>

                        <label>
                            <span>Surname</span>
                            <input
                                name="lastName"
                                type="text"
                                required
                                placeholder="Doe"
                            />
                        </label>
                    </div>

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
                            autocomplete="new-password"
                            required
                            minlength="6"
                            placeholder="Minimum 6 characters"
                        />
                    </label>

                    <label>
                        <span>Confirm Password</span>
                        <input
                            name="confirmPassword"
                            type="password"
                            autocomplete="new-password"
                            required
                            minlength="6"
                            placeholder="Confirm your password"
                        />
                    </label>

                    <div id="registerError" class="form-error" style="display: none;" role="alert"></div>

                    <button type="submit" id="registerBtn">
                        Register
                    </button>
                </form>

                <div class="auth-switch">
                    <p>Already have an account? <a href="login.php">Sign in here</a></p>
                </div>
            </div>
        </div>

        <div class="right-panel">
            <div class="right-content">
                <h2>ValWaste Administration Portal</h2>
                <p>
                    Join the ValWaste administrative team and help manage waste collection 
                    services efficiently across the community.
                </p>
            </div>
        </div>
    </div>

    <script type="module">
        import { initializeApp } from 'https://www.gstatic.com/firebasejs/10.7.1/firebase-app.js';
        import { getAuth, createUserWithEmailAndPassword, updateProfile } from 'https://www.gstatic.com/firebasejs/10.7.1/firebase-auth.js';
        import { getFirestore, doc, setDoc } from 'https://www.gstatic.com/firebasejs/10.7.1/firebase-firestore.js';

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

        const registerForm = document.getElementById('registerForm');
        const registerBtn = document.getElementById('registerBtn');
        const registerError = document.getElementById('registerError');

        function showError(message) {
            registerError.textContent = message;
            registerError.style.display = 'block';
        }

        function hideError() {
            registerError.style.display = 'none';
        }

        function setLoading(loading) {
            registerBtn.disabled = loading;
            registerBtn.textContent = loading ? 'Creating Account...' : 'Register';
        }

        registerForm.addEventListener('submit', async (e) => {
            e.preventDefault();
            hideError();
            setLoading(true);

            const formData = new FormData(e.target);
            const firstName = formData.get('firstName').trim();
            const lastName = formData.get('lastName').trim();
            const email = formData.get('email').trim();
            const password = formData.get('password');
            const confirmPassword = formData.get('confirmPassword');

            // Validation
            if (!firstName || !lastName || !email || !password || !confirmPassword) {
                showError('Please fill in all fields.');
                setLoading(false);
                return;
            }

            if (password !== confirmPassword) {
                showError('Passwords do not match.');
                setLoading(false);
                return;
            }

            if (password.length < 6) {
                showError('Password must be at least 6 characters long.');
                setLoading(false);
                return;
            }

            try {
                // Create user account
                const userCredential = await createUserWithEmailAndPassword(auth, email, password);
                const user = userCredential.user;

                // Update user profile
                await updateProfile(user, {
                    displayName: `${firstName} ${lastName}`
                });

                // Create user document in Firestore
                await setDoc(doc(db, 'users', user.uid), {
                    firstName: firstName,
                    lastName: lastName,
                    email: email,
                    role: 'Administrator',
                    createdAt: new Date().toISOString(),
                    isActive: true
                });

                // Store user data in localStorage
                localStorage.setItem('valwaste_admin', JSON.stringify({
                    uid: user.uid,
                    email: user.email,
                    displayName: `${firstName} ${lastName}`,
                    role: 'Administrator'
                }));

                // Redirect to dashboard
                window.location.href = 'dashboard.php';

            } catch (error) {
                console.error('Registration error:', error);
                
                let errorMessage = 'An error occurred during registration.';
                
                switch (error.code) {
                    case 'auth/email-already-in-use':
                        errorMessage = 'An account with this email already exists.';
                        break;
                    case 'auth/invalid-email':
                        errorMessage = 'Please enter a valid email address.';
                        break;
                    case 'auth/weak-password':
                        errorMessage = 'Password is too weak. Please choose a stronger password.';
                        break;
                    case 'auth/network-request-failed':
                        errorMessage = 'Network error. Please check your connection and try again.';
                        break;
                    default:
                        errorMessage = error.message || 'An error occurred during registration.';
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
