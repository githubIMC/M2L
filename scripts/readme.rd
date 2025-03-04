apt install tftpd-hpa xinetd
nano /etc/default/tftpd-hpa

# /etc/default/tftpd-hpa

TFTP_USERNAME="tftp"
TFTP_DIRECTORY="/srv/tftp"
TFTP_ADDRESS=":69"
TFTP_OPTIONS="--secure --create"

mkdir -p /srv/tftp
chown tftp:tftp /srv/tftp
chmod 777 /srv/tftp

systemctl restart tftpd-hpa
systemctl enable tftpd-hpa
