#!/bin/bash
output=`curl -v --header "Connection: keep-alive" "https://spark-toolkit.herokuapp.com/api/flsforbuild?username=$1&password=$2"`
echo output=$output;
message=`echo $output | sed -e 's/^.*"message"[ ]*:[ ]*"//' -e 's/".*//'`;
echo $message;

for ((i=1;i<=12;i++));
do
sleep 10s;
output2=`curl -v --header "Connection: keep-alive" "https://spark-toolkit.herokuapp.com/api/jobstatus?id=$message"`;
status=`echo $output2 | sed -e 's/^.*"message"[ ]*:[ ]*"//' -e 's/".*//'`;
echo $status;
if [ "$status" == "Success" ]
then
  echo "FLS run Success";
  exit 0;
fi
done
echo "FLS run failed";
exit 1;
