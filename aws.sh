#!/bin/bash

# Comprovació que estem amb root
if [ "$(id -u)" != "0" ]; then
   echo "Aquest programa s'ha d'executar amb l'usuari root" 1>&2;
   exit 1;
else
    echo "Espereu mentre descarreguem els paquets necessaris per iniciar la instal·lació"  1>&2;
fi


# Comprovacions prèvies
apt update > /dev/null 2> /dev/null;
apt install dialog gcc make net-tools unzip -y > /dev/null 2> /dev/null;


# Variables globals
userPass="";

# Contrasenya d'usuari pel XAMPP -> preguntem mentre no s'indiqui dues vegades la mateixa
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

# Diàleg de descarrega del XAMPP
dialog --title "XAMPP" --infobox "Espereu mentre instal·lem i configurem XAMPP. Aquesta operació pot trigar uns minuts." 5 50;

# Descarreguem, instal·lem i configurem XAMPP
wget https://github.com/smx-m14/aws/raw/main/xampp/xampp.zip.001 > /dev/null 2> /dev/null;
wget https://github.com/smx-m14/aws/raw/main/xampp/xampp.zip.002 > /dev/null 2> /dev/null;
wget https://github.com/smx-m14/aws/raw/main/xampp/xampp.zip.003 > /dev/null 2> /dev/null;
wget https://github.com/smx-m14/aws/raw/main/xampp/xampp.zip.004 > /dev/null 2> /dev/null;
wget https://github.com/smx-m14/aws/raw/main/xampp/xampp.zip.005 > /dev/null 2> /dev/null;
wget https://github.com/smx-m14/aws/raw/main/xampp/xampp.zip.006 > /dev/null 2> /dev/null;
wget https://github.com/smx-m14/aws/raw/main/xampp/xampp.zip.007 > /dev/null 2> /dev/null;
cat xampp* > xampp.zip;
unzip xampp.zip > /dev/null 2> /dev/null;
chmod u+x xampp.run > /dev/null 2> /dev/null;
./xampp.run --mode unattended > /dev/null 2> /dev/null;
/opt/lampp/lampp restart > /dev/null 2> /dev/null;
rm xampp* > /dev/null 2> /dev/null;

# Diàleg XAMPP instal·lat
dialog --title "XAMPP" --infobox "XAMPP correctament instal·lat." 5 50;

# Canvi de password de l'usuari pma i root de mysql
/opt/lampp/bin/mysql --user="root" --database="mysql" --execute="update user set Password=password('$userPass') where User = 'pma';"
/opt/lampp/bin/mysql --user="root" --execute="ALTER USER 'pma'@'localhost' IDENTIFIED BY '$userPass';"
/opt/lampp/bin/mysql --user="root" --execute="ALTER USER 'root'@'localhost' IDENTIFIED BY '$userPass';"
/opt/lampp/bin/mysql --user="root" --password="$userPass" --execute="FLUSH PRIVILEGES;"
/opt/lampp/bin/mysqladmin reload;

# Desactiva XAMPP per xarxa
sed -i 's/#skip-networking/skip-networking/' /opt/lampp/etc/my.cnf;

# Configuració phpmyadmin
sed -i 's/AllowOverride AuthConfig Limit/AllowOverride AuthConfig/' /opt/lampp/etc/extra/httpd-xampp.conf
sed -i 's/Require local/Require all granted/' /opt/lampp/etc/extra/httpd-xampp.conf

cat /opt/lampp/phpmyadmin/config.inc.php | grep -v 'controlpass' | grep -v 'password' | grep -v 'auth_type' > config.inc.php
echo "\$cfg['Servers'][\$i]['auth_type'] = 'cookie';" >> config.inc.php;
echo "\$cfg['Servers'][\$i]['controlpass'] = '$userPass';" >> config.inc.php;
echo "\$cfg['Servers'][\$i]['password'] = '$userPass';" >> config.inc.php;
mv config.inc.php /opt/lampp/phpmyadmin/config.inc.php

# Fem que daemon funcioni amb la contrasenya establida
chown -R daemon:daemon /opt/lampp/htdocs;
sed -i 's/UserPassword/#UserPassword/' /opt/lampp/etc/proftpd.conf;
echo "PassivePorts           30000 30100" >> /opt/lampp/etc/proftpd.conf;
echo "daemon:$userPass" | chpasswd;

/opt/lampp/lampp restart > /dev/null 2> /dev/null;


# Archive unzipper
cd /opt/lampp/htdocs
wget https://raw.githubusercontent.com/smx-m14/aws/main/unzipper/unzipper.php > /dev/null 2> /dev/null;


# Creem arxiu d'arrencada automàtica pel XAMPP
echo "[Unit]
Description=XAMPP

[Service]
ExecStart=/opt/lampp/lampp start
ExecStop=/opt/lampp/lampp stop
Type=forking

[Install]
WantedBy=multi-user.target" > /etc/systemd/system/xampp.service

# Habilitem servei
systemctl enable xampp

# Instal·lació NO-IP
dialog --title "NO-IP" --msgbox "Ara configurarem el servei NO-IP en el servidor. Tingueu en compte que necessiteu tenir creat el compte a https://www.noip.com/ i un domini per poder-lo configurar.\n\nContesteu les preguntes del script de configuració a continuació:" 12 50 

cd /usr/local/src/;
wget http://www.noip.com/client/linux/noip-duc-linux.tar.gz  > /dev/null 2> /dev/null;
tar xf noip-duc-linux.tar.gz  > /dev/null 2> /dev/null;
cd noip-2.1.9-1/  > /dev/null 2> /dev/null;

# Servei NO IP --> repetim mentre la configuració no sigui correcta
exitCode2=1;
while [[ $exitCode2 -ne 0 ]]
do
    make install;
    exitCode2=$?;
    echo "finalització noip $exitCode2";
    
    #if [[ $exitCode2 -ne 0 ]]
    #then
    #    dialog --title "NO-IP" --msgbox "La configuració de NO-IP no s'ha pogut completar correctament. Si us plau, reviseu totes les dades introduïdes." 12 50 
    #fi
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

systemctl enable noip;
systemctl start noip;

dialog --title "Configuració finalitzada" --msgbox "El vostre servidor web ha estat correctament configurat. Espereu uns minuts per accedir al vostre domini no-ip i veure el lloc web funcionant.\n\nRecordeu que usareu els noms d'usuari habituals del XAMPP amb la contrasenya que hàgiu indicat al principi." 14 50

# Netegem pantalla
cd;
history -c;
clear;
