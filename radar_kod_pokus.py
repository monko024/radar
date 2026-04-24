import numpy as np
import pandas as pd
from acconeer.exptool import a111
import serial
import time
import subprocess
import os

def reset_com_port(port='COM3'):
    """Reset COM port by cycling it through disable/enable"""
    print(f"Attempting to reset {port}...")
    
    try:
        # Method 1: Use devcon if available (more reliable)
        devcon_paths = [
            r"C:\Program Files\Windows Kits\10\Tools\x64\devcon.exe",
            r"C:\Program Files (x86)\Windows Kits\10\Tools\x64\devcon.exe",
            r"C:\Program Files\Windows Kits\8.1\Tools\x64\devcon.exe"
        ]
        
        devcon_found = False
        for devcon_path in devcon_paths:
            if os.path.exists(devcon_path):
                print("Using devcon to reset port...")
                # Find all serial devices
                result = subprocess.run([devcon_path, 'find', 'USB*'], capture_output=True, text=True)
                result2 = subprocess.run([devcon_path, 'find', '*COM*'], capture_output=True, text=True)
                
                devices = result.stdout.split('\n') + result2.stdout.split('\n')
                for line in devices:
                    if port in line and line.strip():
                        hw_id = line.split(':')[0].strip()
                        print(f"Found device: {hw_id}")
                        # Disable and re-enable
                        subprocess.run([devcon_path, 'disable', hw_id], capture_output=True)
                        time.sleep(1)
                        subprocess.run([devcon_path, 'enable', hw_id], capture_output=True)
                        print(f"Reset {port} using devcon")
                        time.sleep(2)
                        devcon_found = True
                        break
                
                if devcon_found:
                    break
        
        if not devcon_found:
            # Method 2: Use pnputil (built-in Windows tool)
            print("Using pnputil to reset port...")
            subprocess.run(['pnputil.exe', '/enum-devices'], capture_output=True)
            time.sleep(1)
            
            # Try to restart the serial service
            try:
                subprocess.run(['net', 'stop', 'serial'], capture_output=True)
                time.sleep(1)
                subprocess.run(['net', 'start', 'serial'], capture_output=True)
                time.sleep(1)
            except:
                pass
                
            print(f"Reset attempt completed for {port}")
        
        return True
        
    except Exception as e:
        print(f"Port reset failed: {e}")
        return False

def check_com_port(port='COM3'):
    """Check if COM port is accessible before attempting connection"""
    try:
        test_serial = serial.Serial(port, timeout=1)
        test_serial.close()
        print(f"Port {port} is accessible")
        return True
    except Exception as e:
        print(f"Port {port} is not accessible: {e}")
        return False

def collect_radar_data(num_sweeps,range1,range2):
    num_sweeps = int(num_sweeps)

    # Check COM port accessibility first
    if not check_com_port('COM3'):
        print("Port not accessible, attempting reset...")
        if not reset_com_port('COM3'):
            print("ERROR: Cannot reset COM3. Check port availability and permissions.")
            return None
        
        # Check again after reset
        if not check_com_port('COM3'):
            print("ERROR: COM3 still not accessible after reset.")
            return None

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

