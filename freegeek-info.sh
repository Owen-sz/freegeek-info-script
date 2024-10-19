#!/bin/bash

BOLD='\033[1m'
RESET='\033[0m'

# Run updates in background
gnome-terminal --window -- bash -c "sudo apt install -y libcdio-utils smartmontools cheese && sudo apt update && sudo apt upgrade -y; exec bash"
echo -e "${BOLD}~~~~~~OPENING NEW WINDOW FOR UPDATES, VERIFY COMPLETION WHEN DONE~~~~~~${RESET}"
echo ""

sleep 1

# CPU
cpu_info=$(grep -m 1 'model name' /proc/cpuinfo | awk -F: '{gsub(/^[ \t]+|[ \t]+$/, "", $2); print $2}')
cores=$(lscpu | grep -i 'core(s)' | awk '{print $4}')
threads=$(nproc)
echo -e "${BOLD}CPU:${RESET} $cpu_info"
echo -e "${BOLD}Cores:${RESET} $cores"
echo -e "${BOLD}Threads:${RESET} $threads"

# GPUs
gpus=$(lspci | grep -i 'vga\|3d\|2d')

# Iterate over detected GPUs and classify as iGPU or dGPU
while IFS= read -r gpu; do
    gpu_name=$(echo "$gpu" | awk '{for (i=5; i<=NF; i++) printf $i " "; print ""}')
    if echo "$gpu" | grep -qi 'intel'; then
        echo -e "${BOLD}iGPU:${RESET} $gpu_name"
        echo ""
        if [[ "$gpu" =~ "ARC" ]]; then
            vram=$(lspci -v -s $(lspci | grep -i 'arc' | awk '{print $1}') | grep -i 'prealloc size' | awk '{print $3}' | tr -d 'M')
            if [[ "$vram" =~ ^[0-9]+$ ]]; then
                vram_gb=$(echo "scale=2; $vram / 1024" | bc)
                echo -e "${BOLD}VRAM:${RESET} ${vram_gb} GB"
                echo ""
            else
                echo -e "${BOLD}VRAM:${RESET} Error in detecting VRAM, google it"
                echo ""
            fi
        fi
    else
        echo -e "${BOLD}dGPU:${RESET} $gpu_name"
        if echo "$gpu" | grep -qi 'nvidia'; then
            if command -v nvidia-smi &> /dev/null; then
                vram=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits)
                if [[ "$vram" =~ ^[0-9]+$ ]]; then
                    vram_gb=$(echo "scale=2; $vram / 1024" | bc)
                    echo -e "${BOLD}VRAM:${RESET} ${vram_gb} GB"
                    echo ""
                else
                    echo -e "${BOLD}VRAM:${RESET} Error in detecting VRAM, might be a driver issue, google it"
                    echo ""
                fi
            else
                echo "nvidia-smi not found, cannot detect VRAM for NVIDIA dGPU."
                echo ""
            fi
        elif echo "$gpu" | grep -qi 'amd'; then
            vram=$(lspci -v | grep -i 'vga\|3d\|2d' | grep -i memory | awk '{print $2 $3}' | tr -d 'M')
            if [[ "$vram" =~ ^[0-9]+$ ]]; then
                vram_gb=$(echo "scale=2; $vram / 1024" | bc)
                echo -e "${BOLD}VRAM:${RESET} ${vram_gb} GB"
                echo ""
            else
                echo -e "${BOLD}VRAM:${RESET} Error in detecting VRAM, google it"
                echo ""
            fi
        else
            echo -e "${BOLD}VRAM:${RESET} Not detected for this dGPU."
            echo ""
        fi
    fi
done <<< "$gpus"

# RAM
memtotal=$(cat /proc/meminfo | grep -i memtotal | awk '{print $2/1000000 " GB"}')
memspeed=$(sudo dmidecode -t memory | grep -iE '^\s*Speed: [0-9]+ MT/s' | head -n 1 | awk '{print $2}')
slotsused=$(sudo dmidecode --type 17 | grep -A 10 'Memory Device' | grep -c 'Size: [0-9]')
slotstotal=$(sudo dmidecode -t connector | grep -ic 'memory slot')
generation=$(sudo dmidecode --type 17 | grep -i ddr | awk '{print $2}' | uniq)
generationsdr=$(sudo dmidecode --type 17 | grep -i sdr | awk '{print $2}' | uniq)
echo -e "${BOLD}Ram:${RESET}" "$memtotal"
echo -e "${BOLD}***If slightly above or below 4, 8, 16, etc, mark the whole number on the build sheet instead of the exact output***${RESET}"
echo -e "${BOLD}Speed:${RESET}" "$memspeed" "MHz"
echo -e "${BOLD}Slots used:${RESET}" "$slotsused"
if [[ -n "$slotstotal" && "$slotstotal" -ne 0 ]]; then
    echo -e "${BOLD}Slots total:${RESET} $slotstotal"
else
    echo -e "${BOLD}Slots total:${RESET} Unknown"
fi
echo -e "${BOLD}Generation:${RESET}" "$generation" || "$generationsdr why are you putting linux mint on an SDR device? bringn this th the retro department" || "Generation not found"

echo ""

# disk

# Check if smartmontools is installed
check_smartmontools() {
    if apt list --installed 2>/dev/null | grep -q "^smartmontools/"; then
        return 0
    else
        return 1
    fi
}

# Get the root device without the partition number
root=$(df / | awk 'NR==2 {print $1}' | sed 's/[0-9]*$//')
rotation_info=$(lsblk -dn -o ROTA "$root")

# Check if the root device is cringe eMMC '/dev/mmcblk*'
if [[ "$root" == /dev/mmcblk* ]]; then
    echo "Root device is an eMMC storage, skipping SMART health check. Please run a bad blocks scan with 'sudo badblocks -v /dev/mmcblk0' after this script"
    healthcheck="Not applicable for eMMC"
else
    # Loop until smartmontools is installed
    until check_smartmontools; do
        echo "smartmontools not found. Waiting for it to be installed..."
        sleep 5
    done

    # Run the SMART health check on the device and filter for PASSED or FAILED
    healthcheck=$(sudo smartctl -H "$root" | grep -E "PASSED|FAILED" | awk '{print $NF}')
fi

# Get total storage
total_storage=$(df / | awk 'NR==2 {print $2 / 1000000 "GBs"}')

# Get interface and type information
interface=$(lsblk -o TRAN | grep -v 'zram' | awk 'NR>1 {print $1}' | sort -u | paste -sd " ")

# Determine the type (SSD or HDD)
type=$(if [ "$rotation_info" -eq 0 ]; then echo "SSD (if no interface, probably eMMC)"; elif [ "$rotation_info" -eq 1 ]; then echo "HDD"; else echo "Unknown"; fi)

echo -e "${BOLD}Total Storage:${RESET} $total_storage"
echo -e "${BOLD}Interface:${RESET} $interface"
echo -e "${BOLD}Type:${RESET} $type"
echo -e "${BOLD}Health:${RESET} $healthcheck"
echo ""

# Battery
batteryhealth=$(upower -i /org/freedesktop/UPower/devices/battery_BAT0 | grep -E "capacity" | awk '{print $2}')
batteryhealth2=$(upower -i /org/freedesktop/UPower/devices/battery_BAT1 | grep -E "capacity" | awk '{print $2}')

if [[ -n "$batteryhealth" ]]; then
    echo -e "${BOLD}Battery Health:${RESET} $batteryhealth"
elif [[ -n "$batteryhealth2" ]]; then
    echo -e "${BOLD}Battery Health:${RESET} $batteryhealth2"
else
    echo -e "${BOLD}Battery Health:${RESET} Not found"
fi

echo ""

# Port stuff

# SD Card
mmc=$(sudo dmesg | grep -i mmc)
if [[ -n "$mmc" ]]; then
    echo -e "${BOLD}SD Card slot:${RESET} Probably"
else
    echo -e "${BOLD}SD Card slot:${RESET} No"
fi

# USB 3.0
usb3=$(lsblk | grep 3.0)
if [[ -n "$usb3" ]]; then
    echo -e "${BOLD}USB3.0:${RESET} Probably"
else
    echo -e "${BOLD}USB3.0:${RESET} No"
fi

# Gigabite ethernet
GbE=$(lspci | grep -i gigabit)
if [[ -n "$GbE" ]]; then
    echo -e "${BOLD}Gigabite Ethernet:${RESET} Yes, check for physical port"
else
    echo -e "${BOLD}Gigabite Ethernet:${RESET} No"
fi

# Optical drive

# Check if libcdio-utils is installed
check_libcdio_utils() {
    if apt list --installed 2>/dev/null | grep -q "^libcdio-utils/"; then
        return 0
    else
        return 1
    fi
}

if check_libcdio_utils; then
    cdrom=$(cd-drive 2>/dev/null)
    if [[ -n "$cdrom" ]]; then
        echo -e "${BOLD}Optical (CD) Drive:${RESET} Yes"
    else
        echo -e "${BOLD}Optical (CD) Drive:${RESET} No"
    fi
else
    echo "libcdio-utils is not installed, skipping optical drive check."
fi

echo ""

# Product name (works best on laptops)
product_name=$(sudo dmidecode -s system-product-name)
echo -e "${BOLD}Product name:${RESET} (if on a laptop, this is your model and manufacturer. If on a desktop, you may need to refer to the outside branding)" "$product_name"

# Baseboard (motherboard for desktops)
baseboard=$(sudo dmidecode -t baseboard | grep -i "product name" | awk -F: '{print $2}')
echo -e "${BOLD}Motherboard name:${RESET} (if on a desktop, this is your motherboard model. If on a laptop/all-in-one, this is probably worthless information)" "$baseboard"

echo ""

# bluetooth
bluetooth=$(rfkill list | grep -i bluetooth)
if [[ -n "$bluetooth" ]]; then 
    echo -e "${BOLD}Bluetooth:${RESET} Yes"
else
    echo -e "${BOLD}Bluetooth:${RESET} No"
fi

# wifi
wifi=$(rfkill list | grep -i wifi)
wifi2=$(rfkill list | grep -i wireless)
standard=$(lspci | grep -io '802.11[a-z0-9]*')
standard2=$(lsusb | grep -io '802.11[a-z0-9]*')

if [[ -n "$wifi" ]] || [[ -n "$wifi2" ]]; then
    echo -e "${BOLD}WiFi:${RESET} Yes"
    if [[ -n "$standard" ]]; then
        echo "Standard: $standard"
    elif [[ -n "$standard2" ]]; then
        echo -e "${BOLD}Standard:${RESET} $standard2"
    else
        echo -e "${BOLD}WiFi Standard not found${RESET}"
    fi
else
    echo -e "${BOLD}WiFi:${RESET} No"
fi

echo ""

echo -e "${BOLD}Press enter to begin camera test. It is reccomended to test speaker and microphone by recording a video with the camera.${RESET}"
echo -e "${BOLD}Once entered, camera test app will be opened${RESET}"
echo -e "${BOLD}If this is a desktop/you do not have a webcam, type 'n'${RESET}"

# Camera (and mic/speaker) test
read -r camera_test
if [[ $camera_test = "n" ]]; then
    echo "Camera test aborted"
    echo "Script over"
elif [[ $camera_test = "" ]]; then
    echo -e "${BOLD}Close camera app to quit script${RESET}"
    cheese
fi