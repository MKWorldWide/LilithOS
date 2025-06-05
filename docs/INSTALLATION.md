# LilithOS Installation Guide

## Prerequisites
- Mac Pro 2009 (Early 2009 or Mid 2010)
- USB flash drive (8GB or larger)
- Backup of your important data
- Internet connection

## Step 1: Prepare Installation Media
1. Download the LilithOS ISO image
2. Insert your USB flash drive
3. Run the USB installer creator:
   ```bash
   sudo ./scripts/create-usb-installer.sh /path/to/lilithos.iso /dev/sdX
   ```
   Replace `/dev/sdX` with your USB drive (e.g., `/dev/sdb`)

## Step 2: Prepare Your Mac Pro
1. Back up your important data
2. Disable System Integrity Protection (SIP):
   - Boot into Recovery Mode (hold Command + R during startup)
   - Open Terminal
   - Run: `csrutil disable`
   - Restart

## Step 3: Install LilithOS
1. Insert the USB installer
2. Hold Option (⌥) during startup
3. Select the USB drive
4. Choose "LilithOS Installer" from the GRUB menu
5. Follow the installation wizard:
   - Select language and keyboard layout
   - Choose installation type (Dual Boot)
   - Select disk and partition size
   - Create user account
   - Wait for installation to complete

## Step 4: Configure Dual Boot
1. After installation, the system will install GRUB
2. GRUB will automatically detect macOS
3. You can select your OS at boot time

## Step 5: Post-Installation
1. Update your system:
   ```bash
   sudo apt update
   sudo apt upgrade
   ```
2. Install additional drivers if needed
3. Configure your desktop environment

## Troubleshooting

### Boot Issues
- If GRUB doesn't appear, try:
  ```bash
  sudo update-grub
  ```
- If macOS doesn't appear in GRUB:
  ```bash
  sudo os-prober
  sudo update-grub
  ```

### Graphics Issues
- If you experience graphics problems, boot with "Safe Graphics" option
- Install appropriate drivers:
  ```bash
  sudo apt install firmware-linux
  ```

### Network Issues
- Check network configuration:
  ```bash
  sudo systemctl status NetworkManager
  ```
- Install additional firmware if needed:
  ```bash
  sudo apt install firmware-linux-nonfree
  ```

## Support
If you encounter any issues:
1. Check the troubleshooting section
2. Review system logs:
   ```bash
   dmesg | less
   journalctl -xe
   ```
3. Visit our support forum or GitHub issues page

## Security Notes
- Enable full disk encryption during installation
- Keep your system updated
- Use strong passwords
- Enable firewall:
  ```bash
  sudo ufw enable
  ``` 