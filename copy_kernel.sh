#!/bin/sh

# Script to copy modules quickly from mtk bazel kernel builds
# Brought to you by: rio004
#

GREEN="\033[0;32m"
RED="\033[0;31m"
RESET="\033[0m"

KERNEL_DIR="$1"
SRC_DIR="$KERNEL_DIR/out/dist/"

[ -z "$KERNEL_DIR" ] && { echo "Usage: $0 /path/to/kernel/"; exit 1; }
[ ! -d "$KERNEL_DIR" ] && { echo "${RED}Invalid KERNEL_DIR:${RESET} $KERNEL_DIR"; exit 1; }

# Module load lists and their destination directories
MODULE_LISTS="
    modules.load:vendor
    modules.load.ramdisk:ramdisk
    modules.load.recovery:ramdisk
    modules.load.system:system
"

# Extra vendor modules not listed in modules.load
EXTRA_MODULES="
    anc_fps_mmi.ko
    awinic_sar.ko
    cmdq-test.ko
    con_dfpar.ko
    emi-fake-eng.ko
    focaltech_touch_v3_u_mmi.ko
    goodix_brl_u_mmi.ko
    goodix_fod_mmi_u.ko
    gps_pwr.ko
    gps_scp.ko
    met.ko
    met_backlight_api.ko
    met_emi_api.ko
    met_gpu_adv_api.ko
    met_gpu_api.ko
    met_gpueb_api.ko
    met_ipi_api.ko
    met_mcupm_api.ko
    met_scmi_api.ko
    met_sspm_api.ko
    met_vcore_api.ko
    mm_iosched.ko
    mmi_info.ko
    mmi_relay.ko
    mmi_stow.ko
    moto_binder.ko
    moto_f_usbnet.ko
    moto_mmap_fault.ko
    moto_sched.ko
    moto_swap.ko
    msync2_frd.ko
    qpnp_adaptive_charge.ko
    scheduler_ext.ko
    sensors_class.ko
    skb_latency.ko
    st54lnfc.ko
    st54lspi.ko
    sx937x_sar.ko
    touchscreen_u_mmi.ko
    tui-common.ko
    utags.ko
"

copy_module() {
    mod="$1"
    dest="$2"
    found=$(find "$SRC_DIR" -type f -name "$mod" -print -quit)
    if [ -n "$found" ]; then
        cp "$found" "./$dest/"
        chmod -x "./$dest/$(basename "$found")"
        echo "${GREEN}Copied:${RESET} $mod -> $dest/"
    else
        echo "${RED}Missing:${RESET} $mod"
    fi
}

# Copy modules from lists
for entry in $MODULE_LISTS; do
    list_file="${entry%%:*}"
    dest_dir="${entry##*:}"
    if [ ! -f "$list_file" ]; then
        echo "${RED}Missing list:${RESET} $list_file"
        continue
    fi
    while read -r mod; do
        [ -z "$mod" ] && continue
        case "$mod" in \#*) continue ;; esac
        copy_module "$mod" "$dest_dir"
    done < "$list_file"
done

# Copy extra modules to vendor
for mod in $EXTRA_MODULES; do
    copy_module "$mod" "vendor"
done

# Strip symbols
CLANG_VERISON=clang-r487747c
find ./vendor ./ramdisk ./system -name '*.ko' \
    -exec ${KERNEL_DIR}/prebuilts/clang/host/linux-x86/${CLANG_VERISON}/bin/llvm-strip --strip-debug {} +

# Kernel artifacts
for artifact in Image.gz; do
    found=$(find "$SRC_DIR" -type f -name "$artifact" -print -quit)
    if [ -n "$found" ]; then
        cp "$found" ./
        chmod -x "./$(basename "$found")"
        echo "${GREEN}Copied:${RESET} $(basename "$found")"
    else
        echo "${RED}Missing:${RESET} $artifact"
    fi
done
