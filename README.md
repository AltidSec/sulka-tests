# Sulka tests

This repository contains the tests for Sulka, secure Yocto distribution. The tests are written for Robot framework.

To run the tests, do the following:
```
python3 -m venv venv
source venv/bin/activate
pip install -r ./requirements.txt
robot --argumentfile arguments.robot tests
```
