import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';

// -----------------------------------------------------------------------------
// CONSTANTS & CONFIGURATION
// -----------------------------------------------------------------------------
class AppConfig {
  static const int udpPort = 5005;
  static const String defaultIp = "192.168.1.100";
  static const String appTitle = "GripX";
  static const String developerCredit = "DEVELOPED BY JOEL DAVID";
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appTitle,
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
      ),
      home: const ModeSelectionScreen(),
    );
  }
}

// -----------------------------------------------------------------------------
// UDP NETWORK SERVICE
// -----------------------------------------------------------------------------
class UdpService {
  RawDatagramSocket? _socket;

  Future<void> init() async {
    try {
      _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    } catch (e) {
      debugPrint("UDP Socket Error: $e");
    }
  }

  void sendPayload(String ip, Map<String, dynamic> data) {
    if (_socket == null || ip.isEmpty) return;
    try {
      final payload = jsonEncode(data);
      _socket!.send(
        utf8.encode(payload),
        InternetAddress(ip),
        AppConfig.udpPort,
      );
    } catch (e) {
      debugPrint("Error sending UDP Packet: $e");
    }
  }

  void dispose() {
    _socket?.close();
    _socket = null;
  }
}

// -----------------------------------------------------------------------------
// 1. MAIN MODE SELECTION SCREEN & CONNECT GUIDE
// -----------------------------------------------------------------------------
class ModeSelectionScreen extends StatefulWidget {
  const ModeSelectionScreen({super.key});

  @override
  State<ModeSelectionScreen> createState() => _ModeSelectionScreenState();
}

class _ModeSelectionScreenState extends State<ModeSelectionScreen> {
  final TextEditingController _ipController =
      TextEditingController(text: AppConfig.defaultIp);

  @override
  void initState() {
    super.initState();
    _loadSavedIp();
  }

  Future<void> _loadSavedIp() async {
    final prefs = await SharedPreferences.getInstance();
    final savedIp = prefs.getString('saved_pc_ip');
    if (savedIp != null && savedIp.isNotEmpty) {
      setState(() => _ipController.text = savedIp);
    }
  }

  Future<void> _saveIp(String ip) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_pc_ip', ip);
  }

  void _showHowToConnectDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.help_outline, color: Colors.greenAccent),
            SizedBox(width: 8),
            Text("How to Connect", style: TextStyle(color: Colors.white)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: const [
              _StepItem(
                number: "1",
                title: "Same Local Network",
                desc: "Connect both your PC and Phone to the exact same Wi-Fi network or Mobile Hotspot.",
              ),
              _StepItem(
                number: "2",
                title: "Find PC IPv4 Address",
                desc: "Open Command Prompt (cmd) on your PC, run 'ipconfig', and copy your IPv4 address.",
              ),
              _StepItem(
                number: "3",
                title: "Launch Python Server",
                desc: "Run 'python server.py' on your PC. Ensure Windows Firewall permits UDP Port 5005.",
              ),
              _StepItem(
                number: "4",
                title: "Connect & Play",
                desc: "Paste your IP above and choose a controller mode. Inputs auto-feed directly into XInput games!",
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("GOT IT",
                style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // Header & IP Setup Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    AppConfig.appTitle,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.0,
                      color: Colors.white,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.help_outline, color: Colors.greenAccent),
                        tooltip: "How to Connect",
                        onPressed: _showHowToConnectDialog,
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 220,
                        height: 42,
                        child: TextField(
                          controller: _ipController,
                          onChanged: _saveIp,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: const InputDecoration(
                            labelText: "PC IPv4 Address",
                            labelStyle: TextStyle(color: Colors.white70, fontSize: 12),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            border: OutlineInputBorder(),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.white30),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.greenAccent),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Game Controller Modes
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: _buildModeCard(
                        title: "Xbox Controller",
                        icon: Icons.sports_esports,
                        color: Colors.greenAccent,
                        desc: "Full Xbox 360 layout with Dual Joysticks, D-Pad, LT/RT Triggers, and ABXY.",
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => FullXboxControllerScreen(
                                ip: _ipController.text.trim()),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildModeCard(
                        title: "Custom Motion Racing",
                        icon: Icons.edit_attributes,
                        color: Colors.blueAccent,
                        desc: "Tilt Steering with Drag-and-Drop Paddles and Haptic Shift Pedals.",
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CustomTiltMotionScreen(
                                ip: _ipController.text.trim()),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Developer Watermark
              const Text(
                AppConfig.developerCredit,
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeCard({
    required String title,
    required IconData icon,
    required Color color,
    required String desc,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.4), width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 44, color: color),
            const SizedBox(height: 8),
            Text(title,
                style: TextStyle(
                    color: color, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(desc,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white60, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

// Helper Widget for "How to Connect" steps
class _StepItem extends StatelessWidget {
  final String number;
  final String title;
  final String desc;

  const _StepItem({
    required this.number,
    required this.title,
    required this.desc,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 11,
            backgroundColor: Colors.greenAccent,
            child: Text(
              number,
              style: const TextStyle(
                  color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
                const SizedBox(height: 2),
                Text(desc, style: const TextStyle(color: Colors.white70, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 2. CUSTOM MOTION TILT RACING MODE
// -----------------------------------------------------------------------------
class CustomTiltMotionScreen extends StatefulWidget {
  final String ip;
  const CustomTiltMotionScreen({super.key, required this.ip});

  @override
  State<CustomTiltMotionScreen> createState() => _CustomTiltMotionScreenState();
}

class _CustomTiltMotionScreenState extends State<CustomTiltMotionScreen> {
  final UdpService _udpService = UdpService();
  StreamSubscription<AccelerometerEvent>? _accelSub;
  Timer? _sendTimer;

  bool _isEditMode = false;
  double _steering = 0.0;
  double _accel = 0.0;
  double _brake = 0.0;
  bool _gearUp = false;
  bool _gearDown = false;

  Map<String, Offset> _positions = {
    "accel": const Offset(280, 140),
    "brake": const Offset(20, 140),
    "gear_up": const Offset(280, 40),
    "gear_down": const Offset(20, 40),
  };

  @override
  void initState() {
    super.initState();
    _udpService.init();
    _loadPositions();
    _startAccelerometer();
    _sendTimer =
        Timer.periodic(const Duration(milliseconds: 16), (_) => _sendData());
  }

  Future<void> _loadPositions() async {
    final prefs = await SharedPreferences.getInstance();
    final savedJson = prefs.getString('custom_layout_tilt');
    if (savedJson != null) {
      final Map<String, dynamic> decoded = jsonDecode(savedJson);
      setState(() {
        decoded.forEach((key, val) {
          _positions[key] = Offset(val['x'], val['y']);
        });
      });
    }
  }

  Future<void> _savePositions() async {
    final prefs = await SharedPreferences.getInstance();
    Map<String, dynamic> exportMap = {};
    _positions.forEach((key, offset) {
      exportMap[key] = {'x': offset.dx, 'y': offset.dy};
    });
    await prefs.setString('custom_layout_tilt', jsonEncode(exportMap));
  }

  void _startAccelerometer() {
    _accelSub = accelerometerEvents.listen((event) {
      double norm = (event.y / 5.0).clamp(-1.0, 1.0);
      if (norm.abs() < 0.05) norm = 0.0;
      setState(() => _steering = norm);
    });
  }

  void _triggerHaptic({required bool isGearUp}) async {
    bool? hasAmp = await Vibration.hasAmplitudeControl();
    if (isGearUp) {
      hasAmp == true
          ? Vibration.vibrate(duration: 80, amplitude: 255)
          : Vibration.vibrate(duration: 80);
    } else {
      hasAmp == true
          ? Vibration.vibrate(duration: 40, amplitude: 140)
          : Vibration.vibrate(duration: 40);
    }
  }

  void _sendData() {
    if (_isEditMode) return;
    _udpService.sendPayload(widget.ip, {
      "mode": "tilt",
      "ls_x": _steering,
      "rt": _accel,
      "lt": _brake,
      "btn_rb": _gearUp,
      "btn_lb": _gearDown,
    });
  }

  @override
  void dispose() {
    _accelSub?.cancel();
    _sendTimer?.cancel();
    _udpService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _isEditMode
                        ? "DRAG CONTROLS TO CUSTOMIZE"
                        : "Steering Angle: ${_steering.toStringAsFixed(2)}",
                    style: TextStyle(
                      fontSize: 16,
                      color: _isEditMode ? Colors.orangeAccent : Colors.greenAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              _isEditMode ? Colors.green[700] : Colors.grey[800],
                        ),
                        onPressed: () {
                          setState(() => _isEditMode = !_isEditMode);
                          if (!_isEditMode) _savePositions();
                        },
                        icon: Icon(_isEditMode ? Icons.check : Icons.edit,
                            color: Colors.white),
                        label: Text(_isEditMode ? "Save Layout" : "Edit Layout",
                            style: const TextStyle(color: Colors.white)),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        style:
                            ElevatedButton.styleFrom(backgroundColor: Colors.grey[800]),
                        onPressed: () => Navigator.pop(context),
                        child:
                            const Text("Exit", style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            _buildDraggableControl(
              id: "accel",
              screenSize: screenSize,
              child: _buildPedal("ACCEL", _accel, Colors.green,
                  (p) => setState(() => _accel = p ? 1.0 : 0.0)),
            ),
            _buildDraggableControl(
              id: "brake",
              screenSize: screenSize,
              child: _buildPedal("BRAKE", _brake, Colors.redAccent,
                  (p) => setState(() => _brake = p ? 1.0 : 0.0)),
            ),
            _buildDraggableControl(
              id: "gear_up",
              screenSize: screenSize,
              child: _buildPaddle("GEAR +", Colors.cyanAccent, (p) {
                setState(() => _gearUp = p);
                if (p) _triggerHaptic(isGearUp: true);
              }),
            ),
            _buildDraggableControl(
              id: "gear_down",
              screenSize: screenSize,
              child: _buildPaddle("GEAR -", Colors.orangeAccent, (p) {
                setState(() => _gearDown = p);
                if (p) _triggerHaptic(isGearUp: false);
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDraggableControl({
    required String id,
    required Size screenSize,
    required Widget child,
  }) {
    Offset pos = _positions[id] ?? const Offset(50, 50);

    return Positioned(
      left: pos.dx,
      top: pos.dy,
      child: GestureDetector(
        onPanUpdate: _isEditMode
            ? (details) {
                setState(() {
                  double newX =
                      (pos.dx + details.delta.dx).clamp(0.0, screenSize.width - 100);
                  double newY =
                      (pos.dy + details.delta.dy).clamp(0.0, screenSize.height - 100);
                  _positions[id] = Offset(newX, newY);
                });
              }
            : null,
        child: Container(
          decoration: _isEditMode
              ? BoxDecoration(
                  border: Border.all(color: Colors.orangeAccent, width: 2),
                  borderRadius: BorderRadius.circular(12),
                )
              : null,
          child: child,
        ),
      ),
    );
  }

  Widget _buildPaddle(String label, Color color, Function(bool) onPressed) {
    return GestureDetector(
      onTapDown: (_) => _isEditMode ? null : onPressed(true),
      onTapUp: (_) => _isEditMode ? null : onPressed(false),
      onTapCancel: () => _isEditMode ? null : onPressed(false),
      child: Container(
        width: 100,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color, width: 2),
        ),
        child: Center(
            child: Text(label,
                style: TextStyle(color: color, fontWeight: FontWeight.bold))),
      ),
    );
  }

  Widget _buildPedal(
      String label, double val, Color color, Function(bool) onPressed) {
    bool active = val > 0;
    return GestureDetector(
      onTapDown: (_) => _isEditMode ? null : onPressed(true),
      onTapUp: (_) => _isEditMode ? null : onPressed(false),
      onTapCancel: () => _isEditMode ? null : onPressed(false),
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: active ? color : Colors.grey[850],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
            child: Text(label,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold))),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 3. FULL XBOX CONTROLLER MODE (ENLARGED TOUCH CONTROLS)
// -----------------------------------------------------------------------------
class FullXboxControllerScreen extends StatefulWidget {
  final String ip;
  const FullXboxControllerScreen({super.key, required this.ip});

  @override
  State<FullXboxControllerScreen> createState() =>
      _FullXboxControllerScreenState();
}

class _FullXboxControllerScreenState extends State<FullXboxControllerScreen> {
  final UdpService _udpService = UdpService();
  Timer? _sendTimer;

  double _lsX = 0.0, _lsY = 0.0;
  double _rsX = 0.0, _rsY = 0.0;
  double _lt = 0.0, _rt = 0.0;

  final Map<String, bool> _buttons = {
    "btn_a": false,
    "btn_b": false,
    "btn_x": false,
    "btn_y": false,
    "btn_lb": false,
    "btn_rb": false,
    "dpad_up": false,
    "dpad_down": false,
    "dpad_left": false,
    "dpad_right": false,
    "btn_start": false,
    "btn_back": false,
  };

  @override
  void initState() {
    super.initState();
    _udpService.init();
    _sendTimer =
        Timer.periodic(const Duration(milliseconds: 16), (_) => _sendData());
  }

  void _sendData() {
    _udpService.sendPayload(widget.ip, {
      "mode": "xbox",
      "ls_x": _lsX,
      "ls_y": _lsY,
      "rs_x": _rsX,
      "rs_y": _rsY,
      "lt": _lt,
      "rt": _rt,
      ..._buttons,
    });
  }

  @override
  void dispose() {
    _sendTimer?.cancel();
    _udpService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: [
              // Top Bar: Triggers & System Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: [
                    _buildTrigger("LT", _lt > 0, (v) => setState(() => _lt = v)),
                    const SizedBox(width: 10),
                    _buildTopBumper("LB", "btn_lb", Colors.grey[800]!),
                  ]),
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Row(children: [
                    _buildTopBumper("RB", "btn_rb", Colors.grey[800]!),
                    const SizedBox(width: 10),
                    _buildTrigger("RT", _rt > 0, (v) => setState(() => _rt = v)),
                  ]),
                ],
              ),
              const SizedBox(height: 10),

              // Main Control Area: Joysticks, D-Pad, and ABXY
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Left Joystick
                    _buildJoystick(
                      xVal: _lsX,
                      yVal: _lsY,
                      onMoved: (x, y) => setState(() {
                        _lsX = x;
                        _lsY = y;
                      }),
                    ),
                    
                    // Enlarged D-Pad
                    _buildDPad(),
                    
                    // Enlarged ABXY Buttons
                    _buildABXY(),
                    
                    // Right Joystick
                    _buildJoystick(
                      xVal: _rsX,
                      yVal: _rsY,
                      onMoved: (x, y) => setState(() {
                        _rsX = x;
                        _rsY = y;
                      }),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Generic Button Builder with custom radius and font size
  Widget _buildButton(String label, String key, Color color,
      {double radius = 28, double fontSize = 18}) {
    bool pressed = _buttons[key] ?? false;
    return GestureDetector(
      onTapDown: (_) => setState(() => _buttons[key] = true),
      onTapUp: (_) => setState(() => _buttons[key] = false),
      onTapCancel: () => setState(() => _buttons[key] = false),
      child: CircleAvatar(
        radius: radius,
        backgroundColor: pressed ? color : Colors.grey[850],
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: fontSize,
          ),
        ),
      ),
    );
  }

  // Top Shoulder Bumpers (LB / RB)
  Widget _buildTopBumper(String label, String key, Color color) {
    bool pressed = _buttons[key] ?? false;
    return GestureDetector(
      onTapDown: (_) => setState(() => _buttons[key] = true),
      onTapUp: (_) => setState(() => _buttons[key] = false),
      onTapCancel: () => setState(() => _buttons[key] = false),
      child: Container(
        width: 70,
        height: 48,
        decoration: BoxDecoration(
          color: pressed ? Colors.white24 : color,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white38, width: 1.5),
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
      ),
    );
  }

  // Triggers (LT / RT)
  Widget _buildTrigger(
      String label, bool isActive, Function(double) onChanged) {
    return GestureDetector(
      onTapDown: (_) => onChanged(1.0),
      onTapUp: (_) => onChanged(0.0),
      onTapCancel: () => onChanged(0.0),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 50),
        width: 75,
        height: 48,
        decoration: BoxDecoration(
          color: isActive ? Colors.blueAccent : Colors.grey[900],
          border:
              Border.all(color: isActive ? Colors.white : Colors.white38, width: 2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.white70,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  // Joystick Widget
  Widget _buildJoystick({
    required double xVal,
    required double yVal,
    required Function(double, double) onMoved,
  }) {
    const double size = 130.0;
    const double radius = size / 2;

    return GestureDetector(
      onPanUpdate: (details) {
        double dx = details.localPosition.dx - radius;
        double dy = details.localPosition.dy - radius;

        double normX = (dx / radius).clamp(-1.0, 1.0);
        double normY = (-dy / radius).clamp(-1.0, 1.0);

        onMoved(normX, normY);
      },
      onPanEnd: (_) => onMoved(0.0, 0.0),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.grey[900],
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white38, width: 2),
        ),
        child: Stack(
          children: [
            Align(
              alignment: Alignment(xVal, -yVal),
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.grey[700],
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: const [
                    BoxShadow(color: Colors.black45, blurRadius: 6)
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // D-Pad Control Cluster
  Widget _buildDPad() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildButton("▲", "dpad_up", Colors.grey[700]!, radius: 24, fontSize: 16),
        const SizedBox(height: 4),
        Row(
          children: [
            _buildButton("◀", "dpad_left", Colors.grey[700]!, radius: 24, fontSize: 16),
            const SizedBox(width: 24),
            _buildButton("▶", "dpad_right", Colors.grey[700]!, radius: 24, fontSize: 16),
          ],
        ),
        const SizedBox(height: 4),
        _buildButton("▼", "dpad_down", Colors.grey[700]!, radius: 24, fontSize: 16),
      ],
    );
  }

  // ABXY Action Buttons Cluster
  Widget _buildABXY() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildButton("Y", "btn_y", Colors.amber[700]!, radius: 28, fontSize: 20),
        const SizedBox(height: 4),
        Row(
          children: [
            _buildButton("X", "btn_x", Colors.blueAccent, radius: 28, fontSize: 20),
            const SizedBox(width: 28),
            _buildButton("B", "btn_b", Colors.redAccent, radius: 28, fontSize: 20),
          ],
        ),
        const SizedBox(height: 4),
        _buildButton("A", "btn_a", Colors.green, radius: 28, fontSize: 20),
      ],
    );
  }
}