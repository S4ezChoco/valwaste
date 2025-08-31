import React, { useEffect, useRef, useState } from "react";
import { NavLink, useNavigate } from "react-router-dom";
import {
  LayoutGrid, Users, FileText, ClipboardCheck, LogOut, Menu, X, Truck,
  Search, ChevronDown, Check
} from "lucide-react";
import { useAuth } from "../context/AuthContext";
import "./dashboard.css";

/* Small dropdown used for the two filters */
function FilterDropdown({ value, onChange, options, width = 160 }) {
  const [open, setOpen] = useState(false);
  const ref = useRef(null);

  useEffect(() => {
    const onDoc = (e) => { if (open && ref.current && !ref.current.contains(e.target)) setOpen(false); };
    const onEsc = (e) => e.key === "Escape" && setOpen(false);
    document.addEventListener("mousedown", onDoc);
    window.addEventListener("keydown", onEsc);
    return () => { document.removeEventListener("mousedown", onDoc); window.removeEventListener("keydown", onEsc); };
  }, [open]);

  return (
    <div className="um-filter-wrap" ref={ref} style={{ width }}>
      <button type="button" className="um-filter" style={{ width: "100%" }} onClick={() => setOpen((o) => !o)}>
        <span>{value}</span>
        <ChevronDown size={16} />
      </button>
      {open && (
        <div className="um-menu" style={{ width: "100%" }}>
          {options.map((opt) => (
            <button
              key={opt}
              type="button"
              className="um-menu-item"
              onClick={() => { onChange(opt); setOpen(false); }}
            >
              <Check size={16} className={`um-check ${value === opt ? "show" : ""}`} />
              <span>{opt}</span>
            </button>
          ))}
        </div>
      )}
    </div>
  );
}

export default function ReportM() {
  const [open, setOpen] = useState(false);
  const { logout } = useAuth();
  const navigate = useNavigate();

  /* Tabs + counts (UI only) */
  const [tab, setTab] = useState("Pending");
  const counts = { Pending: 0, Resolved: 0, Unresolved: 0 };

  const TAB_SUB = {
    Pending: "Reports waiting for review and resolution",
    Resolved: "Reports that have been successfully resolved",
    Unresolved: "Reports that could not be resolved and need attention",
  };

  /* Category options per tab */
  const CATEGORY_OPTIONS = {
    Pending: ["All Categories", "Missed Collection", "Illegal Dumping", "Complaint"],
    Resolved: ["All Categories", "Damaged Equipment"],
    Unresolved: ["All Categories", "Other"],
  };

  /* Filters (UI only) */
  const [priority, setPriority] = useState("All Priorities");
  const [category, setCategory] = useState("All Categories");

  /* Ensure category stays valid when switching tabs */
  useEffect(() => {
    const opts = CATEGORY_OPTIONS[tab];
    if (!opts.includes(category)) setCategory("All Categories");
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [tab]);

  useEffect(() => {
    const onResize = () => { if (window.innerWidth >= 1025) setOpen(false); };
    onResize();
    window.addEventListener("resize", onResize);
    return () => window.removeEventListener("resize", onResize);
  }, []);

  async function handleSignOut() {
    try { setOpen(false); await logout(); } finally { navigate("/", { replace: true }); }
  }

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
        <h1 className="page-title">Report Management</h1>
      </div>

      {/* Sidebar */}
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
          <NavLink to="/dashboard"  className={({isActive}) => `nav-item ${isActive ? "active" : ""}`}>
            <span className="icon-left"><LayoutGrid size={18} /></span><span className="label">Dashboard</span>
          </NavLink>
          <NavLink to="/users"      className={({isActive}) => `nav-item ${isActive ? "active" : ""}`}>
            <span className="icon-left"><Users size={18} /></span><span className="label">User Management</span>
          </NavLink>
          <NavLink to="/reports"    className={({isActive}) => `nav-item ${isActive ? "active" : ""}`}>
            <span className="icon-left"><FileText size={18} /></span><span className="label">Report Management</span>
          </NavLink>
          <NavLink to="/schedule"   className={({isActive}) => `nav-item ${isActive ? "active" : ""}`}>
            <span className="icon-left"><Truck size={18} /></span><span className="label">Truck Schedule</span>
          </NavLink>
          <NavLink to="/attendance" className={({isActive}) => `nav-item ${isActive ? "active" : ""}`}>
            <span className="icon-left"><ClipboardCheck size={18} /></span><span className="label">Attendance</span>
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

      {/* Content */}
      <main className="content">
        <div className="page-container">

          {/* Top controls */}
          <div className="rm-controls">
            <button type="button" className="btn-soft">Refresh Reports</button>
          </div>

          {/* Tabs */}
          <div className="rm-tabs">
            <div className="rm-seg">
              {["Pending", "Resolved", "Unresolved"].map((name) => (
                <button
                  key={name}
                  type="button"
                  className={`rm-tab ${tab === name ? "active" : ""}`}
                  onClick={() => setTab(name)}
                >
                  <span>{name}</span>
                  <span
                    className={`count-dot ${
                      name === "Resolved" ? "count-green" :
                      name === "Unresolved" ? "count-red" : "count-gray"
                    }`}
                  >
                    {counts[name]}
                  </span>
                </button>
              ))}
            </div>
          </div>

          {/* Panel */}
          <section className="card rm-panel">
            <h3 className="rm-title">{tab} Reports</h3>
            <p className="rm-sub">{TAB_SUB[tab]}</p>

            <div className="rm-row">
              <div className="rm-search">
                <Search size={16} />
                <input placeholder="Search reports..." />
              </div>

              <div className="rm-filters">
                <FilterDropdown
                  value={priority}
                  onChange={setPriority}
                  options={["All Priorities", "High", "Medium", "Low"]}
                  width={160}
                />
                <FilterDropdown
                  value={category}
                  onChange={setCategory}
                  options={CATEGORY_OPTIONS[tab]}   // <- per-tab categories
                  width={160}
                />
              </div>
            </div>

            <div className="card um-table-card">
              <table className="um-table">
                <thead>
                  <tr>
                    <th>Title</th>
                    <th>Location</th>
                    <th>Reported By</th>
                    <th>Priority</th>
                    <th>Category</th>
                    <th>Date</th>
                    <th className="col-actions">Actions</th>
                  </tr>
                </thead>
                <tbody>
                  <tr className="empty">
                    <td colSpan={7}>No reports found</td>
                  </tr>
                </tbody>
              </table>
            </div>
          </section>
        </div>
      </main>
    </div>
  );
}
