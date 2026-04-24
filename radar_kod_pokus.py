import numpy as np
import pandas as pd
from acconeer.exptool import a111
import time

def collect_radar_data(num_sweeps,range1,range2):
    num_sweeps = int(num_sweeps)

    # Ensure COM port is correct. If you moved the USB, it might be COM4, COM5, etc.
    client = a111.Client(serial_port='COM3', protocol=a111.Protocol.MODULE)
    connected = False
    
    try:
        print("Connecting to sensor...")
        # Retry connection with delays
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
        config.range_interval = [range1, range2] #set measured distance
        config.update_rate = 30  # Added: explicitly set a rate (Hz)
        
        print("Setting up session...")
        client.setup_session(config)
        client.start_session()

        matrix_list = []
        print(f"Starting capture of {num_sweeps} sweeps...")
        
        for i in range(num_sweeps):
            try:
                # Add a timeout check
                info, data = client.get_next()
                if data is not None:
                    matrix_list.append(data)
                    if i % 5 == 0: # Print every 5th sweep to show progress
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

        # Exporting
        np.savetxt("radar_capture.csv", full_matrix, delimiter=",")
        # Optimization: pandas can be slow for large radar files, 
        # but for small captures it is fine.
        df = pd.DataFrame(full_matrix)
        df.to_excel("radar_capture.xlsx", index=False)
        
        print("Success! Files saved: radar_capture.csv and radar_capture.xlsx")
        return full_matrix

    except Exception as e:
        print(f"Critical Error: {e}")
        return None

    finally:
        print("Disconnecting sensor...")
        if connected:
            import time
            time.sleep(0.5)  # Brief pause before disconnect
            try:
                client.disconnect()
            except Exception as e:
                print(f"Warning: Error during disconnect: {e}")
                # Force close if needed
                try:
                    client._client.close()
                except:
                    pass

