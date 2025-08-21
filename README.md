# freegeek-info-script
Shell script that pools together info needed for Free Geek build sheets. Will only work on Linux Mint and Ultramarine Linux. Yes there is a powershell script, however it is very new and not at all ready. It will be in a usable state in the coming weeks.

### How to run:

#### Linux:

1. Open the terminal app from the dock. If it is not there, search the applications menu.
2. Paste this into the terminal to install git if needed, clone (download) the scripit, and run it. It is recommended to increase the size of your terminal at this time.
```console
(which git || sudo apt install -y git) && git clone https://github.com/Owen-sz/freegeek-info-script.git && cd freegeek-info-script && sudo bash freegeek-info.sh
```
> [!TIP]
>  Use `Ctrl + Shift + V` to paste into the terminal

#### Windows:

`Set-ExecutionPolicy RemoteSigned -Scope CurrentUser; winget install -y git; start-process powershell; git clone https://Owen-sz/freegeek-info-script.git; cd freegeek-info-script; ./freegeek-info.ps1`

If you would like to just use the files on their own, Download the `freegeek-info.sh` file. If you need to use on Ultramarine, download both, store in the same folder, and always run the `freegeek-info.sh` first. Running `freegeek-info.sh` will auto-update the script every time there is a new commit.

## For Contributors

### Still Needs:
- [ ] Add build sheet PDFs to repo
- [ ] Add Ultramarine Xfce Edition xfce-terminal background logic
- [ ] Foolproofing tips for things like what exactly to google or what kinds of branding to look for on a desktop case
- [ ] Ability to detect and list multiple drives
- [ ] Reliably list total number of RAM slots
- [ ] NVIDIA will need an extra package installed
- [ ] Find out if Ethernet module works on 10/100, 2.5 Gig, or 10 Gig ports.
- [ ] Add message to tell users to look up year the CPU name out to find the year of the machine
- [ ] Utilize `inxi -Fxxxz` to find display output ports, find usefulness in machine section
- [ ] Test multi-battery support
- [ ] Pipe output to file on desktop

### Bugs:
- [ ] Typing anything but `n` or `{Enter}` in the camera module closes the script without sign off message
- [ ] Disk Health module sometimes doesn't output anything, seems to not be able to detect "$root" as a device type
- [ ] Screen Size and Resolution modules unreliable on laptops, `inxi` works fine
- [ ] SD card is not always accurate

### Quirks:
- NVIDIA drivers may not be properly installed to scrape VRAM, may need an extra package installed
- Product name may not show manufacturer
- Disk sizes are not very accurate
