# Start timming
#flink="../../build-target"
flink="../../flink-1.0.3"
rm -rf app01.log
rm -rf app01.debug.log
~/hadoop-2.7.0/bin/hadoop fs -rmr -skipTrash hdfs:///.../app01.out
#for i in `seq 1 5`;	
#do
	rm -rf app01.out	
	echo $i >> app01.log
	date --rfc-3339=seconds >> app01.log
	# run the Flink app
	$flink/bin/flink run $flink/examples/batch/WordCount.jar --input hdfs:///.../app01.txt --output hdfs:///.../app01.out
	# Stop timming
	date --rfc-3339=seconds >> app01.log        
#	sleep 60
#done  

