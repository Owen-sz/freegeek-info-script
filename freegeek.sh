#!/bin/bash

BOLD='\033[1m'
RESET='\033[0m'

# Run updates in background
gnome-terminal --window -- bash -c "sudo apt update && sudo apt upgrade -y; exec bash"
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
echo ""

# GPUs
gpus=$(lspci | grep -i 'vga\|3d\|2d')

# Iterate over detected GPUs and classify as iGPU or dGPU
while IFS= read -r gpu; do
    gpu_name=$(echo "$gpu" | awk '{for (i=5; i<=NF; i++) printf $i " "; print ""}')
    if echo "$gpu" | grep -qi 'intel'; then
        echo -e "${BOLD}iGPU:${RESET} $gpu_name"
        vram=$(cat /sys/class/drm/card0/memory_vram_total 2> /dev/null)
        if [ -n "$vram" ]; then
            vram_gb=$(echo "scale=2; $vram / 1073741824" | bc)
        fi
    else
        echo -e "${BOLD}dGPU:${RESET} $gpu_name"
        if echo "$gpu" | grep -qi 'nvidia'; then
            if command -v nvidia-smi &> /dev/null; then
                vram=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits)
                vram_gb=$(echo "scale=2; $vram / 1024" | bc)
                echo -e "${BOLD}VRAM (NVIDIA):${RESET} ${vram_gb} GB"
            else
                echo "nvidia-smi not found, cannot detect VRAM for NVIDIA dGPU."
            fi
        elif echo "$gpu" | grep -qi 'amd'; then
            vram=$(lspci -v | grep -i 'vga\|3d\|2d' | grep -i memory | awk '{print $2 $3}' | tr -d 'M')
            vram_gb=$(echo "scale=2; $vram / 1024" | bc)
            echo -e "${BOLD}VRAM (AMD):${RESET} ${vram_gb} GB"
        else
            echo -e "${BOLD}VRAM:${RESET} Not detected for this dGPU."
        fi
    fi
done <<< "$gpus"

echo ""

# RAM
memtotal=$(cat /proc/meminfo | grep -i memtotal | awk '{print $2/1024/1024 " GB"}')
echo -e "${BOLD}Total Memory:${RESET}" "$memtotal"
echo -e "${BOLD}***If slightly below 4, 8, 16, 32, etc, mark that on the build sheet instead of the outputted number***${RESET}"
# TODO: Speed and count

echo ""

# disk
echo -e "${BOLD}Disk Info:${RESET}"

# Find root device
disk=$(lsblk -no pkname "$(df / | awk 'NR==2 {print $1}')") | grep -v 'zram'

# Get total storage
total_storage=$(lsblk -dn -o SIZE "/dev/$disk")
interface=$(lsblk -o TRAN | grep -v 'zram' | awk 'NR>1 {print $1}' | sort -u | paste -sd " ")
type=$(lsblk -d -o NAME,rota | grep -v 'zram')

echo -e "${BOLD}Total Storage:${RESET}" "$total_storage"
echo -e "${BOLD}Interface:${RESET}" "$interface"
echo -e "${BOLD}Type:${RESET}" "	$type"

echo -e "${BOLD}***If your internal root disk gives a '0' you have an SSD or eMMC/other, if it gives a '1' you have an HDD***${RESET}"

echo ""

# battery
batteryhealth=$(upower -i /org/freedesktop/UPower/devices/battery_BAT0 | grep -E "capacity" | awk '{print $2}')
echo -e "${BOLD}Battery Health:${RESET}" "$batteryhealth"

# Product name (works best on laptops)
product_name=$(sudo dmidecode -s system-product-name)
echo -e "${BOLD}Product name (if on a laptop, this is your model and manufacturer. If on a desktop, you may need to refer to the outside branding):${RESET}" "$product_name"

# Baseboard (motherboard for desktops)
baseboard=$(sudo dmidecode -t baseboard | grep -i "product name" | awk -F: '{print $2}')
echo -e "${BOLD}Motherboard name (if on a desktop, this is your motherboard model. If on a laptop/all-in-one, this is probably worthless information):${RESET}" "$baseboard"

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

if [[ -n "$wifi" ]] || [[ -n "$wifi2" ]]; 
then 
	echo -e "${BOLD}WiFI:${RESET} Yes"
else
	echo -e "${BOLD}WiFI:${RESET} No"
fi

# TODO: I/O, speaker test, camera test
