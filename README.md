# freegeek-info-script
WIP Script for getting info on Linux Mint needed for Freegeek build sheets

Must run with sudo

Still needs:
- RAM speed and DIMM count
- WiFi type
- I/O / MMC
- Speaker, mic, camera test
- Drive SMART/bad_block test
- Optical drive test?
- Ethernet Y/N + type

Bugs:
- Disk Info: lsblk: /dev/: not a block device
- Total storage display issue
- Bluetooth if function may not be working properly

Issues:
- Nvidia drivers may not be properly installed to scrape VRAM, may need an extra package installed
- Product name may not show manufacturer

