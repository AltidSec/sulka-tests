*** Settings ***
Documentation    Run Audits on Sulka
Library          SSHLibrary
Resource         ../resources/kas.resource
Resource         ../resources/ssh.resource
Suite Setup      Run Keywords
...    Add Sulka Configuration    SULKA_INSTALL_SSH_KEYS="1"
...    AND    Add Sulka Configuration    DL_DIR="${CURDIR}/../${TEMP_DIR}/downloads"
...    AND    Add Sulka Configuration    SSTATE_DIR="${CURDIR}/../${TEMP_DIR}/sstate-cache"
...    AND    Add Sulka Configuration    SULKA_SERVICEUSER_PASSWORD="\\\$y\\\$jCT\\\$seWjSFPPf4lsQL74hWMWG1\\\$eGCxO7c/4jDlHQnYtGRd8yDLyDNqIDt8A5Tv43elk0."
...    AND    Add Sulka Configuration    SULKA_SSH_KEYS_DIR="${CURDIR}/../auth-keys/"
...    AND    Add Sulka Configuration    SULKA_EXTRA_COMPLIANCY="1"
...    AND    Enable Sudo
...    AND    Reset Sulka Image    kas-sulka.yml:extra_fragments/audit.yml:extra_fragments/development.yml
...    AND    Build Sulka Image    kas-sulka.yml:extra_fragments/audit.yml:extra_fragments/development.yml
...    AND    Prepare QEMU For Audit
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

    Open Connection    127.0.0.1    port=2222
    Set Client Configuration    prompt=${SULKA_SERVICEUSER_USERNAME}@qemux86-64:~$
    Set Client Configuration    timeout=25m
    Login With Public Key    username=${SULKA_SERVICEUSER_USERNAME}    keyfile=./auth-keys/ssh_auth_ed25519_key

    ${output}=    Write Sudo SSH   sudo lynis audit system --no-colors    ${SULKA_SERVICEUSER_NEW_PASSWORD}

    Should Contain    ${output}    Suggestions (16):

    [Teardown]    Stop QEMU    ${handle}

Run OSCAP Scan
    [Documentation]    Run OSCAP Scan On QEMU
    [Tags]             audit
    ${handle}=    Launch Image With QEMU    kas-sulka.yml:extra_fragments/audit.yml:extra_fragments/development.yml

    Open Connection    127.0.0.1    port=2222
    Set Client Configuration    prompt=${SULKA_SERVICEUSER_USERNAME}@qemux86-64:~$
    Set Client Configuration    timeout=10m
    Login With Public Key    username=${SULKA_SERVICEUSER_USERNAME}    keyfile=./auth-keys/ssh_auth_ed25519_key

    Write Sudo SSH    sudo sh -c 'echo "ID=nodistro" > /etc/os-release'    ${SULKA_SERVICEUSER_NEW_PASSWORD}
    Write Sudo SSH    sudo sh -c 'echo "NAME=\"OpenEmbedded\"" >> /etc/os-release'    ${SULKA_SERVICEUSER_NEW_PASSWORD}
    Write Sudo SSH    sudo sh -c 'echo "VERSION=\"nodistro.0\"" >> /etc/os-release'    ${SULKA_SERVICEUSER_NEW_PASSWORD}
    Write Sudo SSH    sudo sh -c 'echo "VERSION_ID=nodistro.0" >> /etc/os-release'    ${SULKA_SERVICEUSER_NEW_PASSWORD}
    Write Sudo SSH    sudo sh -c 'echo "PRETTY_NAME=\"OpenEmbedded nodistro.0\"" >> /etc/os-release'    ${SULKA_SERVICEUSER_NEW_PASSWORD}

    ${output}=    Write Sudo SSH   sudo oscap xccdf eval --profile xccdf_org.ssgproject.content_profile_expanded /usr/share/xml/scap/ssg/content/ssg-openembedded-ds.xml    ${SULKA_SERVICEUSER_NEW_PASSWORD}

    Should Contain X Times    ${output}    fail    2

    [Teardown]    Stop QEMU    ${handle}

*** Keywords ***
Prepare QEMU For Audit
    [Documentation]    Prepare system for audit by enabling monitoring tools

    ${handle}=    Launch Image With QEMU    kas-sulka.yml:extra_fragments/audit.yml:extra_fragments/development.yml
    Change Expired Password Via SSH    ${SULKA_SERVICEUSER_USERNAME}    ${SULKA_SERVICEUSER_OLD_PASSWORD}    ${SULKA_SERVICEUSER_NEW_PASSWORD}

    Open Connection    127.0.0.1    port=2222
    Set Client Configuration    prompt=${SULKA_SERVICEUSER_USERNAME}@qemux86-64:~$
    Set Client Configuration    timeout=25s
    Login With Public Key    username=${SULKA_SERVICEUSER_USERNAME}    keyfile=./auth-keys/ssh_auth_ed25519_key

    Write Sudo SSH    sudo mv /usr/lib/aide/aide.db.new.gz /usr/lib/aide/aide.db.gz    ${SULKA_SERVICEUSER_NEW_PASSWORD}
    Write Sudo SSH    sudo augenrules    ${SULKA_SERVICEUSER_NEW_PASSWORD}
    Write Sudo SSH    sudo auditctl -R /etc/audit/audit.rules    ${SULKA_SERVICEUSER_NEW_PASSWORD}

    [Teardown]    Stop QEMU    ${handle}
