import numpy as np
import time
import os
from acconeer.exptool import a111

_client = None
_connected = False

def radar_init(range1, range2):
    global _client, _connected
    
    # --- NEW: Clear existing CSV file at startup ---
    if os.path.exists("radar_capture.csv"):
        try:
            os.remove("radar_capture.csv")
            print("Existing radar_capture.csv cleared.")
        except Exception as e:
            print(f"Note: Could not delete old CSV: {e}")

    print(f"Attempting to connect to Acconeer on COM3...")
    _client = a111.Client(serial_port='COM3', protocol=a111.Protocol.MODULE)
    
    try:
        _client.connect()
        _connected = True
        
        config = a111.EnvelopeServiceConfig()
        config.range_interval = [range1, range2]
        config.update_rate = 30
        
        _client.setup_session(config)
        _client.start_session()
        print("Radar ready.")
    except Exception as e:
        _connected = False
        print(f"Init failed: {e}")
        _client = None 
        raise

def capture_sweeps(num_sweeps, timeout_sec=10.0):
    global _client
    if _client is None or not _connected:
        raise RuntimeError("Radar not initialised.")

    # --- STEP 3 IMPLEMENTATION: Clear stale buffer ---
    # Discard any frames that accumulated while the motor was moving
    for _ in range(5): 
        try:
            _client.get_next()
        except:
            break

    matrix_list = []
    deadline = time.time() + timeout_sec

    for i in range(int(num_sweeps)):
        if time.time() > deadline:
            raise RuntimeError("Capture timed out.")

        info, data = _client.get_next()
        if data is not None:
            matrix_list.append(data)

    if not matrix_list:
        raise RuntimeError("No data collected.")

    full_matrix = np.array(matrix_list)
    
    # --- STEP 2 IMPLEMENTATION: Remove Excel saving ---
    # Only save CSV for MATLAB to keep the loop fast
    np.savetxt("radar_capture.csv", full_matrix, delimiter=",")
    return full_matrix

def radar_cleanup():
    global _client, _connected
    if _client:
        try:
            _client.stop_session()
            _client.disconnect()
        except:
            pass
    _client = None
    _connected = False