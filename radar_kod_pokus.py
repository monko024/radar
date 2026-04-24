import numpy as np
import pandas as pd
import time
from acconeer.exptool import a111


def _safe_disconnect(client):
    """Stop session and drain any in-flight frames before disconnecting."""
    try:
        client.stop_session()
    except Exception:
        pass

    # Drain any frames the sensor pushed after stop_session()
    # so disconnect() doesn't see a corrupt/unexpected frame
    for _ in range(5):
        try:
            client.get_next()
        except Exception:
            break  # No more frames — safe to disconnect now

    time.sleep(0.3)

    try:
        client.disconnect()
    except Exception as e:
        # Last-resort: force-close the underlying socket/serial
        print(f"Warning: clean disconnect failed ({e}), forcing close.")
        try:
            client._client.close()
        except Exception:
            pass


def collect_radar_data(num_sweeps, range1, range2):
    num_sweeps = int(num_sweeps)

    client = a111.Client(serial_port='COM3', protocol=a111.Protocol.MODULE)
    connected = False

    try:
        print("Connecting to sensor...")
        for attempt in range(3):
            try:
                client.connect()
                connected = True
                print("Sensor connected successfully")
                break
            except Exception as conn_e:
                print(f"Connection attempt {attempt+1} failed: {conn_e}")
                if attempt < 2:
                    print("Retrying in 2 seconds...")
                    time.sleep(2)
                else:
                    raise conn_e

        config = a111.EnvelopeServiceConfig()
        config.range_interval = [range1, range2]
        config.update_rate = 30

        print("Setting up session...")
        client.setup_session(config)
        client.start_session()

        matrix_list = []
        print(f"Starting capture of {num_sweeps} sweeps...")

        for i in range(num_sweeps):
            try:
                info, data = client.get_next()
                if data is not None:
                    matrix_list.append(data)
                    if i % 5 == 0:
                        print(f"Captured sweep {i}...")
                else:
                    print(f"Warning: Sweep {i} returned no data.")
            except Exception as e:
                print(f"Error during capture at sweep {i}: {e}")
                break

        if len(matrix_list) == 0:
            print("FAILED: No data was collected. Check sensor connection.")
            return None

        full_matrix = np.array(matrix_list)
        print(f"Capture complete. Matrix shape: {full_matrix.shape}")

        np.savetxt("radar_capture.csv", full_matrix, delimiter=",")
        df = pd.DataFrame(full_matrix)
        df.to_excel("radar_capture.xlsx", index=False)

        print("Success! Files saved: radar_capture.csv and radar_capture.xlsx")
        return full_matrix

    except Exception as e:
        print(f"Critical Error: {e}")
        return None

    finally:
        if connected:
            print("Disconnecting sensor...")
            _safe_disconnect(client)