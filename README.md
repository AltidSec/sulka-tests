# Sulka tests

This repository contains the tests for Sulka, secure Yocto distribution. The tests are written for Robot framework.

To run the tests, do the following:
```
python3 -m venv venv
source venv/bin/activate
pip install -r ./requirements.txt
./prepare_tests.sh
robot --variablefile global_variables.py tests
```

Note that the tests run against the development meta-layers by default. This is achieved by appending `:extra_fragments/kas-layers-development.yml` to the build configurations in `global_variables.py`. To run the tests against a released version (or some other version), remove this either manually or with `sed`:

```
sed -i 's#:extra_fragments/kas-layers-development.yml##g' global_variables.py
```

## Running Individual Tests And Suites

Always point Robot at the `tests` directory and select what to run with `--suite`, `--test`, or `--include`. The `tests/__init__.robot` Suite Setup clones the shared `kas-sulka` workspace, and that init only runs when the directory is the target — passing a file path directly skips the clone.

Run a single suite:
```
robot --variablefile global_variables.py --suite 02_run_audits tests
```

Run a single test:
```
robot --variablefile global_variables.py --test "Run Lynis Scan" tests
```

## Global Build Options

If you want to add global options to the Yocto builds, you can use the `GLOBAL_BUILD_CONFIG` variable and add it to the `global_variables.py`. The values in the variable will be added to `local.conf`.

For example, to use sysvinit as the init manager, add the following:

```
GLOBAL_BUILD_CONFIG = 'INIT_MANAGER = "sysvinit"'
```

Multiple options are separated with `;;.

```
GLOBAL_BUILD_CONFIG = 'INIT_MANAGER = "systemd";;TEST_VARIABLE = "testvalue"'
GLOBAL_BUILD_CONFIG = 'INIT_MANAGER = "systemd" ;; EXTRA_IMAGE_FEATURES = "debug-tweaks tools-debug"'
```

## Writing New Test Suites

When writing new tests, note that `Add Common Build Configuration` should always be added to the `Suite Setup`, and `Reset Sulka Configuration` to the `Suite Teardown`.
