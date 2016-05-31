#!/bin/bash
test=0
isDownload=false
flinkTar="flink.tar"
flinkVer="flink-1.0.3"
flinkSrc="/home/tan/projects/Flink"
testCase="/home/tan/projects/Flink/test/wordcount"
numOfworkers=8

# refer ~/.ssh/config
serverList="master worker01 worker02 worker03 worker04 worker05 worker06 worker07 worker08"
masterNode="nm"
slaveNodes="cp-1 cp-2 cp-3 cp-4 cp-5 cp-6 cp-7 cp-8"

#ssh-keygen -t dsa -P '' -f ~/.ssh/id_dsa 
for server in $serverList; do
	scp ~/.ssh/id_dsa* tanle@$server:~/.ssh/
	ssh-copy-id -i ~/.ssh/id_dsa.pub tanle@$server	
	# note: run cat $HOME/.ssh/id_dsa.pub >> $HOME/.ssh/authorized_keys on each node
done

# download and extract Flink
if $isDownload 
then 
	wget http://www.trieuvan.com/apache/flink/flink-1.0.2/flink-1.0.2-bin-hadoop27-scala_2.11.tgz
	tar -xvzf flink-1.0.2-bin-hadoop27-scala_2.11.tgz
	cd $flinkVer  
else
	cd $flinkSrc
	cd flink-dist/target/flink-1.0.3-bin/flink-1.0.3
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
sed -i -e 's/parallelism.default: 1/parallelism.default: 256/g' conf/flink-conf.yaml
#Add hostnames of all worker nodes to the slaves file conf/slaves
rm -rf conf/slaves
for slave in $slaveNodes; do
	echo $slave >> conf/slaves
done

if $isDownload 
then 
	cd ..
	tar zcvf $flinkTar $flinkVer
else 		
	cd ..
	tar zcvf ../../../test/$flinkTar flink-1.0.3
	cd ../../../test
fi

for server in $serverList; do
	scp $flinkTar tanle@$server:~/ 
done

# upload test cases
cd $flinkSrc
rm -rf test/wordcount/*.txt test/wordcount/*.out test/wordcount/*.log
tar zcvf test.tar test
scp test.tar tanle@master:~/ 

#ssh $masterNode
#bin/start-cluster.sh
