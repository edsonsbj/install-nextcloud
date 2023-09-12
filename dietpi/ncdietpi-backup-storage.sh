# Change data directory for external storage
sudo lsblk

# Prompt the user to select the correct folder
while true; do
    read -p "Where is the main volume? Please enter (a) 'sda1', (b) 'sdb1', (c) 'sdc1', or (d) 'sdd1': " drive_option
    case $drive_option in
        [aA])
            drive="/dev/sda1"
            break
            ;;
        [bB])
            drive="/dev/sdb1"
            break
            ;;
        [cC])
            drive="/dev/sdc1"
            break
            ;;
        [dD])
            drive="/dev/sdd1"
            break
            ;;
        *)
            echo "Invalid input. Please enter 'a', 'b', 'c', or 'd'."
            ;;
    esac
done

# Confirm user's choice
while true; do
    read -p "You selected $drive. Is this correct? (Y/N): " confirm
    case $confirm in
        [yY])
            break
            ;;
        [nN])
            # Repeat the drive selection process
            while true; do
                read -p "Where is the main volume? Please enter (a) 'sda1', (b) 'sdb1', (c) 'sdc1', or (d) 'sdd1': " drive_option
                case $drive_option in
                    [aA])
                        drive="/dev/sda1"
                        break
                        ;;
                    [bB])
                        drive="/dev/sdb1"
                        break
                        ;;
                    [cC])
                        drive="/dev/sdc1"
                        break
                        ;;
                    [dD])
                        drive="/dev/sdd1"
                        break
                        ;;
                    *)
                        echo "Invalid input. Please enter 'a', 'b', 'c', or 'd'."
                        ;;
                esac
            done
            ;;
        *)
            echo "Invalid input. Please enter 'Y' or 'N'."
            ;;
    esac
done

# Display a warning message
echo "WARNING: Formatting $drive will result in data loss!"
while true; do
    read -p "Do you want to continue? (Y/N): " continue_format
    case $continue_format in
        [yY])
            break
            ;;
        [nN])
            echo "Formatting aborted. Exiting script."
            exit 1
            ;;
        *)
            echo "Invalid input. Please enter 'Y' or 'N'."
            ;;
    esac
done

# Install required packages and format the selected drive
sudo apt install btrfs-progs -y
sudo umount "$drive"
sudo mkfs.btrfs -f "$drive"
sudo mkdir /media/myCloudBackup

echo "Drive $drive has been formatted and is ready for use."


echo -e "\033[1;32mInstalling RCLONE from DietPi Market.\033[0m"
/boot/dietpi/dietpi-software install 202
echo -e "\033[1;32mInstalling GIT from DietPi Market.\033[0m"
/boot/dietpi/dietpi-software install 17
echo -e "\033[1;32mAll softwares needed from market were installed.\033[0m"

sudo apt install borgbackup -y
