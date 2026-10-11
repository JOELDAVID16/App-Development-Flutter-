# 🎮 GripX — Wireless Android Virtual Gamepad

**Turn your Android smartphone into a wireless Xbox 360 controller for Windows.**

GripX transforms your smartphone into a virtual game controller using local Wi-Fi communication. It combines responsive touch controls, motion-based steering, and haptic feedback to create an alternative way to play PC games without a physical controller.

Built with **Flutter, Python, UDP networking, and ViGEmBus**, GripX bridges Android input with Windows virtual gamepad emulation.

## ✨ Features

* 🎮 **Virtual Xbox 360 Controller** — Emulates an Xbox 360 controller on Windows for compatible games and applications.
* 📱 **Touch-Based Controls** — Provides on-screen gas, brake, and action buttons, including A, B, X, and Y.
* 🏎️ **Motion-Based Steering** — Uses phone orientation to control analog steering with adjustable sensitivity and deadzone filtering.
* 📳 **Dynamic Haptic Feedback** — Supports vibration feedback associated with throttle input.
* ⚡ **Low-Latency Communication** — Uses lightweight UDP packets for responsive real-time controller input.
* 📡 **Local Wi-Fi Connectivity** — Connects an Android phone to a Windows PC over the same local network.
* ⚙️ **Simple IP Configuration** — Allows users to enter the PC's local IP address directly in the app.
* 🔄 **Continuous Input Streaming** — Sends controller state updates at an approximate target rate of 60 Hz.

## 🏗️ System Architecture

GripX uses a client-server architecture to transfer controller inputs from an Android smartphone to a Windows PC.

```text
┌──────────────────────────┐
│     Android Smartphone   │
│                          │
│ Flutter Application      │
│ • Touch Controls         │
│ • Motion Sensors         │
│ • Haptic Feedback        │
└────────────┬─────────────┘
             │
             │ UDP / JSON
             │ Local Wi-Fi
             ▼
┌──────────────────────────┐
│       Windows PC         │
│                          │
│ Python Receiver Server   │
│ • Receive Input Packets  │
│ • Parse Controller Data  │
│ • Map Button & Axis Data │
└────────────┬─────────────┘
             │
             ▼
┌──────────────────────────┐
│     Virtual Gamepad      │
│                          │
│ Python: vgamepad         │
│ Driver: ViGEmBus         │
└────────────┬─────────────┘
             │
             ▼
┌──────────────────────────┐
│    Windows Games & OS    │
│                          │
│ Xbox 360 Controller Input│
└──────────────────────────┘
```

### How It Works

**1. Android Client — Flutter**

The mobile application captures touch inputs and device orientation using Flutter plugins. It packages the controller state into JSON messages and transmits them over UDP to the Windows host.

**2. Windows Host — Python**

The Python receiver listens on UDP port `5005`, decodes incoming messages, and maps the received values to virtual controller axes and buttons.

**3. Virtual Controller — vgamepad + ViGEmBus**

The `vgamepad` library communicates with the virtual gamepad driver to expose Xbox 360 controller input to compatible Windows applications.

## 🕹️ Controls

| Input             | Function        |
| ----------------- | --------------- |
| Tilt left / right | Analog steering |
| GAS               | Accelerate      |
| BRAKE             | Brake           |
| A, B, X, Y        | Action buttons  |
| Phone vibration   | Haptic feedback |

*Actual control mappings depend on the implementation and game configuration.*

## 📂 Project Structure

```text
virtual-gamepad/
│
├── client/                  # Flutter Android application
│   ├── lib/                 # Application source code
│   ├── android/             # Android platform configuration
│   └── pubspec.yaml         # Flutter dependencies
│
├── server/                  # Python Windows host
│   ├── server.py            # UDP receiver and controller mapping
│   └── requirements.txt     # Python dependencies
│
├── README.md
```

## ⚙️ Requirements

### Windows PC

* Windows 10 or Windows 11
* Python 3.8 or later
* ViGEmBus driver, if required by the selected virtual gamepad implementation
* Android phone and Windows PC connected to the same local network

### Android Smartphone

* Android device
* Flutter SDK for development
* USB debugging enabled if running through Flutter over USB
* Motion sensors and vibration hardware for the corresponding features

### Main Dependencies

| Component             | Technology     |
| --------------------- | -------------- |
| Mobile application    | Flutter / Dart |
| Motion sensing        | `sensors_plus` |
| Haptic feedback       | `vibration`    |
| PC receiver           | Python         |
| UDP communication     | Python socket  |
| Virtual controller    | `vgamepad`     |
| Virtual device driver | ViGEmBus       |

## 🚀 Installation & Setup

### Part 1 — Configure the Windows Host

**Step 1: Install the required driver**

Install the compatible ViGEmBus driver from the official [Nefarius ViGEmBus releases](https://github.com/nefarius/ViGEmBus/releases).

**Note:** ViGEmBus is a legacy project. Check its current maintenance status and compatibility before installing it on a new system.

**Step 2: Install Python dependencies**

Open a terminal and navigate to the server directory.

```bash
cd server
python -m pip install -r requirements.txt
```

**Step 3: Start the receiver**

```bash
python server.py
```

Allow Python through Windows Firewall on your trusted private network if prompted or required.

### Part 2 — Configure the Android Client

**Step 1: Navigate to the client directory**

```bash
cd client
```

**Step 2: Install Flutter dependencies**

```bash
flutter pub get
```

**Step 3: Connect and run the application**

Connect your Android phone using USB debugging, or use a supported wireless development setup.

```bash
flutter run --release
```

Alternatively, build an APK:

```bash
flutter build apk --release
```

The generated APK can be found under:

```text
build/app/outputs/flutter-apk/app-release.apk
```

## 🎯 How to Use GripX

1. Connect your Android phone and Windows PC to the same Wi-Fi network.
2. On Windows, open Command Prompt and run `ipconfig`.
3. Find the PC's IPv4 address for the active Wi-Fi adapter.
4. Start the Python receiver using `python server.py`.
5. Open GripX on your Android phone.
6. Enter the Windows PC's local IP address in the connection field.
7. Connect and use the on-screen controls or motion steering in a compatible game.

**Troubleshooting tips**

* Verify that both devices are on the same reachable network.
* Confirm that the receiver is listening on UDP port `5005`.
* Check Windows Firewall rules if packets cannot reach the server.
* Avoid exposing the receiver port to public networks.
* Confirm that the game supports controller input and that the virtual controller is detected.

## 🧠 Technical Highlights

* **UDP networking:** Prioritizes fresh controller state updates without TCP retransmission delays.
* **Sensor-based input:** Converts phone orientation into analog steering values.
* **Deadzone filtering:** Helps reduce unwanted steering caused by small sensor movements.
* **Controller emulation:** Translates mobile input into a virtual Xbox 360 controller.
* **Client-server design:** Separates mobile input handling from Windows controller emulation.

## 🔮 Future Improvements

* Customizable steering sensitivity and deadzone.
* Configurable controller layouts.
* Automatic PC discovery on the local network.
* Connection status and packet-loss indicators.
* Configurable button mappings and vibration intensity.
* Improved reconnection handling and input safety when the connection drops.
* Support for additional controller profiles.

## 🔐 Security

GripX is designed for use on a trusted local network. UDP communication does not inherently provide encryption or authentication, so additional safeguards may be needed before use on untrusted networks.



---

**Built to explore mobile input, real-time networking, and virtual controller emulation.**

*GripX — Your phone. Your controls. Your game.*
