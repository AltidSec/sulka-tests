*** Settings ***
Documentation    SSH helper resources
Library          SSHLibrary

*** Keywords ***
Open Default SSH Connection
    [Arguments]    ${timeout}=1m
    Open Connection    127.0.0.1    port=2222
    Set Client Configuration    prompt=${SULKA_SERVICEUSER_USERNAME}@qemux86-64:~$
    Set Client Configuration    timeout=${timeout}
    Login With Public Key    username=${SULKA_SERVICEUSER_USERNAME}    keyfile=./auth-keys/ssh_auth_ed25519_key

Change Expired Password Via SSH
    [Documentation]    Change SSH password if it is expired
    [Arguments]    ${username}    ${old_password}    ${new_password}
    Open Connection    127.0.0.1    port=2222
    Set Client Configuration    prompt=Current password:
    Set Client Configuration    timeout=2m 30s
    Login With Public Key    username=${username}    keyfile=./auth-keys/ssh_auth_ed25519_key

    Write    ${old_password}
    Read Until    Enter new password:
    Write    ${new_password}
    Read Until    Re-type new password:
    Write    ${new_password}
    Read Until    passwd: password updated successfully

Write SSH
    [Documentation]    Write command over SSH
    [Arguments]    ${command}
    Write    ${command}
    ${output}=    Read Until Prompt    strip_prompt=True
    RETURN    ${output}

Write Sudo SSH
    [Documentation]    Write Sudo command over SSH
    [Arguments]    ${command}    ${password}
    Write    ${command}
    Read Until    Password:
    Write    ${password}
    ${output}=    Read Until Prompt    strip_prompt=True
    ${output}=  Fetch From Left    ${output}    \x1b]
    RETURN    ${output}
