*** Settings ***
Documentation    Test Sulka build
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

*** Test Cases ***
Run Lynis Scan
    [Documentation]    Run Lynis Scan On QEMU
    [Tags]             audit
    ${handle}=    Launch Image With QEMU    kas-sulka.yml:extra_fragments/audit.yml:extra_fragments/development.yml
    Change Expired Password Via SSH

    Open Connection    127.0.0.1    port=2222
    Set Client Configuration    prompt=serviceuser@qemux86-64:~$
    Set Client Configuration    timeout=25m
    Login With Public Key    username=serviceuser    keyfile=./auth-keys/ssh_auth_ed25519_key

    Prepare QEMU For Audit

    ${output}=    Write Sudo SSH   sudo lynis audit system --no-colors    Sulka-5ecure-Distro

    Should Contain    ${output}    Suggestions (17):

    Stop QEMU    ${handle}

*** Keywords ***
Prepare QEMU For Audit
    [Documentation]    Prepare system for audit by enabling monitoring tools
    Write Sudo SSH    sudo mv /usr/lib/aide/aide.db.new.gz /usr/lib/aide/aide.db.gz    Sulka-5ecure-Distro
    Write Sudo SSH    sudo augenrules    Sulka-5ecure-Distro
    Write Sudo SSH    sudo auditctl -R /etc/audit/audit.rules    Sulka-5ecure-Distro
