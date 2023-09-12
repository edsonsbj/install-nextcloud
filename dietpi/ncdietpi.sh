#!/bin/bash

###################### COLLOR PALETTE ######################
BLACK='\033[0;30m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[0;37m'

BOLD_BLACK='\033[1;30m'
BOLD_RED='\033[1;31m'
BOLD_GREEN='\033[1;32m'
BOLD_YELLOW='\033[1;33m'
BOLD_BLUE='\033[1;34m'
BOLD_MAGENTA='\033[1;35m'
BOLD_CYAN='\033[1;36m'
BOLD_WHITE='\033[1;37m'

BACKGROUND_BLACK='\033[40m'
BACKGROUND_RED='\033[41m'
BACKGROUND_GREEN='\033[42m'
BACKGROUND_YELLOW='\033[43m'
BACKGROUND_BLUE='\033[44m'
BACKGROUND_MAGENTA='\033[45m'
BACKGROUND_CYAN='\033[46m'
BACKGROUND_WHITE='\033[47m'

LIGHT_GREEN='\033[0;92m'  # Light Green
ORANGE='\033[0;33m'       # Orange
PURPLE='\033[0;35m'       # Purple
LIGHT_BLUE='\033[0;94m'   # Light Blue
RESET_COLOR='\033[0m'  # Restaura as configurações de cores para o padrão.

#EXAMPLE
#echo -e "${Blue}Welcome ${WHITE}to ${RED}France"
################## END OF COLLOR PALETTE ###################


###################### STEP 0 ######################
exec > >(tee -i nextcloud-dietpi.log)
exec 2>&1

# Get the local IP address of the device
NEXTCLOUD_IP=$(hostname -I | awk '{print $1}')

# Prompt the user to confirm and use the local IP address
echo -e -n "[ ${BOLD_YELLOW}!${RESET_COLOR} ] Your local IP address is ${YELLOW}$NEXTCLOUD_IP${RESET_COLOR}. Is this correct? (Y/N): "
read confirm

if [[ "$confirm" != "Y" && "$confirm" != "y" ]]; then
    echo "Please configure your local IP address correctly and re-run the script."
    exit 1
fi
################## END OF STEP 0 ###################


###################### STEP 1 ######################
echo -e "${LIGHT_GREEN}Installing rsync from debian repository through 'apt install'.${RESET_COLOR}"
sudo apt install rsync
echo -e "${LIGHT_GREEN}Installing Apache2 from DietPi Market.${RESET_COLOR}"
/boot/dietpi/dietpi-software install 83
echo -e "${LIGHT_GREEN}Installing Nextcloud from DietPi Market.${RESET_COLOR}"
/boot/dietpi/dietpi-software install 114
echo -e "\${LIGHT_GREEN}Installing Docker from DietPi Market.${RESET_COLOR}"
/boot/dietpi/dietpi-software install 162
echo -e "${LIGHT_GREEN}Installing Docker-Composer from DietPi Market.${RESET_COLOR}"
/boot/dietpi/dietpi-software install 134
echo -e "${LIGHT_GREEN}Installing FFMPEG from DietPi Market.${RESET_COLOR}"
/boot/dietpi/dietpi-software install 7
echo -e "${LIGHT_GREEN}Installing PHP-BCMATCH, PHP-GMP e PMP-IMAGICK from debian repository.${RESET_COLOR}"
sudo apt install imagemagick php8.2-{bcmath,gmp,imagick} -y

chown -R www-data:www-data /var/www/nextcloud
chmod -R 755 /var/www/nextcloud


# Install Nginx Proxy Manager
echo -e "${LIGHT_GREEN}Preparing for NGINX PROXY MANAGER installation${RESET_COLOR}"
cd /
sudo mkdir docker/ && cd docker/
cd /docker/
sudo mkdir nginx && cd nginx
touch docker-compose.yml
echo -e "Creating docker-compose.yml..."
sudo cat <<EOF >>/docker/nginx/docker-compose.yml
version: '3.8'
services:
  app:
    image: 'jc21/nginx-proxy-manager:latest'
    restart: unless-stopped
    ports:
      - '8880:80' # CHANGE THE PORT 8880 TO AN HTTP PORT OF YOUR CHOICE
      - '81:81'
      - '8443:443' # CHANGE THE PORT 8443 TO AN HTTPS PORT OF YOUR CHOICE
    volumes:
      - ./data:/data
      - ./letsencrypt:/etc/letsencrypt

EOF

echo -e "${LIGHT_GREEN}Opening folder of docker-compose.yml${RESET_COLOR}"
cd /docker/nginx
echo -e "${LIGHT_GREEN}Installing NGINX PROXY MANAGER using Docker Compose${RESET_COLOR}"
docker compose up -d
echo -e "${LIGHT_GREEN}NGINX PROXY MANAGER INSTALLED VIA DOCKER$${RESET_COLOR}"

echo -e "[ ${BOLD_YELLOW}!${RESET_COLOR} ] All softwares needed were installed.{$RESET_COLOR}"

################## END OF STEP 1 ###################


###################### STEP 2 ######################

# Create the nextcloud.conf file
CONF_FILE="/etc/apache2/sites-available/nextcloud.conf"
cat <<EOF > $CONF_FILE
<VirtualHost *:80>
    ServerName $NEXTCLOUD_IP
    #ServerAlias domain.duckdns.org
    #ServerAdmin webmaster@example.com
    DocumentRoot /var/www/nextcloud

    <Directory /var/www/nextcloud>
        Options FollowSymLinks MultiViews
        AllowOverride All
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/example.com-error.log
    CustomLog \${APACHE_LOG_DIR}/example.com-access.log combined

    SetEnv HOME /var/www/nextcloud
    SetEnv HTTP_HOME /var/www/nextcloud
</VirtualHost>
EOF

echo -e "\033[1;32mCreated $CONF_FILE with the specified content.\033[0m"

#cat $CONF_FILE
#while true; do
#   echo -e "[ ${BOLD_YELLOW}!${RESET_COLOR} ] Is the LOCAL IP address in $CONF_FILE correct for your Nextcloud? (Y/N): "
#   read user_input
#    if [ "$user_input" == "Y" ] || [ "$user_input" == "y" ]; then
#        break
#    elif [ "$user_input" == "N" ] || [ "$user_input" == "n" ]; then
#        nano $CONF_FILE
#    else
#        echo -e "Invalid input. Please enter 'Y' or 'N'."
#    fi
#done

################## END OF STEP 2 ###################

###################### STEP 3 ######################

# Enable the new configuration
sudo a2ensite nextcloud.conf

# Disable other configurations
sudo a2dissite 000-default.conf
sudo a2dissite dietpi-nextcloud.conf

# Restart Apache
sudo systemctl reload apache2

################## END OF STEP 3 ###################

###################### STEP 4 ######################

# Edit config.php and make necessary changes
#sudo sed -i "/'htaccess.RewriteBase' => '\/nextcloud/d" /var/www/nextcloud/config/config.php
#sudo sed -i "s|'http://localhost/nextcloud|'http://localhost|g" /var/www/nextcloud/config/config.php

# Execute maintenance:update:htaccess
sudo -u www-data php /var/www/nextcloud/occ maintenance:update:htaccess
echo -e "\033[1;32mConfig.php updated and maintenance:update:htaccess executed.\033[0m"

################## END OF STEP 4 ###################

###################### STEP 5 ######################
# Prompt user to configure NGINX Proxy Manager
while true; do
    echo -e "[ ${BOLD_YELLOW}!${RESET_COLOR} ] Please configure NGINX Proxy Manager now (E-mail Adsress: ${YELLOW}admin@example.com${RESET_COLOR} | Password: ${YELLOW}changeme${RESET_COLOR}) . Once done, type 'CONTINUE' to proceed with the script: "
    read user_input
    if [ "$user_input" == "CONTINUE" ]; then
        break
    else
        echo -e "Invalid input. Please type 'CONTINUE' to proceed IF NGINX is configured."
    fi
done
################## END OF STEP 5 ###################

###################### STEP 6 ######################

# Check if config.php was created before
config_file='/var/www/nextcloud/config/config.php'
custom_config_file='/var/www/nextcloud/config/custom.config.php'
if [ ! -f "$config_file" ]; then
    echo -e " [ ${BOLD_RED}!${RESET_COLOR} ] File config.php not found ${YELLOW}$config_file{RESET_COLOR}."
    exit 1
fi

cp "$config_file" "$config_file.bak"

while true; do
    # Prompt the user to enter the domain (without 'http', 'https', 'www', or 'http://')
    echo -e -n "Please enter the domain (without 'http', 'https', 'www', or 'http://') for 'overwritehost' (e.g., example.com): "
    read first_domain

    # Remove blank/empty spaces
    first_domain=$(echo "$first_domain" | tr -d '[:space:]')

    # Verify domain format
    if [[ ! "$first_domain" =~ ^[a-zA-Z0-9.-]+$ || "$first_domain" == *":"* ]]; then
        echo  -e " [ ${BOLD_RED}!${RESET_COLOR} ] Invalid domain format or contains ':' symbol at the end. Please try again."
    else
        while true; do
            # Prompt the user to enter the domain again for confirmation
            echo -e -n "Please re-enter the domain to confirm: "
            read second_domain

            # Remove blank/empty spaces
            second_domain=$(echo "$second_domain" | tr -d '[:space:]')

            # Check if the second domain matches the first one
            if [ "$second_domain" == "$first_domain" ]; then
                break 2  # Exit both loops if the domains match
            else
                echo -e " [ ${BOLD_RED}!${RESET_COLOR} ] Domains do not match. Please try again."
            fi
        done
    fi
done

# Now, both domains match and are stored in the 'first_domain' variable
echo -e "[ ${BOLD_YELLOW}!${RESET_COLOR} ] You entered the domain: ${BOLD_GREEN}$first_domain${RESET_COLOR} "

cat <<EOF > "$custom_config_file"
<?php
\$CONFIG = array (
  'default_phone_region' => 'BR',
  'skeletondirectory' => '',
  'enabledPreviewProviders' =>
  array (
    0 => 'OC\\Preview\\PNG',
    1 => 'OC\\Preview\\JPEG',
    2 => 'OC\\Preview\\GIF',
    3 => 'OC\\Preview\\BMP',
    4 => 'OC\\Preview\\XBitmap',
    5 => 'OC\\Preview\\Movie',
    6 => 'OC\\Preview\\PDF',
    7 => 'OC\\Preview\\MP3',
    8 => 'OC\\Preview\\TXT',
    9 => 'OC\\Preview\\MarkDown',
    10 => 'OC\\Preview\\Image',
    11 => 'OC\\Preview\\HEIC',
    12 => 'OC\\Preview\\TIFF',
  ),
  'trashbin_retention_obligation' => 'auto,30',
  'versions_retention_obligation' => 'auto,30',
  'default_language' => 'pt',
  'force_language' => 'pt',
  'default_locale' => 'pt_BR',
  'force_locale' => 'pt_BR',
  'overwritehost' => '${first_domain}:8443',
  'overwriteprotocol' => 'https',
);

EOF

sed -i "s/'overwrite.cli.url' => 'http:\/\/localhost\/nextcloud',/'overwrite.cli.url' => 'http:\/\/localhost\/',/" "$config_file"
sed -i "s/'htaccess.RewriteBase' => '\/nextcloud',/'htaccess.RewriteBase' => '\/',/" "$config_file"

while true; do
    echo -e "File ${YELLOW}$custom_config_file${RESET_COLOR} has been changed. In another SSH Terminal window check if everything is okay. Type 'CONTINUE' to proceed:"
    read user_input
    if [ "$user_input" == "CONTINUE" ]; then
        break
    else
        echo -e "Invalid input. Please type 'CONTINUE' to proceed IF it's done."
    fi
done

sudo -u www-data php /var/www/nextcloud/occ maintenance:update:htaccess
################## END OF STEP 6 ###################

###################### STEP 7 ######################
# Output TODO items with formatting
echo -e "\n\n[ ${BOLD_YELLOW}!${RESET_COLOR} ]Change the password of Nextcloud Admin."
sudo -u www-data php /var/www/nextcloud/occ user:resetpassword admin
echo -e "PASSWORD CHANGE"
################## END OF STEP 7 ###################

echo -e "\n\n${BOLD_GREEN}INSTALLATION COMPLETED!${RESET_COLOR}"
echo -e "LOG of this script can be found saved as ${YELLOW}nextcloud-dietpi.log${RESET_COLOR}"
echo -e "${LIGHT_GREEN}───────────────────────────────────────────────────────────────────────────────────────────────────${RESET_COLOR}"
echo -e "Thank you for using this script!"
echo -e "If you found it helpful, consider supporting the developer by buying a coffee using the link below:"
echo -e "\n${LIGHT_GREEN}buymeacoffee.com/lstavares84${RESET_COLOR}"
echo -e "\nYour contribution helps maintain this project and enables the creation of more useful features in the future."
echo -e "Thank you for your support!"
echo -e "${LIGHT_GREEN}──────────────────────────────────────────────────────────────────────────────────────────────────${RESET_COLOR}"


###################### STEP 8 ######################
unset BLACK RED GREEN YELLOW BLUE MAGENTA CYAN WHITE
unset BOLD_BLACK BOLD_RED BOLD_GREEN BOLD_YELLOW BOLD_BLUE BOLD_MAGENTA BOLD_CYAN BOLD_WHITE
unset BACKGROUND_BLACK BACKGROUND_RED BACKGROUND_GREEN BACKGROUND_YELLOW BACKGROUND_BLUE BACKGROUND_MAGENTA BACKGROUND_CYAN BACKGROUND_WHITE
unset LIGHT_GREEN ORANGE PURPLE LIGHT_BLUE RESET_COLOR
unset NEXTCLOUD_IP confirm CONF_FILE config_file config_file_bak
unset passwordsalt_extracted secret_extracted dbpassword_extracted instanceid_extracted
unset first_domain second_domain
################## END OF STEP 8 ###################
