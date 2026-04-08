# Execution OS 🛡️🦾 

**"Don't track intentions. Track reality."**

Execution OS is a psychology-driven productivity hub built for elite performers who value **integrity over intention.** Unlike traditional todo apps, Execution OS maps your daily tasks directly to your **Identity**. It ranks you through dynamic **Identity Tiers** based on a 7-day rolling integrity score. It detects your behavioral "Leaks"—like Overplanning or Integrity Gaps—and provides brutal, data-backed feedback through its integrated **Reality Hero HUD.**

---

### **🛡️ The Identity Pillars**

#### **1. Identity Progression 🥇**
You are ranked into one of four tiers based on your recent execution:
*   **Drifter**: < 50% avg score (3 days)
*   **Consistent**: > 50% avg score (3 days)
*   **The Operator**: > 70% avg score (5 days)
*   **Elite Operator**: > 90% avg score (7 perfect days)

#### **2. The Reality Hero (Brutal Logic) 🦾**
A high-contrast HUD that calls out your bullshit. It tracks the gap between your planned focus minutes and your actual activity. If you lie to yourself, the Hero lets you know.

#### **3. Commander’s Insights (Pattern Detection) 🛰️**
The OS analyzes your last 7 days to detect leaks:
*   **Overplanning**: High task volume vs. Low completion.
*   **Integrity Gap**: Intent vs. Actual focus time.
*   **Early Quitting**: Tracking abandoned sessions.

#### **4. Minimalist Focus Engine (Deep Work) 🧠**
A dedicated focus timer that integrates native **Haptic Feedback** and **Wakelock** support for professional, distraction-free execution.

---

### **🚀 Tech Stack**

*   **Frontend**: Flutter (Mobile & Web) 
*   **Backend**: Supabase (Cloud-Sync ready)
*   **State**: Repository Pattern (Local Storage & Supabase Hybrid)
*   **Storage**: PostgreSQL (Cloud) & Shared Preferences (Local)
*   **Sensory**: Tactile Haptics & Neon-Brutalist Design System

---

### **🛠️ Setup & Deployment**

1.  **Clone & Install**:
    ```bash
    git clone https://github.com/YOUR_USERNAME/execution-os.git
    cd execution_os
    flutter pub get
    ```

2.  **Cloud Infrastructure**:
    Paste the contents of `database_setup.sql` into your **Supabase SQL Editor** to initialize the Reality Ledger.

3.  **Config**:
    Update `lib/config.dart` with your Supabase URL and Anon Key. Toggle `isCloudReady = true`.

4.  **Run**:
    ```bash
    flutter run -d chrome  # For Web
    flutter build apk      # For Mobile
    ```

---

### **License & Disclaimer**
Built for high-stakes execution. Reality is what you execute, not what you plan. 🫡🔥
