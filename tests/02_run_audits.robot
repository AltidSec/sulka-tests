*** Settings ***
Documentation    Run Audits on Sulka
Library          SSHLibrary
Resource         ../resources/kas.resource
Resource         ../resources/ssh.resource
Resource         ../resources/versions.resource
Suite Setup      Run Keywords
...    Add Common Build Configuration
...    AND    Add Common User Configuration
...    AND    Add Sulka Configuration    SULKA_EXTRA_COMPLIANCY = "1"
...    AND    Add Sulka Configuration    SULKA_ENABLE_READ_ONLY_ROOTFS = "0"
...    AND    Add Sulka Configuration    IMAGE_FSTYPES:append = " ext4"
...    AND    Add Sulka Configuration    QB_DEFAULT_FSTYPE = "ext4"
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

    ${global_config}=    Get Variable Value    ${GLOBAL_BUILD_CONFIG}    ${EMPTY}
    IF    'INIT_MANAGER="sysvinit"' in $global_config
        ${expected_suggestions}=    Get Expected Value    lynis_suggestions_sysvinit
        ${expected_warnings}=    Get Expected Value    lynis_warnings_sysvinit
    ELSE
        ${expected_suggestions}=    Get Expected Value    lynis_suggestions_default
        ${expected_warnings}=    Get Expected Value    lynis_warnings_default
    END
    Should Contain    ${output}    ${expected_suggestions}
    Should Contain    ${output}    ${expected_warnings}

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

    ${expected}=    Get Expected Value    oscap_fail_count
    Should Contain X Times    ${output}    fail    ${expected}

    [Teardown]    Stop QEMU    ${handle}

*** Keywords ***
Prepare QEMU For Audit
    [Documentation]    Prepare system for audit by enabling monitoring tools

    ${handle}=    Launch Image With QEMU    ${FULL_CONFIG}
    Change Expired Password Via SSH    ${SULKA_SERVICEUSER_USERNAME}    ${SULKA_SERVICEUSER_OLD_PASSWORD}    ${SULKA_SERVICEUSER_NEW_PASSWORD}

    Open Default SSH Connection    timeout=2m 30s

    # Not sure why, but it seems like at least one sudo command needs to be executed
    # after the password change to make the password stick. Possibly a timing issue,
    # so run sync to ensure that the changes get written.
    Write Sudo SSH     sudo sync      ${SULKA_SERVICEUSER_NEW_PASSWORD}

    [Teardown]    Stop QEMU    ${handle}
