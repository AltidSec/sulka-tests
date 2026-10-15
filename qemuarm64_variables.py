import os as _os
import sys as _sys

_sys.path.insert(0, _os.path.dirname(_os.path.abspath(__file__)))
from global_variables import *  # noqa: E402,F401,F403

MACHINE = "qemuarm64"
# qemuarm64 boots with verified boot, which needs the FIT signing keys
VERIFIED_BOOT = "1"
# U-Boot loads the FIT image from the disk image. Give it to runqemu
# explicitly, as runqemu takes the image name from qemuboot.conf, which is
# not updated when only the disk image is rebuilt. The path is relative to
# the build directory.
RUNQEMU_ARGS = "tmp/deploy/images/qemuarm64/core-image-base-qemuarm64.rootfs.wic"
_MACHINE_FRAGMENT = ":extra_fragments/qemuarm64.yml"
CORE_CONFIG += _MACHINE_FRAGMENT
DEVEL_CONFIG += _MACHINE_FRAGMENT
FULL_CONFIG += _MACHINE_FRAGMENT
