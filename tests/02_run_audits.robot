*** Settings ***
Documentation    Run Audits on Sulka
Library          SSHLibrary
Resource         ../resources/kas.resource
Resource         ../resources/ssh.resource
Suite Setup      Run Keywords
...    Add Common Build Configuration
...    AND    Add Common User Configuration
...    AND    Add Sulka Configuration    SULKA_EXTRA_COMPLIANCY="1"
...    AND    Reset Sulka Image    ${FULL_CONFIG}
...    AND    Build Sulka Image    ${FULL_CONFIG}
...    AND    Prepare QEMU For Audit
Suite Teardown    Reset Sulka Configuration

*** Test Cases ***
Run Lynis Scan
    [Documentation]    Run Lynis Scan On QEMU
    [Tags]             audit
    ${handle}=    Launch Image With QEMU    ${FULL_CONFIG}

    Open Default SSH Connection    timeout=60m

    ${output}=    Write Sudo SSH   sudo lynis audit system --no-colors    ${SULKA_SERVICEUSER_NEW_PASSWORD}

    Should Contain    ${output}    Suggestions (18):

    [Teardown]    Stop QEMU    ${handle}

Run OSCAP Scan
    [Documentation]    Run OSCAP Scan On QEMU
    [Tags]             audit
    ${handle}=    Launch Image With QEMU    ${FULL_CONFIG}

    Open Default SSH Connection    timeout=10m

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

    ${handle}=    Launch Image With QEMU    ${FULL_CONFIG}
    Change Expired Password Via SSH    ${SULKA_SERVICEUSER_USERNAME}    ${SULKA_SERVICEUSER_OLD_PASSWORD}    ${SULKA_SERVICEUSER_NEW_PASSWORD}

    Open Default SSH Connection    timeout=2m 30s

    Write Sudo SSH    sudo augenrules    ${SULKA_SERVICEUSER_NEW_PASSWORD}
    Write Sudo SSH    sudo auditctl -R /etc/audit/audit.rules    ${SULKA_SERVICEUSER_NEW_PASSWORD}

    [Teardown]    Stop QEMU    ${handle}
