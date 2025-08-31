import React, { useEffect, useMemo, useState } from "react";
import { NavLink, useNavigate } from "react-router-dom";
import {
  LayoutGrid,
  Users as UsersIcon,
  FileText,
  ClipboardCheck,
  LogOut,
  Menu,
  X,
  Truck,
  ChevronDown,
  ChevronRight,
  Clock,
  CheckCircle2,
  XCircle,
  User as UserIcon,
  Camera,
} from "lucide-react";
import { useAuth } from "../context/AuthContext";
import "./dashboard.css";

/* ---------- small helpers ---------- */
function StatusBadge({ status }) {
  const cls =
    status === "verified"
      ? "att-badge att-badge-green"
      : status === "not-out"
      ? "att-badge att-badge-gray"
      : "att-badge att-badge-amber";
  const label =
    status === "verified"
      ? "Verified"
      : status === "pending"
      ? "Pending Verification"
      : "Not Checked Out";
  return <span className={cls}>{label}</span>;
}

function DriverCell({ name, role }) {
  return (
    <div className="att-driver">
      <div className="att-avatar"><UserIcon size={16} /></div>
      <div className="att-driver-meta">
        <div className="att-driver-name">{name}</div>
        <span className="att-role-pill">{role}</span>
      </div>
    </div>
  );
}

function chipFor(role) {
  const r = String(role).toLowerCase();
  if (r === "collector" || r === "waste collector") {
    return { label: "Waste Collector", cls: "att-chip att-chip-collector" };
  }
  if (r === "palero" || r === "paleros") {
    return { label: "Palero", cls: "att-chip att-chip-palero" };
  }
  if (r === "driver") {
    return { label: "Driver", cls: "att-role-pill" };
  }
  return { label: role, cls: "att-chip" };
}

function fmtDateTime(d) {
  const M = ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"];
  let h = d.getHours(), am = h >= 12 ? "PM" : "AM";
  h = h % 12 || 12;
  return `${M[d.getMonth()]} ${d.getDate()}, ${String(h).padStart(2,"0")}:${String(d.getMinutes()).padStart(2,"0")} ${am}`;
}

/* ---------- Details Modal (unchanged actions styling) ---------- */
function AttendanceDetailsModal({ open, onClose, record, onVerify, onReject }) {
  if (!open || !record) return null;
  const pending = record.status === "pending";

  return (
    <div className="um-modal" onMouseDown={(e) => e.target === e.currentTarget && onClose()}>
      <div className="um-modal-card large" role="dialog" aria-modal="true" aria-labelledby="attd-title">
        <button className="um-modal-close" aria-label="Close" onClick={onClose}><X size={18} /></button>

        <h3 id="attd-title" className="um-modal-title">Team Attendance Details</h3>
        <p className="um-modal-sub">Detailed information about the team's attendance record.</p>

        <div style={{ display: "grid", gridTemplateColumns: "repeat(2,minmax(0,1fr))", gap: 16, marginTop: 8 }}>
          <div className="card" style={{ padding: 12 }}>
            <div style={{ fontWeight: 600, marginBottom: 8 }}>Check-In Photo</div>
            <div style={{ background: "#eef2f7", border: "1px solid var(--border)", borderRadius: 12, height: 220, display: "grid", placeItems: "center", color: "#64748b", marginBottom: 8 }}>
              <div>Photo placeholder</div>
            </div>
            <div style={{ color: "#475569", fontSize: 14 }}>Check-in time: {record.checkIn || "—"}</div>
          </div>

          <div className="card" style={{ padding: 12 }}>
            <div style={{ fontWeight: 600, marginBottom: 8 }}>Check-Out Photo</div>
            <div style={{ background: "#eef2f7", border: "1px solid var(--border)", borderRadius: 12, height: 220, display: "grid", placeItems: "center", color: "#64748b", marginBottom: 8 }}>
              <div>Photo placeholder</div>
            </div>
            <div style={{ color: "#475569", fontSize: 14 }}>Check-out time: {record.checkOut || "—"}</div>
          </div>
        </div>

        <div className="card" style={{ marginTop: 16, padding: 16 }}>
          <div style={{ fontWeight: 700, marginBottom: 12 }}>Team Members</div>
          <div style={{ display: "grid", gap: 8 }}>
            <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
              <span className="att-role-pill">Driver</span>
              <span style={{ fontWeight: 600 }}>{record.driver}</span>
            </div>
            {record.members.map((m, i) => {
              const chip = chipFor(m.role);
              return (
                <div key={i} style={{ display: "flex", alignItems: "center", gap: 10 }}>
                  <span className={chip.cls}>{chip.label}</span>
                  <span>{m.name}</span>
                </div>
              );
            })}
          </div>
        </div>

        <div className="card" style={{ marginTop: 12, padding: 16 }}>
          <div style={{ fontWeight: 700, marginBottom: 10 }}>Additional Information</div>
          <div style={{ display: "flex", gap: 6, marginBottom: 6 }}>
            <span style={{ fontWeight: 700 }}>Location:</span>
            <span>{record.location || "—"}</span>
          </div>
          <div style={{ color: "#111827" }}>{record.notes || "—"}</div>
        </div>

        {pending && (
          <div className="um-modal-actions att-actions-row">
            <button type="button" className="att-cta att-reject" onClick={onReject}>
              <XCircle size={16} /> Reject
            </button>
            <button type="button" className="att-cta att-verify" onClick={onVerify}>
              <CheckCircle2 size={16} /> Verify
            </button>
          </div>
        )}
      </div>
    </div>
  );
}

/* ---------- Record Check-In Modal ---------- */
function CheckInModal({ open, onClose, drivers, members, onSubmit }) {
  const [teamType, setTeamType] = useState("Waste Collection");
  const [driver, setDriver] = useState("");
  const [memberPick, setMemberPick] = useState("");
  const [teamMembers, setTeamMembers] = useState([]);
  const [photoCaptured, setPhotoCaptured] = useState(false);
  const [location, setLocation] = useState("");
  const [notes, setNotes] = useState("");

  useEffect(() => {
    if (!open) return;
    setTeamType("Waste Collection");
    setDriver("");
    setMemberPick("");
    setTeamMembers([]);
    setPhotoCaptured(false);
    setLocation("");
    setNotes("");
  }, [open]);

  if (!open) return null;

  function addMember() {
    if (!memberPick) return;
    if (!teamMembers.includes(memberPick)) setTeamMembers((m) => [...m, memberPick]);
  }
  function removeMember(name) {
    setTeamMembers((m) => m.filter((x) => x !== name));
  }

  function submit(e) {
    e.preventDefault();
    if (!driver) return alert("Please select a driver.");
    if (teamMembers.length === 0) return alert("Please add at least one team member.");
    onSubmit({ teamType, driver, members: teamMembers, location, notes, photoCaptured });
    onClose();
  }

  return (
    <div className="um-modal" onMouseDown={(e) => e.target === e.currentTarget && onClose()}>
      <div className="um-modal-card large" role="dialog" aria-modal="true" aria-labelledby="checkin-title">
        <button className="um-modal-close" aria-label="Close" onClick={onClose}><X size={18} /></button>

        <h3 id="checkin-title" className="um-modal-title">Record Team Check-In</h3>
        <p className="um-modal-sub">Take a team photo and record check-in time for your waste collection team.</p>

        <form className="um-form" onSubmit={submit}>
          {/* Team Type segmented */}
          <label className="um-field">
            <span className="um-label">Team Type</span>
            <div className="checkin-seg">
              <button type="button" className={`seg ${teamType === "Waste Collection" ? "active" : ""}`} onClick={() => setTeamType("Waste Collection")}>Waste Collection</button>
              <button type="button" className={`seg ${teamType === "Special Operations" ? "active" : ""}`} onClick={() => setTeamType("Special Operations")}>Special Operations</button>
            </div>
          </label>

          {/* Driver */}
          <label className="um-field">
            <span className="um-label">Select Driver</span>
            <div className="um-select-wrap">
              <select className="um-select" value={driver} onChange={(e) => setDriver(e.target.value)} required>
                <option value="" disabled>Select a driver</option>
                {drivers.map((d) => <option key={d} value={d}>{d}</option>)}
              </select>
              <ChevronDown size={16} className="um-select-caret" />
            </div>
          </label>

          {/* Team members add */}
          <label className="um-field">
            <span className="um-label">Team Members</span>
            <div className="checkin-row">
              <div className="um-select-wrap">
                <select className="um-select" value={memberPick} onChange={(e) => setMemberPick(e.target.value)}>
                  <option value="" disabled>Select team member</option>
                  {members.map((m) => <option key={m} value={m}>{m}</option>)}
                </select>
                <ChevronDown size={16} className="um-select-caret" />
              </div>
              <button
                type="button"
                className="checkin-plus"
                style={{ width: "auto", padding: "0 12px", borderRadius: 10, height: 36, display: "inline-flex", alignItems: "center", fontWeight: 600 }}
                onClick={addMember}
                title="Add member"
              >
                Add
              </button>
            </div>

            {teamMembers.length === 0 ? (
              <div className="checkin-empty">No team members selected</div>
            ) : (
              <div className="checkin-chips">
                {teamMembers.map((n) => (
                  <span key={n} className="checkin-chip">
                    {n}
                    <button type="button" className="x" aria-label={`Remove ${n}`} onClick={() => removeMember(n)}>×</button>
                  </span>
                ))}
              </div>
            )}
          </label>

          {/* Photo */}
          <label className="um-field">
            <span className="um-label">Check-In Photo</span>
            <button type="button" className="checkin-photo-btn" onClick={() => setPhotoCaptured(true)}>
              <Camera size={16} /> {photoCaptured ? "Photo Captured" : "Capture Team Photo"}
            </button>
          </label>

          {/* Location */}
          <label className="um-field">
            <span className="um-label">Location</span>
            <input className="um-input" value={location} onChange={(e) => setLocation(e.target.value)} placeholder="Enter location or route" />
          </label>

          {/* Notes */}
          <label className="um-field">
            <span className="um-label">Additional Information</span>
            <textarea className="um-input" rows={4} value={notes} onChange={(e) => setNotes(e.target.value)} placeholder="Enter any additional information" />
          </label>

          <div className="um-modal-actions" style={{ justifyContent: "flex-end" }}>
            <button type="submit" className="btn-primary">
              <Clock size={16} /> Record Check-In
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}

/* ---------- NEW: Record Check-Out Modal ---------- */
function CheckOutModal({ open, onClose, rows, onSubmit }) {
  const [rowId, setRowId] = useState("");
  const [photoCaptured, setPhotoCaptured] = useState(false);
  const [notes, setNotes] = useState("");

  useEffect(() => {
    if (!open) return;
    setRowId("");
    setPhotoCaptured(false);
    setNotes("");
  }, [open]);

  if (!open) return null;

  // Only teams that are not yet checked out
  const activeRows = rows.filter((r) => !r.checkOut);

  const selected = activeRows.find((r) => r.id === rowId);

  function submit(e) {
    e.preventDefault();
    if (!rowId) return alert("Please select a team to check out.");
    onSubmit({ id: rowId, photoCaptured, notes });
    onClose();
  }

  return (
    <div className="um-modal" onMouseDown={(e) => e.target === e.currentTarget && onClose()}>
      <div className="um-modal-card large" role="dialog" aria-modal="true" aria-labelledby="checkout-title">
        <button className="um-modal-close" aria-label="Close" onClick={onClose}><X size={18} /></button>

        <h3 id="checkout-title" className="um-modal-title">Record Team Check-Out</h3>
        <p className="um-modal-sub">Pick a checked-in team, capture a photo, and record their check-out time.</p>

        <form className="um-form" onSubmit={submit}>
          {/* Pick team (by driver) */}
          <label className="um-field">
            <span className="um-label">Select Team</span>
            <div className="um-select-wrap">
              <select className="um-select" value={rowId} onChange={(e) => setRowId(e.target.value)} required>
                <option value="" disabled>
                  {activeRows.length ? "Select driver/team to check out" : "No teams available for check-out"}
                </option>
                {activeRows.map((r) => (
                  <option key={r.id} value={r.id}>
                    {r.driver} — In: {r.checkIn}
                  </option>
                ))}
              </select>
              <ChevronDown size={16} className="um-select-caret" />
            </div>
          </label>

          {/* Preview members */}
          {selected && (
            <div className="card" style={{ padding: 12 }}>
              <div style={{ fontWeight: 700, marginBottom: 8 }}>Team Members</div>
              <ul className="att-member-list">
                <li className="att-member-row"><span className="att-role-pill">Driver</span><span className="att-member-name">{selected.driver}</span></li>
                {selected.members.map((m, i) => {
                  const chip = chipFor(m.role);
                  return (
                    <li key={i} className="att-member-row">
                      <span className={chip.cls}>{chip.label}</span>
                      <span className="att-member-name">{m.name}</span>
                    </li>
                  );
                })}
              </ul>
            </div>
          )}

          {/* Photo */}
          <label className="um-field">
            <span className="um-label">Check-Out Photo</span>
            <button type="button" className="checkin-photo-btn" onClick={() => setPhotoCaptured(true)}>
              <Camera size={16} /> {photoCaptured ? "Photo Captured" : "Capture Team Photo"}
            </button>
          </label>

          {/* Notes */}
          <label className="um-field">
            <span className="um-label">Additional Information</span>
            <textarea className="um-input" rows={4} value={notes} onChange={(e) => setNotes(e.target.value)} placeholder="Enter any additional information" />
          </label>

          <div className="um-modal-actions" style={{ justifyContent: "flex-end" }}>
            <button type="submit" className="btn-soft">
              <Clock size={16} /> Record Check-Out
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}

/* ============================ PAGE ============================ */
export default function Attendance() {
  const [open, setOpen] = useState(false);
  const { logout } = useAuth();
  const navigate = useNavigate();

  useEffect(() => {
    const onResize = () => { if (window.innerWidth >= 1025) setOpen(false); };
    onResize();
    window.addEventListener("resize", onResize);
    return () => window.removeEventListener("resize", onResize);
  }, []);

  async function handleSignOut() {
    try { setOpen(false); await logout(); } finally { navigate("/", { replace: true }); }
  }

  // demo pools for modal
  const driversPool = ["John Doe", "Sarah Johnson", "Pedro Reyes"];
  const membersPool = ["Maria Garcia", "Ahmed Ali", "Carlos Rodriguez", "Dina", "Evan", "Mike Williams", "Elena Vasquez"];

  const [rows, setRows] = useState([
    {
      id: "r1",
      driver: "John Doe",
      role: "Driver",
      teamCount: 3,
      checkIn: "May 15, 08:00 AM",
      checkOut: null,
      status: "pending",
      members: [
        { name: "Maria Garcia", role: "Collector" },
        { name: "Ahmed Ali", role: "Collector" },
        { name: "Carlos Rodriguez", role: "Palero" },
      ],
      location: "Central Waste Facility",
      notes: "Morning shift, Route A - North sector",
      expanded: false,
    },
    {
      id: "r2",
      driver: "Sarah Johnson",
      role: "Driver",
      teamCount: 2,
      checkIn: "May 15, 08:15 AM",
      checkOut: "May 15, 04:30 PM",
      status: "verified",
      members: [
        { name: "Dina", role: "Collector" },
        { name: "Evan", role: "Palero" },
      ],
      location: "West Transfer Station",
      notes: "Afternoon shift, Route B",
      expanded: false,
    },
  ]);

  const counts = useMemo(
    () => ({ all: rows.length, pending: rows.filter(r => r.status === "pending").length }),
    [rows]
  );

  const [tab, setTab] = useState("Team Records");
  const shown = useMemo(
    () => (tab === "Pending Verification" ? rows.filter(r => r.status === "pending") : rows),
    [rows, tab]
  );

  const PANEL =
    tab === "Pending Verification"
      ? { title: "Pending Verification", sub: "Team attendance records that need administrator verification", empty: "No pending records" }
      : { title: "Team Attendance Records", sub: "View all team attendance records for drivers, waste collectors, and paleros", empty: "No records found" };

  function toggleExpand(id) {
    setRows(rs => rs.map(r => (r.id === id ? { ...r, expanded: !r.expanded } : r)));
  }
  function verifyRow(id) { setRows(rs => rs.map(r => (r.id === id ? { ...r, status: "verified", checkOut: r.checkOut || "May 15, 04:00 PM" } : r))); }
  function rejectRow(id) { setRows(rs => rs.map(r => (r.id === id ? { ...r, status: "not-out" } : r))); }

  // Details modal state
  const [detailsOpen, setDetailsOpen] = useState(false);
  const [detailsRecord, setDetailsRecord] = useState(null);
  function openDetails(id) {
    setRows(rs => rs.map(r => (r.id === id ? { ...r, expanded: true } : r)));
    const rec = rows.find(r => r.id === id);
    if (rec) { setDetailsRecord(rec); setDetailsOpen(true); }
  }

  // Check-in modal state
  const [checkOpen, setCheckOpen] = useState(false);
  function handleCheckInSubmit(form) {
    const id = "r" + Math.random().toString(36).slice(2, 8);
    const newRow = {
      id,
      driver: form.driver,
      role: "Driver",
      teamCount: form.members.length,
      checkIn: fmtDateTime(new Date()),
      checkOut: null,
      status: "pending",
      members: form.members.map((n) => ({ name: n, role: "Collector" })), // simple default
      location: form.location,
      notes: form.notes,
      expanded: false,
    };
    setRows((rs) => [newRow, ...rs]);
  }

  // Check-out modal state
  const [checkOutOpen, setCheckOutOpen] = useState(false);
  function handleCheckOutSubmit({ id }) {
    setRows((rs) =>
      rs.map((r) => (r.id === id ? { ...r, checkOut: fmtDateTime(new Date()) } : r))
    );
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
        <h1 className="page-title">Attendance</h1>
      </div>

      <aside className={`sidebar ${open ? "is-open" : ""}`}>
        <div className="sidebar-mobile-header">
          <div className="brand"><div className="brand-circle">V</div><div className="brand-name">ValWaste</div></div>
          <button className="closebtn" aria-label="Close sidebar" onClick={() => setOpen(false)}><X size={20} /></button>
        </div>

        <nav className="nav" onClick={() => setOpen(false)}>
          <NavLink to="/dashboard"  className={({isActive}) => `nav-item ${isActive ? "active" : ""}`}><span className="icon-left"><LayoutGrid size={18} /></span><span className="label">Dashboard</span></NavLink>
          <NavLink to="/users"      className={({isActive}) => `nav-item ${isActive ? "active" : ""}`}><span className="icon-left"><UsersIcon size={18} /></span><span className="label">User Management</span></NavLink>
          <NavLink to="/reports"    className={({isActive}) => `nav-item ${isActive ? "active" : ""}`}><span className="icon-left"><FileText size={18} /></span><span className="label">Report Management</span></NavLink>
          <NavLink to="/schedule"   className={({isActive}) => `nav-item ${isActive ? "active" : ""}`}><span className="icon-left"><Truck size={18} /></span><span className="label">Truck Schedule</span></NavLink>
          <NavLink to="/attendance" className={({isActive}) => `nav-item ${isActive ? "active" : ""}`}><span className="icon-left"><ClipboardCheck size={18} /></span><span className="label">Attendance</span></NavLink>
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
          <div className="att-pagehead">
            <div>
              <h2 className="att-h2">Team Attendance Management</h2>
              <p className="att-sub">Track attendance for waste collection teams</p>
            </div>
            <div className="att-ctas">
              <button className="btn-soft" onClick={() => setCheckOutOpen(true)}>
                <Clock size={16} /> Record Check-Out
              </button>
              <button className="btn-primary" onClick={() => setCheckOpen(true)}>
                <CheckCircle2 size={16} /> Record Check-In
              </button>
            </div>
          </div>

          <div className="rm-tabs">
            <div className="rm-seg">
              <button type="button" className={`rm-tab ${tab === "Team Records" ? "active" : ""}`} onClick={() => setTab("Team Records")}><span>Team Records</span></button>
              <button type="button" className={`rm-tab ${tab === "Pending Verification" ? "active" : ""}`} onClick={() => setTab("Pending Verification")}><span>Pending Verification</span><span className="count-dot count-red">{counts.pending}</span></button>
            </div>
          </div>

          <section className="card att-card">
            <div className="att-head">
              <h3 className="att-title">{PANEL.title}</h3>
              <p className="att-sub2">{PANEL.sub}</p>
            </div>

            <div className="card um-table-card">
              <table className="um-table att-table">
                <colgroup>
                  <col className="col-driver" />
                  <col className="col-team" />
                  <col className="col-in" />
                  <col className="col-out" />
                  <col className="col-status" />
                  <col className="col-actions" />
                </colgroup>
                <thead>
                  <tr>
                    <th>Driver</th>
                    <th>Team</th>
                    <th>Check-In</th>
                    <th>Check-Out</th>
                    <th>Status</th>
                    <th className="col-actions">Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {shown.length === 0 && (
                    <tr className="empty">
                      <td colSpan={6}>{PANEL.empty}</td>
                    </tr>
                  )}

                  {shown.map(r => (
                    <React.Fragment key={r.id}>
                      <tr>
                        <td>
                          <button className="att-caret" onClick={() => toggleExpand(r.id)} aria-label="toggle">
                            {r.expanded ? <ChevronDown size={16} /> : <ChevronRight size={16} />}
                          </button>
                          <DriverCell name={r.driver} role={r.role} />
                        </td>
                        <td><div className="att-cell"><UsersIcon size={16} /><span className="att-teamcount">{r.teamCount}</span></div></td>
                        <td><div className="att-cell att-mono"><Clock size={14} /> {r.checkIn}</div></td>
                        <td>{r.checkOut ? <div className="att-cell att-mono"><Clock size={14} /> {r.checkOut}</div> : <span className="att-badge att-badge-gray">Not Checked Out</span>}</td>
                        <td><StatusBadge status={r.status} /></td>
                        <td className="att-actions"><button className="btn-soft-sm" onClick={() => openDetails(r.id)}>Details</button></td>
                      </tr>

                      {r.expanded && (
                        <tr className="att-expand">
                          <td colSpan={6}>
                            <div className="att-expand-grid">
                              <div className="att-col">
                                <div className="att-expand-title">Team Members</div>
                                <ul className="att-member-list">
                                  <li className="att-member-row"><span className="att-role-pill">Driver</span><span className="att-member-name">{r.driver}</span></li>
                                  {r.members.map((m, i) => {
                                    const chip = chipFor(m.role);
                                    return <li key={i} className="att-member-row"><span className={chip.cls}>{chip.label}</span><span className="att-member-name">{m.name}</span></li>;
                                  })}
                                </ul>
                              </div>
                              <div className="att-col">
                                <div className="att-expand-title">Additional Information</div>
                                <div className="att-kv"><span className="att-k">Location:</span><span className="att-v">{r.location || "—"}</span></div>
                                <div className="att-note">{r.notes || "—"}</div>
                              </div>
                            </div>
                          </td>
                        </tr>
                      )}
                    </React.Fragment>
                  ))}
                </tbody>
              </table>
            </div>
          </section>
        </div>
      </main>

      {/* Details Modal */}
      <AttendanceDetailsModal
        open={detailsOpen}
        onClose={() => setDetailsOpen(false)}
        record={detailsRecord}
        onVerify={() => { if (detailsRecord) verifyRow(detailsRecord.id); setDetailsOpen(false); }}
        onReject={() => { if (detailsRecord) rejectRow(detailsRecord.id); setDetailsOpen(false); }}
      />

      {/* Record Check-In Modal */}
      <CheckInModal
        open={checkOpen}
        onClose={() => setCheckOpen(false)}
        drivers={driversPool}
        members={membersPool}
        onSubmit={handleCheckInSubmit}
      />

      {/* Record Check-Out Modal */}
      <CheckOutModal
        open={checkOutOpen}
        onClose={() => setCheckOutOpen(false)}
        rows={rows}
        onSubmit={handleCheckOutSubmit}
      />
    </div>
  );
}
