<div align="center">

<h1>📱 Smart Medical Sample Transport — Mobile App</h1>

<p>
  <strong>The human-facing layer of the Smart Medical Sample Transport System</strong><br/>
  A cross-platform Flutter application connecting Doctors, Storage Staff, and Admins to an autonomous hospital sample transport robot in real time.
</p>

<p>
  <img src="https://img.shields.io/badge/Platform-Android%20%7C%20iOS-blue?style=for-the-badge&logo=flutter&logoColor=white" alt="Platform"/>
  <img src="https://img.shields.io/badge/Flutter-3.8.1+-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter"/>
  <img src="https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart"/>
  <img src="https://img.shields.io/badge/Auth-JWT-black?style=for-the-badge&logo=jsonwebtokens&logoColor=white" alt="JWT"/>
  <img src="https://img.shields.io/badge/License-Academic-lightgrey?style=for-the-badge" alt="License"/>
</p>

<p>
  <img src="https://img.shields.io/badge/State%20Management-BLoC-blue?style=flat-square" alt="BLoC"/>
  <img src="https://img.shields.io/badge/Networking-Dio-9C27B0?style=flat-square" alt="Dio"/>
  <img src="https://img.shields.io/badge/DI-GetIt-orange?style=flat-square" alt="GetIt"/>
  <img src="https://img.shields.io/badge/Localization-Easy%20Localization-4CAF50?style=flat-square" alt="Easy Localization"/>
  <img src="https://img.shields.io/badge/Notifications-Firebase-FFCA28?style=flat-square&logo=firebase&logoColor=black" alt="Firebase"/>
</p>

</div>

---

## 📖 Table of Contents

- [Overview](#-overview)
- [Where This App Fits](#-where-this-app-fits-in-the-system)
- [Key Benefits](#-key-benefits)
- [User Roles & Features](#-user-roles--features)
  - [Doctor Interface](#-doctor-interface)
  - [Storage Staff Interface](#-storage-staff-interface)
  - [Admin Interface](#-admin-interface)
- [Notification Flow](#-notification-flow)
- [Technology Stack](#-technology-stack)
- [Project Structure](#-project-structure)
- [Getting Started](#-getting-started)
- [Building for Release](#-building-for-release)
- [Contributors](#-contributors)

---

## 🌐 Overview

In hospitals, transporting medical samples (blood specimens, lab materials, small medical items) between doctors' rooms and the central lab has traditionally relied on nurses or porters walking samples from room to room — a process that is slow, error-prone, and pulls staff away from direct patient care.

This Flutter application is the **primary human interface** for the Smart Medical Sample Transport System, a broader project that replaces manual sample transport with an autonomous mobile robot. The app is what doctors, storage staff, and hospital administrators actually use, day to day, to request samples, dispatch the robot, track deliveries, and monitor system-wide activity — all from a single, role-aware codebase.

## 🔗 Where This App Fits in the System

The full Smart Medical Sample Transport System spans four layers: this **mobile app**, a **Django backend**, an **MQTT communication layer**, and an **IoT/embedded robot**. This repository/README covers only the mobile application layer — the interface through which every human interaction with the system happens.

```
┌─────────────────────────────────────────┐
│           THIS APP (Flutter)             │
│    Doctor · Storage Staff · Admin UI     │
└───────────────────┬───────────────────────┘
                    │  REST API + JWT
                    ▼
            Django Backend Server
                    │
                    ▼
         MQTT Broker  →  Robot (RPi + ATmega)
```

## ✨ Key Benefits

| Benefit | Description |
|---|---|
| ⏱️ **Speed** | Doctors request samples on demand — no waiting on staff availability |
| 🔍 **Traceability** | Every request, pickup, and delivery is logged and timestamped |
| 🧾 **Accountability** | Explicit human confirmation required for every delivery — no assumed handoffs |
| 🧑‍⚕️ **Role-Aware UX** | One codebase, three completely tailored experiences (Doctor / Storage / Admin) |
| 🔔 **Real-Time Awareness** | Push notifications keep every relevant user informed the instant something happens physically |

---

## 👤 User Roles & Features

The app includes a unified sign-up/login flow that routes each authenticated user to a dedicated, role-specific interface based on their account type: **Doctor**, **Storage Staff**, or **Admin**.

### 🩺 Doctor Interface

The doctor experience is built around four main tabs:

| Tab | Description |
|---|---|
| **Home** | Personal statistics dashboard — a quick visual overview of the doctor's own request activity and history (requested, completed, cancelled) |
| **Request** | Request a sample pickup from any specific room — the entry point that creates the demand the robot responds to |
| **Requested Samples** | A live list of all samples the doctor has already requested, with the ability to cancel any pending request before the robot arrives |
| **Profile** | Standard account management — personal info and settings |

Doctors also receive **real-time push notifications** the moment the robot physically arrives at their room with a sample.

### 🏪 Storage Staff Interface

The storage employee's home screen mirrors the doctor's statistics concept, framed around the storage employee's own performance and activity — giving management a similar accountability metric for storage staff.

Beyond that, storage staff have the operational controls that actually build a transport run:

- **View all current sample requests** coming in from doctors across all rooms.
- **Add or remove specific samples** from the robot's upcoming delivery batch — curating exactly what it will carry on its next trip.
- **Dispatch the car** — the action that triggers the robot to start moving and visiting rooms in sequence.
- A dedicated **Profile tab**, plus a **notification system**: when the robot completes its route and returns to storage, a notification confirms it is idle and ready for the next batch.

### 🛡️ Admin Interface

The administrator role exists purely for oversight and control rather than daily operational use:

- **Statistical analysis with flexible time filtering** — system-wide usage and performance statistics filterable by *last year*, *last month*, or *all time*, useful for evaluating efficiency trends, staff workload, and system adoption.
- **Restriction controls** — restrict access for specific doctor or storage accounts (e.g., suspending an account misusing the system, or temporarily disabling a department).
- **Force stop dispatch** — remotely halt any active robot route. A critical safety and operational-control feature if something goes wrong physically with the robot mid-route.

---

## 🔔 Notification Flow

1. The robot physically arrives at the doctor's room with a sample → a push notification is sent to the doctor's phone.
2. The doctor opens the notification and **confirms whether the sample was actually received**. This closes the loop on accountability — the system never assumes delivery happened, it requires explicit human confirmation.
3. Immediately after confirming receipt, a **follow-up popup** asks the doctor if they'd like to **return a sample on the same robot visit**, since the robot is already physically present at the door.
4. If the doctor says yes, the app shows the list of samples currently in that room, letting them select which ones to send back — avoiding a second dedicated robot trip just for a return.
5. When the robot later completes its route and returns, the **storage staff app** receives its own notification confirming the car is back and idle.

---

## 🛠️ Technology Stack

| Category | Technology |
|---|---|
| Framework | Flutter (cross-platform: Android & iOS) |
| Language | Dart |
| State Management | BLoC |
| Networking | Dio |
| Dependency Injection | GetIt |
| Localization | Easy Localization |
| Push Notifications | Firebase Cloud Messaging |
| Authentication | JWT (issued by the Django backend) |

---

## 📂 Project Structure

```text
Flutter/
├── lib/                    # Dart source code
│   ├── core/                # Shared utilities, DI setup, networking
│   ├── features/            # Feature modules (auth, doctor, storage, admin)
│   ├── shared/               # Common widgets, theming
│   └── main.dart
├── assets/                 # Images, fonts, localization files
├── android/                # Android platform configuration
├── ios/                    # iOS platform configuration
├── web/                    # Web platform configuration (if applicable)
└── pubspec.yaml             # Package dependencies and metadata
```

> Note: exact folder names may vary slightly depending on the internal feature-module organization of the codebase.

---

## 🚀 Getting Started

**Prerequisites:** Flutter SDK 3.8.1+, Dart SDK, a running instance of the backend API (see the backend module's setup instructions).

```bash
# 1. Navigate to the mobile app directory
cd Flutter

# 2. Fetch all Flutter package dependencies
flutter pub get

# 3. (Optional) Verify your environment
flutter doctor

# 4. Configure the backend API base URL
#    Update the relevant config/constants file with your
#    Django backend's base URL (e.g. http://<your-backend-host>:8000/)

# 5. Run on a connected device or emulator
flutter run
```

## 📦 Building for Release

```bash
# Android release APK
flutter build apk --release

# Android App Bundle (for Play Store)
flutter build appbundle --release

# iOS release build
flutter build ios --release
```

---

## 👥 Contributors

<table>
  <tr>
    <td align="center" width="50%">
      <img src="assets/teams/1.png" width="120" height="120" style="border-radius: 50%; object-fit: cover;" alt="Khalid Abdelrazk"/><br/>
      <b>Khalid Abdelrazk (Team Leader)</b><br/>
      Flutter Developer
    </td>
    <td align="center" width="50%">
      <img src="assets/teams/8.png" width="120" height="120" style="border-radius: 50%; object-fit: cover;" alt="Mohammed Tarek"/><br/>
      <b>Mohammed Tarek</b><br/>
      Flutter Developer
    </td>
  </tr>
</table>

<div align="center">

**Smart Medical Sample Transport System — Mobile Application**

*The interface where a tap on a phone screen sets an autonomous hospital robot in motion.*

---

<sub>Built with ❤️ as part of a graduation project demonstrating full-stack and systems engineering across mobile, backend, IoT, and robotics domains.</sub>

</div>
