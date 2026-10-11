import socket
import json
import vgamepad as vg

# 1. Initialize Two Virtual Controllers
try:
    pad1 = vg.VX360Gamepad()
    pad2 = vg.VX360Gamepad()
    print("[SUCCESS] Controllers 1 and 2 active on XInput.")
except Exception as e:
    print(f"[ERROR] Could not initialize ViGEmBus driver: {e}")
    exit(1)

UDP_IP = "0.0.0.0"
UDP_PORT = 5005

sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
sock.bind((UDP_IP, UDP_PORT))

print(f"[KONTROL SERVER] Listening for inputs on Port {UDP_PORT}...")

BUTTON_MAP = {
    "btn_a": vg.XUSB_BUTTON.XUSB_GAMEPAD_A,
    "btn_b": vg.XUSB_BUTTON.XUSB_GAMEPAD_B,
    "btn_x": vg.XUSB_BUTTON.XUSB_GAMEPAD_X,
    "btn_y": vg.XUSB_BUTTON.XUSB_GAMEPAD_Y,
    "btn_lb": vg.XUSB_BUTTON.XUSB_GAMEPAD_LEFT_SHOULDER,
    "btn_rb": vg.XUSB_BUTTON.XUSB_GAMEPAD_RIGHT_SHOULDER,
    "dpad_up": vg.XUSB_BUTTON.XUSB_GAMEPAD_DPAD_UP,
    "dpad_down": vg.XUSB_BUTTON.XUSB_GAMEPAD_DPAD_DOWN,
    "dpad_left": vg.XUSB_BUTTON.XUSB_GAMEPAD_DPAD_LEFT,
    "dpad_right": vg.XUSB_BUTTON.XUSB_GAMEPAD_DPAD_RIGHT,
    "btn_start": vg.XUSB_BUTTON.XUSB_GAMEPAD_START,
    "btn_back": vg.XUSB_BUTTON.XUSB_GAMEPAD_BACK,
}

# Dynamic player tracking by IP address
player_map = {}

def process_controller(gamepad, payload):
    # Joysticks
    ls_x = payload.get("ls_x", 0.0)
    ls_y = payload.get("ls_y", 0.0)
    rs_x = payload.get("rs_x", 0.0)
    rs_y = payload.get("rs_y", 0.0)
    
    gamepad.left_joystick_float(x_value_float=ls_x, y_value_float=ls_y)
    gamepad.right_joystick_float(x_value_float=rs_x, y_value_float=rs_y)

    # Triggers
    lt = int(payload.get("lt", 0.0) * 255)
    rt = int(payload.get("rt", 0.0) * 255)
    
    gamepad.left_trigger(value=lt)
    gamepad.right_trigger(value=rt)

    # Buttons
    for key, button_flag in BUTTON_MAP.items():
        if payload.get(key, False):
            gamepad.press_button(button=button_flag)
        else:
            gamepad.release_button(button=button_flag)

    gamepad.update()

while True:
    try:
        data, addr = sock.recvfrom(1024)
        client_ip = addr[0]

        # Assign incoming IP to Player 1 or Player 2
        if client_ip not in player_map:
            if len(player_map) == 0:
                player_map[client_ip] = pad1
                print(f"[PLAYER 1 ASSIGNED] IP: {client_ip}")
            elif len(player_map) == 1:
                player_map[client_ip] = pad2
                print(f"[PLAYER 2 ASSIGNED] IP: {client_ip}")
            else:
                # Ignore inputs if 2 players are already connected
                continue

        payload = json.loads(data.decode('utf-8'))
        assigned_pad = player_map[client_ip]
        process_controller(assigned_pad, payload)

    except Exception:
        pass