# Smart Medical Sample Transport System
<<<<<<< HEAD

Welcome to the **Smart Medical Sample Transport System** repository. This project is a comprehensive graduation project designed to automate, secure, and monitor the transport of medical samples within healthcare facilities using smart robotic carts.

## 🌟 Project Overview

The system provides a seamless end-to-end workflow for hospital staff to request, monitor, and manage the transport of medical samples. It integrates a Flutter mobile application, a scalable Django backend, and reliable IoT/Embedded software for the transport carts.

## 🏗️ Architecture & Modules

This repository is organized into four main components:

### 1. `smart_midecal_transport_app` (Mobile Application)
A cross-platform mobile app built with **Flutter**. 
- **Purpose**: Used by healthcare providers and hospital staff to request sample transports, track cart locations in real-time, and manage their assigned tasks.
- **Key Technologies**: Flutter, Dart, BLoC (State Management), Dio (Networking), GetIt, Easy Localization.

### 2. `Medical_Robot` (Backend API)
The central server communicating with the mobile app and the IoT carts.
- **Purpose**: Manages users, hospital wards, medical samples, cart assignments, and dynamic tracking of transport requests.
- **Key Apps/Modules**: `accounts`, `cars`, `healthcare`, `samples`, `transport`.
- **Key Technologies**: Python, Django, SQLite (database), and OpenAPI/Swagger for comprehensive API documentation.

### 3. `Iot` & `Embedded` (Hardware Integration)
The intelligence running on the physical transport carts.
- **Purpose**: Communicates cart status (e.g., ON/OFF states for LED indicators) and accepts remote commands.
- **Key Technologies**: Python, Raspberry Pi, HiveMQ MQTT (for real-time, lightweight message queuing on topics like `carts/+/status`).

## 📂 Folder Structure

```text
Smart-medical-sample-transport-system/
├── Embedded/                        # Microcontroller and lower-level embedded system code
├── Iot/                             # IoT scripts bridging hardware and MQTT (e.g., ledcontrol.py)
├── Medical_Robot/                   # Django REST backend application
├── smart_midecal_transport_app/     # Flutter mobile application for staff
└── README.md                        # Project documentation (this file)
```

## 🚀 Getting Started

### Backend (`Medical_Robot`)
1. Navigate to the `Medical_Robot` directory.
2. Ensure you have Python installed.
3. Install dependencies: `pip install -r requirements.txt`
4. Run migrations: `python manage.py migrate`
5. Start the server: `python manage.py runserver`
6. Access the Swagger documentation at the API root or `/api/schema/swagger-ui/`.

### Mobile App (`smart_midecal_transport_app`)
1. Navigate to the `smart_midecal_transport_app` directory.
2. Ensure you have the Flutter SDK installed (`v3.8.1` or higher).
3. Fetch packages: `flutter pub get`
4. Run the app: `flutter run`

### IoT Scripts (`Iot`)
1. Navigate to the `Iot` directory.
2. Install the required MQTT library: `pip install paho-mqtt`
3. If running on a Raspberry Pi, ensure `RPi.GPIO` is installed.
4. Run the script: `python ledcontrol.py`

## 👥 Contributors
Developed as part of a Graduation Project.
=======
test 
test
teeeeeeeeest
>>>>>>> merge
