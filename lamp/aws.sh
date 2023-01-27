#!/bin/bash

# Comprovació que estem amb root
if [ "$(id -u)" != "0" ]; then
   echo "Aquest programa s'ha d'executar amb l'usuari root" 1>&2;
   exit 1;
else
	echo "Espereu mentre descarreguem els paquets necessaris per iniciar la instal·lació"  1>&2;
fi

# Comprovacions prèvies i paquets mínims
apt update > /dev/null 2> /dev/null;
apt install dialog unzip -y > /dev/null 2> /dev/null;

# Variables globals
userPass="";

# Contrasenya d'usuari -> preguntem mentre no s'indiqui dues vegades la mateixa
exitCode1=1;
while [[ $exitCode1 -ne 0 ]]
do
   userPass=$(dialog --title "Contrasenyes pel XAMPP" --insecure --clear --passwordbox "Indiqueu la contrasenya del vostre compte d'usuari" 10 50 3>&1- 1>&2- 2>&3- );
   exitCode1=$?;
   
   userPassC=$(dialog --title "Contrasenyes pel XAMPP" --insecure --clear --passwordbox "Confirmeu la contrasenya del vostre compte d'usuari" 10 50 3>&1- 1>&2- 2>&3- );
   exitCode2=$?;
   
   #Comprovar que no sigui buida i que coincideixin.
   if [ -z "$userPass" ]
   then
 	dialog --msgbox "La contrasenya no pot ser buida. Si us plau, introduïu una contrasenya vàlida." 7 50
 	exitCode1=1;   
   fi
   
   if [ "$userPass" != "$userPassC" ]
   then
 	dialog --msgbox "Les contrasenyes indicades no coincideixen. Si us plau, introduïu-les de nou." 7 50
 	exitCode1=1;   
   fi
done

# Instal·lem tota la resta de paquets pel servidor
apt install -y apache2 mysql-server libapache2-mod-php8.1 php8.1-intl php8.1-gmp php8.1-bcmath php-imagick  php8.1-sqlite3 dbconfig-common dbconfig-mysql default-mysql-client icc-profiles-free  javascript-common libjs-bootstrap4 libjs-codemirror libjs-jquery libjs-jquery-mousewheel libjs-jquery-timepicker libjs-jquery-ui libjs-popper.js libjs-sizzle libjs-sphinxdoc libjs-underscore libonig5 libzip4 mysql-client-8.0 mysql-client-core-8.0 mysql-common node-jquery php-bz2 php-cli php-common php-curl php-gd php-google-recaptcha php-json   php-mariadb-mysql-kbs php-mbstring php-mysql php-nikic-fast-route   php-phpmyadmin-motranslator php-phpmyadmin-shapefile php-phpmyadmin-sql-parser php-phpseclib php-psr-cache php-psr-container php-psr-log php-symfony-cache php-symfony-cache-contracts php-symfony-config php-symfony-dependency-injection php-symfony-deprecation-contracts php-symfony-expression-language php-symfony-filesystem php-symfony-polyfill-php80 php-symfony-polyfill-php81   php-symfony-service-contracts php-symfony-var-exporter php-tcpdf php-twig   php-twig-i18n-extension php-xml php-zip php8.1-bz2 php8.1-cli php8.1-common php8.1-curl php8.1-gd php8.1-mbstring php8.1-mysql php8.1-opcache php8.1-readline php8.1-xml php8.1-zip gcc make > /dev/null 2> /dev/null;

# Habilitem mòdul manualment
sudo phpenmod mbstring > /dev/null 2> /dev/null;

# Permisos per la carpeta www-data
usermod -m -d /var/www/html/ www-data  > /dev/null 2> /dev/null;
usermod -s /bin/bash www-data  > /dev/null 2> /dev/null;
echo "www-data:$userPass" | chpasswd;

# Habilitem mysql a l'inici
sudo systemctl enable mysql  > /dev/null 2> /dev/null;

# Descarreguem i configurem phpmyadmin
cd /tmp;
wget https://files.phpmyadmin.net/phpMyAdmin/5.2.0/phpMyAdmin-5.2.0-all-languages.zip  > /dev/null 2> /dev/null;
unzip phpMyAdmin-5.2.0-all-languages.zip > /dev/null 2> /dev/null;
mv phpMyAdmin-5.2.0-all-languages phpmyadmin > /dev/null 2> /dev/null;
sudo mv phpmyadmin /var/www/ > /dev/null 2> /dev/null;
cd /var/www/phpmyadmin > /dev/null 2> /dev/null;
sudo mv config.sample.inc.php config.inc.php > /dev/null 2> /dev/null;
echo "\$cfg['blowfish_secret'] = '{[bbcI]yh#s@rk+&(nr;mSmaH|qZiQs[';" >> config.inc.php;
echo "\$cfg['Servers'][\$i]['controluser'] = 'pma';" >> config.inc.php;
echo "\$cfg['Servers'][\$i]['controlpass'] = '$userPass';" >> config.inc.php;
sudo sed -i "29 i\    	Alias /phpmyadmin /var/www/phpmyadmin" /etc/apache2/sites-available/000-default.conf;

sudo systemctl start mysql > /dev/null 2> /dev/null;
sudo mysql --execute "ALTER USER 'root'@'localhost' IDENTIFIED WITH caching_sha2_password BY '$userPass'" > /dev/null 2> /dev/null;
mysql -uroot -p"$userPass" < /var/www/phpmyadmin/sql/create_tables.sql > /dev/null 2> /dev/null;
sudo mysql -uroot -p"$userPass" --execute "CREATE USER 'pma'@'localhost' IDENTIFIED WITH caching_sha2_password BY '$userPass'" > /dev/null 2> /dev/null;
sudo mysql -uroot -p"$userPass" --execute "GRANT SELECT, INSERT, UPDATE, DELETE ON phpmyadmin.* TO 'pma'@'localhost'" > /dev/null 2> /dev/null;


# Descarreguem i instal·lem unzipper
cd /var/www/html
rm index.html > /dev/null 2> /dev/null;
wget https://raw.githubusercontent.com/smx-m14/aws/main/landing/index.html > /dev/null 2> /dev/null;
wget https://raw.githubusercontent.com/smx-m14/aws/main/unzipper/unzipper.php > /dev/null 2> /dev/null;

# Instal·lem i configurem FTP
sudo apt install -y proftpd-basic > /dev/null 2> /dev/null;
sudo chown -R www-data:www-data /var/www/ > /dev/null 2> /dev/null;
sudo sed -i "73 i\DefaultRoot /var/www/html" /etc/proftpd/proftpd.conf;
sed -i 's/User proftpd/User www-data/' /etc/proftpd/proftpd.conf;
sed -i 's/Group nogroup/Group www-data/' /etc/proftpd/proftpd.conf;
sed -i 's/# PassivePorts 49152 65534/PassivePorts 30000 30100/' /etc/proftpd/proftpd.conf;

# Habilitem i arrenquem tots els serveis
sudo systemctl enable proftpd > /dev/null 2> /dev/null;
sudo systemctl enable apache2 > /dev/null 2> /dev/null;
sudo systemctl restart proftpd > /dev/null 2> /dev/null;
sudo systemctl restart apache2 > /dev/null 2> /dev/null;
sudo systemctl restart mysql > /dev/null 2> /dev/null;


# Instal·lació NO-IP
dialog --title "NO-IP" --msgbox "Ara configurarem el servei NO-IP en el servidor. Tingueu en compte que necessiteu tenir creat el compte a https://www.noip.com/ i un domini per poder-lo configurar.\n\nContesteu les preguntes del script de configuració a continuació:\n  * Correu\n  * Contrasenya\n\nLa resta de preguntes es poden contestar amb Enter." 17 50 
clear;
cd /usr/local/src/;
wget http://www.noip.com/client/linux/noip-duc-linux.tar.gz  > /dev/null 2> /dev/null;
tar xf noip-duc-linux.tar.gz  > /dev/null 2> /dev/null;
cd noip-2.1.9-1/  > /dev/null 2> /dev/null;

# Servei NO IP --> repetim mentre la configuració no sigui correcta
lines=0;
while [ $lines -ne 1 ]
do
   make install 2>&1 | tee /tmp/noip.txt;
   lines=`cat /tmp/noip.txt | grep "It will be used" | wc -l`;
   
   if [ $lines -ne 1 ]
   then
        dialog --title "NO-IP" --msgbox "La configuració de NO-IP no s'ha pogut completar correctament. Si us plau, reviseu tots els paràmetres de configuració." 8 50     
   fi
done

# Configurem inici automàtic NO IP
echo "[Unit]
Description=NOIP
[Service]
Type=forking
ExecStart=/usr/local/bin/noip2
Restart=always
[Install]
WantedBy=multi-user.target" > /etc/systemd/system/noip.service

systemctl enable noip 2> /dev/null > /dev/null;
systemctl start noip 2> /dev/null > /dev/null;

dialog --title "Configuració finalitzada" --msgbox "El vostre servidor web ha estat correctament configurat. Espereu uns minuts per accedir-hi per primera vegada" 8 50

# Netegem pantalla
clear;
history -c;

