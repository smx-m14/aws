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
apt install dialog gcc make net-tools -y > /dev/null 2> /dev/null;

# Funcions
askPassword() {
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
}


# Variables globals
userPass="Thos123!";


exitCode1=1;
while [[ $exitCode1 -ne 0 ]]
do
   askPassword;
done


# Demanar password per la màquina
#echo "root:$userPass" | chpasswd;
#echo "ubuntu:$userPass" | chpasswd;
# No ho fem, ho farem amb el certificat?


# TO DO: COMPTE CAL BUSCAR EL NOM D'ARXIU!!!!
# Si no fem la part de dalt, aquesta tampoc
# Permetem l'accés per password a la consola i reiniciem servei
#sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' filename
#service sshd restart

# TO DO: UNA ADREÇA DE XAMPP QUE SERVEIXI, ARA NO HI HA 7.4.33 --> MILLOR FER MIRROR

# Instal·lem i configurem XAMPP
wget https://sourceforge.net/projects/xampp/files/XAMPP%20Linux/7.4.21/xampp-linux-x64-7.4.21-1-installer.run/download > /dev/null 2> /dev/null;
mv download xampp.run;
chmod u+x xampp.run;
./xampp.run --mode unattended > /dev/null 2> /dev/null;
/opt/lampp/lampp restart  > /dev/null 2> /dev/null;
rm xampp.run;

# Desactiva XAMPP per xarxa
sed -i 's/#skip-networking/skip-networking/' /opt/lampp/etc/my.cnf

# Canvia password del pma i del root
echo "update user set Password=password('$userPass') where User = 'pma';" | /opt/lampp/bin/mysql -uroot mysql
echo "ALTER USER 'root'@'localhost' IDENTIFIED BY '$userPass';flush privileges;exit;" | /opt/lampp/bin/mysql -uroot
/opt/lampp/bin/mysqladmin reload


# Configuració phpmyadmin
cat /opt/lampp/phpmyadmin/config.inc.php | grep -v 'controlpass' | grep -v 'password' | grep -v 'auth_type' > config.inc.php
echo "\$cfg['Servers'][\$i]['auth_type'] = 'cookie';" >> config.inc.php;
echo "\$cfg['Servers'][\$i]['controlpass'] = '$userPass';" >> config.inc.php;
echo "\$cfg['Servers'][\$i]['password'] = '$userPass';" >> config.inc.php;
mv config.inc.php /opt/lampp/phpmyadmin/config.inc.php
/opt/lampp/lampp restart > /dev/null 2> /dev/null;

# Obrim phpmyadmin per xarxa
sed -i 's/AllowOverride AuthConfig Limit/AllowOverride AuthConfig/' /opt/lampp/etc/extra/httpd-xampp.conf
sed -i 's/Require local/Require all granted/' /opt/lampp/etc/extra/httpd-xampp.conf

# Fem que daemon funcioni amb la contrasenya establida
chown -R daemon:daemon /opt/lampp/htdocs
sed -i 's/UserPassword/#UserPassword/' /opt/lampp/etc/proftpd.conf
echo "PassivePorts           30000 30100" >> /opt/lampp/etc/proftpd.conf
echo "daemon:$userPass" | chpasswd;

/opt/lampp/lampp restart  > /dev/null 2> /dev/null;


# Archive unzipper --> me'l puc guardar al meu repo si cal
cd /opt/lampp/htdocs
wget https://raw.githubusercontent.com/ndeet/unzipper/master/unzipper.php > /dev/null 2> /dev/null;


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


dialog --title "NO-IP" --msgbox "Ara configurarem el servei NO-IP en el servidor. Tingueu en compte que necessiteu tenir creat el compte a https://www.noip.com/ i un domini per poder-lo configurar.\n\nContesteu les preguntes del script de configuració a continuació:" 12 50 

# NO IP
# Mostrar missatge que ja està el XAMPP configurat correctament, ara configurarem NO IP
cd /usr/local/src/
wget http://www.noip.com/client/linux/noip-duc-linux.tar.gz  > /dev/null 2> /dev/null;
tar xf noip-duc-linux.tar.gz  > /dev/null 2> /dev/null;
cd noip-2.1.9-1/  > /dev/null 2> /dev/null;
make install
# comprobar exit code == 0 o reiniciar programa $? o hacer con while

echo "[Unit]
Description=NOIP

[Service]
Type=forking
ExecStart=/usr/local/bin/noip2
Restart=always

[Install]
WantedBy=multi-user.target" > /etc/systemd/system/noip.service

systemctl enable noip
systemctl start noip

dialog --title "Configuració finalitzada" --msgbox "El vostre servidor web ha estat correctament configurat. Espereu uns minuts per accedir al vostre domini no-ip per veure el lloc web funcionant.\n\nRecordeu que usareu els noms d'usuari habituals del XAMPP amb la contrasenya que hàgiu indicat al principi." 14 50


#TO DO: HACER LOS TÍPICOS CLEAR SCREEN Y DE HISTORIAL DE COMANDOS
