## Simple flake with NixOS configuration

### Install on VM

- Create VM:
  ```bash
  virt-install --connect qemu:///system \
      --console pty,target.type=virtio \
      --graphics none \
      --name nixos \
      --memory 2048 \
      --vcpus 1 \
      --disk size=20 \
      --boot uefi \
      --os-variant detect=on \
      --cdrom ~/downloads/latest-nixos-minimal-x86_64-linux.iso
  ```
- Partitioning and formatting according to the [NixOS
  manual](https://nixos.org/manual/nixos/stable/index.html#sec-installation-partitioning)
  (UEFI).
- Generate `hardware-configuration.nix`:
  ```bash
  nixos-generate-config --root /mnt && rm /mnt/etc/nixos/configuration.nix
  ```
- Clone the repo and update the hw-config input:
  ```bash
  nix-shell -p git nixUnstable
  git clone https://github.com/name-snrl/learn_nix_flake
  cd learn_nix_flake/configuration/
  sed -i 's#file:///etc#file:///mnt/etc#g' flake.nix
  nix --extra-experimental-features 'nix-command flakes' flake update
  ```
- Install NixOS - `nixos-install --flake .#nixos`
