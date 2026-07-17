import threading
import time
import queue

class SharedState:
    """Thread-safe state container for console to read."""
    def __init__(self):
        self.lock = threading.Lock()
        self.current_state = "IDLE"
        self.current_batch = None
        self.current_room = None
        self.uart_status = "UNKNOWN"
        self.mqtt_status = "UNKNOWN"
        
    def update(self, **kwargs):
        with self.lock:
            for k, v in kwargs.items():
                if hasattr(self, k):
                    setattr(self, k, v)
                    
    def get_snapshot(self):
        with self.lock:
            return {
                "state": self.current_state,
                "batch": self.current_batch,
                "room": self.current_room,
                "uart": self.uart_status,
                "mqtt": self.mqtt_status
            }

class ConsoleMonitor:
    """
    Runs in a separate thread to periodically print the system state
    without blocking the main thread or requiring manual inputs.
    """
    def __init__(self, shared_state: SharedState):
        self.shared_state = shared_state
        self.running = False
        self.thread = None

    def _run(self):
        while self.running:
            snapshot = self.shared_state.get_snapshot()
            
            # Print a neat dashboard
            print("\n" + "="*40)
            print("🚗 SMART MEDICAL TRANSPORT ROBOT")
            print("="*40)
            print(f"[*] State      : {snapshot['state']}")
            print(f"[*] Batch ID   : {snapshot['batch'] if snapshot['batch'] else 'None'}")
            print(f"[*] Room       : {snapshot['room'] if snapshot['room'] else 'None'}")
            print(f"[*] MQTT Status: {snapshot['mqtt']}")
            print(f"[*] UART Status: {snapshot['uart']}")
            print("="*40)
            
            time.sleep(2)  # Update every 2 seconds

    def start(self):
        self.running = True
        self.thread = threading.Thread(target=self._run, daemon=True)
        self.thread.start()

    def stop(self):
        self.running = False
        if self.thread:
            self.thread.join()
