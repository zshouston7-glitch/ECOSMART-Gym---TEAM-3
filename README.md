# ⚡ EcoSmart Gym Analytics Platform (Team 3)

> **"Don't just burn calories—power the grid."**

[![MATLAB](https://img.shields.io/badge/Language-MATLAB_R2023a+-green.svg?style=flat-square&logo=analytics)](https://www.mathworks.com/products/matlab.html)
[![License](https://img.shields.io/badge/License-MIT-blue.svg?style=flat-square)](LICENSE)
[![EDP Stage](https://img.shields.io/badge/EDP_Stage-App_Prototype-orange.svg?style=flat-square)](#)
[![Team](https://img.shields.io/badge/NACME_Team-Team_3-brightgreen.svg?style=flat-square)](#)

---

## 📖 The Story & Problem Setup

Meet **Randy Byers**, the CEO of GetFit Gyms. Every day, his facilities are packed with members running, spinning, and sweating. Collectively, they produce an incredible amount of kinetic energy. Yet, at the end of every month, Randy is hit with a devastating **$6,000 electricity bill**.

While Randy has invested in "eco-friendly" workout equipment, he faces a massive **Data Blind Spot**:
1. He has zero visibility into which machines are net-positive energy producers and which ones are severe power drains (like old commercial treadmills drawing up to 1,450W continuously).
2. Raw sensor output logs from the gym floor are riddled with high-frequency noise and power surges, making raw data unreadable and unscientific.

### 💡 The Solution: EcoSmart Gym App
Our team engineered a specialized, user-friendly **MATLAB App Designer** dashboard. By importing raw `.mat` sensor files, the app instantly filters out electrical surge noise using advanced digital signal processing. It provides Randy with clean, visual time-series graphs of active energy consumption versus generation, backed by a real-time reactive **Red/Green status warning lamp** to identify failing equipment instantly.

---

## 👥 Meet the Team & Core Roles

We are **Team 3**, collaborating for the **2026 NACME NVB Engineering Design Project**. Our diverse engineering roles allowed us to bring the EcoSmart Gym platform from a conceptual trade-off layout to a fully functional MATLAB analytic tool.

| Name | Core Project Role | Key Repository Contributions |
| :--- | :--- | :--- |
| **Zoey Houston** | **Project Manager & Doc Lead** | Handled project timelines, structured the team agreement, oversaw technical documentation, and managed the README clarity for non-expert users. |
| **Chenglang Ou** | **Backend Data Engineer** | Designed the `.mat` data parser, mapped power/current/voltage/temperature dictionaries, and programmed the `smoothdata` filtering algorithms. |
| **Jose Herrera** | **Frontend UI Lead** | Created the interactive two-panel App Designer layout, implemented the toggle switches, and designed the reactive red/green warning status lamps. |
| **Gabriel Perez** | **Analytics & Modeling Lead** | Developed the mathematical energy effectiveness conversions, set consumption thresholds, and conducted Quality Assurance (QA) testing. |

---

## 🛠️ App Architecture & Layout

Following our **Design Trade-off**, we prioritized a clean, **two-panel layout** to prevent confusing non-technical gym investors or CEOs:





## ⚙️ Technical "Non-Negotiables" & Implementation

Our app satisfies 5 core functional engineering standards:

1. **Smart Data Import:** Automatically loads `.mat` files mapping variables: `power` (Watts), `current` (Amps), `voltage` (Volts), and `temperature` (Celsius).
2. **Signal Processing:** Implements a dynamic moving median via `smoothdata(data, 'movmedian', 5)` to automatically shave off transient electrical surges from equipment startups.
3. **User Interactivity:** Features an interactive toggle switch allowing gym staff to switch displays instantly between Consumption metrics and Generation stats.
4. **Visual Indicators:** Prominently features an active visual status lamp which flashes red if consumption exceeds the safety threshold of **450 Watts**.
5. **Professional Delivery:** Thoroughly documented with instructions tested and verified by non-technical family members to guarantee ease of use.

---
