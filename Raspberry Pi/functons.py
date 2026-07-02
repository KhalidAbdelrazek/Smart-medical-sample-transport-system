"""
Backward compatibility wrapper for misspelled functons.py.
Delegates all calls to the correctly spelled functions.py.
"""

import warnings

# Emit deprecation warning on import
warnings.warn(
    "The 'functons' module is deprecated due to misspelling. Please import from 'functions' instead.",
    category=DeprecationWarning,
    stacklevel=2
)

# Import everything from the new module to preserve compatibility
from functions import (
    get_timestamp,
    setup_gpio,
    read_sensors,
    filter_sensors,
    confirm_intersection,
    decide_movement,
    read_sensors_fast,
)