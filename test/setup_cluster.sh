#!/bin/bash

## NOTES
# 1. We have to install Ganglia web server manually

###########
vmemRatio=4
yarnNodeMem=65536
yarnMaxMem=32768
scheduler="org.apache.hadoop.yarn.server.resourcemanager.scheduler.fair.FairScheduler"
yarnVcores=32
########

cloudLabPubKey="/home/tanle/Dropbox/Papers/System/Flink/cloudlab/cloudlab.pem"
java_home='/usr/lib/jvm/java-8-openjdk-amd64'

hadoopVer="hadoop-2.7.0"
hadoopLink="http://download.nextag.com/apache/hadoop/common/hadoop-2.7.0/hadoop-2.7.0.tar.gz"
hadoopTgz="hadoop-2.7.0.tar.gz"

flinkTar="flink.tar"
flinkVer="flink-1.0.3"
flinkTgz="flink-1.0.3-bin-hadoop27-scala_2.10.tgz"
flinkDownloadLink="http://apache.mesi.com.ar/flink/flink-1.0.3/flink-1.0.3-bin-hadoop27-scala_2.10.tgz"
flinkSrc="/home/tan/projects/Flink"
testCase="/home/tan/projects/Flink/test/wordcount"

REBOOT=false
isTest=true

isInitPath=false

isDownload=true
isExtract=true

isUploadKey=false
isGenerateKey=false
isPasswordlessSSH=false

isInstallJava=true

isInstallGanglia=false
startGanglia=false
if $isInstallGanglia
then
	startGanglia=true
fi

isInstallHadoop=false
isModifyHadoop=false

isShutDownHadoop=false
restartHadoop=true
if $isInstallHadoop
then
	isShutDownHadoop=true
	restartHadoop=true
fi

isInstallFlink=false
isModifyFlink=false
startFlinkYarn=false
shudownFlink=false

startFlinkStandalone=false # not necessary

isUploadTestCase=false

isRun=false


masterNode="nm"
clientNode="ctl"

if $isTest
then
	numOfworkers=1
	serverList="nm cp-1"
	slaveNodes="cp-1"
else
	numOfworkers=8
	serverList="nm cp-1 cp-2 cp-3 cp-4 cp-5 cp-6 cp-7 cp-8 cp-9 cp-10 cp-11 cp-12 cp-13 cp-14"
	slaveNodes="cp-1 cp-2 cp-3 cp-4 cp-5 cp-6 cp-7 cp-8 cp-9 cp-10 cp-11 cp-12 cp-13 cp-14"
fi

############### REBOOT all servers #############################
if $REBOOT
then
	while true; do
	    read -p "Do you wish to reboot the whole cluster?" yn
	    case $yn in
		[Yy]* ) make install; break;;
		[Nn]* ) exit;;
		* ) echo "Please answer yes or no.";;
	    esac
	done

	for server in $serverList; do		
		echo reboot server $server
		ssh tanle@$server "ssh $server 'sudo reboot'" &
	done
fi

################################# passwordless SSH ####################################

if $isUploadKey
then		
	if $isGenerateKey 
	then 	
		sudo rm -rf $HOME/.ssh/id_dsa*
		sudo rm -rf $HOME/.ssh/authorized_keys*
		yes Y | ssh-keygen -t dsa -P '' -f ~/.ssh/id_dsa 		
		sudo chmod 600 $HOME/.ssh/id_dsa*
#		sudo cat $HOME/.ssh/id_dsa.pub >> $HOME/.ssh/authorized_keys
#		ssh-add $cloudLabPubKey
#		cat $cloudLabPubKey >> $HOME/.ssh/authorized_keys
#		sudo chmod 0600 $HOME/.ssh/authorized_keys
#		echo 'StrictHostKeyChecking no' >> ~/.ssh/config
#		sudo chmod 0600 $HOME/.ssh/config
	fi
	rm -rf ~/.ssh/known_hosts
	for server in $serverList; do
		echo upload keys to $server
#		ssh tanle@$server 'sudo rm -rf $HOME/.ssh/id_dsa*'
		scp ~/.ssh/id_dsa* tanle@$server:~/.ssh/
		ssh tanle@$server "cat ~/.ssh/id_dsa.pub >> ~/.ssh/authorized_keys ;
		 chmod 0600 ~/.ssh/id_dsa*; 
		 chmod 0600 ~/.ssh/authorized_keys; 
		 rm -rf ~/.ssh/known_hosts; 	
		 echo 'StrictHostKeyChecking no' > ~/.ssh/config"
		ssh tanle@$server "echo password less from localhost to $server"
	done	
fi
if $isPasswordlessSSH
then
	passwordlessSSH () { echo $1 to $2;	ssh tanle@$1 "ssh $2 'echo test passwordless SSH'" ;}
	for server1 in $serverList; do
		for server2 in $serverList; do
			passwordlessSSH $server1 $server2 &
		done
	done
fi
################################# install JAVA ######################################
if $isInstallJava
then
	installJava () {
		ssh tanle@$1 'apt-get install openjdk-8-jdk';
	}
	echo "TODO: install JAVA"
	for server in $serverList; do
		installJava $server &
	done
fi

################################# install Ganglia ###################################
# Master

if $isInstallGanglia
then
	echo "Configure Ganglia master node $masterNode"
	ssh tanle@$masterNode 'yes Y | sudo apt-get purge ganglia-monitor gmetad'
	### PLZ manually install Ganglia as we need to respond to some pop-ups
	# we may restart the Apache2 twice
	#ssh tanle@$masterNode 'sudo apt-get install -y rrdtool  ganglia-webfrontend'
	ssh tanle@$masterNode 'sudo apt-get install -y ganglia-monitor gmetad'
	
	# 
	ssh tanle@$masterNode 'sudo cp /etc/ganglia-webfrontend/apache.conf /etc/apache2/sites-enabled/ganglia.conf'
	# change data_source 'SBU Flink' 1 localhost
	#ganglia.conf
	ssh tanle@$masterNode "sudo sed -i -e 's/data_source \"my cluster\" localhost/data_source \"sbu flink\" 1 localhost/g' /etc/ganglia/gmetad.conf"
	#gmond.conf
	ssh tanle@$masterNode "sudo sed -i -e 's/name = \"unspecified\"/name = \"sbu flink\"/g' /etc/ganglia/gmond.conf"
	ssh tanle@$masterNode "sudo sed -i -e 's/mcast_join = 239.2.11.71/#mcast_join = 239.2.11.71/g' /etc/ganglia/gmond.conf"
	ssh tanle@$masterNode "sudo sed -i -e 's/bind = 239.2.11.71/#bind = 239.2.11.71/g' /etc/ganglia/gmond.conf"
	ssh tanle@$masterNode "sudo sed -i -e 's/udp_send_channel {/udp_send_channel { host=nm/g' /etc/ganglia/gmond.conf"
	
	installGangliaFunc(){
		ssh tanle@$1 'sudo apt-get install -y ganglia-monitor'
		ssh tanle@$1 "sudo sed -i -e 's/name = \"unspecified\"/name = \"sbu flink\"/g' /etc/ganglia/gmond.conf"
		ssh tanle@$1 "sudo sed -i -e 's/mcast_join = 239.2.11.71/#mcast_join = 239.2.11.71/g' /etc/ganglia/gmond.conf"
#		ssh tanle@$1 "sudo sed '/udp_send_channel {/a host=nm' /etc/ganglia/gmond.conf"
		ssh tanle@$1 "sudo sed -i -e 's/udp_send_channel {/udp_send_channel { host=nm/g' /etc/ganglia/gmond.conf"
	}

	for server in $slaveNodes; do
		installGangliaFunc $server &
	done	

fi

if $startGanglia
then
	echo restart Ganglia
	# restart all related services
	ssh tanle@$masterNode 'sudo service ganglia-monitor restart & sudo service gmetad restart & sudo service apache2 restart'
	for server in $slaveNodes; do
		ssh tanle@$server 'sudo service ganglia-monitor restart' &
	done	
fi

#################################### Hadoop Yarn ####################################
if $isShutDownHadoop
then
	echo shutdown Hadoop and Yarn
	ssh tanle@$masterNode "$hadoopVer/sbin/stop-dfs.sh"
	ssh tanle@$masterNode "$hadoopVer/sbin/stop-yarn.sh"
	ssh tanle@$masterNode "$hadoopVer/sbin/yarn-daemon.sh --config $HADOOP_CONF_DIR stop proxyserver"
#	ssh tanle@$masterNode "$hadoopVer/sbin/mr-jobhistory-daemon.sh --config $HADOOP_CONF_DIR stop historyserver"
fi 
if $isInstallHadoop
then
echo "==========install Hadoop Yarn=========="
# http://hadoop.apache.org/docs/current/hadoop-project-dist/hadoop-common/ClusterSetup.html
	if $isModifyHadoop 
	then 
		echo "TODO: enter the hadoop source code folder"	
	else
		for server in $serverList; do
			echo Set up Hadoop at $server
			if $isDownload
			then		
				echo downloading $hadoopVer		
				ssh tanle@$server "rm -rf $hadoopTgz; wget $hadoopLink"
			fi
			if $isExtract
			then 
				echo extract $hadoopTgz
				ssh tanle@$server "rm -rf $hadoopVer; tar -xvzf $hadoopTgz >> log.txt"	
			fi
			# add JAVA_HOME
			echo Configure Hadoop at $server
			ssh tanle@$server "echo export JAVA_HOME=$java_home > temp.txt"			
			ssh tanle@$server "cat temp.txt ~/$hadoopVer/etc/hadoop/hadoop-env.sh > temp2.txt ; mv temp2.txt ~/$hadoopVer/etc/hadoop/hadoop-env.sh"

			if $isInitPath
			then	
				ssh tanle@$server "echo export JAVA_HOME=$java_home >> .bashrc"				
				# Administrators can configure individual daemons using the configuration options shown below in the table:	
				#ssh tanle@$server 'echo export HADOOP_NAMENODE_OPTS="-XX:+UseParallelGC" > temp.txt'
				#ssh tanle@$server "cat /$hadoopVer/etc/hadoop/hadoop-env.sh temp.txt > temp2.txt; mv temp2.txt /$hadoopVer/etc/hadoop/hadoop-env.sh"
				# HADOOP_DATANODE_OPTS
	 			# HADOOP_DATANODE_OPTS
				# HADOOP_SECONDARYNAMENODE_OPTS	
				# YARN_RESOURCEMANAGER_OPTS
				# YARN_NODEMANAGER_OPTS
				# YARN_PROXYSERVER_OPTS
				# HADOOP_JOB_HISTORYSERVER_OPTS
			
				# Other useful configuration parameters for hadoop & yarn
				# HADOOP_PID_DIR - The directory where the daemons’ process id files are stored.
				# HADOOP_LOG_DIR - The directory where the daemons’ log files are stored. 
				# HADOOP_HEAPSIZE
				# ssh tanle@$server "sed -i -e 's/#export HADOOP_HEAPSIZE=/export HADOOP_HEAPSIZE=4096/g' $hadoopVer/etc/hadoop/hadoop-env.sh"
				# YARN_HEAPSIZE
				# ssh tanle@$server "sed -i -e 's/# YARN_HEAPSIZE=1000/# YARN_HEAPSIZE=4096/g' $hadoopVer/etc/hadoop/yarn-env.sh"
			
				# configure HADOOP_PREFIX 
				ssh tanle@$server "echo export HADOOP_PREFIX=~/$hadoopVer >> .bashrc"
				ssh tanle@$server "echo export HADOOP_CONF_DIR=~/$hadoopVer/etc/hadoop >> .bashrc"
				ssh tanle@$server "echo export HADOOP_YARN_HOME=~/$hadoopVer >> .bashrc"
				ssh tanle@$server "echo export HADOOP_HOME=~/$hadoopVer >> .bashrc"				
				ssh tanle@$server "echo export HADOOP_CONF_DIR=~/$hadoopVer/etc/hadoop >> .bashrc"
				ssh tanle@$server "echo export YARN_CONF_DIR=~/$hadoopVer/etc/hadoop >> .bashrc"
			fi

			# etc/hadoop/core-site.xml
			
			ssh tanle@$server "sudo rm -rf /dev/hdfs; sudo mkdir /dev/hdfs; sudo chmod 777 /dev/hdfs"

			ssh tanle@$server "echo '<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<?xml-stylesheet type=\"text/xsl\" href=\"configuration.xsl\"?>
<configuration>

  <property>
    <name>fs.defaultFS</name>
    <value>hdfs://$masterNode:9000/</value>
  </property>

  <property>
    <name>io.file.buffer.size</name>
    <value>131072</value>
  </property>

  <property>
    <name>hadoop.tmp.dir</name>
    <value>131072</value>
  </property>

</configuration>' > $hadoopVer/etc/hadoop/core-site.xml"

			# etc/hadoop/hdfs-site.xml
ssh tanle@$server "echo '<?xml version=\"1.0\" encoding=\"UTF-8\"?> 
<?xml-stylesheet type=\"text/xsl\" href=\"configuration.xsl\"?>
<configuration>
    <property>
        <name>dfs.replication</name>
        <value>$numOfworkers</value>
    </property>
  <property>
    <name>dfs.blocksize</name>
    <value>268435456</value>
  </property>

</configuration>' > $hadoopVer/etc/hadoop/hdfs-site.xml"

			echo Configure Yarn at $server

			# etc/hadoop/yarn-site.xml
			## Configurations for ResourceManager and NodeManager:

			ssh tanle@$server "echo '<?xml version=\"1.0\"?>
<configuration>

  <property>
    <name>yarn.nodemanager.aux-services</name>
    <value>mapreduce_shuffle</value>
  </property>

  <property>
    <name>yarn.resourcemanager.hostname</name>
    <value>$masterNode</value>
  </property>
  
  <property>
    <name>yarn.resourcemanager.scheduler.class</name>
    <value>$scheduler</value>
  </property>

  <property>
    <name>yarn.scheduler.maximum-allocation-mb</name>
    <value>$yarnMaxMem</value>
  </property>

  <property>
    <name>yarn.nodemanager.resource.memory-mb</name>
    <value>$yarnNodeMem</value>
  </property>

  <property>
    <name>yarn.nodemanager.vmem-pmem-ratio</name>
    <value>$vmemRatio</value>
  </property>

  <property>
    <name>yarn.scheduler.maximum-allocation-vcores</name>
    <value>$yarnVcores</value>
  </property>

</configuration>' > $hadoopVer/etc/hadoop/yarn-site.xml"

			# etc/hadoop/mapred-site.xml
			ssh tanle@$server "echo '<?xml version=\"1.0\"?>
<?xml-stylesheet type=\"text/xsl\" href=\"configuration.xsl\"?>
<configuration>

  <property>
    <name>mapreduce.framework.name</name>
    <value>yarn</value>
  </property>

  <property>
    <name>mapreduce.map.memory.mb</name>
    <value>1536</value>
  </property>

  <property>
    <name>mapreduce.map.java.opts</name>
    <value>-Xmx1024M</value>
  </property>

  <property>
    <name>mapreduce.reduce.memory.mb</name>
    <value>3072</value>
  </property>

  <property>
    <name>mapreduce.reduce.java.opts</name>
    <value>-Xmx2560M</value>
  </property>

  <property>
    <name>mapreduce.task.io.sort.mb</name>
    <value>512</value>
  </property>

  <property>
    <name>mapreduce.task.io.sort.factor</name>
    <value>100</value>
  </property>

  <property>
    <name>mapreduce.reduce.shuffle.parallelcopies</name>
    <value>50</value>
  </property>

</configuration>' > $hadoopVer/etc/hadoop/mapred-site.xml"			

			# monitoring script in etc/hadoop/yarn-site.xml

			# slaves etc/hadoop/slaves
			ssh tanle@$server "rm -rf $hadoopVer/etc/hadoop/slaves"
			for svr in $slaveNodes; do
				ssh tanle@$server "echo $svr >> $hadoopVer/etc/hadoop/slaves"
			done	

		done				
	fi
fi


if $restartHadoop
then
	# shutdown all before starting.

	ssh tanle@$masterNode "$hadoopVer/sbin/stop-dfs.sh"
	ssh tanle@$masterNode "$hadoopVer/sbin/stop-yarn.sh"
	echo '============================ starting Hadoop==================================='
	# operating HDFS
	ssh tanle@$masterNode "yes Y | $hadoopVer/bin/hdfs namenode -format HDFS4Flink"
	ssh tanle@$masterNode "$hadoopVer/sbin/start-dfs.sh"
	echo '============================ starting Yarn==================================='
	# operating YARN
	ssh tanle@$masterNode "$hadoopVer/sbin/start-yarn.sh"
	# operating MapReduce
	#ssh tanle@$masterNode '$HADOOP_PREFIX/sbin/mr-jobhistory-daemon.sh --config $HADOOP_CONF_DIR start historyserver'
fi


#################################### Apache Flink ################################
if $shudownFlink
then
	ssh $masterNode "$flinkVer/bin/stop-cluster.sh"
	#ssh $masterNode "$hadoopVer/bin/yarn application -kill appplication_id"
fi

if $isInstallFlink 
then 	
	for server in $serverList; do
		if $isDownload
		then
		ssh $server "rm -rf $flinkTgz; wget $flinkDownloadLink"
		fi
		if $isExtract
		then
			ssh $server "rm -rf $flinkVer; tar -xvzf $flinkTgz"
		fi
		
		#Replace localhost with resourcemanager in conf/flink-conf.yaml (jobmanager.rpc.address)
		ssh $server "sed -i -e 's/jobmanager.rpc.address: localhost/jobmanager.rpc.address: nm/g' $flinkVer/conf/flink-conf.yaml"
		ssh $server "sed -i -e 's/jobmanager.heap.mb: 256/taskmanager.heap.mb: 1024/g' $flinkVer/conf/flink-conf.yaml"
		#total amount of memory per machine
		ssh $server "sed -i -e 's/taskmanager.heap.mb: 512/taskmanager.heap.mb: $yarnMaxMem/g' $flinkVer/conf/flink-conf.yaml"
		#Setup the number of task slots = total number of CPUs/ machine
		ssh $server "sed -i -e 's/taskmanager.numberOfTaskSlots: 1/taskmanager.numberOfTaskSlots: $yarnVcores/g' $flinkVer/conf/flink-conf.yaml"
		#Setup the threads = total number of CPUs in the cluster
		#Add hostnames of all worker nodes to the slaves file flinkVer/conf/slaves"
		ssh $server "rm -rf $flinkVer/conf/slaves"
		for slave in $slaveNodes; do
			ssh $server "echo $slave >> $flinkVer/conf/slaves"
		done	
	done
fi


if $startFlinkStandalone	
then
	ssh $masterNode "$flinkVer/bin/stop-cluster.sh"
	ssh $masterNode "$flinkVer/bin/start-cluster.sh"
fi	
if $startFlinkYarn
then
	echo ############################ start Yars session for Flink#########################
#	ssh $masterNode "$flinkVer/bin/yarn-session.sh -n $numOfworkers -d -jm 1024 -tm 32768 -s 4"
	echo "$flinkVer/bin/yarn-session.sh -n $numOfworkers -d -jm 1024 -tm $yarnMaxMem"
fi


############################################### TEST CASES ###########################################
# upload test cases
if $isUploadTestCase 
then 
	cd $flinkSrc	
	rm -rf test/wordcount/*.txt test/wordcount/*.out test/wordcount/*.log
	tar zcvf test.tar test
	ssh tanle@$masterNode 'rm -rf test*'
	scp test.tar tanle@$masterNode:~/ 
	ssh tanle@$masterNode 'tar -xvzf test.tar'

	rm -rf test.tar
fi
