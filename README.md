<div align="center">

<h1>⚙️ Smart Medical Sample Transport — Backend Server</h1>

<p>
  <strong>The coordination core of the Smart Medical Sample Transport System</strong><br/>
  A Django REST API responsible for authentication, business logic, the full sample lifecycle, and bridging the mobile app to the physical transport robot.
</p>

<p>
  <img src="https://img.shields.io/badge/Backend-Django%205.2-green?style=for-the-badge&logo=django&logoColor=white" alt="Django"/>
  <img src="https://img.shields.io/badge/API-DRF%203.16-ff1709?style=for-the-badge" alt="DRF"/>
  <img src="https://img.shields.io/badge/Auth-JWT-black?style=for-the-badge&logo=jsonwebtokens&logoColor=white" alt="JWT"/>
  <img src="https://img.shields.io/badge/Database-SQLite-07405E?style=for-the-badge&logo=sqlite&logoColor=white" alt="SQLite"/>
  <img src="https://img.shields.io/badge/Protocol-MQTT-orange?style=for-the-badge&logo=eclipsemosquitto&logoColor=white" alt="MQTT"/>
</p>

<p>
  <img src="https://img.shields.io/badge/Python-3.x-3776AB?style=flat-square&logo=python" alt="Python"/>
  <img src="https://img.shields.io/badge/SimpleJWT-5.5.1-black?style=flat-square" alt="SimpleJWT"/>
  <img src="https://img.shields.io/badge/paho--mqtt-2.1.0-8B4513?style=flat-square" alt="paho-mqtt"/>
  <img src="https://img.shields.io/badge/drf--spectacular-0.29.0-9C27B0?style=flat-square" alt="drf-spectacular"/>
  <img src="https://img.shields.io/badge/CORS-django--cors--headers-4CAF50?style=flat-square" alt="CORS"/>
  <img src="https://img.shields.io/badge/License-Academic-lightgrey?style=flat-square" alt="License"/>
</p>

</div>

---

## 📖 Table of Contents

- [Overview](#-overview)
- [Where This Server Fits](#-where-this-server-fits-in-the-system)
- [Responsibilities](#-responsibilities)
- [Django Apps](#-django-apps)
- [Authentication & Security](#-authentication--security)
- [Sample Lifecycle](#-sample-lifecycle)
- [MQTT Bridge](#-mqtt-bridge)
- [Database](#-database)
- [Technology Stack](#-technology-stack)
- [Project Structure](#-project-structure)
- [Getting Started](#-getting-started)
- [API Documentation](#-api-documentation)
- [Contributors](#-contributors)

---

## 🌐 Overview

In hospitals, transporting medical samples (blood specimens, lab materials, small medical items) between doctors' rooms and the central lab has traditionally relied on manual staff effort — slow, error-prone, and a drain on time that should go to patient care.

This Django backend is the **coordination core** of the Smart Medical Sample Transport System, a broader project that replaces manual sample transport with an autonomous mobile robot. Every meaningful decision in the system — who is allowed to do what, which rooms the robot should visit next, whether a sample has actually been delivered — is decided here. It is what turns a simple remote-controlled cart into a genuinely *smart*, accountable, trackable transport system.

## 🔗 Where This Server Fits in the System

The full system spans four layers: a **Flutter mobile app**, this **Django backend**, an **MQTT communication layer**, and an **IoT/embedded robot**. This README covers only the backend server layer — the brain that sits between the two.

```
        Mobile App (Flutter)
                │  REST API + JWT
                ▼
┌───────────────────────────────────┐
│         THIS SERVER (Django)       │
│  Auth · Business Logic · Dispatch  │
└───────────────────┬───────────────┘
                    │  MQTT Publish / Subscribe
                    ▼
         MQTT Broker  →  Robot (RPi + ATmega)
```

---

## 🧭 Responsibilities

- **User authentication and authorization** using JWT — every login issues a signed token used to verify identity and role on every subsequent request, without re-sending credentials.
- **Business logic for the entire sample lifecycle** — creating requests, grouping requests by room into a single dispatch batch, generating unique batch and request IDs, and tracking samples as picked up, delivered, or returned.
- **Acting as the bridge to the physical robot** — deciding *what* needs to happen physically (which rooms to visit, in what order) and translating app-level actions like "dispatch the car" into a structured dispatch payload the robot can execute over MQTT.
- **Notification delivery** — triggering the push notifications the doctor and storage apps display (sample arrived, car returned to storage, etc.) the moment something physically happens.
- **Historical record-keeping** — maintaining the full request/dispatch/delivery history that powers the statistics dashboards in the mobile app.

---

## 🧩 Django Apps

| App | Responsibility |
|---|---|
| `accounts` | User registration, JWT login/refresh, role-based permissions (Doctor · Storage · Admin) |
| `cars` | Robot/cart entity management, dispatch tracking |
| `healthcare` | Wards, rooms, hospital structural entities |
| `samples` | Sample records, status lifecycle (requested → picked up → delivered → returned) |
| `transport` | Batch creation, dispatch coordination, MQTT command publishing |
| `restrictions` | Account suspension and reinstatement controls |
| `analytics` | Aggregated statistics with time-range filtering |
| `dashboard` | Admin-facing overview views |
| `common` | Shared base models, mixins, and utilities |

---

## 🔐 Authentication & Security

- **JWT (JSON Web Tokens)** via `djangorestframework-simplejwt`.
- Stateless, signed tokens carry user identity and role on every request — no server-side session state required.
- Role-based permission classes enforce endpoint access at the API level:
  - A **doctor** cannot access dispatch controls or admin restrictions.
  - **Storage staff** cannot access analytics dashboards.
  - **Admins** have full read access across all resources, plus restriction and force-stop controls.

---

## 🔄 Sample Lifecycle

1. A doctor's app request creates a new sample request, logged with a timestamp and unique ID.
2. Storage staff group pending requests into a delivery **batch**, each assigned a unique batch ID.
3. Dispatching the batch triggers the backend to publish a structured payload to the robot over MQTT — the rooms to visit, and in what order.
4. As the robot reports arrivals back over MQTT, the backend updates each sample's status and fires the relevant push notification.
5. Doctor confirmation of receipt (or a return request) is written back to the sample record, keeping the full lifecycle — requested → dispatched → delivered/returned — fully auditable.
6. All of this feeds the **analytics** app, which aggregates the history into the statistics shown across the Doctor, Storage, and Admin dashboards.

---

## 📡 MQTT Bridge

The backend does not talk to the robot directly over a persistent connection — it publishes and subscribes to structured MQTT topics through a broker, keeping the robot and the server loosely coupled and able to operate asynchronously (the robot can't always move instantly; it may need to wait for human confirmation before proceeding).

| Direction | Topic | Payload | Description |
|---|---|---|---|
| Backend → Robot | `dispatch/` | JSON batch (rooms + sample IDs) | Tells the robot which rooms to visit and in what order |
| Robot → Backend | `acknowledgement/` | Dispatch ID | Robot confirms it received and accepted a dispatch |
| Robot → Backend | `arrival/` | Room ID + fulfilled request IDs | Robot reports physical arrival at a room or storage |
| Backend → Robot | `control/` | `proceed` + next destination | Clears the robot to leave the current room and continue |

> Full payload schemas and flow diagrams are documented in `mqtt-flow.md`.

---

## 🗄️ Database

**SQLite** (`db.sqlite3`) is used for development and demonstration. The schema is designed for a straightforward migration to PostgreSQL or MySQL in a production deployment by changing a single `DATABASES` setting in Django — no changes to models or business logic required.

---

## 🛠️ Technology Stack

| Layer | Technology | Version |
|---|---|---|
| Language | Python | 3.x |
| Framework | Django | 5.2.7 |
| REST API | Django REST Framework | 3.16.1 |
| Authentication | SimpleJWT | 5.5.1 |
| MQTT Client | paho-mqtt | 2.1.0 |
| API Documentation | drf-spectacular (OpenAPI 3) | 0.29.0 |
| CORS | django-cors-headers | 4.9.0 |
| Database | SQLite (dev) | built-in |

---

## 📂 Project Structure

```text
Medical_Robot/
├── accounts/                    # User auth, JWT, role management
├── analytics/                   # Statistics and reporting
├── cars/                        # Robot/cart management
├── common/                      # Shared utilities
├── dashboard/                   # Admin dashboard views
├── healthcare/                  # Wards and hospital entities
├── restrictions/                # Account restriction controls
├── samples/                     # Sample lifecycle management
├── transport/                   # Request batching & dispatch logic
├── Medical_Robot/               # Django project settings
├── manage.py
├── requirements.txt
├── db.sqlite3                   # SQLite database (development)
├── openapi.json                 # OpenAPI schema
└── mqtt-flow.md                 # MQTT flow documentation
```

---

## 🚀 Getting Started

**Prerequisites:** Python 3.x, pip

```bash
# 1. Navigate to the backend directory
cd Medical_Robot

# 2. Create and activate a virtual environment (recommended)
python -m venv venv
source venv/bin/activate        # Linux / macOS
venv\Scripts\activate           # Windows

# 3. Install all dependencies
pip install -r requirements.txt

# 4. Apply database migrations
python manage.py migrate

# 5. (Optional) Create a superuser for the Django admin panel
python manage.py createsuperuser

# 6. Configure MQTT broker credentials
#    Set the broker host, port, username, and password
#    in your settings/environment configuration.

# 7. Start the development server
python manage.py runserver
```

The server will be available at `http://127.0.0.1:8000/`

---

## 📄 API Documentation

The backend exposes a fully documented REST API using **OpenAPI 3 / Swagger** via `drf-spectacular`.

| Endpoint | Description |
|---|---|
| `/api/schema/swagger-ui/` | Interactive Swagger UI |
| `/api/schema/redoc/` | ReDoc alternative view |
| `/api/schema/` | Raw OpenAPI JSON schema |

The static schema file is also available at `openapi.json`.

---

## 👥 Contributors

<table>
  <tr>
    <td align="center" width="33%">
      <img src="Medical_Robot/teams/5.jpg" width="120" height="120" style="border-radius: 50%; object-fit: cover;" alt="Mohammed Ashraf"/><br/>
      <b>Mohammed Ashraf</b><br/>
      Back-End Developer
    </td>
    <td align="center" width="33%">
      <img src="Medical_Robot/teams/6.png" width="120" height="120" style="border-radius: 50%; object-fit: cover;" alt="Shahd Hegazy"/><br/>
      <b>Shahd Hegazy</b><br/>
      Back-End Developer
    </td>
    <td align="center" width="33%">
      <img src="Medical_Robot/teams/7.png" width="120" height="120" style="border-radius: 50%; object-fit: cover;" alt="Merna Ezzat"/><br/>
      <b>Merna Ezzat</b><br/>
      Back-End Developer
    </td>
  </tr>
</table>

<div align="center">

**Smart Medical Sample Transport System — Backend Server**

*The brain that turns a phone tap into a coordinated, accountable robot dispatch.*

---

<sub>Built with ❤️ as part of a graduation project demonstrating full-stack and systems engineering across mobile, backend, IoT, and robotics domains.</sub>

</div>
