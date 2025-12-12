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

## Writing New Test Suites

When writing new tests, note that `Add Common Build Configuration` should always be added to the `Suite Setup`, and `Reset Sulka Configuration` to the `Suite Teardown`.
