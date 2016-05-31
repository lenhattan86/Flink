# https://www.digitalocean.com/community/tutorials/introduction-to-ganglia-on-ubuntu-14-04
# http://www.ubuntugeek.com/install-ganglia-on-ubuntu-14-04-server-trusty-tahr.html
# install Ganglia monitor
sudo apt-get install -y ganglia-monitor
sudo vi /etc/ganglia/gmond.conf
# modify cluster, udp_send_channel sections
# comment out udp_recv_channel
# restart all related services
sudo service ganglia-monitor restart 
