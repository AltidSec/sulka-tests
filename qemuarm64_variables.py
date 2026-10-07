import os as _os
import sys as _sys

_sys.path.insert(0, _os.path.dirname(_os.path.abspath(__file__)))
from global_variables import *  # noqa: E402,F401,F403

MACHINE = "qemuarm64"
_MACHINE_FRAGMENT = ":extra_fragments/qemuarm64.yml"
CORE_CONFIG += _MACHINE_FRAGMENT
DEVEL_CONFIG += _MACHINE_FRAGMENT
FULL_CONFIG += _MACHINE_FRAGMENT
