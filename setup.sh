#!/bin/sh

# Check for user-id and exit if not root
if [ $(id -u) -ne 0 ] 
then
	echo "[!] You need to run this as root!"
	exit 1
fi

# Installing required packages

echo "[+] Install requirements..."
apt update && apt install cryptsetup -y

# Delete all unused images and container to free up space, stop docker daemon
# and move all remaining stuff to a temporary directory
echo "[i] Remove all unused docker stuff..."
docker container prune
docker images prune

echo "[i] Stopping docker " 
systemctl stop docker.service docker.socket

echo "[-] Move remaining images & Container to temp folder"
mkdir /root/docker
mv /var/lib/docker/* /root/docker/

echo "[i] Creating Vault, encrypt it and create filesystem"
# Creating directory for the vault
mkdir /var/lib/docker-vault
cd /var/lib/docker-vault

# Ask for vault size
read -p "[?] Size in GB of vault as int: " VAULT_SIZE

# Creating Vault-Frame, encrypt it and create a file system on it.
echo "[+] Generate Vault-Frame with $VAULT_SIZE GB in size. Please wait, this can take some time..."
dd if=/dev/random of=docker.crypt bs=1G count=$VAULT_SIZE status=progress
cryptsetup luksFormat ./docker.crypt
echo "[!] Open Vault for the first time"
cryptsetup luksOpen ./docker.crypt docker.crypt

mkfs.ext4 /dev/mapper/docker.crypt

echo "[i] Integrate Vault to docker"
# mount the vault and put everyting inside
mount /dev/mapper/docker.crypt /var/lib/docker
echo "[+] Moving data to vault, this can take some time..."
mv /root/docker/* /var/lib/docker/
rmdir /root/docker

echo "[i] Restart and Test docker with hello-world"
# restart docker and run hello-world
systemctl start docker.service docker.socket
docker run --rm hello-world

echo "[-] Disable Docker on startup to avoid crashes."
systemctl disable docker.service
 
echo "[+] Modifie docker.service file to checko if docker.crypt exist"
sed -i '/\[Unit\]/a ConditionPathExists = /dev/mapper/docker.crypt' /lib/systemd/system/docker.service
systemctl daemon-reload

echo "[+] Create lock & unlock scripts under /var/lib/docker-vault/"

# Gen Unlock-Docker Script
echo "#!/bin/bash
if [ $(id -u) -ne 0 ] 
then
	echo "[!] You need to run this as root!"
	exit 1
fi
echo 'Unlock Docker-Vault & start service'
if [ -e /dev/mapper/docker.crypt ] 
then
    echo 'Docker is already unlocked!'
    exit 0
fi
rm -rf /var/lib/docker/*
cryptsetup luksOpen /var/lib/docker-vault/docker.crypt docker.crypt && 
mount /dev/mapper/docker.crypt /var/lib/docker && 
systemctl start docker.service docker.socket
" > /var/lib/docker-vault/unlock-docker.sh && chmod u+x /var/lib/docker-vault/unlock-docker.sh

# Gen Lock-Docker Script
echo "#!/bin/bash
if [ $(id -u) -ne 0 ] 
then
	echo "[!] You need to run this as root!"
	exit 1
fi


echo 'Lock Docker-Vault & tart service'
systemctl stop docker.service docker.socket
umount /var/lib/docker
cryptsetup luksClose docker.crypt
" > /var/lib/docker-vault/lock-docker.sh && chmod u+x /var/lib/docker-vault/lock-docker.sh

echo "[!] Done!"

