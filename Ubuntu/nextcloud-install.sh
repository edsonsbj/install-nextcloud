#!/bin/bash

# Verifique se o script está sendo executado com privilégios de superusuário (root).
if [ "$EUID" -ne 0 ]
  then echo "Por favor, execute este script como superusuário (sudo)."
  exit
fi

## Verificar se o site está online
elif ! wget --spider https://download.nextcloud.com/server/releases/latest.zip; then
    echo "O site https://download.nextcloud.com não está online. Verifique a conexão com a Internet."
    exit 1
fi

# Definir uma senha aleatória para o usuário do banco de dados e o usuário admin do nextcloud
DB_PASS=$(openssl rand -base64 12)
ADMIN_PASS=$(openssl rand -base64 12)

# Criar um arquivo de log para gravar as saídas dos comandos
LOG_FILE=/var/log/nextcloud_install.log
touch $LOG_FILE
exec > >(tee -a $LOG_FILE)
exec 2>&1

# Atualize o sistema.
apt update
apt -y full-upgrade

# Instala o Apache
sudo apt install apache2 apache2-utils -y

# Instala o MariaDB
sudo apt install mariadb-server mariadb-client -y


# Instala o PHP 8.2 e extensões necessárias
# Solicitar ao usuário a escolha entre Debian e Ubuntu
echo "Bem-vindo ao instalador PHP para Debian ou Ubuntu!"
while true; do
    read -p "Digite 'Debian' ou 'Ubuntu' para escolher a distribuição desejada: " distro
    case $distro in
        Debian)
            # Comandos para DEBIAN
            sudo apt install apt-transport-https lsb-release ca-certificates wget -y
            sudo wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg 
            sudo sh -c 'echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list'
            sudo apt update
            sudo apt install unzip imagemagick php8.2 php8.2-{fpm,cli,curl,gd,mbstring,xml,zip,bz2,intl,bcmath,gmp,imagick,mysql} -y
            break
            ;;
        Ubuntu)
            # Comandos para Ubuntu
            sudo apt install software-properties-common -y
            sudo add-apt-repository ppa:ondrej/php -y
            sudo apt update
            sudo apt install unzip imagemagick php8.2 php8.2-{fpm,cli,curl,gd,mbstring,xml,zip,bz2,intl,bcmath,gmp,imagick,mysql} -y
            break
            ;;
        *)
            echo "Escolha inválida. Por favor, digite 'Debian' ou 'Ubuntu'."
            ;;
    esac
done

# Instala o Redis
sudo apt install redis-server php-redis -y

# Configura o PHP-FPM
sed -i 's/memory_limit = .*/memory_limit = 512M/' /etc/php/8.2/fpm/php.ini
sed -i 's/;date.timezone.*/date.timezone = America\/\Sao_Paulo/' /etc/php/8.2/fpm/php.ini
sed -i 's/upload_max_filesize = .*/upload_max_filesize = 10240M/' /etc/php/8.2/fpm/php.ini
sed -i 's/post_max_size = .*/post_max_size = 10240M/' /etc/php/8.2/fpm/php.ini

# Cria o VirtualHost para o Nextcloud
sudo tee -a /etc/apache2/sites-available/nextcloud.conf <<EOF
<VirtualHost *:80>
   ServerAdmin no-reply@iclouud.com.br
   DocumentRoot "/var/www/nextcloud"
   ServerName nextcloud
 <Directory "/var/www/nextcloud/">
   Options MultiViews FollowSymlinks
  
   AllowOverride All
   Order allow,deny
   Allow from all
 </Directory>
   TransferLog /var/log/apache2/nextcloud_access.log
   ErrorLog /var/log/apache2/nextcloud_error.log
</VirtualHost>
EOF

# Reinicia e aplica as alterações no Apache e PHP
sudo a2dismod php8.2
sudo a2enmod proxy_fcgi setenvif
sudo a2enconf php8.2-fpm
sudo phpenmod redis
sudo a2ensite nextcloud.conf
sudo a2dissite 000-default.conf
sudo a2enmod rewrite headers env dir mime setenvif ssl
sudo systemctl restart apache2
sudo systemctl restart php8.2-fpm

# Cria o Banco de Dados
sudo mysql -e "CREATE DATABASE nextcloud;"
sudo mysql -e "CREATE USER 'nextcloud'@'localhost' IDENTIFIED BY '$DB_PASS';"
sudo mysql -e "GRANT ALL PRIVILEGES ON nextcloud.* TO 'nextcloud'@'localhost';"
sudo mysql -e "FLUSH PRIVILEGES;"

# Baixa e instala o Nextcloud
wget https://download.nextcloud.com/server/releases/latest.zip
unzip latest.zip
mv nextcloud /var/www/
chown -R www-data:www-data /var/www/nextcloud
chmod -R 755 /var/www/nextcloud

# Executar o script de instalação do nextcloud
sudo -u www-data php /var/www/nextcloud/occ maintenance:install --database "mysql" --database-name "$NC_DB" --database-user "$NC_USER" --database-pass "$DB_PASS" --admin-user $USER --admin-pass "$ADMIN_PASS"

# Exibir as senhas geradas no final do script
echo "As senhas geradas são as seguintes:"
echo "Senha do usuário admin do nextcloud: '$ADMIN_PASS'"

echo "A instalação do Nextcloud foi concluída com sucesso!"
