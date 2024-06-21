
sed \
  -e 's/\/\/Unattended-Upgrade::Automatic-Reboot/Unattended-Upgrade::Automatic-Reboot/' \
  -e 's/\/\/Unattended-Upgrade::Remove-Unused-Kernel-Packages/Unattended-Upgrade::Remove-Unused-Kernel-Packages/' \
  -e 's/\/\/Unattended-Upgrade::Remove-New-Unused-Dependencies/Unattended-Upgrade::Remove-New-Unused-Dependencies/' \
  < /etc/apt/apt.conf.d/50unattended-upgrades \
  > /tmp/50unattended-upgrades
mv /tmp/50unattended-upgrades /etc/apt/apt.conf.d/

shutdown -r +1