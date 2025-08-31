import React, { createContext, useContext, useEffect, useState } from "react";
import { account } from "../lib/appwrite";

const AuthCtx = createContext(null);

export function AuthProvider({ children }) {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);

  async function refresh() {
    try {
      const me = await account.get();
      setUser(me);
    } catch {
      setUser(null);
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => { refresh(); }, []);

  async function login(email, password) {
  // Debug: see what the SDK exposes at runtime
  const methods = {
    createEmailPasswordSession: typeof account.createEmailPasswordSession,
    createEmailSession: typeof account.createEmailSession,
  };
  console.log("Auth login() args", { email, hasPassword: Boolean(password) });
  console.log("SDK methods", methods);

  try {
    if (typeof account.createEmailPasswordSession === "function") {
      // Newer SDK: object payload
      await account.createEmailPasswordSession({ email, password });
    } else if (typeof account.createEmailSession === "function") {
      // Older SDK: positional args
      await account.createEmailSession(email, password);
    } else {
      // Last-resort fallback: call the REST endpoint directly
      await manualEmailPasswordSession(email, password);
    }
  } catch (e) {
    console.error("create session failed:", e);
    // If we got a parameter error, try the other signature once
    if (typeof account.createEmailPasswordSession === "function") {
      // We tried object form; try positional
      if (typeof account.createEmailSession === "function") {
        await account.createEmailSession(email, password);
      } else {
        await manualEmailPasswordSession(email, password);
      }
    } else if (typeof account.createEmailSession === "function") {
      // We tried positional; try object
      if (typeof account.createEmailPasswordSession === "function") {
        await account.createEmailPasswordSession({ email, password });
      } else {
        await manualEmailPasswordSession(email, password);
      }
    } else {
      throw e;
    }
  }

  await refresh(); // GET /account to load the user
}
  async function logout() {
    try { await account.deleteSession("current"); } catch {}
    setUser(null);
  }

  return (
    <AuthCtx.Provider value={{ user, loading, login, logout }}>
      {children}
    </AuthCtx.Provider>
  );
}

export function useAuth() {
  return useContext(AuthCtx);
}

async function manualEmailPasswordSession(email, password) {
  const endpoint = import.meta.env.VITE_APPWRITE_ENDPOINT?.replace(/\/+$/, "");
  const project = import.meta.env.VITE_APPWRITE_PROJECT_ID;
  if (!endpoint || !project) {
    throw new Error("Missing Appwrite env: VITE_APPWRITE_ENDPOINT / VITE_APPWRITE_PROJECT_ID");
  }

  const res = await fetch(`${endpoint}/account/sessions/email`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "X-Appwrite-Project": project,
    },
    credentials: "include", // allow the session cookie to be set
    body: JSON.stringify({ email, password }),
  });

  if (!res.ok) {
    let msg = "Login failed";
    try {
      const data = await res.json();
      msg = data?.message || msg;
    } catch {}
    throw new Error(msg);
  }
}
