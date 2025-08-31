import React, { useState, useEffect } from "react";
import { NavLink, useNavigate } from "react-router-dom";
import {
  LayoutGrid,
  Users,
  FileText,
  ClipboardCheck,
  LogOut,
  Menu,
  X,
  Truck,
  AlertTriangle,
  MapPin,
} from "lucide-react";
import { useAuth } from "../context/AuthContext";
import "./dashboard.css";

/* ==== Leaflet imports ==== */
import { MapContainer, TileLayer, Marker, Popup } from "react-leaflet";
import L from "leaflet";

/* ---- Custom SVG pin icons (data-URI, works in Vite) ---- */
const makePin = (hex) =>
  new L.Icon({
    iconUrl:
      "data:image/svg+xml;utf8," +
      encodeURIComponent(
        `<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 32 48'>
           <path fill='${hex}' d='M16 0c8.8 0 16 7.2 16 16 0 11-16 32-16 32S0 27 0 16C0 7.2 7.2 0 16 0z'/>
           <circle cx='16' cy='16' r='6' fill='white'/>
         </svg>`
      ),
    iconSize: [32, 48],
    iconAnchor: [16, 48],
    popupAnchor: [0, -42],
    className: "valwaste-pin",
  });

const greenPin = makePin("#3AC84D");  // idle / brand green
const bluePin = makePin("#3B82F6");   // on route
const orangePin = makePin("#F59E0B"); // collecting / warning

function StatsCard({ icon, label, value, sub, extra }) {
  return (
    <div className="card stats-card">
      <div className="stats-meta">
        <p className="stats-label">{label}</p>
        <h3 className="stats-value">{value}</h3>
        {sub && <p className="stats-sub">{sub}</p>}
        {extra}
      </div>
      <div className="stats-icon">{icon}</div>
    </div>
  );
}

function ReportItem({ title, place, date, status = "pending" }) {
  return (
    <div className="report-row">
      <div className="report-main">
        <div className="report-title">{title}</div>
        <div className="report-sub">
          <MapPin size={14} />
          <span>{place}</span>
        </div>
        <div className="report-date">{date}</div>
      </div>
      <span className={`pill pill-${status}`}>{status}</span>
    </div>
  );
}

/* Quick action card (bottom 3) */
function ActionCard({ icon, title, desc, onClick, color = "green" }) {
  return (
    <button type="button" className={`card action-card action-${color}`} onClick={onClick}>
      <div className="action-icon">{icon}</div>
      <div className="action-copy">
        <div className="action-title">{title}</div>
        <div className="action-desc">{desc}</div>
      </div>
    </button>
  );
}

export default function Dashboard() {
  const [open, setOpen] = useState(false);
  const { logout } = useAuth();
  const navigate = useNavigate();

  /* === Announcement state (UI only) === */
  const [announcement, setAnnouncement] = useState("No announcement yet.");
  const [isEditingAnnc, setIsEditingAnnc] = useState(false);
  const [draftAnnc, setDraftAnnc] = useState(announcement);

  const startEditAnnc = () => {
    setDraftAnnc(announcement);
    setIsEditingAnnc(true);
  };
  const saveAnnc = () => {
    setAnnouncement(draftAnnc.trim());
    setIsEditingAnnc(false);
  };
  const cancelAnnc = () => {
    setDraftAnnc(announcement);
    setIsEditingAnnc(false);
  };

  useEffect(() => {
    const onResize = () => {
      if (window.innerWidth >= 1025) setOpen(false);
    };
    onResize();
    window.addEventListener("resize", onResize);
    return () => window.removeEventListener("resize", onResize);
  }, []);

  async function handleSignOut() {
    try {
      setOpen(false);
      await logout();
    } finally {
      navigate("/", { replace: true });
    }
  }

  // --- dummy data for UI preview only ---
  const recentReports = [
    { title: "Garbage overflow at Main Street", place: "Block 5, Main Street", date: "5/12/2023", status: "pending" },
    { title: "Truck missed scheduled collection", place: "Green Valley Subdivision", date: "5/11/2023", status: "pending" },
    { title: "Illegal dumping spotted", place: "Riverside Park", date: "5/11/2023", status: "pending" },
  ];

  const trucks = [
    { id: "Truck-01", position: [14.734, 120.957], status: "idle",       note: "Idle" },
    { id: "Truck-02", position: [14.716, 120.991], status: "route",      note: "On route" },
    { id: "Truck-03", position: [14.751, 120.972], status: "collecting", note: "Collecting" },
  ];
  const statusIcon = { idle: greenPin, route: bluePin, collecting: orangePin };

  // Valenzuela approximate center
  const center = [14.72, 120.97];

  return (
    <div className="app-shell">
      <div className="brandbar">
        <div className="brand">
          <div className="brand-circle">V</div>
          <div className="brand-name">ValWaste</div>
        </div>
      </div>

      <div className="topbar">
        <button className="hamburger" aria-label="Open sidebar" onClick={() => setOpen(true)}>
          <Menu size={20} />
        </button>
        <h1 className="page-title">Dashboard</h1>
      </div>

      <aside className={`sidebar ${open ? "is-open" : ""}`}>
        <div className="sidebar-mobile-header">
          <div className="brand">
            <div className="brand-circle">V</div>
            <div className="brand-name">ValWaste</div>
          </div>
          <button className="closebtn" aria-label="Close sidebar" onClick={() => setOpen(false)}>
            <X size={20} />
          </button>
        </div>

        <nav className="nav" onClick={() => setOpen(false)}>
          <NavLink to="/dashboard" className={({ isActive }) => `nav-item ${isActive ? "active" : ""}`}>
            <span className="icon-left"><LayoutGrid size={18} /></span>
            <span className="label">Dashboard</span>
          </NavLink>
          <NavLink to="/users" className={({ isActive }) => `nav-item ${isActive ? "active" : ""}`}>
            <span className="icon-left"><Users size={18} /></span>
            <span className="label">User Management</span>
          </NavLink>
          <NavLink to="/reports" className={({ isActive }) => `nav-item ${isActive ? "active" : ""}`}>
            <span className="icon-left"><FileText size={18} /></span>
            <span className="label">Report Management</span>
          </NavLink>
          <NavLink to="/schedule" className={({ isActive }) => `nav-item ${isActive ? "active" : ""}`}>
            <span className="icon-left"><Truck size={18} /></span>
            <span className="label">Truck Schedule</span>
          </NavLink>
          <NavLink to="/attendance" className={({ isActive }) => `nav-item ${isActive ? "active" : ""}`}>
            <span className="icon-left"><ClipboardCheck size={18} /></span>
            <span className="label">Attendance</span>
          </NavLink>
        </nav>

        <div className="sidebar-footer">
          <div className="account">
            <div className="account-circle" aria-hidden="true">
              <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2" />
                <circle cx="12" cy="7" r="4" />
              </svg>
            </div>
            <div className="account-name">Admin</div>
          </div>

          <button className="signout" type="button" onClick={handleSignOut}>
            <LogOut className="icon" aria-hidden="true" />
            <span>Sign Out</span>
          </button>
        </div>
      </aside>

      {open && <div className="backdrop" onClick={() => setOpen(false)} />}

      <main className="content">
        <div className="page-container">
          {/* Stats */}
          <section className="stats-grid">
            <StatsCard label="Total Users" value={0} sub="Registered in the system" icon={<Users size={22} />} />
            <StatsCard label="Total Reports" value={0} sub="Reports made by users" icon={<FileText size={22} />} />
            <StatsCard label="Total Trucks" value={0} sub="Available on the map" icon={<Truck size={22} />} />
            <StatsCard
  label="Critical Issues"
  value={0}
  sub="Requiring immediate attention"
  icon={<AlertTriangle size={22} />}
/>

          </section>

          {/* Map + Recent */}
          <section className="main-grid">
            <div className="card map-panel">
              <MapContainer center={center} zoom={12} className="leaflet-map" scrollWheelZoom>
                <TileLayer
                  attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
                  url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
                />
                {trucks.map((t) => (
                  <Marker key={t.id} position={t.position} icon={statusIcon[t.status] || greenPin}>
                    <Popup>
                      <strong>{t.id}</strong><br />
                      Status: {t.status}<br />
                      {t.note}
                    </Popup>
                  </Marker>
                ))}
              </MapContainer>
            </div>

            <aside className="card recent">
              <h3 className="recent-title">Recent Reports</h3>
              <div className="recent-list">
                {recentReports.map((r, i) => (<ReportItem key={i} {...r} />))}
              </div>
              <button className="btn-outline" type="button" onClick={() => navigate("/reports")}>
                View All Reports
              </button>
            </aside>
          </section>

          {/* Latest Announcement */}
          <section className="card annc-card">
            <h3 className="annc-title">Latest Announcement</h3>

            {!isEditingAnnc ? (
              <>
                <p className="annc-body">{announcement || "No announcement yet."}</p>
                <div className="annc-actions">
                  <button type="button" className="btn-outline" onClick={startEditAnnc}>
                    Edit Announcement
                  </button>
                </div>
              </>
            ) : (
              <>
                <textarea
                  className="annc-textarea"
                  value={draftAnnc}
                  onChange={(e) => setDraftAnnc(e.target.value)}
                  placeholder="Type your announcement..."
                />
                <div className="annc-actions">
                  <button type="button" className="btn-primary" onClick={saveAnnc}>
                    Save
                  </button>
                  <button type="button" className="btn-ghost" onClick={cancelAnnc}>
                    Cancel
                  </button>
                </div>
              </>
            )}
          </section>

          {/* Bottom quick actions */}
          <section className="action-grid">
            <ActionCard
              icon={<Users size={22} />}
              title="User Management"
              desc="Manage residents, collectors, and drivers"
              color="green"
              onClick={() => navigate("/users")}
            />
            <ActionCard
              icon={<FileText size={22} />}
              title="Report Management"
              desc="View and respond to community reports"
              color="blue"
              onClick={() => navigate("/reports")}
            />
            <ActionCard
              icon={<Truck size={22} />}
              title="Truck Schedules"
              desc="Manage collection routes and schedules"
              color="teal"
              onClick={() => navigate("/schedule")}
            />
          </section>
        </div>
      </main>
    </div>
  );
}
