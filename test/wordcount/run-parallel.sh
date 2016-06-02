# refer: http://stackoverflow.com/questions/8246172/execute-multiple-shell-scripts-concurrently
# remember to check the number of available Task Slots in flink-conf.yaml
# Start the processes in parallel...
# TODO: why cannot work with for loops?
rm -rf *.out
rm -rf *.log

./run01.sh 1>/dev/null 2>&1 &
pid1=$!
./run02.sh 1>/dev/null 2>&1 &
pid2=$!

# Wait for processes to finish...
echo -ne "Commands sent... "
wait $pid1
err1=$?
wait $pid2
err2=$?

#echo "done"

# Do something useful with the return codes...
if [ $err1 -eq 0 -a $err2 -eq 0 ]
then
    echo "pass"
else
    echo "fail"
fi
