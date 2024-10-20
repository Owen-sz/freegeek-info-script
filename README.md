# freegeek-info-script
Shell script that pools together info needed for Free Geek build sheets.

### How to run:
1. Type `Ctrl + Alt + T` to open a terminal
2. Paste `git clone https://github.com/Owen-sz/freegeek-info-script.git` into the terminal to clone (download) the script
3. Paste `sudo bash freegeek-info.sh` into the terminal to run the script
> [!TIP]
>  Use `Ctrl + Shift + V` to paste into the terminal

[Join the Free Geek Discord!](https://discord.gg/umxcyCDmr8)
## For Contributors

### Still Needs:
- [ ] Add build sheet PDFs to repo
- [ ] Foolproofing tips for things like what exactly to google or what kinds of branding to look for on a desktop case
- [ ] Ability to detect and list multiple drives
- [ ] Reliably list total number of RAM slots
- [ ] NVIDIA will need an extra package installed
- [ ] Test if Ethernet module works on 10/100, 2.5 Gig, or 10 Gig ports.
- [ ] Add multi-port functionality to Ethernet module
- [ ] PSU Info (if possible)
- [ ] Add message to tell users to look up year the CPU came out to find the year of the machine
- [ ] Utilize `inxi -Fxxxz` to find display output ports, find usefulness in machine section. (if this command is present or packaged for Mint)
- [ ] Test screen size and res modules on laptops
- [ ] Test multi-battery support

### Bugs:
- [x] Ethernet speed module broken
- [ ] Typing anything but n or {Enter} in the camera module closes the script without sign off message
- [x] USB3.0 detection doesnt work, uses `lsblk`???
- [ ] Disk Health module sometimes doesn't output anything, seems to not be able to detect "$root" as a device type
- [ ] RAM Generation module doesn't reliably provide an output

### Issues:
- NVIDIA drivers may not be properly installed to scrape VRAM, may need an extra package installed
- Product name may not show manufacturer
- Disk sizes are not very accurate
