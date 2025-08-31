import React, { useEffect, useMemo, useRef, useState } from "react";
import { NavLink, useNavigate } from "react-router-dom";
import {
  LayoutGrid, Users, FileText, ClipboardCheck, LogOut, Menu, X, Truck,
  ChevronDown, Check
} from "lucide-react";
import { useAuth } from "../context/AuthContext";
import "./dashboard.css";

/* ===== helpers ===== */
function startOfMonth(d) { const x = new Date(d); x.setDate(1); x.setHours(0,0,0,0); return x; }
function daysInMonth(y, m) { return new Date(y, m + 1, 0).getDate(); }
function toInputDate(d) { const y=d.getFullYear(); const m=String(d.getMonth()+1).padStart(2,"0"); const day=String(d.getDate()).padStart(2,"0"); return `${y}-${m}-${day}`; }
function fromInputDate(s) { const [y,m,d]=s.split("-").map(Number); return new Date(y, m-1, d); }
function buildMonthGrid(anchorDate) {
  const first = startOfMonth(anchorDate);
  const y = first.getFullYear(); const m = first.getMonth();
  const firstDow = first.getDay(); const dim = daysInMonth(y, m);
  const cells = Array.from({ length: 42 }, (_, i) => {
    const dayNum = i - firstDow + 1;
    if (dayNum < 1 || dayNum > dim) return null;
    const date = new Date(y, m, dayNum);
    const t = new Date();
    const isToday = date.getFullYear()===t.getFullYear() && date.getMonth()===t.getMonth() && date.getDate()===t.getDate();
    return { day: dayNum, date, isToday };
  });
  return cells;
}

/* ===== Month dropdown ===== */
function MonthDropdown({ monthIndex, onSelect }) {
  const [open, setOpen] = useState(false);
  const ref = useRef(null);
  const months = Array.from({ length: 12 }, (_, i) =>
    new Date(2000, i, 1).toLocaleString(undefined, { month: "long" })
  );
  useEffect(() => {
    const onDoc = (e) => { if (open && ref.current && !ref.current.contains(e.target)) setOpen(false); };
    const onEsc = (e) => e.key === "Escape" && setOpen(false);
    document.addEventListener("mousedown", onDoc); window.addEventListener("keydown", onEsc);
    return () => { document.removeEventListener("mousedown", onDoc); window.removeEventListener("keydown", onEsc); };
  }, [open]);

  return (
    <div className="um-filter-wrap month-dd" ref={ref}>
      <button type="button" className="um-filter" onClick={() => setOpen(o => !o)}>
        <span>{months[monthIndex]}</span>
        <ChevronDown size={16} />
      </button>
      {open && (
        <div className="um-menu month-dd-menu">
          {months.map((label, i) => (
            <button key={label} type="button"
              className={`um-menu-item ${i===monthIndex ? "active" : ""}`}
              onClick={() => { onSelect(i); setOpen(false); }}>
              <Check size={16} className={`um-check ${i===monthIndex ? "show" : ""}`} />
              <span>{label}</span>
            </button>
          ))}
        </div>
      )}
    </div>
  );
}

/* ===== Create Schedule Modal ===== */
function CreateScheduleModal({ open, onClose, onCreate, initialDate }) {
  const firstRef = useRef(null);
  const trucks = ["Truck 01","Truck 02","Truck 03"];
  const drivers = ["Juan Dela Cruz","Maria Santos","Pedro Reyes"];
  const collectors = ["Alex","Bea","Carl","Dina","Evan"];
  const locations = ["Isla Street 1","Isla Street 2","Isla Market","Isla Plaza"];

  const [form, setForm] = useState({
    truck: "", date: toInputDate(initialDate || new Date()),
    start: "08:00", end: "16:00",
    driver: "", collectors: [], locations: [],
  });

  useEffect(() => {
    if (open) {
      setForm((f) => ({ ...f, date: toInputDate(initialDate || new Date()) }));
      setTimeout(() => firstRef.current?.focus(), 0);
      const onEsc = (e) => e.key === "Escape" && onClose();
      window.addEventListener("keydown", onEsc);
      return () => window.removeEventListener("keydown", onEsc);
    }
  }, [open, initialDate, onClose]);

  if (!open) return null;
  const update = (k) => (e) => setForm((f) => ({ ...f, [k]: e.target.value }));
  function toggleArray(k, v) {
    setForm((f) => { const set = new Set(f[k]); set.has(v) ? set.delete(v) : set.add(v); return { ...f, [k]: [...set] }; });
  }
  function submit(e) {
    e.preventDefault();
    if (form.collectors.length !== 3) return alert("Please select exactly 3 waste collectors.");
    if (form.locations.length < 1) return alert("Please select at least 1 location.");
    if (form.end <= form.start) return alert("End time must be later than start time.");
    onCreate?.({ ...form, dateObj: fromInputDate(form.date) });
    onClose();
  }

  return (
    <div className="um-modal sched-modal" onMouseDown={(e) => e.target === e.currentTarget && onClose()}>
      <div className="um-modal-card large sched-modal-card" role="dialog" aria-modal="true" aria-labelledby="sched-title">
        <button className="um-modal-close" aria-label="Close" onClick={onClose}><X size={18} /></button>

        <h3 id="sched-title" className="um-modal-title">Create Schedule</h3>
        <p className="um-modal-sub">Fill details</p>

        {/* Make the form the scroll area */}
        <form id="createScheduleForm" className="um-form sched-modal-scroll" onSubmit={submit}>
          <label className="um-field">
            <span className="um-label">Select Truck</span>
            <div className="um-select-wrap">
              <select ref={firstRef} className="um-select" value={form.truck} onChange={update("truck")} required>
                <option value="" disabled>Truck</option>
                {trucks.map(t => <option key={t} value={t}>{t}</option>)}
              </select>
              <ChevronDown size={16} className="um-select-caret" />
            </div>
          </label>

          <label className="um-field">
            <span className="um-label">Date</span>
            <input type="date" className="um-input" value={form.date} onChange={update("date")} required />
          </label>

          <div className="um-row-2">
            <label className="um-field">
              <span className="um-label">Start</span>
              <input type="time" step="900" className="um-input" value={form.start} onChange={update("start")} required />
            </label>
            <label className="um-field">
              <span className="um-label">End</span>
              <input type="time" step="900" className="um-input" value={form.end} onChange={update("end")} required />
            </label>
          </div>

          <label className="um-field">
            <span className="um-label">Driver</span>
            <div className="um-select-wrap">
              <select className="um-select" value={form.driver} onChange={update("driver")} required>
                <option value="" disabled>Select driver</option>
                {drivers.map(d => <option key={d} value={d}>{d}</option>)}
              </select>
              <ChevronDown size={16} className="um-select-caret" />
            </div>
          </label>

          <label className="um-field">
            <span className="um-label">Waste Collectors (Select exactly 3)</span>
            <div className="um-menu" style={{ width: "100%", position: "relative" }}>
              {collectors.map(name => (
                <label key={name} className="um-menu-item" style={{ cursor: "pointer" }}>
                  <input type="checkbox"
                    checked={form.collectors.includes(name)}
                    onChange={() => toggleArray("collectors", name)} />
                  <span>{name}</span>
                </label>
              ))}
            </div>
          </label>

          <div className="um-field">
            <span className="um-label">Locations (Select at least 1)</span>
            <div className="um-boxlist">
              {locations.map(loc => (
                <label key={loc} className="um-checkrow">
                  <input type="checkbox"
                    checked={form.locations.includes(loc)}
                    onChange={() => toggleArray("locations", loc)} />
                  <span>{loc}</span>
                </label>
              ))}
            </div>
          </div>
        </form>

        {/* Footer outside the scroll area so it never gets clipped */}
        <div className="sched-modal-actions">
          <button type="button" className="btn-ghost" onClick={onClose}>Cancel</button>
          <button type="submit" form="createScheduleForm" className="btn-primary">Create</button>
        </div>
      </div>
    </div>
  );
}

/* ===== Page ===== */
export default function Schedule() {
  const [open, setOpen] = useState(false);
  const { logout } = useAuth();
  const navigate = useNavigate();

  const [cursor, setCursor] = useState(startOfMonth(new Date()));
  const grid = useMemo(() => buildMonthGrid(cursor), [cursor]);

  const [createOpen, setCreateOpen] = useState(false);
  const [modalDate, setModalDate] = useState(new Date());

  useEffect(() => {
    const onResize = () => { if (window.innerWidth >= 1025) setOpen(false); };
    onResize(); window.addEventListener("resize", onResize);
    return () => window.removeEventListener("resize", onResize);
  }, []);

  async function handleSignOut() { try { setOpen(false); await logout(); } finally { navigate("/", { replace: true }); } }
  function prev(){ const d=new Date(cursor); d.setMonth(d.getMonth()-1); setCursor(startOfMonth(d)); }
  function next(){ const d=new Date(cursor); d.setMonth(d.getMonth()+1); setCursor(startOfMonth(d)); }
  function today(){ setCursor(startOfMonth(new Date())); }
  function jumpToMonth(m){ setCursor(startOfMonth(new Date(cursor.getFullYear(), m, 1))); }
  function openCreate(date){ setModalDate(date || new Date()); setCreateOpen(true); }

  const monthLabel = cursor.toLocaleString(undefined, { month: "long", year: "numeric" });

  return (
    <div className="app-shell">
      <div className="brandbar"><div className="brand"><div className="brand-circle">V</div><div className="brand-name">ValWaste</div></div></div>
      <div className="topbar">
        <button className="hamburger" aria-label="Open sidebar" onClick={() => setOpen(true)}><Menu size={20} /></button>
        <h1 className="page-title">Truck Schedule</h1>
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
          <div className="sched-topbar">
            <button type="button" className="btn-primary" onClick={() => openCreate(new Date())}>Create Schedule</button>
          </div>

          <section className="card sched-card">
            <div className="sched-head">
              <div><h3 className="sched-title">Truck Schedule</h3><p className="sched-sub">Manage truck collection schedules</p></div>
              <div><MonthDropdown monthIndex={cursor.getMonth()} onSelect={jumpToMonth} /></div>
            </div>

            <div className="sched-monthrow">
              <h4 className="sched-month">{monthLabel}</h4>
              <div className="sched-nav">
                <button className="btn-ghost-mini" onClick={prev}>&lt;</button>
                <button className="btn-soft-mini" onClick={today}>Today</button>
                <button className="btn-ghost-mini" onClick={next}>&gt;</button>
              </div>
            </div>

            <div className="cal-grid cal-dow">{["Sun","Mon","Tue","Wed","Thu","Fri","Sat"].map(d => <div key={d} className="cal-dow-cell">{d}</div>)}</div>

            <div className="cal-grid">
              {grid.map((cell, i) => (
                <div key={i} className={`cal-cell ${!cell ? "is-empty" : ""} ${cell?.isToday ? "is-today" : ""}`}>
                  {cell && (
                    <>
                      <div className="cal-daynum"><span>{cell.day}</span></div>
                      <button className="cal-add" type="button" onClick={() => openCreate(cell.date)} aria-label="Create schedule for this day">+</button>
                    </>
                  )}
                </div>
              ))}
            </div>
          </section>
        </div>
      </main>

      <CreateScheduleModal
        open={createOpen}
        onClose={() => setCreateOpen(false)}
        initialDate={modalDate}
        onCreate={(data) => console.log("create schedule:", data)}
      />
    </div>
  );
}
