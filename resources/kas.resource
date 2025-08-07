*** Settings ***
Documentation    Keywords for building with kas
Library          Process

*** Keywords ***
Build Sulka Image
    [Arguments]    ${configuration}
    Log    Starting build...
    ${result}=    Run Process    kas    build    ${configuration}    cwd=${TEMP_DIR}    timeout=3h 30m    stdout=kas_stdout.log    stderr=kas_stderr.log
    Log    Return code: ${result.rc}
    Should Be Equal As Integers    ${result.rc}    0    Build failed
    RETURN    ${result}

Launch Image With QEMU
    [Arguments]    ${configuration}
    ${result}=    Run Process    kas    shell    ${configuration}    -c    "runqemu nographic"    cwd=${TEMP_DIR}
    Sleep    60s
