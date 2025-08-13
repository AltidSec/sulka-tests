*** Settings ***
Documentation    Test Sulka build
Library          SSHLibrary

*** Keywords ***
Change Expired Password Via SSH
    [Documentation]    Change SSH password if it is expired
    Open Connection    127.0.0.1    port=2222
    Set Client Configuration    prompt=Current password:
    Set Client Configuration    timeout=15s
    Login With Public Key    username=serviceuser    keyfile=./auth-keys/ssh_auth_ed25519_key

    Write    test
    Read Until    Enter new password:
    Write    Sulka-5ecure-Distro
    Read Until    Re-type new password:
    Write    Sulka-5ecure-Distro
    Read Until    passwd: password updated successfully

Write Sudo SSH
    [Documentation]    Write Sudo command over SSH
    [Arguments]    ${command}    ${password}
    Write    ${command}
    Read Until    Password:
    Write    ${password}
    ${output}=    Read Until Prompt
    RETURN    ${output}
