#!/bin/bash

set -e

BOARD_DIR="$(dirname $0)"
BOARD_NAME="$(basename ${BOARD_DIR})"
GENIMAGE_CFG="${BOARD_DIR}/genimage-${BOARD_NAME}.cfg"
GENIMAGE_TMP="${BUILD_DIR}/genimage.tmp"

# generate genimage from template if a board specific variant doesn't exists
if [ ! -e "${GENIMAGE_CFG}" ]; then
	GENIMAGE_CFG="${BINARIES_DIR}/genimage.cfg"
	FILES=()

	for i in "${BINARIES_DIR}"/*.dtb "${BINARIES_DIR}"/rpi-firmware/*; do
		FILES+=( "${i#${BINARIES_DIR}/}" )
	done

	KERNEL=$(sed -n 's/^kernel=//p' "${BINARIES_DIR}/rpi-firmware/config.txt")
	FILES+=( "${KERNEL}" )

	BOOT_FILES=$(printf '\\t\\t\\t"%s",\\n' "${FILES[@]}")
	sed "s|#BOOT_FILES#|${BOOT_FILES}|" "${BOARD_DIR}/genimage.cfg.in" \
		> "${GENIMAGE_CFG}"
fi

for arg in "$@"
do
	case "${arg}" in
		--gpu_mem_256=*|--gpu_mem_512=*|--gpu_mem_1024=*)
			# Set GPU memory
			gpu_mem="${arg:2}"
			sed -e "/^${gpu_mem%=*}=/s,=.*,=${gpu_mem##*=}," -i "${BINARIES_DIR}/rpi-firmware/config.txt"
			;;

		--tvmode-720)
			if ! grep -qE '^hdmi_mode=4' "${BINARIES_DIR}/rpi-firmware/config.txt"; then
				echo "Adding 'tvmode=720' to config.txt."
				cat << __EOF__ >> "${BINARIES_DIR}/rpi-firmware/config.txt"

# Force 720p
hdmi_group=1
hdmi_mode=4

__EOF__
			fi
			;;

        --tvmode-1080)
	        if ! grep -qE '^hdmi_mode=16' "${BINARIES_DIR}/rpi-firmware/config.txt"; then
	            echo "Adding 'tvmode=1080' to config.txt."
	            cat << __EOF__ >> "${BINARIES_DIR}/rpi-firmware/config.txt"

# Force 1080p
hdmi_group=1
hdmi_mode=16

__EOF__
            fi
	        ;;

	    --silent)
	        if ! grep -qE '^disable_splash=1' "${BINARIES_DIR}/rpi-firmware/config.txt"; then
	            echo "Adding 'silent=1' to config.txt."
	            cat << __EOF__ >> "${BINARIES_DIR}/rpi-firmware/config.txt"

# Silent
disable_splash=1
boot_delay=0

__EOF__
        	fi
	        ;;

		--add-vc4-fkms-v3d-overlay)
			# Enable VC4 overlay
			if ! grep -qE '^dtoverlay=vc4-fkms-v3d' "${BINARIES_DIR}/rpi-firmware/config.txt"; then
				echo "Adding 'dtoverlay=vc4-fkms-v3d' to config.txt."
				cat << __EOF__ >> "${BINARIES_DIR}/rpi-firmware/config.txt"

# Add VC4 GPU support
dtoverlay=vc4-fkms-v3d

__EOF__
			fi
			;;

		--add-vc4-kms-v3d-overlay)
			# Enable VC4 overlay
			echo "Adding 'dtoverlay=vc4-kms-v3d' to config.txt."
			cat << __EOF__ >> "${BINARIES_DIR}/rpi-firmware/config.txt"

# Add VC4 GPU support
dtoverlay=vc4-kms-v3d-pi4

__EOF__
			;;

        --silent)
			if ! grep -qE '^disable_splash=1' "${BINARIES_DIR}/rpi-firmware/config.txt"; then
				echo "Adding 'silent=1' to config.txt."
				cat << __EOF__ >> "${BINARIES_DIR}/rpi-firmware/config.txt"

# Silent
disable_splash=1
boot_delay=0

__EOF__
			fi
			;;

		--add-dtparam-audio)
			if ! grep -qE '^dtparam=audio=on' "${BINARIES_DIR}/rpi-firmware/config.txt"; then
				echo "Adding 'dtparam=audio=on' to config.txt."
				cat << __EOF__ >> "${BINARIES_DIR}/rpi-firmware/config.txt"

# Enable onboard ALSA audio
dtparam=audio=on

__EOF__
			fi
			;;
	esac
done

# Pass an empty rootpath. genimage makes a full copy of the given rootpath to
# ${GENIMAGE_TMP}/root so passing TARGET_DIR would be a waste of time and disk
# space. We don't rely on genimage to build the rootfs image, just to insert a
# pre-built one in the disk image.

trap 'rm -rf "${ROOTPATH_TMP}"' EXIT
ROOTPATH_TMP="$(mktemp -d)"

rm -rf "${GENIMAGE_TMP}"

genimage \
	--rootpath "${ROOTPATH_TMP}"   \
	--tmppath "${GENIMAGE_TMP}"    \
	--inputpath "${BINARIES_DIR}"  \
	--outputpath "${BINARIES_DIR}" \
	--config "${GENIMAGE_CFG}"

exit $?
