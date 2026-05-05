import numpy as np
from acconeer.exptool import a111

_client    = None
_connected = False

def radar_init(range1, range2):
    global _client, _connected
    _client = a111.Client(serial_port='COM3', protocol=a111.Protocol.MODULE)
    try:
        _client.connect()
        _connected = True
        config = a111.EnvelopeServiceConfig()
        config.range_interval = [range1, range2]
        config.update_rate = 30
        _client.setup_session(config)
        _client.start_session()
    except Exception as e:
        _connected = False
        raise

def capture_sweeps(num_sweeps):
    """
    Returns a NumPy array directly. 
    MATLAB's double() function can convert this in one step.
    """
    global _client, _connected
    if not _connected:
        raise RuntimeError("Radar not connected")

    rows = []
    for _ in range(int(num_sweeps)):
        info, data = _client.get_next()
        if data is not None:
            rows.append(data)
    
    # Return as a float64 NumPy array
    return np.array(rows, dtype=np.float64)

def radar_cleanup():
    global _client, _connected
    if _client:
        _client.stop_session()
        _client.disconnect()
    _connected = False