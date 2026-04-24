import numpy as np
import pandas as pd
import time
from acconeer.exptool import a111

# --- Module-level state (persistent across MATLAB calls) ---
_client = None
_connected = False


def radar_init(range1, range2):
    """
    Call once at startup. Connects to the sensor and starts a session.
    Leaves the session running so each capture cycle is fast.
    """
    global _client, _connected

    _client = a111.Client(serial_port='COM3', protocol=a111.Protocol.MODULE)

    print("Connecting to sensor...")
    for attempt in range(3):
        try:
            _client.connect()
            _connected = True
            print("Sensor connected successfully")
            break
        except Exception as e:
            print(f"Connection attempt {attempt+1} failed: {e}")
            if attempt < 2:
                print("Retrying in 2 seconds...")
                time.sleep(2)
            else:
                raise

    config = a111.EnvelopeServiceConfig()
    config.range_interval = [range1, range2]
    config.update_rate = 30

    print("Setting up session...")
    _client.setup_session(config)
    _client.start_session()
    print("Radar ready. Session is live.")


def capture_sweeps(num_sweeps):
    """
    Call once per scan cycle. Reads num_sweeps frames from the already-live
    session and saves radar_capture.csv / .xlsx. No connect/disconnect.
    """
    global _client

    if _client is None or not _connected:
        raise RuntimeError("Radar not initialised. Call radar_init() first.")

    num_sweeps = int(num_sweeps)
    matrix_list = []

    print(f"Starting capture of {num_sweeps} sweeps...")
    for i in range(num_sweeps):
        try:
            info, data = _client.get_next()
            if data is not None:
                matrix_list.append(data)
                if i % 5 == 0:
                    print(f"Captured sweep {i}...")
            else:
                print(f"Warning: Sweep {i} returned no data.")
        except Exception as e:
            print(f"Error at sweep {i}: {e}")
            break

    if len(matrix_list) == 0:
        print("FAILED: No data collected.")
        return None

    full_matrix = np.array(matrix_list)
    print(f"Capture complete. Matrix shape: {full_matrix.shape}")

    np.savetxt("radar_capture.csv", full_matrix, delimiter=",")
    pd.DataFrame(full_matrix).to_excel("radar_capture.xlsx", index=False)
    print("Files saved: radar_capture.csv and radar_capture.xlsx")

    return full_matrix


def radar_cleanup():
    """
    Call once at the end. Cleanly stops the session and disconnects.
    The 'invalid frame' warning during disconnect is expected — the sensor
    sends one trailing frame after stop_session(), which we drain and ignore.
    """
    global _client, _connected

    if _client is None:
        return

    print("Shutting down radar...")

    try:
        _client.stop_session()
    except Exception:
        pass

    # Drain trailing frames so disconnect() sees a clean protocol state
    for _ in range(10):
        try:
            _client.get_next()
        except Exception:
            break

    time.sleep(0.3)

    try:
        _client.disconnect()
    except Exception:
        # Silently force-close — the trailing frame warning is expected here
        try:
            _client._client.close()
        except Exception:
            pass

    _client = None
    _connected = False
    print("Radar disconnected.")