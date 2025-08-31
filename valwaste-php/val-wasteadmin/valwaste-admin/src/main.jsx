import React from 'react'
import ReactDOM from 'react-dom/client'
import { BrowserRouter, Route, Routes } from 'react-router-dom';
import 'leaflet/dist/leaflet.css';

import Login from './Login';
import Dashboard from './pages/Dashboard';
import UserM from "./pages/UserM";
import ReportM from "./pages/ReportM";
import Schedule from "./pages/Schedule";
import Attendance from "./pages/Attendance";

import { AuthProvider } from "./context/AuthContext.jsx";
import ProtectedRoute from "./components/ProtectedRoute.jsx";
import PublicOnlyRoute from "./components/PublicOnlyRoute.jsx";

import './login.css';
import './index.css';

ReactDOM.createRoot(document.getElementById("root")).render(
  <React.StrictMode>
    <AuthProvider>
      <BrowserRouter>
        <Routes>
          
          <Route path="/" element={<PublicOnlyRoute><Login /></PublicOnlyRoute>} />

          <Route path="/dashboard"  element={<ProtectedRoute><Dashboard /></ProtectedRoute>} />
          <Route path="/users"      element={<ProtectedRoute><UserM /></ProtectedRoute>} />
          <Route path="/reports"    element={<ProtectedRoute><ReportM /></ProtectedRoute>} />
          <Route path="/schedule"   element={<ProtectedRoute><Schedule /></ProtectedRoute>} />
          <Route path="/attendance" element={<ProtectedRoute><Attendance /></ProtectedRoute>} />
        </Routes>
      </BrowserRouter>
    </AuthProvider>
  </React.StrictMode>
);
