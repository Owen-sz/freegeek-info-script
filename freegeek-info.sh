#!/bin/bash

BOLD='\033[1m'
RESET='\033[0m'

# Run updates in background
gnome-terminal --window -- bash -c "sudo apt install -y smartmontools cheese && sudo apt update && sudo apt upgrade -y; exec bash"
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
    else
        echo -e "${BOLD}dGPU:${RESET} $gpu_name"
        if echo "$gpu" | grep -qi 'nvidia'; then
            if command -v nvidia-smi &> /dev/null; then
                vram=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits)
                if [[ "$vram" =~ ^[0-9]+$ ]]; then
                    vram_gb=$(echo "scale=2; $vram / 1024" | bc)
                    echo -e "${BOLD}VRAM (NVIDIA):${RESET} ${vram_gb} GB"
                else
                    echo -e "${BOLD}VRAM (NVIDIA):${RESET} Error in detecting VRAM"
                fi
            else
                echo "nvidia-smi not found, cannot detect VRAM for NVIDIA dGPU."
            fi
        elif echo "$gpu" | grep -qi 'amd'; then
            vram=$(lspci -v | grep -i 'vga\|3d\|2d' | grep -i memory | awk '{print $2 $3}' | tr -d 'M')
            if [[ "$vram" =~ ^[0-9]+$ ]]; then
                vram_gb=$(echo "scale=2; $vram / 1024" | bc)
                echo -e "${BOLD}VRAM (AMD):${RESET} ${vram_gb} GB"
            else
                echo -e "${BOLD}VRAM (AMD):${RESET} Error in detecting VRAM"
            fi
        else
            echo -e "${BOLD}VRAM:${RESET} Not detected for this dGPU."
        fi
    fi
done <<< "$gpus"


echo ""

# RAM
memtotal=$(cat /proc/meminfo | grep -i memtotal | awk '{print $2/1000000 " GB"}')
memspeed=$(sudo dmidecode -t memory | grep -iE '^\s*Speed: [0-9]+ MT/s' | head -n 1 | awk '{print $2}')
slotsused=$(sudo dmidecode --type 17 | grep -A 10 'Memory Device' | grep -c 'Size: [0-9]')
slotstotal=$(sudo dmidecode -t connector | grep -i 'memory slot' | wc -l)
generation=$(sudo dmidecode --type 17 | grep -i ddr | awk '{print $2}' | uniq)
generationsdr=$(sudo dmidecode --type 17 | grep -i sdr | awk '{print $2}' | uniq)
echo -e "${BOLD}Ram:${RESET}" "$memtotal"
echo -e "${BOLD}***If slightly above or below 4, 8, 16, etc, mark the whole number on the build sheet instead of the exact output***${RESET}"
echo -e "${BOLD}Speed:${RESET}" "$memspeed" "MHz"
echo -e "${BOLD}Slots used:${RESET}" "$slotsused"
if [[ -n "$slotstotal" ]]; then
    echo -e "${BOLD}Slots total:${RESET}" "$slotstotal"
else
    echo -e "${BOLD}Slots total:${RESET}" "Unknown"
fi
echo -e "${BOLD}Generation:${RESET}" "$generation" || "$generationsdr" || "Generation not found"

echo ""


# disk
# Function to check if smartmontools is installed
check_smartmontools() {
    if dpkg -l | grep -q smartmontools; then
        return 0
    else
        return 1
    fi
}

# Loop until smartmontools is installed
until check_smartmontools; do
    sleep 5
done

# Get the root device without the partition number
health=$(df / | awk 'NR==2 {print $1}' | sed 's/[0-9]*$//')

# Run the SMART health check on the device and filter for PASSED or FAILED
healthcheck=$(sudo smartctl -H "$health" | grep -E "PASSED|FAILED" | awk '{print $NF}')

# Get total storage
total_storage=$(df / | awk 'NR==2 {print $2 / 1000000 "GBs"}')

# Get interface and type information
interface=$(lsblk -o TRAN | grep -v 'zram' | awk 'NR>1 {print $1}' | sort -u | paste -sd " ")
type=$(lsblk -d -o NAME,ROTA | grep -v 'zram')

# Print the results
echo -e "${BOLD}Total Storage:${RESET} $total_storage"
echo -e "${BOLD}Interface:${RESET} $interface"
echo -e "${BOLD}Type:${RESET} $type"
echo -e "${BOLD}Health:${RESET} $healthcheck"
echo -e "${BOLD}***If your internal root disk gives a '0' you have an SSD or eMMC/other, if it gives a '1' you have an HDD***${RESET}"
echo ""

# battery
batteryhealth=$(upower -i /org/freedesktop/UPower/devices/battery_BAT0 | grep -E "capacity" | awk '{print $2}')
batteryhealth2=$(upower -i /org/freedesktop/UPower/devices/battery_BAT1 | grep -E "capacity" | awk '{print $2}')

if [[ -n "$batteryhealth" ]]; then
	echo -e "${BOLD}Battery Health:${RESET}" "$batteryhealth"
else
	echo -e "${BOLD}Battery Health:${RESET}" "$batteryhealth2"
fi

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
standard=$(lspci | grep -io '802.11[a-z0-9]*')
standard2=$(lsusb | grep -io '802.11[a-z0-9]*')

if [[ -n "$wifi" ]] || [[ -n "$wifi2" ]]; then
    echo -e "${BOLD}WiFi:${RESET} Yes"
    if [[ -n "$standard" ]]; then
        echo "Standard: $standard"
    elif [[ -n "$standard2" ]]; then
        echo "Standard: $standard2"
    else
        echo -e "${BOLD}WiFi Standard not found${RESET}"
    fi
else
    echo -e "${BOLD}WiFi:${RESET} No"
fi

echo ""

echo -e "${BOLD}WARNING: MUST WAIT UNTIL UPDATES ARE COMPLETE TO CONTINUE!${RESET}"
echo "Press enter to begin camera test. It is reccomended to test speaker and microphone by recording a video with the camera."
echo "Once entered, camera test app will be installed and opened"
read camera_test
if [[ $camera_test = "" ]]; then
    cheese
fi

# TODO: I/O