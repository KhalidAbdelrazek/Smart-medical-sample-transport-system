import threading
import time


class SharedState:
    """Thread-safe state container read by ConsoleMonitor and written by main."""

    def __init__(self):
        self._lock         = threading.Lock()
        self.current_state = "IDLE"
        self.current_batch = None
        self.current_room  = None
        self.uart_status   = "UNKNOWN"
        self.mqtt_status   = "UNKNOWN"

    def update(self, **kwargs):
        with self._lock:
            for key, val in kwargs.items():
                # Map convenience kwarg names → attribute names
                attr = "current_state" if key == "state" else key
                if hasattr(self, attr):
                    setattr(self, attr, val)

    def get_snapshot(self) -> dict:
        with self._lock:
            return {
                "state": self.current_state,
                "batch": self.current_batch,
                "room":  self.current_room,
                "uart":  self.uart_status,
                "mqtt":  self.mqtt_status,
            }


class ConsoleMonitor:
    """Prints a live dashboard every 2 seconds on a daemon thread."""

    def __init__(self, shared_state: SharedState):
        self.shared_state = shared_state
        self.running      = False
        self.thread       = None

    def _run(self):
        while self.running:
            s = self.shared_state.get_snapshot()
            print("\n" + "=" * 44)
            print("  🚗  SMART MEDICAL TRANSPORT ROBOT")
            print("=" * 44)
            print(f"  State   : {s['state']}")
            print(f"  Batch   : {s['batch'] or '—'}")
            print(f"  Room    : {s['room']  or '—'}")
            print(f"  MQTT    : {s['mqtt']}")
            print(f"  UART    : {s['uart']}")
            print("=" * 44)
            time.sleep(2)

    def start(self):
        self.running = True
        self.thread  = threading.Thread(target=self._run, daemon=True)
        self.thread.start()

    def stop(self):
        self.running = False
        if self.thread:
            self.thread.join(timeout=3)