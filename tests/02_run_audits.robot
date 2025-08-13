*** Settings ***
Documentation    Run Audits on Sulka
Library          SSHLibrary
Resource         ../resources/kas.resource
Resource         ../resources/ssh.resource
Suite Setup      Run Keywords
...    Add Sulka Configuration    SULKA_INSTALL_SSH_KEYS="1"
...    AND    Add Sulka Configuration    SULKA_SERVICEUSER_PASSWORD="\\\$y\\\$jCT\\\$seWjSFPPf4lsQL74hWMWG1\\\$eGCxO7c/4jDlHQnYtGRd8yDLyDNqIDt8A5Tv43elk0."
...    AND    Add Sulka Configuration    SULKA_SSH_KEYS_DIR="${CURDIR}/../auth-keys/"
...    AND    Add Sulka Configuration    SULKA_EXTRA_COMPLIANCY="1"
...    AND    Enable Sudo
...    AND    Build Sulka Image    kas-sulka.yml:extra_fragments/audit.yml:extra_fragments/development.yml
Suite Teardown    Reset Sulka Configuration

*** Variables ***
${SULKA_SERVICEUSER_USERNAME}        serviceuser
${SULKA_SERVICEUSER_OLD_PASSWORD}    test
${SULKA_SERVICEUSER_NEW_PASSWORD}    Sulka-5ecure-Distro

*** Test Cases ***
Run Lynis Scan
    [Documentation]    Run Lynis Scan On QEMU
    [Tags]             audit
    ${handle}=    Launch Image With QEMU    kas-sulka.yml:extra_fragments/audit.yml:extra_fragments/development.yml
    Change Expired Password Via SSH    ${SULKA_SERVICEUSER_USERNAME}    ${SULKA_SERVICEUSER_OLD_PASSWORD}    ${SULKA_SERVICEUSER_NEW_PASSWORD}

    Open Connection    127.0.0.1    port=2222
    Set Client Configuration    prompt=${SULKA_SERVICEUSER_USERNAME}@qemux86-64:~$
    Set Client Configuration    timeout=25m
    Login With Public Key    username=${SULKA_SERVICEUSER_USERNAME}    keyfile=./auth-keys/ssh_auth_ed25519_key

    Prepare QEMU For Audit

    ${output}=    Write Sudo SSH   sudo lynis audit system --no-colors    ${SULKA_SERVICEUSER_NEW_PASSWORD}

    Should Contain    ${output}    Suggestions (17):

    Stop QEMU    ${handle}

*** Keywords ***
Prepare QEMU For Audit
    [Documentation]    Prepare system for audit by enabling monitoring tools
    Write Sudo SSH    sudo mv /usr/lib/aide/aide.db.new.gz /usr/lib/aide/aide.db.gz    ${SULKA_SERVICEUSER_NEW_PASSWORD}
    Write Sudo SSH    sudo augenrules    ${SULKA_SERVICEUSER_NEW_PASSWORD}
    Write Sudo SSH    sudo auditctl -R /etc/audit/audit.rules    ${SULKA_SERVICEUSER_NEW_PASSWORD}
