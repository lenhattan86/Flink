#!/bin/bash

java_home='/usr/lib/jvm/java-8-oracle'

hadoopVer="hadoop-2.7.0"
hadoopLink="http://download.nextag.com/apache/hadoop/common/hadoop-2.7.0/hadoop-2.7.0.tar.gz"
hadoopTgz="hadoop-2.7.0.tar.gz"

flinkTar="flink.tar"
flinkVer="flink-1.0.3"
flinkTgz="flink-1.0.3-bin-hadoop27-scala_2.10.tgz"
flinkDownloadLink="http://apache.mesi.com.ar/flink/flink-1.0.3/flink-1.0.3-bin-hadoop27-scala_2.10.tgz"
flinkSrc="/home/tan/projects/Flink"
testCase="/home/tan/projects/Flink/test/wordcount"


isInitPath=false

isUploadKey=false
isGenerateKey=false
isPasswordlessSSH=false

isInstallJava=false

isInstallGanglia=false
startGanglia=true

isInstallHadoop=false
isModifyHadoop=false

isShutDownHadoop=false
restartHadoop=true

isUploadFlink=false
isModifyFlink=false
startFlink=true
shudownFlink=false

isUploadTestCase=false

isRun=false


# refer ~/.ssh/config
#master worker01 worker02 worker03 worker04 worker05 worker06 worker07 worker08"
isTest=false

masterNode="nm"
clientNode="ctl"

if $isTest
then
	numOfworkers=1
	serverList="nm cp-2"
	slaveNodes="cp-2"
else
	numOfworkers=8
	serverList="nm cp-1 cp-2 cp-3 cp-4 cp-5 cp-6 cp-7 cp-8"
	slaveNodes="cp-1 cp-2 cp-3 cp-4 cp-5 cp-6 cp-7 cp-8"
fi

################################# passwordless SSH ####################################

if $isUploadKey
then		
	if $isGenerateKey 
	then 	
		ssh-keygen -t dsa -P '' -f ~/.ssh/id_dsa 
	fi

	for server in $serverList; do
		scp ~/.ssh/id_dsa* tanle@$server:~/.ssh/
		ssh-copy-id -i ~/.ssh/id_dsa.pub tanle@$server
		# run cat $HOME/.ssh/id_dsa.pub >> $HOME/.ssh/authorized_keys on each node
		ssh tanle@$server 'cat $HOME/.ssh/id_dsa.pub >> $HOME/.ssh/authorized_keys'
		ssh tanle@$server 'chmod 0600 ~/.ssh/authorized_keys'
	done	
fi
if $isPasswordlessSSH
then
	for server1 in $serverList; do
		for server2 in $serverList; do
		echo $server1 to $server2
		ssh tanle@$server1 "ssh $server2 'echo test passwordless SSH'"
		#ssh tanle@$server1 "scp temp.txt tanle@$server2"
		done
	done
fi
################################# install JAVA ######################################
if $isInstallJava
then
	echo "TODO: install JAVA"
	for server in $serverList; do
		ssh tanle@$server 'echo sudo apt-get install python-software-properties'
		ssh tanle@$server 'sudo apt-get install software-properties-common python-software-properties'
		ssh tanle@$server 'sudo add-apt-repository ppa:webupd8team/java'
		ssh tanle@$server 'sudo apt-get update'
		ssh tanle@$server 'sudo apt-get install oracle-java8-installer'
		ssh tanle@$server 'sudo update-alternatives --config java'
		ssh tanle@$server 'sudo update-alternatives --config javac'
		# set JAVA_HOME
		#ssh tanle@$server 'echo JAVA_HOME="/usr/lib/jvm/java-8-oracle" >> /etc/environment'
		#ssh tanle@$server "source /etc/environment"
	done
	#ssh tanle@$server 'export JAVA_HOME=/usr/local/jdk1.6.0_18'
	
fi


################################# install Ganglia ###################################
# Master


if $isInstallGanglia
then
	echo "TODO: install Ganglia"
	echo "Configure Ganglia master node $masterNode"
	#ssh tanle@$masterNode 'sudo apt-get autoremove ganglia-monitor rrdtool gmetad ganglia-webfrontend'
	#ssh tanle@$masterNode 'sudo apt-get install -y ganglia-monitor rrdtool gmetad ganglia-webfrontend'
	# we may restart the Apache2 twice
	# 
	#ssh tanle@$masterNode 'sudo cp /etc/ganglia-webfrontend/apache.conf /etc/apache2/sites-enabled/ganglia.conf'
	# change data_source 'SBU Flink' 1 localhost
	#ssh tanle@$masterNode "sudo sed -i -e 's/data_source \'my cluster\" localhost/data_source \"SBU Flink\" 1 mn cp-1 cp-2 cp-3 cp-4 cp-5 cp-6 cp-7 cp-8/g' /etc/ganglia/gmetad.conf"
	#ssh tanle@$masterNode "sudo sed -i -e 's/data_source \"sbu flink\" 1 localhost/data_source \"sbu flink\" 1 mn cp-1 cp-2 cp-3 cp-4 cp-5 cp-6 cp-7 cp-8/g' /etc/ganglia/gmetad.conf"
	if $isTest
		ssh tanle@$masterNode "sudo sed -i -e 's/data_source \"sbu flink\" 1 mn cp-1 cp-2 cp-3 cp-4 cp-5 cp-6 cp-7 cp-8/data_source \"sbu flink\" 1 $serverList/g' /etc/ganglia/gmetad.conf"
#		ssh tanle@$masterNode "sudo sed -i -e 's/data_source \'my cluster\" localhost/data_source \"sbu flink\" 1 $serverList/g' /etc/ganglia/gmetad.conf"

	then
		ssh tanle@$masterNode "sudo sed -i -e 's/data_source \'my cluster\" localhost/data_source \"SBU Flink\" 1 $serverList/g' /etc/ganglia/gmetad.conf"
	fi
	#The gmond.conf file configures where the node sends its information.
	#ssh tanle@$masterNode 'sudo vi /etc/ganglia/gmond.conf' # modify cluster, udp_send_channel sections
#	ssh tanle@$masterNode "sed -i -e \"s/data_source 'my cluster' localhost/data_source 1 'SBU Flink'/g\" /etc/ganglia/gmetad.conf"
fi

if $startGanglia
then
	# restart all related services
	ssh tanle@$masterNode 'sudo service ganglia-monitor restart & sudo service gmetad restart & sudo service apache2 restart'
	for server in $slaveNodes; do
		#ssh tanle@$server 'sudo apt-get install -y ganglia-monitor'
		#ssh tanle@$server 'sudo vi /etc/ganglia/gmond.conf'
		# modify cluster, udp_send_channel sections : unspecified -> SBU Flink
		# comment out udp_recv_channel
		# restart all related services
		ssh tanle@$server 'sudo service ganglia-monitor restart' 
	done	
fi


#################################### Hadoop Yarn ####################################
if $isShutDownHadoop
then
	echo shutdown Hadoop and Yarn
#	ssh tanle@$masterNode '$HADOOP_PREFIX/sbin/hadoop-daemon.sh --config $HADOOP_CONF_DIR --script hdfs stop namenode'
#	ssh tanle@$masterNode '$HADOOP_PREFIX/sbin/hadoop-daemons.sh --config $HADOOP_CONF_DIR --script hdfs stop datanode'
	ssh tanle@$masterNode '$HADOOP_PREFIX/sbin/stop-dfs.sh'
#	ssh tanle@$masterNode '$HADOOP_YARN_HOME/sbin/yarn-daemon.sh --config $HADOOP_CONF_DIR stop resourcemanager'
#	ssh tanle@$masterNode '$HADOOP_YARN_HOME/sbin/yarn-daemons.sh --config $HADOOP_CONF_DIR stop nodemanager'
	ssh tanle@$masterNode '$HADOOP_PREFIX/sbin/stop-yarn.sh'
	ssh tanle@$masterNode '$HADOOP_YARN_HOME/sbin/yarn-daemon.sh --config $HADOOP_CONF_DIR stop proxyserver'
	ssh tanle@$masterNode '$HADOOP_PREFIX/sbin/mr-jobhistory-daemon.sh --config $HADOOP_CONF_DIR stop historyserver'
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
			#ssh tanle@$server "rm -rf $hadoopTgz; wget $hadoopLink"
			echo extract $hadoopTgz
			ssh tanle@$server "rm -rf $hadoopVer; tar -xvzf $hadoopTgz >> log.txt"	

			# add JAVA_HOME
			echo Configure Hadoop at $server
			ssh tanle@$server "echo export JAVA_HOME=/usr/lib/jvm/java-8-oracle > temp.txt"			
			ssh tanle@$server "cat temp.txt ~/$hadoopVer/etc/hadoop/hadoop-env.sh > temp2.txt ; mv temp2.txt ~/$hadoopVer/etc/hadoop/hadoop-env.sh"

			if $isInitPath
			then	
				ssh tanle@$server "echo export JAVA_HOME=/usr/lib/jvm/java-8-oracle >> .bashrc"				
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
				# HADOOP_CONF_PATH
				ssh tanle@$server "echo export HADOOP_CONF_DIR=~/$hadoopVer/etc/hadoop >> .bashrc"
				# YARN_CONF_PATH
				ssh tanle@$server "echo export YARN_CONF_DIR=~/$hadoopVer/etc/hadoop >> .bashrc"
			fi

			# etc/hadoop/core-site.xml
			ssh tanle@$server "echo '<?xml version=\"1.0\" encoding=\"UTF-8\"?>'  > $hadoopVer/etc/hadoop/core-site.xml"
			ssh tanle@$server "echo '<?xml-stylesheet type=\"text/xsl\" href=\"configuration.xsl\"?>' >> $hadoopVer/etc/hadoop/core-site.xml"
			ssh tanle@$server "echo '<configuration>' >> $hadoopVer/etc/hadoop/core-site.xml"
			ssh tanle@$server "echo '  <property>' >> $hadoopVer/etc/hadoop/core-site.xml"
			ssh tanle@$server "echo '    <name>fs.defaultFS</name>' >> $hadoopVer/etc/hadoop/core-site.xml"
			ssh tanle@$server "echo '    <value>hdfs://$masterNode:9000/</value>' >> $hadoopVer/etc/hadoop/core-site.xml"
			ssh tanle@$server "echo '  </property>' >> $hadoopVer/etc/hadoop/core-site.xml"
			ssh tanle@$server "echo '  <property>' >> $hadoopVer/etc/hadoop/core-site.xml"
			ssh tanle@$server "echo '    <name>io.file.buffer.size</name>' >> $hadoopVer/etc/hadoop/core-site.xml"
			ssh tanle@$server "echo '    <value>131072</value>' >> $hadoopVer/etc/hadoop/core-site.xml"
			ssh tanle@$server "echo '  </property>' >> $hadoopVer/etc/hadoop/core-site.xml"
			ssh tanle@$server "echo '</configuration>' >> $hadoopVer/etc/hadoop/core-site.xml"


			# etc/hadoop/hdfs-site.xml
			ssh tanle@$server "echo '<?xml version=\"1.0\" encoding=\"UTF-8\"?>'  > $hadoopVer/etc/hadoop/hdfs-site.xml"
			ssh tanle@$server "echo '<?xml-stylesheet type=\"text/xsl\" href=\"configuration.xsl\"?>' >> $hadoopVer/etc/hadoop/hdfs-site.xml"
			ssh tanle@$server "echo '<configuration>' >> $hadoopVer/etc/hadoop/hdfs-site.xml"

			ssh tanle@$server "echo '    <property>' >> $hadoopVer/etc/hadoop/hdfs-site.xml"
			ssh tanle@$server "echo '        <name>dfs.replication</name>' >> $hadoopVer/etc/hadoop/hdfs-site.xml"
			ssh tanle@$server "echo '        <value>$numOfworkers</value>' >> $hadoopVer/etc/hadoop/hdfs-site.xml"
			ssh tanle@$server "echo '    </property>' >> $hadoopVer/etc/hadoop/hdfs-site.xml"


			#### Configurations for NameNode:
#			ssh tanle@$server "rm -rf dfs.name.dir; mkdir dfs.name.dir"
#			ssh tanle@$server "echo '  <property>' >> $hadoopVer/etc/hadoop/hdfs-site.xml"
#			ssh tanle@$server "echo '    <name>dfs.namenode.name.dir</name>' >> $hadoopVer/etc/hadoop/hdfs-site.xml"
#			ssh tanle@$server "echo '    <value>dfs.name.dir</value>' >> $hadoopVer/etc/hadoop/hdfs-site.xml"
#			ssh tanle@$server "echo '  </property>' >> $hadoopVer/etc/hadoop/hdfs-site.xml"

#			ssh tanle@$server "echo '  <property>' >> $hadoopVer/etc/hadoop/hdfs-site.xml"
#			ssh tanle@$server "echo '    <name>dfs.hosts</name>' >> $hadoopVer/etc/hadoop/hdfs-site.xml"
#			ssh tanle@$server "echo '    <value>~/dfs.dir</value>' >> $hadoopVer/etc/hadoop/hdfs-site.xml"
#			ssh tanle@$server "echo '  </property>' >> $hadoopVer/etc/hadoop/hdfs-site.xml"

#			ssh tanle@$server "echo '  <property>' >> $hadoopVer/etc/hadoop/hdfs-site.xml"
#			ssh tanle@$server "echo '    <name>dfs.hosts.exclude</name>' >> $hadoopVer/etc/hadoop/hdfs-site.xml"
#			ssh tanle@$server "echo '    <value></value>' >> $hadoopVer/etc/hadoop/hdfs-site.xml"
#			ssh tanle@$server "echo '  </property>' >> $hadoopVer/etc/hadoop/hdfs-site.xml"

			ssh tanle@$server "echo '  <property>' >> $hadoopVer/etc/hadoop/hdfs-site.xml"
			ssh tanle@$server "echo '    <name>dfs.blocksize</name>' >> $hadoopVer/etc/hadoop/hdfs-site.xml"
			ssh tanle@$server "echo '    <value>268435456</value>' >> $hadoopVer/etc/hadoop/hdfs-site.xml"
			ssh tanle@$server "echo '  </property>' >> $hadoopVer/etc/hadoop/hdfs-site.xml"

			ssh tanle@$server "echo '  <property>' >> $hadoopVer/etc/hadoop/hdfs-site.xml"
			ssh tanle@$server "echo '    <name>dfs.namenode.handler.count</name>' >> $hadoopVer/etc/hadoop/hdfs-site.xml"
			ssh tanle@$server "echo '    <value>100</value>' >> $hadoopVer/etc/hadoop/hdfs-site.xml"
			ssh tanle@$server "echo '  </property>' >> $hadoopVer/etc/hadoop/hdfs-site.xml"


			#### Configurations for DataNode:
#			ssh tanle@$server "rm -rf dfs.data.dir; mkdir dfs.data.dir"
#			ssh tanle@$server "echo '  <property>' >> $hadoopVer/etc/hadoop/hdfs-site.xml"
#			ssh tanle@$server "echo '    <name>dfs.datanode.data.dir</name>' >> $hadoopVer/etc/hadoop/hdfs-site.xml"
#			ssh tanle@$server "echo '    <value>~/dfs.data.dir</value>' >> $hadoopVer/etc/hadoop/hdfs-site.xml"
#			ssh tanle@$server "echo '  </property>' >> $hadoopVer/etc/hadoop/hdfs-site.xml"

			ssh tanle@$server "echo '</configuration>' >> $hadoopVer/etc/hadoop/hdfs-site.xml"

			echo Configure Yarn at $server

			# etc/hadoop/yarn-site.xml
			## Configurations for ResourceManager and NodeManager:

			ssh tanle@$server "echo '<?xml version=\"1.0\"?>' > $hadoopVer/etc/hadoop/yarn-site.xml"
			ssh tanle@$server "echo '<configuration>' >> $hadoopVer/etc/hadoop/yarn-site.xml"

			ssh tanle@$server "echo '  <property>' >> $hadoopVer/etc/hadoop/yarn-site.xml"
			ssh tanle@$server "echo '    <name>yarn.nodemanager.aux-services</name>' >> $hadoopVer/etc/hadoop/yarn-site.xml"
			ssh tanle@$server "echo '    <value>mapreduce_shuffle</value>' >> $hadoopVer/etc/hadoop/yarn-site.xml"
			ssh tanle@$server "echo '  </property>' >> $hadoopVer/etc/hadoop/yarn-site.xml"


#			ssh tanle@$server "echo '  <property>' >> $hadoopVer/etc/hadoop/yarn-site.xml"
#			ssh tanle@$server "echo '    <name>yarn.acl.enable</name>' >> $hadoopVer/etc/hadoop/yarn-site.xml"
#			ssh tanle@$server "echo '    <value>false</value>' >> $hadoopVer/etc/hadoop/yarn-site.xml"
#			ssh tanle@$server "echo '  </property>' >> $hadoopVer/etc/hadoop/yarn-site.xml"

#			ssh tanle@$server "echo '  <property>' >> $hadoopVer/etc/hadoop/yarn-site.xml"
#			ssh tanle@$server "echo '    <name>yarn.admin.acl</name>' >> $hadoopVer/etc/hadoop/yarn-site.xml"
#			ssh tanle@$server "echo '    <value>*</value>' >> $hadoopVer/etc/hadoop/yarn-site.xml" # ACL, admin
#			ssh tanle@$server "echo '  </property>' >> $hadoopVer/etc/hadoop/yarn-site.xml"

#			ssh tanle@$server "echo '  <property>' >> $hadoopVer/etc/hadoop/yarn-site.xml"
#			ssh tanle@$server "echo '    <name>yarn.log-aggregation-enable</name>' >> $hadoopVer/etc/hadoop/yarn-site.xml"
#			ssh tanle@$server "echo '    <value>false</value>' >> $hadoopVer/etc/hadoop/yarn-site.xml"
#			ssh tanle@$server "echo '  </property>' >> $hadoopVer/etc/hadoop/yarn-site.xml"

#			ssh tanle@$server "echo '  <property>' >> $hadoopVer/etc/hadoop/yarn-site.xml"
#			ssh tanle@$server "echo '    <name>dfs.datanode.data.dir</name>' >> $hadoopVer/etc/hadoop/yarn-site.xml"
#			ssh tanle@$server "echo '    <value>dfs.data.dir</value>' >> $hadoopVer/etc/hadoop/yarn-site.xml"
#			ssh tanle@$server "echo '  </property>' >> $hadoopVer/etc/hadoop/yarn-site.xml"

			##Configurations for ResourceManager:

#			ssh tanle@$server "echo '  <property>' >> $hadoopVer/etc/hadoop/yarn-site.xml"
#			ssh tanle@$server "echo '    <name>yarn.resourcemanager.hostname</name>' >> $hadoopVer/etc/hadoop/yarn-site.xml"
#			ssh tanle@$server "echo '    <value>$masterNode</value>' >> $hadoopVer/etc/hadoop/yarn-site.xml"
#			ssh tanle@$server "echo '  </property>' >> $hadoopVer/etc/hadoop/yarn-site.xml"

			ssh tanle@$server "echo '  <property>' >> $hadoopVer/etc/hadoop/yarn-site.xml"
			ssh tanle@$server "echo '    <name>yarn.resourcemanager.address</name>' >> $hadoopVer/etc/hadoop/yarn-site.xml"
			ssh tanle@$server "echo '    <value>$masterNode:8040</value>' >> $hadoopVer/etc/hadoop/yarn-site.xml"
			ssh tanle@$server "echo '  </property>' >> $hadoopVer/etc/hadoop/yarn-site.xml"

			ssh tanle@$server "echo '  <property>' >> $hadoopVer/etc/hadoop/yarn-site.xml"
			ssh tanle@$server "echo '    <name>yarn.resourcemanager.scheduler.address</name>' >> $hadoopVer/etc/hadoop/yarn-site.xml"
			ssh tanle@$server "echo '    <value>$masterNode:8030</value>' >> $hadoopVer/etc/hadoop/yarn-site.xml"
			ssh tanle@$server "echo '  </property>' >> $hadoopVer/etc/hadoop/yarn-site.xml"

			ssh tanle@$server "echo '  <property>' >> $hadoopVer/etc/hadoop/yarn-site.xml"
			ssh tanle@$server "echo '    <name>yarn.resourcemanager.resource-tracker.address</name>' >> $hadoopVer/etc/hadoop/yarn-site.xml"
			ssh tanle@$server "echo '    <value>$masterNode:8025</value>' >> $hadoopVer/etc/hadoop/yarn-site.xml"
			ssh tanle@$server "echo '  </property>' >> $hadoopVer/etc/hadoop/yarn-site.xml"

#			ssh tanle@$server "echo '  <property>' >> $hadoopVer/etc/hadoop/yarn-site.xml"
#			ssh tanle@$server "echo '    <name>yarn.resourcemanager.admin.address</name>' >> $hadoopVer/etc/hadoop/yarn-site.xml"
#			ssh tanle@$server "echo '    <value>$masterNode:8020</value>' >> $hadoopVer/etc/hadoop/yarn-site.xml"
#			ssh tanle@$server "echo '  </property>' >> $hadoopVer/etc/hadoop/yarn-site.xml"

#			ssh tanle@$server "echo '  <property>' >> $hadoopVer/etc/hadoop/yarn-site.xml"
#			ssh tanle@$server "echo '    <name>yarn.resourcemanager.webapp.address</name>' >> $hadoopVer/etc/hadoop/yarn-site.xml"
#			ssh tanle@$server "echo '    <value>$masterNode:8015</value>' >> $hadoopVer/etc/hadoop/yarn-site.xml"
#			ssh tanle@$server "echo '  </property>' >> $hadoopVer/etc/hadoop/yarn-site.xml"

#			ssh tanle@$server "echo '  <property>' >> $hadoopVer/etc/hadoop/yarn-site.xml"
#			ssh tanle@$server "echo '    <name>yarn.resourcemanager.scheduler.class</name>' >> $hadoopVer/etc/hadoop/yarn-site.xml"
#			ssh tanle@$server "echo '    <value>CapacityScheduler</value>' >> $hadoopVer/etc/hadoop/yarn-site.xml"
#			ssh tanle@$server "echo '  </property>' >> $hadoopVer/etc/hadoop/yarn-site.xml"

#			ssh tanle@$server "echo '  <property>' >> $hadoopVer/etc/hadoop/yarn-site.xml"
#			ssh tanle@$server "echo '    <name>yarn.scheduler.minimum-allocation-mb</name>' >> $hadoopVer/etc/hadoop/yarn-site.xml"
#			ssh tanle@$server "echo '    <value>16</value>' >> $hadoopVer/etc/hadoop/yarn-site.xml"
#			ssh tanle@$server "echo '  </property>' >> $hadoopVer/etc/hadoop/yarn-site.xml"

#			ssh tanle@$server "echo '  <property>' >> $hadoopVer/etc/hadoop/yarn-site.xml"
#			ssh tanle@$server "echo '    <name>yarn.scheduler.maximum-allocation-mb</name>' >> $hadoopVer/etc/hadoop/yarn-site.xml"
#			ssh tanle@$server "echo '    <value>4096</value>' >> $hadoopVer/etc/hadoop/yarn-site.xml"
#			ssh tanle@$server "echo '  </property>' >> $hadoopVer/etc/hadoop/yarn-site.xml"

#			ssh tanle@$server "echo '  <property>' >> $hadoopVer/etc/hadoop/yarn-site.xml"			
#			ssh tanle@$server "echo '    <name>yarn.resourcemanager.nodes.include-path</name>' >> $hadoopVer/etc/hadoop/yarn-site.xml"
#			ssh tanle@$server "echo '    <value></value>' >> $hadoopVer/etc/hadoop/yarn-site.xml"
#			ssh tanle@$server "echo '  </property>' >> $hadoopVer/etc/hadoop/yarn-site.xml"

#			ssh tanle@$server "echo '  <property>' >> $hadoopVer/etc/hadoop/yarn-site.xml"
#			ssh tanle@$server "echo '    <name>yarn.resourcemanager.nodes.exclude-path</name>' >> $hadoopVer/etc/hadoop/yarn-site.xml"
#			ssh tanle@$server "echo '    <value></value>' >> $hadoopVer/etc/hadoop/yarn-site.xml"
#			ssh tanle@$server "echo '  </property>' >> $hadoopVer/etc/hadoop/yarn-site.xml"


			## Configurations for NodeManager:
#			ssh tanle@$server "echo '  <property>' >> $hadoopVer/etc/hadoop/yarn-site.xml"
#			ssh tanle@$server "echo '    <name>yarn.nodemanager.resource.memory-mb</name>' >> $hadoopVer/etc/hadoop/yarn-site.xml"
#			ssh tanle@$server "echo '    <value>65536</value>' >> $hadoopVer/etc/hadoop/yarn-site.xml" # 64GB
#			ssh tanle@$server "echo '  </property>' >> $hadoopVer/etc/hadoop/yarn-site.xml"

#			ssh tanle@$server "echo '  <property>' >> $hadoopVer/etc/hadoop/yarn-site.xml"
#			ssh tanle@$server "echo '    <name>yarn.nodemanager.vmem-pmem-ratio</name>' >> $hadoopVer/etc/hadoop/yarn-site.xml"
#			ssh tanle@$server "echo '    <value>2.1</value>' >> $hadoopVer/etc/hadoop/yarn-site.xml"
#			ssh tanle@$server "echo '  </property>' >> $hadoopVer/etc/hadoop/yarn-site.xml"

#			ssh tanle@$server "echo '  <property>' >> $hadoopVer/etc/hadoop/yarn-site.xml"
#			ssh tanle@$server "echo '    <name>yarn.nodemanager.local-dirs</name>' >> $hadoopVer/etc/hadoop/yarn-site.xml"
#			ssh tanle@$server "echo '    <value></value>' >> $hadoopVer/etc/hadoop/yarn-site.xml"
#			ssh tanle@$server "echo '  </property>' >> $hadoopVer/etc/hadoop/yarn-site.xml"

#			ssh tanle@$server "echo '  <property>' >> $hadoopVer/etc/hadoop/yarn-site.xml"
#			ssh tanle@$server "echo '    <name>yarn.nodemanager.log-dirs</name>' >> $hadoopVer/etc/hadoop/yarn-site.xml"
#			ssh tanle@$server "echo '    <value>4096</value>' >> $hadoopVer/etc/hadoop/yarn-site.xml"
#			ssh tanle@$server "echo '  </property>' >> $hadoopVer/etc/hadoop/yarn-site.xml"

#			ssh tanle@$server "echo '  <property>' >> $hadoopVer/etc/hadoop/yarn-site.xml"
#			ssh tanle@$server "echo '    <name>yarn.nodemanager.log.retain-seconds</name>' >> $hadoopVer/etc/hadoop/yarn-site.xml"
#			ssh tanle@$server "echo '    <value>10800</value>' >> $hadoopVer/etc/hadoop/yarn-site.xml"
#			ssh tanle@$server "echo '  </property>' >> $hadoopVer/etc/hadoop/yarn-site.xml"

#			ssh tanle@$server "echo '  <property>' >> $hadoopVer/etc/hadoop/yarn-site.xml"
#			ssh tanle@$server "echo '    <name>yarn.nodemanager.remote-app-log-dir</name>' >> $hadoopVer/etc/hadoop/yarn-site.xml"
#			ssh tanle@$server "echo '    <value>/tmp/logs</value>' >> $hadoopVer/etc/hadoop/yarn-site.xml"
#			ssh tanle@$server "echo '  </property>' >> $hadoopVer/etc/hadoop/yarn-site.xml"

#			ssh tanle@$server "echo '  <property>' >> $hadoopVer/etc/hadoop/yarn-site.xml"
#			ssh tanle@$server "echo '    <name>yarn.nodemanager.remote-app-log-dir-suffix</name>' >> $hadoopVer/etc/hadoop/yarn-site.xml"
#			ssh tanle@$server "echo '    <value>logs</value>' >> $hadoopVer/etc/hadoop/yarn-site.xml"
#			ssh tanle@$server "echo '  </property>' >> $hadoopVer/etc/hadoop/yarn-site.xml"

#			ssh tanle@$server "echo '  <property>' >> $hadoopVer/etc/hadoop/yarn-site.xml"
#			ssh tanle@$server "echo '    <name>yarn.nodemanager.aux-services</name>' >> $hadoopVer/etc/hadoop/yarn-site.xml"
#			ssh tanle@$server "echo '    <value>mapreduce_shuffle</value>' >> $hadoopVer/etc/hadoop/yarn-site.xml"
#			ssh tanle@$server "echo '  </property>' >> $hadoopVer/etc/hadoop/yarn-site.xml"

			## Configurations for History Server
#			ssh tanle@$server "echo '  <property>' >> $hadoopVer/etc/hadoop/yarn-site.xml"
#			ssh tanle@$server "echo '    <name>yarn.log-aggregation.retain-seconds</name>' >> $hadoopVer/etc/hadoop/yarn-site.xml"
#			ssh tanle@$server "echo '    <value>-1</value>' >> $hadoopVer/etc/hadoop/yarn-site.xml"
#			ssh tanle@$server "echo '  </property>' >> $hadoopVer/etc/hadoop/yarn-site.xml"

#			ssh tanle@$server "echo '  <property>' >> $hadoopVer/etc/hadoop/yarn-site.xml"
#			ssh tanle@$server "echo '    <name>yarn.log-aggregation.retain-check-interval-seconds</name>' >> $hadoopVer/etc/hadoop/yarn-site.xml"
#			ssh tanle@$server "echo '    <value>-1</value>' >> $hadoopVer/etc/hadoop/yarn-site.xml"
#			ssh tanle@$server "echo '  </property>' >> $hadoopVer/etc/hadoop/yarn-site.xml"

			ssh tanle@$server "echo '</configuration>' >> $hadoopVer/etc/hadoop/yarn-site.xml"

			# etc/hadoop/mapred-site.xml

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
#	ssh tanle@$masterNode '$HADOOP_PREFIX/sbin/hadoop-daemon.sh --config $HADOOP_CONF_DIR --script hdfs stop namenode'
#	ssh tanle@$masterNode '$HADOOP_PREFIX/sbin/hadoop-daemons.sh --config $HADOOP_CONF_DIR --script hdfs stop datanode'
	ssh tanle@$masterNode '$HADOOP_PREFIX/sbin/stop-dfs.sh'
#	ssh tanle@$masterNode '$HADOOP_YARN_HOME/sbin/yarn-daemon.sh --config $HADOOP_CONF_DIR stop resourcemanager'
#	ssh tanle@$masterNode '$HADOOP_YARN_HOME/sbin/yarn-daemons.sh --config $HADOOP_CONF_DIR stop nodemanager'
	ssh tanle@$masterNode '$HADOOP_PREFIX/sbin/stop-yarn.sh'
	ssh tanle@$masterNode '$HADOOP_YARN_HOME/sbin/yarn-daemon.sh --config $HADOOP_CONF_DIR stop proxyserver'
#	ssh tanle@$masterNode '$HADOOP_PREFIX/sbin/mr-jobhistory-daemon.sh --config $HADOOP_CONF_DIR stop historyserver'
	echo '============================ starting Hadoop==================================='
	# operating HDFS
	ssh tanle@$masterNode 'yes Y | $HADOOP_PREFIX/bin/hdfs namenode -format HDFS4Flink'
#	ssh tanle@$masterNode '$HADOOP_PREFIX/sbin/hadoop-daemon.sh --config $HADOOP_CONF_DIR --script hdfs start namenode'
#	ssh tanle@$masterNode '$HADOOP_PREFIX/sbin/hadoop-daemons.sh --config $HADOOP_CONF_DIR --script hdfs start datanode'		
	ssh tanle@$masterNode '$HADOOP_PREFIX/sbin/start-dfs.sh'
	echo '============================ starting Yarn==================================='
	# operating YARN
#	ssh tanle@$masterNode '$HADOOP_PREFIX/sbin/yarn-daemon.sh --config $HADOOP_CONF_DIR start resourcemanager'
#	ssh tanle@$masterNode '$HADOOP_PREFIX/sbin/yarn-daemon.sh --config $HADOOP_CONF_DIR start proxyserver'
	ssh tanle@$masterNode '$HADOOP_PREFIX/sbin/start-yarn.sh'
	# operating MapReduce
	#ssh tanle@$masterNode '$HADOOP_PREFIX/sbin/mr-jobhistory-daemon.sh --config $HADOOP_CONF_DIR start historyserver'
fi


#################################### Apache Flink ################################
if $shudownFlink
then
	ssh $masterNode "$flinkVer/bin/stop-cluster.sh"
fi

if $isUploadFlink 
then 	
	if $isModifyFlink 
	then 
		cd $flinkSrc
		cd flink-dist/target/flink-1.0.3-bin/flink-1.0.3
		cd ..
		tar zcvf ../../../test/$flinkTar flink-1.0.3
		cd ../../../test
	else
		wget $flinkDownloadLink
		tar -xvzf $flinkTgz
		cd $flinkVer
	fi

	#sudo apt-get install vim
	#Replace localhost with resourcemanager in conf/flink-conf.yaml (jobmanager.rpc.address)
	sed -i -e 's/jobmanager.rpc.address: localhost/jobmanager.rpc.address: nm/g' conf/flink-conf.yaml
	#total amount of memory per machine
	#sed -i -e 's/taskmanager.heap.mb: 512/taskmanager.heap.mb: 4096/g' conf/flink-conf.yaml
	#sed -i -e 's/taskmanager.heap.mb: 512/taskmanager.heap.mb: 16384/g' conf/flink-conf.yaml
	sed -i -e 's/taskmanager.heap.mb: 512/taskmanager.heap.mb: 32768/g' conf/flink-conf.yaml
	#Setup the number of task slots = total number of CPUs/ machine
	sed -i -e 's/taskmanager.numberOfTaskSlots: 1/taskmanager.numberOfTaskSlots: 32/g' conf/flink-conf.yaml
	#Setup the threads = total number of CPUs in the cluster
	#sed -i -e 's/parallelism.default: 1/parallelism.default: 256/g' conf/flink-conf.yaml
	sed -i -e 's/parallelism.default: 1/parallelism.default: 8/g' conf/flink-conf.yaml
	#Add hostnames of all worker nodes to the slaves file conf/slaves
	rm -rf conf/slaves
	for slave in $slaveNodes; do
		echo $slave >> conf/slaves
	done	

	cd ..
	tar zcvf $flinkTar $flinkVer 

	for server in $serverList; do
		ssh $server "rm -rf flink*"
		scp $flinkTar tanle@$server:~/ 
		ssh $server "tar -xvzf $flinkTar"
	done
	rm -rf flink*

fi


if $startFlink	
then
	ssh $masterNode "$flinkVer/bin/stop-cluster.sh"
	ssh $masterNode "$flinkVer/bin/start-cluster.sh"
	ssh $masterNode "$flinkVer/bin/yarn-session.sh -n $numOfworkers -tm 8192"
fi

################


####################### TEST CASES ######################
# upload test cases
if $isUploadTestCase 
then 
	cd $flinkSrc	
	rm -rf test/wordcount/*.txt test/wordcount/*.out test/wordcount/*.log
	tar zcvf test.tar test
	for server in $serverList; do
		ssh tanle@$masterNode 'rm -rf test*'
		scp test.tar tanle@$server:~/ 
	done

	rm -rf test.tar
fi
