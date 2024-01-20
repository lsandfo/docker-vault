# docker-vault
A script to create a encrypted place for all you docker content.

---

## Description
Sometimes there is the need for encryption of all, or parts, of the docker content you run on a system.
But sometimes you have no way to setup a full encrypted system, or a encrypted partition or device.
This is where docker-vaults come in!

Docker-Vaults is a bundle of shell scripts that create a encrypted file, containing a filesystem, where all content from docker is saved.


## Details
While bootstrapping the docker-vault with the setup script the following thinks happen:
- All unused images and stopped containeras are optionaly removed to save space.
- All content from /var/lib/docker are temporary moved to directory in under /tmp.
- A encrypted file, in given size of GB, are created under /var/lib/docker-vault/docker.crypt
- A filesystem (actually only ext4, more are planned) are created inside the docker.crypt file.
- The filesystem are mounted under /var/lib/docker 
- All content from the /tmp directory will moved back at /var/lib/docker, which is now inside the encrypted file.
- docker.service will modified to start only if the the docker.crypt file is unlocked and mounted at /var/lib/docker
- a 'lock-docker.sh' and 'unlock-docker.sh' script will created at /var/lib/docker-vault/
- These scripts are for lock/unlocking the docker-vault and start/stop the docker.service



## Planned features
These features are planned:
- Different filesystems, like btrfs or zfs for snapshots and that stuff.
- Scripts to manage the vault, for example resizing.

But before i need to add some more code for better controlling of the setup, since this is a really early version, 
so it's some kind of glas-cannon and will break very easily.
