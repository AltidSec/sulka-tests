TEMP_DIR = "workspace"
KAS_SULKA_BRANCH = "wrynose"
MACHINE = "qemux86-64"
# Extra arguments of runqemu, for example the image to boot
RUNQEMU_ARGS = ""
CORE_CONFIG = "kas-sulka.yml:extra_fragments/kas-layers-development.yml"
DEVEL_CONFIG = "kas-sulka.yml:extra_fragments/development.yml:extra_fragments/kas-layers-development.yml"
FULL_CONFIG = "kas-sulka.yml:extra_fragments/development.yml:extra_fragments/audit.yml:extra_fragments/kas-layers-development.yml"
