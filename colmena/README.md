When VM is ready, you must download hardware configuration:
```bash
scp name_snrl@<IP>:/etc/nixos/hardware-configuration.nix hw-config.nix
git add hw-config.nix
```
We're now ready to deploy with colmena:
```bash
colmena apply
```
