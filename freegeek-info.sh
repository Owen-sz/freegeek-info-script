#!/bin/bash

BOLD='\033[1m'
RESET='\033[0m'

# Run updates in background
gnome-terminal --window -- bash -c "sudo apt install -y libcdio-utils smartmontools ethtool cheese && sudo apt update && sudo apt upgrade -y; exec bash"
echo -e "${BOLD}~~~~~~ OPENING NEW WINDOW FOR UPDATES, VERIFY COMPLETION WHEN DONE ~~~~~~${RESET}"

echo ""

sleep 1

# CPU
cpu_info=$(grep -m 1 'model name' /proc/cpuinfo | awk -F: '{gsub(/^[ \t]+|[ \t]+$/, "", $2); print $2}')
cores=$(lscpu | grep -i 'core(s)' | awk '{print $4}')
threads=$(nproc)
echo -e "${BOLD}CPU:${RESET} $cpu_info"
echo -e "${BOLD}Cores:${RESET} $cores"
echo -e "${BOLD}Threads:${RESET} $threads"

echo ""

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
                vram_gb=$(echo "scale=2; $vram / 1024" | bc | cut -d'.' -f1)                          # needs to be tested
                echo -e "${BOLD}VRAM:${RESET} ${vram_gb}GBs"
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
                    vram_gb=$(echo "scale=2; $vram / 1024" | bc | cut -d'.' -f1)
                    echo -e "${BOLD}VRAM:${RESET} ${vram_gb}GBs"
                    echo ""
                else
                    echo -e "${BOLD}VRAM:${RESET} Error in detecting VRAM, might be a driver issue, google it"
                    echo ""
                fi
            else
                echo "nvidia-smi not found, cannot detect VRAM for NVIDIA dGPU"
                echo ""
            fi
        elif echo "$gpu" | grep -qi 'amd'; then
            vram=$(lspci -v | grep -i 'vga\|3d\|2d' | grep -i memory | awk '{print $2 $3}' | tr -d 'M')
            if [[ "$vram" =~ ^[0-9]+$ ]]; then
                vram_gb=$(echo "scale=2; $vram / 1024" | bc | cut -d'.' -f1)                             # needs to be tested
                echo -e "${BOLD}VRAM:${RESET} ${vram_gb}GBs"
                echo ""
            else
                echo -e "${BOLD}VRAM:${RESET} Error in detecting VRAM, google it"
                echo ""
            fi
        else
            echo -e "${BOLD}VRAM:${RESET} Not detected for this dGPU"
            echo ""
        fi
    fi
done <<< "$gpus"

# RAM
memtotal=$(cat /proc/meminfo | grep -i memtotal | awk '{print (int(($2/1000000 + 1)/2) * 2) "GBs"}')
memspeed=$(dmidecode -t memory | grep -iE '^\s*Speed: [0-9]+ MT/s' | head -n 1 | awk '{print $2}')
slotsused=$(dmidecode --type 17 | grep -A 10 'Memory Device' | grep -c 'Size: [0-9]')
slotstotal=$(dmidecode --type 17 | grep -i ddr | awk '{print $2}' | uniq)
generation=$(sudo dmidecode --type 17 | grep -i ddr | awk '{print $2}' | uniq)
generationsdr=$(dmidecode --type 17 | grep -i sdr | awk '{print $2}' | uniq)
echo -e "${BOLD}RAM:${RESET}" "$memtotal"
echo -e "${BOLD}Speed:${RESET}" "$memspeed" "MHz"
echo -e "${BOLD}Slots Used:${RESET}" "$slotsused"
if [[ -n "$slotstotal" && "$slotstotal" -ne 0 ]]; then
    echo -e "${BOLD}Slots Total:${RESET} $slotstotal"
else
    echo -e "${BOLD}Slots Total:${RESET} Unknown (This isn't very accurate, physically check how many slots there are)"
fi
echo -e "${BOLD}Generation:${RESET}" "$generation" || "$generationsdr Why are you putting Linux Mint on an SDR device?! Bring this to the Retro department." || "Generation not found"

echo ""

# Disk

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
    healthcheck=$(smartctl -H "$root" | grep -E "PASSED|FAILED" | awk '{print $NF}')
fi

# Get total storage
total_storage=$(df / | awk 'NR==2 {print int($2 / 1000000 + 0.5) "GBs"}')

# Get interface and type information
interface=$(lsblk -o TRAN | grep -v 'zram' | awk 'NR>1 {print $1}' | sort -u | paste -sd " ")

# Determine storage type (SSD or HDD)
type=$(if [ "$rotation_info" -eq 0 ]; then echo "SSD (if no interface, probably eMMC)"; elif [ "$rotation_info" -eq 1 ]; then echo "HDD"; else echo "Unknown"; fi)

echo -e "${BOLD}Total Storage:${RESET} $total_storage"
echo -e "${BOLD}Interface:${RESET} $interface"
echo -e "${BOLD}Type:${RESET} $type"
echo -e "${BOLD}Disk Health:${RESET} $healthcheck"
echo ""

# Battery
batteryhealth0=$(upower -i /org/freedesktop/UPower/devices/battery_BAT0 | grep -E "capacity" | awk '{print $2}')
batteryhealth1=$(upower -i /org/freedesktop/UPower/devices/battery_BAT1 | grep -E "capacity" | awk '{print $2}')
batteryhealth2=$(upower -i /org/freedesktop/UPower/devices/battery_BAT2 | grep -E "capacity" | awk '{print $2}')

count=0

if [[ -n "$batteryhealth0" ]]; then
    echo -e "${BOLD}Battery Health:${RESET} $batteryhealth0"
    ((count++))
fi

if [[ -n "$batteryhealth1" ]]; then
    echo -e "${BOLD}Battery Health:${RESET} $batteryhealth1"
    ((count++))
fi

if [[ -n "$batteryhealth2" ]]; then
    echo -e "${BOLD}Battery Health:${RESET} $batteryhealth2"
    ((count++))
fi

if [[ $count -eq 2 ]]; then
    echo -e "${BOLD}This computer has 2 batteries. Check with build lab coordinator on how to mark on build sheet.${RESET}"
elif [[ $count -eq 3 ]]; then
    echo -e "${BOLD}This computer has 3 batteries. That probably should not happen, ask build coordinator${RESET}"
elif [[ $count -eq 0 ]]; then
    echo -e "${BOLD}Battery health not found${RESET}"
fi

echo ""

# Port stuff

# SD Card
mmc=$(dmesg | grep -i mmc)
if [[ -n "$mmc" ]]; then
    echo -e "${BOLD}SD Card Slot:${RESET} Probably (check)"
else
    echo -e "${BOLD}SD Card Slot:${RESET} No"
fi

# USB 3.0
usb3=$(lsusb | grep 3.0)
if [[ -n "$usb3" ]]; then
    echo -e "${BOLD}USB3.0:${RESET} Probably (check, note port may not always be blue, check for 'SS' label)"
else
    echo -e "${BOLD}USB3.0:${RESET} No"
fi

# Ethernet Speed
speed=$(ethtool $(ip link show | awk -F: '/^[0-9]+: e/{print $2}') | grep -Eo 'Speed: ([0-9]+)' | awk '{print $2}')
if [[ $speed == 100 ]]; then
    echo -e "${BOLD}Ethernet Speed:${RESET} 10/100"
elif [[ $speed == 1000 ]]; then
    echo -e "${BOLD}Ethernet Speed:${RESET} Gigabit"
elif [[ $speed == 2500 ]]; then
    echo -e "${BOLD}Ethernet Speed:${RESET} 2.5 Gig"
elif [[ $speed == 10000 ]]; then
    echo -e "${BOLD}Ethernet Speed:${RESET} 10 Gig (wow!)"
else
    echo -e "${BOLD}Ethernet Speed:${RESET} Unknown"
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
fi

echo ""

#Screen Size
screensize=$(inxi -Gxx | awk -F'[()]' '/diag:/ {print $2; exit}')
echo -e "${BOLD}Screen Size:${RESET} $screensize"

# Screen Resolution
resolution=$(inxi -Gxx | awk 'BEGIN {count=0} /res:/ {count++; if (count==2) {for (i=1; i<=NF; i++) if ($i=="res:") {print $(i+1); exit}}}')
echo -e "${BOLD}Screen Resolution:${RESET} $resolution"

echo ""

# Product name (works best on laptops)
product_name=$(dmidecode -s system-product-name)
echo -e "${BOLD}Product Name:${RESET} $product_name (If on a laptop, this is your model and manufacturer. If on a desktop, you may need to refer to the outside branding)"

# Baseboard (motherboard for desktops)
baseboard=$(dmidecode -t baseboard | grep -i "product name" | awk -F: '{print $2}')
echo -e "${BOLD}Motherboard Name:${RESET} $baseboard (If on a desktop, this is your motherboard model. If on a laptop/all-in-one, this is probably worthless information)"

echo ""

# Bluetooth
bluetooth=$(rfkill list | grep -i bluetooth)
if [[ -n "$bluetooth" ]]; then
    echo -e "${BOLD}Bluetooth:${RESET} Yes"
else
    echo -e "${BOLD}Bluetooth:${RESET} No"
fi

# WiFi
wifi=$(rfkill list | grep -i wifi)
wifi2=$(rfkill list | grep -i wireless)
standard=$(lspci | grep -io '802.11[a-z0-9]*')
standard2=$(lsusb | grep -io '802.11[a-z0-9]*')

if [[ -n "$wifi" ]] || [[ -n "$wifi2" ]]; then
    echo -e "${BOLD}WiFi:${RESET} Yes"
    if [[ -n "$standard" ]]; then
        echo "${BOLD}WiFi Standard:${RESET} $standard"
    elif [[ -n "$standard2" ]]; then
        echo -e "${BOLD}WiFi Standard:${RESET} $standard2"
    else
        echo -e "${BOLD}WiFi Standard:${RESET} Unknown"
    fi
else
    echo -e "${BOLD}WiFi:${RESET} No"
fi

echo ""

# Camera, Mic, Speaker test
echo -e "${BOLD}Press enter to begin camera/mic/speaker test.${RESET} (It's recommended to test speakers and mic by recording a video)"
echo -e "${BOLD}Type 'n' if you don't have a webcam${RESET} (If you don't have a webcam, you probably don't have speakers or a mic)"

read -r camera_test
if [[ $camera_test = "n" ]]; then
    echo "Camera test aborted"
    echo -e "${BOLD}~~~~~ SCRIPT COMPLETE ~~~~~${RESET}"
    echo -e "Please check out https://github.com/Owen-sz/freegeek-info-script to report issues or contribute!"
elif [[ $camera_test = "" ]]; then
    echo -e "${BOLD}Close camera app to quit script${RESET}"
    echo -e "Please check out https://github.com/Owen-sz/freegeek-info-script to report issues or contribute!"
    cheese
fi
