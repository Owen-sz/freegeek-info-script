# freegeek-info-script
Shell script that pools together info needed for Free Geek build sheets. Will only work on Linux Mint. Ultramarine Linux support coming soon.

### How to run:
1. Open the terminal app from the dock
2. Paste this into the terminal to install git, clone (download) the scripit, and run it. It is recommended to increase the size of your terminal at this time.
```console
sudo apt install git -y && git clone https://github.com/Owen-sz/freegeek-info-script.git && cd freegeek-info-script && sudo bash freegeek-info.sh
```
> [!TIP]
>  Use `Ctrl + Shift + V` to paste into the terminal

## For Contributors

### Still Needs:
- [ ] Add build sheet PDFs to repo
- [ ] Foolproofing tips for things like what exactly to google or what kinds of branding to look for on a desktop case
- [ ] Ability to detect and list multiple drives
- [ ] Reliably list total number of RAM slots
- [ ] NVIDIA will need an extra package installed
- [ ] Find out if Ethernet module works on 10/100, 2.5 Gig, or 10 Gig ports.
- [ ] Add message to tell users to look up year the CPU name out to find the year of the machine
- [ ] Utilize `inxi -Fxxxz` to find display output ports, find usefulness in machine section
- [ ] Test multi-battery support
- [ ] Break into muiltiple files per OS

### Bugs:
- [ ] Typing anything but `n` or `{Enter}` in the camera module closes the script without sign off message
- [ ] Disk Health module sometimes doesn't output anything, seems to not be able to detect "$root" as a device type
- [ ] Screen Size and Resolution modules unreliable on laptops, `inxi` works fine

### Quirks:
- NVIDIA drivers may not be properly installed to scrape VRAM, may need an extra package installed
- Product name may not show manufacturer
- Disk sizes are not very accurate
