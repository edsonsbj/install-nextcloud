# Change data directory for external storage
sudo lsblk

# Prompt the user to select the correct folder
while true; do
    read -p "Where the main volume? Please enter (a) 'sda1' or (b) 'sdb1': " drive_option
    case $drive_option in
        [aA])
            drive="/dev/sda1"
            break
            ;;
        [bB])
            drive="/dev/sdb1"
            break
            ;;
        *)
            echo "Invalid input. Please enter 'a' or 'b'."
            ;;
    esac
done

sudo -u www-data php /var/www/nextcloud/occ maintenance:mode --on

sudo apt install btrfs-progs -y
sudo umount "$drive"
sudo mkfs.btrfs -f "$drive"
sudo mkdir /media/myCloudDrive          # Change this if you want to mount the drive elsewhere, like /mnt/, or change
UUID=$(sudo blkid -s UUID -o value "$drive")
echo "UUID=$UUID /media/myCloudDrive btrfs defaults 0 0" | sudo tee -a /etc/fstab
sudo mount -a
sudo systemctl daemon-reload

rsync -avh /mnt/dietpi_userdata/nextcloud_data /media/myCloudDrive
chown -R www-data:www-data /media/myCloudDrive/nextcloud_data
chmod -R 770 /media/myCloudDrive/nextcloud_data
sudo -u www-data php /var/www/nextcloud/occ maintenance:mode --off

#sudo -u www-data /usr/bin/php /var/www/nextcloud/occ files:scan-app-data #To “reset” the preview cache
sudo systemctl restart redis-server
sudo systemctl restart apache2

# If Using Swap

sudo swapoff -a
sudo fallocate -l 8G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
sudo swapon --show
free -h
