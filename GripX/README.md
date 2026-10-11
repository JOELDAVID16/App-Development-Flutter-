** GripX-Wireless Android Virtual Gamepad **

Transform your Android smartphone into a fully functional wireless Xbox 360 game controller over your local Wi-Fi network. This project features motion-based tilt steering, on-screen touch controls, dynamic haptic feedback, and a high-performance Python-to-Windows kernel driver bridge.

---

System Architecture & Data Flow

[Android Phone (Wi-Fi)] ---(UDP / JSON)---> [Windows PC Host (Python Receiver)] ---> (ViGEmBus) -> [Windows Game / OS (Xbox 360 Controller)]

1. Android Client (Flutter): Captures device orientation/tilt via accelerometers (sensors_plus), reads touch inputs for gas, brake, and action buttons, triggers dynamic haptic rumbles (vibration), and broadcasts non-blocking UDP packets at ~60Hz.
2. PC Host Server (Python): Binds to UDP port 5005, parses incoming telemetry, and maps values directly into a virtual Xbox 360 controller using vgamepad backed by the ViGEmBus kernel driver.

---

Key Features

* Motion Tilt Steering: Converts phone Y-axis orientation into smooth, adjustable analog steering with a deadzone filter.
* Dynamic Haptic Throttle: Scales vibration amplitude proportionally with gas trigger pressure depth.
* Low-Latency UDP Networking: Skirts TCP head-of-line blocking by transmitting lightweight datagrams optimized for real-time input devices.
* Zero-Configuration UI: Built-in runtime IP configuration to connect instantly to any Windows host on your local network.

---

Repository Structure

virtual-gamepad/
├── client/              # Flutter Android Client App
│   ├── lib/
│   ├── android/
│   └── pubspec.yaml
├── server/              # Python Windows Receiver Server
│   ├── server.py
│   └── requirements.txt
└── README.md

---

Installation & Setup Guide

Part 1: Windows Host Setup (Python Server)

1. Install the ViGEmBus Driver:
* Download and install the latest ViGEmBus driver (required for virtual hardware emulation) from the Nefarius Software official releases.


2. Setup the Python Environment:
* Ensure Python 3.8+ is installed.
* Navigate to the server/ directory and install dependencies:
cd server
pip install -r requirements.txt


3. Run the Receiver Server:
* Launch the server script (run with administrative privileges if prompted by the driver):
python server.py



Part 2: Android Client Setup (Flutter App)

1. Navigate to the Client Directory:
cd client
2. Install Dependencies:
flutter pub get
3. Connect Your Android Device & Run:
* Enable USB Debugging on your Android phone.
* Run the app in release or debug mode:
flutter run --release
(Alternatively, build an APK via flutter build apk and install it on your device).



---

Usage Instructions

1. Find your Windows host PC's local IP address (run ipconfig in your Windows terminal, e.g., 192.168.1.105).
2. Open the Virtual Gamepad app on your Android device (the app locks automatically to landscape mode).
3. Enter your PC's IP address into the top configuration field.
4. Tilt your phone left or right to steer, tap the GAS or BRAKE triggers, and use the on-screen action buttons (A, B, X, Y).

---

Requirements & Dependencies

* PC Server: vgamepad>=2.1.0, Windows 10/11, ViGEmBus Driver.
* Mobile Client: Flutter SDK, sensors_plus: ^5.0.0, vibration: ^2.0.0.

---

License

Distributed under the MIT License. See LICENSE for more information.
