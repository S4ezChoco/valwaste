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
import { initializeApp } from 'firebase/app';
import { getAuth } from 'firebase/auth';
import { getFirestore } from 'firebase/firestore';

const app = initializeApp(firebaseConfig);
export const auth = getAuth(app);
export const db = getFirestore(app);
