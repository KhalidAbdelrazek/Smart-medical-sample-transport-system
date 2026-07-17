<div align="center">

<h1>🔌 Smart Medical Sample Transport — IoT Bridge</h1>

<p>
  <strong>The MQTT ↔ hardware bridge scripts of the Smart Medical Sample Transport System</strong><br/>
  Lightweight Python utilities connecting real-time MQTT signals to physical status indicators on the robot.
</p>

<p>
  <img src="https://img.shields.io/badge/Protocol-MQTT-orange?style=for-the-badge&logo=eclipsemosquitto&logoColor=white" alt="MQTT"/>
  <img src="https://img.shields.io/badge/Hardware-Raspberry%20Pi%20GPIO-red?style=for-the-badge&logo=raspberrypi&logoColor=white" alt="Raspberry Pi"/>
  <img src="https://img.shields.io/badge/Vision-OpenCV-5C3EE8?style=for-the-badge&logo=opencv&logoColor=white" alt="OpenCV"/>
  <img src="https://img.shields.io/badge/MCU-ATmega%20(AVR)-1E90FF?style=for-the-badge" alt="ATmega"/>
  <img src="https://img.shields.io/badge/License-Academic-lightgrey?style=for-the-badge" alt="License"/>
</p>

<p>
  <img src="https://img.shields.io/badge/Python-3.x-3776AB?style=flat-square&logo=python" alt="Python"/>
  <img src="https://img.shields.io/badge/paho--mqtt-2.1.0-8B4513?style=flat-square" alt="paho-mqtt"/>
  <img src="https://img.shields.io/badge/RPi.GPIO-status%20control-C51A4A?style=flat-square" alt="RPi.GPIO"/>
</p>

</div>

---

## 📖 Table of Contents

- [Overview](#-overview)
- [Where This Module Fits](#-where-this-module-fits-in-the-system)
- [Scripts](#-scripts)
- [Why a Separate Bridge Layer?](#-why-a-separate-bridge-layer)
- [Technology Stack](#-technology-stack)
- [Project Structure](#-project-structure)
- [Getting Started](#-getting-started)
- [Contributors](#-contributors)

---

## 🌐 Overview

The Smart Medical Sample Transport System replaces manual hospital sample transport with an autonomous robot, coordinated end-to-end through a mobile app, a Django backend, MQTT messaging, and embedded hardware.

This module — the **IoT bridge** — is a small but important set of Python scripts that sit alongside the main embedded controller. Its job is to translate real-time MQTT signals and computer-vision results into physical, human-visible status cues (like LED indicators) and to wire together the OpenCV and ATmega integration points that give hospital staff standing near the robot an immediate, at-a-glance sense of what it's doing.

## 🔗 Where This Module Fits in the System

The full system spans four layers: a **Flutter mobile app**, a **Django backend**, an **MQTT communication layer**, and the **embedded robot** (Raspberry Pi + ATmega). This IoT bridge module operates alongside the embedded robot layer, subscribing to the same MQTT signals to drive physical status indicators.

```
        MQTT Broker
             │
             ▼
┌──────────────────────────────┐
│   THIS MODULE (IoT Bridge)   │
│  MQTT → GPIO status signals  │
│  OpenCV ↔ ATmega integration │
└──────────────────────────────┘
             │
             ▼
   Physical LEDs / status indicators
```

---

## 📜 Scripts

| Script | Responsibility |
|---|---|
| `ledcontrol.py` | **LED status bridge** — subscribes to MQTT topics and drives GPIO pins to light physical LED indicators reflecting the robot's current state (e.g., idle, moving, arrived) |
| `IoT opencv final` | Final integration of the OpenCV-based room recognition pipeline into the IoT bridge context |
| `led_control_backend_atmega` | Wiring between backend-triggered signals and ATmega-driven LED/status control |

---

## 🤔 Why a Separate Bridge Layer?

Keeping these scripts separate from the core `rpi_main.py` state machine keeps the primary navigation and dispatch logic focused and uncluttered. The IoT bridge scripts are intentionally lightweight, single-purpose utilities — each one listens for a specific class of event (an MQTT message, a vision result, a backend signal) and reacts by driving a physical indicator. This separation makes it easy to test, swap, or extend the physical feedback layer (e.g., adding a new LED color or indicator) without touching the robot's core navigation and dispatch logic.

---

## 🛠️ Technology Stack

| Layer | Technology |
|---|---|
| Language | Python 3.x |
| Messaging | MQTT via `paho-mqtt` |
| Hardware I/O | RPi.GPIO |
| Computer Vision | OpenCV |
| Downstream Hardware | ATmega (AVR) via serial/UART signaling |

---

## 📂 Project Structure

```text
Iot/
├── ledcontrol.py                      # LED status bridge (MQTT ↔ GPIO)
├── IoT opencv final                   # Final OpenCV integration
└── led_control_backend_atmega         # Backend-ATmega LED control
```

---

## 🚀 Getting Started

**Prerequisites:** Raspberry Pi with Python 3.x, connected to the same network as the MQTT broker, with GPIO-connected LEDs/indicators wired up.

```bash
# 1. Navigate to the IoT bridge directory
cd Iot

# 2. Install required Python packages
pip install paho-mqtt RPi.GPIO opencv-python

# 3. Configure MQTT broker credentials
#    Edit ledcontrol.py and set:
#      BROKER_HOST = "<your-hivemq-host>"
#      BROKER_PORT = 8883
#      USERNAME    = "<your-mqtt-username>"
#      PASSWORD    = "<your-mqtt-password>"

# 4. Configure GPIO pin mappings
#    Match the LED/indicator pin numbers to your physical wiring.

# 5. Run the LED status bridge
python ledcontrol.py
```

---

## 👥 Contributors

<table>
  <tr>
    <td align="center" width="33%">
      <img src="Iot/teams/2.jpg" width="120" height="120" style="border-radius: 50%; object-fit: cover;" alt="Menna Tallah Khaled"/><br/>
      <b>Menna Tallah Khaled</b><br/>
      IoT & Embedded Systems Engineer
    </td>
    <td align="center" width="33%">
      <img src="Iot/teams/3.jpg" width="120" height="120" style="border-radius: 50%; object-fit: cover;" alt="Mohammed Fadel"/><br/>
      <b>Mohammed Fadel</b><br/>
      IoT & Embedded Systems Engineer
    </td>
    <td align="center" width="33%">
      <img src="Iot/teams/1.png" width="120" height="120" style="border-radius: 50%; object-fit: cover;" alt="Khalid Abdelrazk"/><br/>
      <b>Khalid Abdelrazk (Team Leader)</b><br/>
      Flutter & Embedded Systems Engineer
    </td>
  </tr>
</table>

<div align="center">

**Smart Medical Sample Transport System — IoT Bridge**

*Turning an MQTT message into a blinking light hospital staff can trust.*

---

<sub>Built with ❤️ as part of a graduation project demonstrating full-stack and systems engineering across mobile, backend, IoT, and robotics domains.</sub>

</div>
