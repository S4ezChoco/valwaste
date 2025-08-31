import React, { useState } from "react";
import { useNavigate } from "react-router-dom";
import { useAuth } from "./context/AuthContext";
import "./login.css";

export default function Login() {
  const { login } = useAuth();
  const navigate = useNavigate();
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState("");

  async function handleSubmit(e) {
    e.preventDefault();
    setError("");
    setSubmitting(true);

    const form = new FormData(e.currentTarget);
    const email = String(form.get("email") || "").trim();
    const password = String(form.get("password") || "");

    // Guard: if names are wrong or empty, bail early
    if (!email || !password) {
      setError("Please enter your email and password.");
      setSubmitting(false);
      return;
    }

      console.log("Form submit →", {
        email,
        passwordLength: password ? password.length : 0,
      });

    try {
      await login(email, password);
      navigate("/dashboard", { replace: true });
    } catch (err) {
      setError(err?.message || "Invalid email or password. Please try again.");
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <div className="login-container">
      <div className="left-panel">
        <div className="left-content">
          <div className="brand">
            <div className="brand-logo">V</div>
            <h1 className="brand-title">ValWaste Admin</h1>
          </div>

          <div className="welcome">
            <h2>Welcome back</h2>
            <p>Please sign in to your account to continue</p>
          </div>

          <form className="login-form" onSubmit={handleSubmit} noValidate>
            <label>
              <span>Email</span>
              <input
                name="email"                 /* <-- REQUIRED */
                type="email"
                inputMode="email"
                autoComplete="username"
                required
                placeholder="admin@valwaste.com"
              />
            </label>

            <label>
              <span>Password</span>
              <input
                name="password"              /* <-- REQUIRED */
                type="password"
                autoComplete="current-password"
                required
                minLength={6}
                placeholder="********"
              />
            </label>

            {error && (
              <div className="form-error" role="alert">
                {error}
              </div>
            )}

            <button type="submit" disabled={submitting} aria-busy={submitting}>
              {submitting ? "Signing in…" : "Sign In"}
            </button>
          </form>
        </div>
      </div>

      <div className="right-panel">
        <div className="right-content">
          <h2>ValWaste Administration Portal</h2>
          <p>
            Manage users, reports, and truck schedules all from a single dashboard.
            Monitor waste collection activities and improve community cleanliness.
          </p>
        </div>
      </div>
    </div>
  );
}
