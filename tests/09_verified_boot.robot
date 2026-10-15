*** Settings ***
Documentation    Test verified boot. U-Boot must boot the signed FIT image and refuse FIT images
...              that are modified, signed with another key or not signed. qemuarm64 is the
...              reference machine for verified boot, so the suite runs only with
...              qemuarm64_variables.py.
Library          OperatingSystem
Library          Process
Resource         ../resources/kas.resource
Resource         ../resources/ssh.resource
Suite Setup      Run Keywords
...    Skip If    '${MACHINE}' != 'qemuarm64'    Verified boot is tested only on qemuarm64
...    AND    Add Common Build Configuration
...    AND    Add Common User Configuration
...    AND    Build Sulka Image    ${FULL_CONFIG}
...    AND    Prepare Verified Boot Tests
Suite Teardown    Reset Sulka Configuration

*** Variables ***
${REJECT_TIMEOUT}          3min
# The modified images the tests create into ${MODIFIED_IMAGE_DIR}
@{MODIFIED_IMAGES}         modified    other-key    unsigned

*** Test Cases ***
Test Signed FIT Image Boots
    [Documentation]    U-Boot verifies the signature of the FIT configuration and boots the kernel,
    ...                which mounts the root file system given in the U-Boot boot arguments.
    [Tags]             configuration
    ${handle}=    Launch Image With QEMU    ${FULL_CONFIG}
    ...    runqemu_args=snapshot ${DISK_IMAGE}    console_log=verified_boot_signed.log
    ${console}=    OperatingSystem.Get File    ${TEMP_DIR}/verified_boot_signed.log
    Should Contain    ${console}    sha256,rsa4096:sulka-fit+ OK
    Open Default SSH Connection
    ${cmdline}=    Execute Command    cat /proc/cmdline
    Should Contain    ${cmdline}    root=/dev/vda2
    [Teardown]    Stop QEMU    ${handle}

Test Modified FIT Image Is Rejected
    [Documentation]    A byte changed in the kernel no longer matches the hash in the signed
    ...                configuration.
    [Tags]             configuration
    ${disk}=    Create Disk Image With Modified FIT    modified
    ...    printf '\\377' | dd of="$FIT" bs=1 seek=1048576 conv=notrunc status=none
    ${handle}=    Launch Image With QEMU    ${FULL_CONFIG}    runqemu_args=${MACHINE} snapshot ${disk}
    ...    console_log=verified_boot_modified.log    wait_for_ssh=${False}
    Boot Should Be Rejected    verified_boot_modified.log    Bad hash value for 'hash-1' hash node in 'kernel-1' image node
    [Teardown]    Stop QEMU    ${handle}

Test FIT Image Signed With Another Key Is Rejected
    [Documentation]    The configuration is signed again with another key of the same name, which
    ...                does not match the public key in U-Boot.
    [Tags]             configuration
    ${disk}=    Create Disk Image With Modified FIT    other-key
    ...    mkdir -p "$MODIFIED_IMAGE_DIR/other-key" && openssl genrsa -F4 -out "$MODIFIED_IMAGE_DIR/other-key/sulka-fit.key" 4096 && mkimage -F -k "$MODIFIED_IMAGE_DIR/other-key" "$FIT"
    ${handle}=    Launch Image With QEMU    ${FULL_CONFIG}    runqemu_args=${MACHINE} snapshot ${disk}
    ...    console_log=verified_boot_other_key.log    wait_for_ssh=${False}
    Boot Should Be Rejected    verified_boot_other_key.log    Failed to verify required signature 'key-sulka-fit'
    [Teardown]    Stop QEMU    ${handle}

Test Unsigned FIT Image Is Rejected
    [Documentation]    The signature is removed from the configuration.
    [Tags]             configuration
    ${disk}=    Create Disk Image With Modified FIT    unsigned
    ...    fdtput -r "$FIT" "/configurations/$(fdtget "$FIT" /configurations default)/signature-1"
    ${handle}=    Launch Image With QEMU    ${FULL_CONFIG}    runqemu_args=${MACHINE} snapshot ${disk}
    ...    console_log=verified_boot_unsigned.log    wait_for_ssh=${False}
    Boot Should Be Rejected    verified_boot_unsigned.log    Failed to verify required signature 'key-sulka-fit'
    [Teardown]    Stop QEMU    ${handle}

Test Missing FIT Signing Key Fails The Build
    [Documentation]    The build must fail at configuration parse time when the FIT signing key
    ...                does not exist. Run last, as the teardown resets the configuration.
    [Tags]             configuration
    Add Sulka Configuration    UBOOT_SIGN_KEYNAME:forcevariable = "missing-key"
    ${result}=    Build Sulka Image    ${FULL_CONFIG}    expect_success=False
    Should Contain    ${result.stdout}${result.stderr}    requires a FIT signing key
    [Teardown]    Reset Sulka Configuration

*** Keywords ***
Prepare Verified Boot Tests
    [Documentation]    Set ${DISK_IMAGE} to the disk image the build deployed, ${FIT_IMAGE} to the
    ...                FIT image in it, ${NATIVE_TOOLS} to the PATH of the native tools that modify
    ...                them, and ${MODIFIED_IMAGE_DIR} to the directory of the modified images,
    ...                without the images of earlier runs.
    ${deploy_dir}=    Get Bitbake Variable    DEPLOY_DIR_IMAGE    ${FULL_CONFIG}    recipe=core-image-base
    ${link_name}=    Get Bitbake Variable    IMAGE_LINK_NAME    ${FULL_CONFIG}    recipe=core-image-base
    ${components_dir}=    Get Bitbake Variable    COMPONENTS_DIR    ${FULL_CONFIG}
    ${build_arch}=    Get Bitbake Variable    BUILD_ARCH    ${FULL_CONFIG}
    ${tools}=    Set Variable    ${components_dir}/${build_arch}
    ${modified_image_dir}=    Normalize Path    ${CURDIR}/../${TEMP_DIR}/build/verified-boot-modified-images
    Set Suite Variable    ${DISK_IMAGE}    ${deploy_dir}/${link_name}.wic
    Set Suite Variable    ${FIT_IMAGE}    ${deploy_dir}/fitImage
    Set Suite Variable    ${NATIVE_TOOLS}
    ...    ${tools}/u-boot-tools-native/usr/bin:${tools}/dtc-native/usr/bin:${tools}/mtools-native/usr/bin
    Set Suite Variable    ${MODIFIED_IMAGE_DIR}    ${modified_image_dir}
    Remove Modified Images
    Create Directory    ${MODIFIED_IMAGE_DIR}

Remove Modified Images
    [Documentation]    Remove the files the tests create into ${MODIFIED_IMAGE_DIR}, one by one, so
    ...                that nothing else in it is removed. Removing the directories fails if they
    ...                contain other files.
    FOR    ${name}    IN    @{MODIFIED_IMAGES}
        Remove File    ${MODIFIED_IMAGE_DIR}/${name}.rootfs.wic
        Remove File    ${MODIFIED_IMAGE_DIR}/${name}.fitImage
    END
    Remove File    ${MODIFIED_IMAGE_DIR}/other-key/sulka-fit.key
    Remove Directory    ${MODIFIED_IMAGE_DIR}/other-key
    Remove Directory    ${MODIFIED_IMAGE_DIR}

Create Disk Image With Modified FIT
    [Documentation]    Copy the disk image and the FIT image into ${MODIFIED_IMAGE_DIR}, run the
    ...                shell command ${modification} to modify the copy of the FIT image given in
    ...                $FIT, and replace the FIT image in the copy of the disk image with it. Return
    ...                the path of the disk image.
    [Arguments]    ${name}    ${modification}
    # runqemu recognises a disk image by .rootfs. in its name
    ${disk}=    Set Variable    ${MODIFIED_IMAGE_DIR}/${name}.rootfs.wic
    ${fit}=    Set Variable    ${MODIFIED_IMAGE_DIR}/${name}.fitImage
    Copy File    ${FIT_IMAGE}    ${fit}
    ${result}=    Run Process    ${modification}    shell=True
    ...    env:FIT=${fit}    env:MODIFIED_IMAGE_DIR=${MODIFIED_IMAGE_DIR}    env:PATH=${NATIVE_TOOLS}:%{PATH}
    Should Be Equal As Integers    ${result.rc}    0    Modifying the FIT image failed:\n${result.stderr}
    # The boot partition starts at 1 MiB, see the wks file of the qemuarm64 reference
    ${result}=    Run Process    cp --sparse\=always "${DISK_IMAGE}" "${disk}" && mcopy -o -i "${disk}@@1M" "${fit}" ::fitImage
    ...    shell=True    env:PATH=${NATIVE_TOOLS}:%{PATH}
    Should Be Equal As Integers    ${result.rc}    0    Replacing the FIT image failed:\n${result.stderr}
    RETURN    ${disk}

Boot Should Be Rejected
    [Documentation]    Wait until U-Boot resets. Fail unless U-Boot printed ${expected} to the serial
    ...                console in ${TEMP_DIR}/${console_log} before it, or if it started the kernel.
    ...                The disk images are not next to a qemuboot.conf, so the tests give the machine
    ...                to runqemu, which then reads the qemuboot.conf of the deployed image.
    [Arguments]    ${console_log}    ${expected}
    Wait Until Keyword Succeeds    ${REJECT_TIMEOUT}    5s
    ...    Console Log Should Contain    ${TEMP_DIR}/${console_log}    resetting
    ${console}=    OperatingSystem.Get File    ${TEMP_DIR}/${console_log}
    Should Contain    ${console}    ${expected}
    Should Not Contain    ${console}    Starting kernel

Console Log Should Contain
    [Arguments]    ${path}    ${expected}
    ${console}=    OperatingSystem.Get File    ${path}
    Should Contain    ${console}    ${expected}
