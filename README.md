<div align="center">

<h1>🤖 Smart Medical Sample Transport — Embedded Robot</h1>

<p>
  <strong>The physical heart of the Smart Medical Sample Transport System</strong><br/>
  A two-tier embedded robotics platform that autonomously navigates hospital corridors to pick up and deliver medical samples.
</p>

<p>
  <img src="https://img.shields.io/badge/SBC-Raspberry%20Pi-red?style=for-the-badge&logo=raspberrypi&logoColor=white" alt="Raspberry Pi"/>
  <img src="https://img.shields.io/badge/MCU-ATmega%20(AVR)-1E90FF?style=for-the-badge" alt="ATmega"/>
  <img src="https://img.shields.io/badge/Protocol-MQTT-orange?style=for-the-badge&logo=eclipsemosquitto&logoColor=white" alt="MQTT"/>
  <img src="https://img.shields.io/badge/Vision-OpenCV%20%2B%20OCR-5C3EE8?style=for-the-badge&logo=opencv&logoColor=white" alt="OpenCV"/>
  <img src="https://img.shields.io/badge/License-Academic-lightgrey?style=for-the-badge" alt="License"/>
</p>

<p>
  <img src="https://img.shields.io/badge/Python-3.x-3776AB?style=flat-square&logo=python" alt="Python"/>
  <img src="https://img.shields.io/badge/paho--mqtt-2.1.0-8B4513?style=flat-square" alt="paho-mqtt"/>
  <img src="https://img.shields.io/badge/C-Atmel%20Studio-00979D?style=flat-square" alt="C / Atmel Studio"/>
  <img src="https://img.shields.io/badge/UART-Serial%20Comm-9C27B0?style=flat-square" alt="UART"/>
  <img src="https://img.shields.io/badge/IMU-Gyroscope-4CAF50?style=flat-square" alt="IMU"/>
</p>

</div>

---

## 📖 Table of Contents

- [Overview](#-overview)
- [Where This Module Fits](#-where-this-module-fits-in-the-system)
- [Hardware Architecture](#-hardware-architecture)
- [Raspberry Pi — High-Level Brain](#-raspberry-pi--high-level-brain)
- [ATmega Microcontroller — Real-Time Control](#-atmega-microcontroller--real-time-control)
- [Why Two Boards?](#-why-two-boards)
- [Sensors](#-sensors)
- [Navigation Behavior Walkthrough](#-navigation-behavior-walkthrough)
- [Technology Stack](#-technology-stack)
- [Project Structure](#-project-structure)
- [Getting Started](#-getting-started)
- [Contributors](#-contributors)

---

## 🌐 Overview

In hospitals, transporting medical samples (blood specimens, lab materials, small medical items) between doctors' rooms and the central lab has traditionally relied on nurses or porters walking samples from room to room — slow, error-prone, and a drain on staff time.

This module is the **physical robot** at the center of the Smart Medical Sample Transport System — the piece that actually drives down a hospital corridor, identifies rooms, and carries samples. It is arguably the most technically demanding part of the project, spanning two hardware tiers, three sensor types, and real-time embedded software working in tight coordination.

## 🔗 Where This Module Fits in the System

The full system spans four layers: a **Flutter mobile app**, a **Django backend**, an **MQTT communication layer**, and this **embedded robot**. This README covers only the embedded layer — the physical execution end of the pipeline.

```
   Backend (Django)  →  MQTT Broker
                              │
                              ▼
        ┌──────────────────────────────────────────┐
        │        THIS MODULE (Robot)               │
        │  ┌───────────────┐      ┌──────────────┐ │
        │  │ Raspberry Pi  │◄────►│  ATmega MCU  │ │
        │  │ (Brain)       │ UART │ (Real-Time)  │ │
        │  └───────────────┘      └──────────────┘ │
        └──────────────────────────────────────────┘
```

---

## 🏗️ Hardware Architecture

The robot is built from two coordinating boards, each responsible for a different tier of control, plus a set of sensors that feed both:

```
┌──────────────────────────┐         ┌───────────────────────────┐
│      Raspberry Pi        │  UART   │       ATmega MCU          │
│   (High-Level Brain)     │◄───────►│   (Real-Time Control)     │
│  · MQTT client           │         │  · Motor drivers          │
│  · State machine         │         │  · IR line sensors        │
│  · Camera + OCR          │         │  · Intersection detection │
│  · IMU integration       │         │  · Skip-N-intersections   │
│                          │         │  · Buzzer signalling      │
└──────────────────────────┘         └───────────────────────────┘
```

---

## 🧠 Raspberry Pi — High-Level Brain

The Raspberry Pi runs the robot's main control program and handles everything that requires networking, vision, or higher-level decision-making.

| Module | Responsibility |
|---|---|
| `rpi_main.py` | **Master state machine** — drives the robot's full lifecycle: Idle → Dispatched → Moving → Scanning → Arriving → Waiting → Returning → Storage |
| `mqtt_controller.py` | MQTT client — subscribes to dispatch/control topics, publishes arrival/acknowledgement events |
| `uart_controller.py` | Serial (UART) interface to the ATmega — sends movement commands, receives intersection stop signals |
| `camera_module.py` | **OpenCV + OCR room recognition** — reads room number signage at intersections, validates against the expected target before stopping |
| `functons.py` | IMU integration utilities for precise 90° rotation using gyroscope angular velocity |

**Key Behaviors:**

- **Camera + OCR Localization** — At every intersection, the camera reads the printed room number using OCR and compares it against the current target. If it doesn't match, the robot continues forward automatically; no expensive localization hardware required.
- **IMU-Controlled Rotation** — After confirming the correct room, the robot rotates 90° to face the door. The gyroscope's angular velocity is integrated in real time to measure exact rotation, guaranteeing a consistent, accurate turn regardless of battery level, motor speed variance, or floor friction.
- **State-Machine-Driven Navigation** — Every stage of the robot's behavior (idle, moving, scanning, waiting at a door, returning) is an explicit tracked state, making the robot's behavior predictable, debuggable, and safe.
- **Return Routing (Skip-N Logic)** — When returning to storage from a mid-corridor room, the robot can skip over N intersections rather than stopping at each one, computing the correct number of corridors to bypass to reach storage directly.

---

## ⚡ ATmega Microcontroller — Real-Time Control

While the Raspberry Pi handles "thinking," the ATmega handles time-critical, low-latency physical control — tasks a general-purpose Linux SBC cannot handle reliably due to OS scheduling jitter.

| Function | Detail |
|---|---|
| **Motor Control** | Direct H-bridge motor driving: forward, backward, left turn, right turn, stop |
| **IR Line Following** | Continuously polls IR sensors mounted under the chassis, making constant micro-corrections to stay centered on the floor line |
| **Intersection Detection** | Both left and right IR sensors simultaneously detect a crossing line → hard stop at that point, signalled to the RPi via UART |
| **Skip-N Intersections** | Executes a "pass-through N intersections" command from the RPi for direct return routing |
| **UART Communication** | Receives high-level commands from the RPi, sends acknowledgements and stop signals back |
| **Buzzer** | Audible arrival alert at each room — a physical cue in addition to the digital push notification |

---

## 🔀 Why Two Boards?

This two-tier hardware design is a deliberate engineering decision: the Raspberry Pi is excellent at Python, networking, camera processing, and OCR, but it is **not a real-time system** and can suffer timing jitter under load. The ATmega, in contrast, is a dedicated microcontroller that polls sensors and drives motors with tight, predictable timing — exactly what stable line-following and accurate intersection detection require.

Splitting responsibilities this way is a common and proven pattern in production robotics, and demonstrates an understanding of choosing the right tool for each job rather than forcing everything onto a single board.

---

## 📡 Sensors

| Sensor | Purpose |
|---|---|
| **IR Line Sensors** | Path following along the corridor floor line and intersection detection |
| **IMU (Gyroscope / Accelerometer)** | Precise rotational positioning — measuring exact turn angle for 90° door-facing rotations |
| **Camera** | Room identification via OCR on printed room number signage |

---

## 🚶 Navigation Behavior Walkthrough

1. Robot receives a dispatch batch over MQTT and begins driving down the corridor.
2. IR sensors keep it centered on the floor line; the ATmega detects each intersection and signals a stop.
3. At each intersection, the camera + OCR pipeline reads the room number and compares it to the current target.
4. On a **match** — the robot rotates 90° using IMU feedback to face the door and signals arrival back to the backend over MQTT.
5. On a **mismatch** — the robot continues forward automatically to the next intersection.
6. After delivery/return confirmation from the app (relayed via MQTT `control/` topic), the robot reverses out, rotates back to face the corridor, and either proceeds to the next room in the batch or returns directly to storage — using **skip-N-intersections** logic to bypass intermediate rooms when heading straight back.
7. On arrival at storage, the buzzer sounds and an MQTT arrival message notifies the backend, which in turn notifies storage staff.

---

## 🛠️ Technology Stack

| Layer | Technology |
|---|---|
| SBC | Raspberry Pi |
| SBC Language | Python 3.x |
| MCU | ATmega (AVR) |
| MCU Language | C (Atmel Studio) |
| Inter-board Communication | UART (Serial) |
| Cloud Communication | MQTT via `paho-mqtt` |
| Computer Vision | OpenCV + OCR |
| Orientation Sensing | IMU (gyroscope/accelerometer) |
| Line Following | IR sensors |

---

## 📂 Project Structure

```text
Embedded/
├── rpi/                              # Raspberry Pi Python modules
│   ├── rpi_main.py                    # Main state machine controller
│   ├── mqtt_controller.py             # MQTT client (dispatch / control)
│   ├── uart_controller.py             # Serial comms with ATmega
│   ├── camera_module.py               # OpenCV + OCR room detection
│   └── functons.py                    # IMU / helper utilities
├── Car_main_controller/               # ATmega C firmware
├── Line_Follower_Logic.h              # IR sensor line-following logic
└── gyroscope.txt                      # IMU integration notes
```

---

## 🚀 Getting Started

**Prerequisites:** Raspberry Pi running Python 3.x, connected to the same network as the MQTT broker; Atmel Studio for ATmega firmware development.

### Raspberry Pi Setup

```bash
# 1. Navigate to the RPi module directory
cd Embedded/rpi

# 2. Install required Python packages
pip install paho-mqtt opencv-python RPi.GPIO pyserial

# 3. Configure MQTT broker credentials
#    Edit mqtt_controller.py and set:
#      BROKER_HOST = "<your-hivemq-host>"
#      BROKER_PORT = 8883
#      USERNAME    = "<your-mqtt-username>"
#      PASSWORD    = "<your-mqtt-password>"

# 4. Run the main robot controller
python rpi_main.py
```

### ATmega Firmware

1. Open `Embedded/Car_main_controller_C.atsln` in **Atmel Studio**.
2. Build the project.
3. Flash the compiled firmware to the ATmega board via your programmer.
4. Connect the ATmega to the Raspberry Pi via UART, matching the baud rate configured in `uart_controller.py`.

---

## 👥 Contributors

<table>
  <tr>
    <td align="center" width="33%">
      <img src="Embedded/teams/1.png" width="120" height="120" style="border-radius: 50%; object-fit: cover;" alt="Khalid Abdelrazk"/><br/>
      <b>Khalid Abdelrazk (Team Leader)</b><br/>
      Embedded Systems Engineer
    </td>
    <td align="center" width="33%">
      <img src="Embedded/teams/2.jpg" width="120" height="120" style="border-radius: 50%; object-fit: cover;" alt="Menna Tallah Khaled"/><br/>
      <b>Menna Tallah Khaled</b><br/>
      IoT & Embedded Systems Engineer
    </td>
    <td align="center" width="33%">
      <img src="Embedded/teams/3.jpg" width="120" height="120" style="border-radius: 50%; object-fit: cover;" alt="Mohammed Fadel"/><br/>
      <b>Mohammed Fadel</b><br/>
      IoT & Embedded Systems Engineer
    </td>
  </tr>
  <tr>
    <td align="center" width="33%">
      <img src="Embedded/teams/4.jpg" width="120" height="120" style="border-radius: 50%; object-fit: cover;" alt="Nader Ahmed"/><br/>
      <b>Nader Ahmed</b><br/>
      Embedded Systems Engineer
    </td>
    <td></td>
    <td></td>
  </tr>
</table>

<div align="center">

**Smart Medical Sample Transport System — Embedded Robot**

*Where an MQTT message becomes a motor turning in a hospital hallway.*

---

<sub>Built with ❤️ as part of a graduation project demonstrating full-stack and systems engineering across mobile, backend, IoT, and robotics domains.</sub>

</div>
