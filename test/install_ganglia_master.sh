# https://www.digitalocean.com/community/tutorials/introduction-to-ganglia-on-ubuntu-14-04
# http://www.ubuntugeek.com/install-ganglia-on-ubuntu-14-04-server-trusty-tahr.html
# install Ganglia monitor, RRDtool, Gmead and Ganglia web front ends
sudo apt-get install -y ganglia-monitor rrdtool gmetad ganglia-webfrontend
# we may restart the Apache2 twice
# 
sudo cp /etc/ganglia-webfrontend/apache.conf /etc/apache2/sites-enabled/ganglia.conf
# change data_source 'my cluster' localhost
sudo vi /etc/ganglia/gmetad.conf
#The gmond.conf file configures where the node sends its information.
sudo vi /etc/ganglia/gmond.conf
# modify cluster, udp_send_channel sections

# restart all related services
sudo service ganglia-monitor restart & sudo service gmetad restart & sudo service apache2 restart
