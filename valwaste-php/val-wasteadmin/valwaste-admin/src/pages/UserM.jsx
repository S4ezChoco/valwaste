import React, { useEffect, useRef, useState } from "react";
import { NavLink, useNavigate } from "react-router-dom";
import {
  LayoutGrid, Users, FileText, ClipboardCheck, LogOut, Menu, X, Truck,
  UserPlus, Search, ChevronDown, Check
} from "lucide-react";
import { useAuth } from "../context/AuthContext";
import "./dashboard.css";

/* ---------- Create User Modal ---------- */
function CreateUserModal({ open, onClose, onCreate }) {
  const firstRef = useRef(null);
  const [form, setForm] = useState({
    firstName: "",
    lastName: "",
    email: "",
    role: "Barangay Official",
  });

  useEffect(() => {
    if (!open) return;
    setTimeout(() => firstRef.current?.focus(), 0);
    const onEsc = (e) => e.key === "Escape" && onClose();
    window.addEventListener("keydown", onEsc);
    return () => window.removeEventListener("keydown", onEsc);
  }, [open, onClose]);

  const update = (k) => (e) => setForm({ ...form, [k]: e.target.value });

  const submit = (e) => {
    e.preventDefault();
    onCreate?.(form);     // hook to backend later
    onClose();
  };

  if (!open) return null;

  return (
    <div className="um-modal" onMouseDown={(e) => e.target === e.currentTarget && onClose()}>
      <div className="um-modal-card" role="dialog" aria-modal="true" aria-labelledby="um-create-title">
        <button className="um-modal-close" aria-label="Close" onClick={onClose}><X size={18} /></button>

        <h3 id="um-create-title" className="um-modal-title">Create New User</h3>
        <p className="um-modal-sub">Add a new user to the system.</p>

        <form className="um-form" onSubmit={submit}>
          <label className="um-field">
            <span className="um-label">First Name</span>
            <input
              ref={firstRef}
              className="um-input"
              placeholder="First Name"
              value={form.firstName}
              onChange={update("firstName")}
              required
            />
          </label>

          <label className="um-field">
            <span className="um-label">Last Name</span>
            <input
              className="um-input"
              placeholder="Last Name"
              value={form.lastName}
              onChange={update("lastName")}
              required
            />
          </label>

          <label className="um-field">
            <span className="um-label">Email</span>
            <input
              type="email"
              className="um-input"
              placeholder="Email"
              value={form.email}
              onChange={update("email")}
              required
            />
          </label>

          <label className="um-field">
            <span className="um-label">Role</span>
            <div className="um-select-wrap">
              <select className="um-select" value={form.role} onChange={update("role")}>
                <option>Barangay Official</option>
                <option>Collector</option>
                <option>Driver</option>
              </select>
              <ChevronDown size={16} className="um-select-caret" />
            </div>
          </label>

          <div className="um-modal-actions">
            <button type="button" className="btn-ghost" onClick={onClose}>Cancel</button>
            <button type="submit" className="btn-primary">Create User</button>
          </div>
        </form>
      </div>
    </div>
  );
}

/* ---------- Role Filter dropdown ---------- */
function RoleFilter({ value, onChange }) {
  const [open, setOpen] = useState(false);
  const ref = useRef(null);
  const roles = ["All Roles", "Admin", "Resident", "Collector", "Driver"];

  useEffect(() => {
    const onDocClick = (e) => {
      if (open && ref.current && !ref.current.contains(e.target)) setOpen(false);
    };
    const onEsc = (e) => e.key === "Escape" && setOpen(false);
    document.addEventListener("mousedown", onDocClick);
    window.addEventListener("keydown", onEsc);
    return () => {
      document.removeEventListener("mousedown", onDocClick);
      window.removeEventListener("keydown", onEsc);
    };
  }, [open]);

  return (
    <div className="um-filter-wrap" ref={ref}>
      <button type="button" className="um-filter" onClick={() => setOpen((o) => !o)}>
        <span>{value}</span>
        <ChevronDown size={16} />
      </button>

      {open && (
        <div className="um-menu">
          {roles.map((r) => (
            <button
              key={r}
              type="button"
              className="um-menu-item"
              onClick={() => { onChange(r); setOpen(false); }}
            >
              <Check size={16} className={`um-check ${value === r ? "show" : ""}`} />
              <span>{r}</span>
            </button>
          ))}
        </div>
      )}
    </div>
  );
}

export default function UserM() {
  const [open, setOpen] = useState(false);
  const [createOpen, setCreateOpen] = useState(false);
  const [roleFilter, setRoleFilter] = useState("All Roles");
  const { logout } = useAuth();
  const navigate = useNavigate();

  useEffect(() => {
    const onResize = () => { if (window.innerWidth >= 1025) setOpen(false); };
    onResize();
    window.addEventListener("resize", onResize);
    return () => window.removeEventListener("resize", onResize);
  }, []);

  // lock scroll when modal is open
  useEffect(() => {
    document.body.classList.toggle("no-scroll", createOpen);
    return () => document.body.classList.remove("no-scroll");
  }, [createOpen]);

  async function handleSignOut() {
    try { setOpen(false); await logout(); } finally { navigate("/", { replace: true }); }
  }

  return (
    <div className="app-shell">
      <div className="brandbar">
        <div className="brand"><div className="brand-circle">V</div><div className="brand-name">ValWaste</div></div>
      </div>

      <div className="topbar">
        <button className="hamburger" aria-label="Open sidebar" onClick={() => setOpen(true)}><Menu size={20} /></button>
        <h1 className="page-title">User Management</h1>
      </div>

      <aside className={`sidebar ${open ? "is-open" : ""}`}>
        <div className="sidebar-mobile-header">
          <div className="brand"><div className="brand-circle">V</div><div className="brand-name">ValWaste</div></div>
          <button className="closebtn" aria-label="Close sidebar" onClick={() => setOpen(false)}><X size={20} /></button>
        </div>

        <nav className="nav" onClick={() => setOpen(false)}>
          <NavLink to="/dashboard"  className={({isActive}) => `nav-item ${isActive ? "active" : ""}`}><span className="icon-left"><LayoutGrid size={18} /></span><span className="label">Dashboard</span></NavLink>
          <NavLink to="/users"      className={({isActive}) => `nav-item ${isActive ? "active" : ""}`}><span className="icon-left"><Users size={18} /></span><span className="label">User Management</span></NavLink>
          <NavLink to="/reports"    className={({isActive}) => `nav-item ${isActive ? "active" : ""}`}><span className="icon-left"><FileText size={18} /></span><span className="label">Report Management</span></NavLink>
          <NavLink to="/schedule"   className={({isActive}) => `nav-item ${isActive ? "active" : ""}`}><span className="icon-left"><Truck size={18} /></span><span className="label">Truck Schedule</span></NavLink>
          <NavLink to="/attendance" className={({isActive}) => `nav-item ${isActive ? "active" : ""}`}><span className="icon-left"><ClipboardCheck size={18} /></span><span className="label">Attendance</span></NavLink>
        </nav>

        <div className="sidebar-footer">
          <div className="account">
            <div className="account-circle" aria-hidden="true">
              <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2" /><circle cx="12" cy="7" r="4" /></svg>
            </div>
            <div className="account-name">Admin</div>
          </div>
          <button className="signout" type="button" onClick={handleSignOut}><LogOut className="icon" aria-hidden="true" /><span>Sign Out</span></button>
        </div>
      </aside>

      {open && <div className="backdrop" onClick={() => setOpen(false)} />}

      <main className="content">
        <div className="page-container">
          {/* Header row */}
          <div className="um-headrow">
            <h2 className="um-title">User Management</h2>
            <button type="button" className="btn-primary btn-icon" onClick={() => setCreateOpen(true)}>
              <UserPlus size={18} /><span>Add New User</span>
            </button>
          </div>

          {/* Toolbar */}
          <div className="um-toolbar">
            <div className="um-search">
              <Search size={16} />
              <input placeholder="Search users…" />
            </div>
            <RoleFilter value={roleFilter} onChange={setRoleFilter} />
          </div>

          {/* Table */}
          <div className="card um-table-card">
            <table className="um-table">
              <thead>
                <tr><th>Name</th><th>Email</th><th>Role</th><th>Status</th><th>Created At</th><th className="col-actions">Actions</th></tr>
              </thead>
              <tbody>
                <tr className="empty"><td colSpan={6}>No users found</td></tr>
              </tbody>
            </table>
          </div>
        </div>
      </main>

      {/* Modal */}
      <CreateUserModal
        open={createOpen}
        onClose={() => setCreateOpen(false)}
        onCreate={(data) => console.log("create user:", data)}
      />
    </div>
  );
}
