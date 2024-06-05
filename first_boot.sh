#!/bin/bash
sudo dpkg --add-architecture i386

sudo wget http://repo.steampowered.com/steam/archive/stable/steam.gpg -P /usr/share/keyrings/
echo "deb [arch=amd64,i386 signed-by=/usr/share/keyrings/steam.gpg] https://repo.steampowered.com/steam/ stable steam" | sudo tee /etc/apt/sources.list.d/steam.list

echo 'APT::Install-Suggests "0";' | sudo tee /etc/apt/apt.conf.d/99no-suggests
echo 'APT::Install-Recommends "0";' | sudo tee /etc/apt/apt.conf.d/99no-recommends

sudo apt update && sudo apt upgrade -y
sudo apt install -y adwaita-icon-theme-full alsa-utils awscli baobab build-essential dkms dmz-cursor-theme gdm3 gedit gnome-control-center gnome-session gnome-shell-extension-appindicator gnome-terminal httpie libc6-dev libcanberra-pulse libglvnd-dev libva-drm2 libva2 libvdpau1 libvulkan1 linux-gcp linux-headers-gcp nautilus pkg-config pulseaudio pulseaudio-module-gsettings steam-launcher steam-libs-amd64 unzip xdg-desktop-portal-gtk xdg-utils xserver-xorg-core xserver-xorg-dev xserver-xorg-input-libinput

# sudo mkfs.ext4 /dev/sdb
# sudo mkdir -p /mnt
# sudo chown -R sunshine:sunshine /mnt
# sudo mount /dev/sdb /mnt
# echo "/dev/sdb /mnt ext4 defaults,nofail 0 2" | sudo tee -a /etc/fstab

sudo useradd -m -s /bin/bash sunshine
sudo usermod -aG users,audio,video,plugdev,netdev,input sunshine

cat <<EOF | sudo tee /etc/modprobe.d/blacklist.conf
blacklist vga16fb
blacklist nouveau
blacklist rivafb
blacklist nvidiafb
blacklist rivatv
EOF

cat <<EOF | sudo tee /etc/modprobe.d/nvidia.conf
options nvidia NVreg_EnableGpuFirmware=0
EOF

cat <<EOF | sudo tee /etc/gdm3/custom.conf
[daemon]
WaylandEnable=false
AutomaticLoginEnable = true
AutomaticLogin = sunshine
[security]
[xdmcp]
[chooser]
[debug]
EOF

cat <<EOF | sudo tee /etc/udev/rules.d/85-sunshine-input.rules
KERNEL=="uinput", GROUP="input", MODE="0660", OPTIONS+="static_node=uinput"
EOF

cat <<EOF | sudo tee /opt/sunshine_systemd_user_service.patch
5,7c5
< PartOf=graphical-session.target
< Wants=xdg-desktop-autostart.target
< After=xdg-desktop-autostart.target
---
> After=graphical-session.target
15c13
< WantedBy=xdg-desktop-autostart.target
---
> WantedBy=graphical-session.target
EOF


cat <<EOF | sudo tee /opt/install_nvidia_driver.sh
#!/bin/bash
set -euo pipefail
cd /mnt
curl -O https://storage.googleapis.com/nvidia-drivers-us-public/GRID/vGPU17.1/NVIDIA-Linux-x86_64-550.54.15-grid.run
chmod +x ./NVIDIA-Linux-x86_64-550.54.15-grid.run
sudo bash ./NVIDIA-Linux-x86_64-550.54.15-grid.run --no-dkms --tmpdir=/mnt --silent
rm -f ./NVIDIA-Linux-x86_64-550.54.15-grid.run
update-initramfs -u
cat << EOF2 | sudo tee -a /etc/nvidia/gridd.conf
vGamingMarketplace=2
EOF2
curl -o /etc/nvidia/GridSwCert.txt "https://storage.googleapis.com/nvidia-drivers-us-public/GRID/vGPU17.1/GridSwCertLinux_2021_10_2.cert"
nvidia-xconfig --preserve-busid --enable-all-gpus
nvidia-smi -q | head
EOF


sudo chmod +x /opt/install_nvidia_driver.sh

cat <<EOF | sudo tee /etc/systemd/system/init_mnt.service
[Unit]
After = network-online.target
Wants = network-online.target
[Service]
Type = oneshot
RemainAfterExit = yes
ExecStart = mkdir -p /mnt/sunshine
ExecStart = chown sunshine:sunshine /mnt/sunshine
[Install]
WantedBy = multi-user.target
EOF

cat <<EOF | sudo tee /home/sunshine/enable_sunshine_services.sh
#!/bin/bash
systemctl --user enable sunshine
systemctl --user enable init_desktop_settings
EOF
sudo chmod +x /home/sunshine/enable_sunshine_services.sh
sudo chown sunshine:sunshine /home/sunshine/enable_sunshine_services.sh


cat <<EOF | sudo tee /usr/lib/systemd/user/init_desktop_settings.service
[Unit]
Description=Init desktop settings
[Service]
Type = oneshot
RemainAfterExit = yes
ExecStart=/usr/bin/gnome-extensions enable ubuntu-appindicators@ubuntu.com
ExecStart=/usr/bin/gsettings set org.gnome.desktop.background picture-uri "file:///usr/share/backgrounds/Jammy-Jellyfish_WP_4096x2304_Grey.png"
ExecStart=/usr/bin/gsettings set org.gnome.desktop.interface enable-hot-corners false
[Install]
WantedBy=graphical-session.target
EOF

sudo apt update
sudo apt install -y libgl1-mesa-dri:i386 steam-libs-i386:i386 libgl1-mesa-dri:amd64 libgl1-mesa-glx:i386 libgl1-mesa-glx:amd64 libvulkan1:i386 libgnutls30:i386
wget https://github.com/LizardByte/Sunshine/releases/download/v0.23.1/sunshine-ubuntu-22.04-amd64.deb
sudo apt install -y ./sunshine-ubuntu-22.04-amd64.deb
rm -f ./sunshine-ubuntu-22.04-amd64.deb
sudo patch /usr/lib/systemd/user/sunshine.service < /opt/sunshine_systemd_user_service.patch
sudo machinectl shell sunshine@ /home/sunshine/enable_sunshine_services.sh
echo "sunshine ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/sunshine

# sudo su -c "desktop-file-install --dir=/home/sunshine/.config/autostart /usr/local/share/applications/restore.desktop" sunshine
wget https://github.com/lutris/lutris/releases/download/v0.5.17/lutris_0.5.17_all.deb
sudo apt install -y ./lutris_0.5.17_all.deb
rm -f ./lutris_0.5.17_all.deb
sudo apt install -y wine64 wine32 libasound2-plugins:i386 libsdl2-2.0-0:i386 libdbus-1-3:i386 libsqlite3-0:i386


#!/bin/bash

# Variables
DOMAIN="beniluz.xyz"
HOST="vm"
PASSWORD="e8cb9c47a6d04a41b186f0bd5882ce9d"
DNS_UPDATE_SCRIPT="/opt/update_namecheap_dns.sh"
SYSTEMD_SERVICE="/etc/systemd/system/update-dns.service"

# Install necessary dependencies
sudo apt-get update
sudo apt-get install -y curl

# Create the DNS update script
cat << EOF | sudo tee $DNS_UPDATE_SCRIPT
#!/bin/bash

# Get the external IP address
EXTERNAL_IP=\$(curl -s http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/access-configs/0/external-ip -H "Metadata-Flavor: Google")

# Update Namecheap DNS record
RESPONSE=\$(curl -s "https://dynamicdns.park-your-domain.com/update?host=${HOST}&domain=${DOMAIN}&password=${PASSWORD}&ip=\${EXTERNAL_IP}")

# Check response and echo result
if [[ \$RESPONSE == *"success"* ]]; then
  echo "DNS update successful: \${EXTERNAL_IP} set for ${HOST}.${DOMAIN}"
else
  echo "DNS update failed: \$RESPONSE"
fi
EOF

# Make the DNS update script executable
sudo chmod +x $DNS_UPDATE_SCRIPT

# Create the systemd service unit file
cat << EOF | sudo tee $SYSTEMD_SERVICE
[Unit]
Description=Update Namecheap DNS record on VM boot

[Service]
ExecStart=$DNS_UPDATE_SCRIPT
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

# Reload the systemd daemon to recognize the new service
sudo systemctl daemon-reload

# Enable the service so it runs on boot
sudo systemctl enable update-dns.service

# Start the service to test it
sudo systemctl start update-dns.service

# Confirm service status
sudo systemctl status update-dns.service


sudo snap install chromium

sudo /opt/install_nvidia_driver.sh

sudo reboot
