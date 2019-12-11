l=100
for ((i=1;i<=475380000;i+=${l}))
do
    endnum=`expr ${i} + ${l}`
    python bilibili.py ${i} ${endnum} 10 &
    sleep 0.1;
    num=`ps -ef |grep -v grep |grep bilibili.py|wc -l`
    while [[ ${num} -gt 19 ]]
    do
        num=`ps -ef |grep -v grep |grep bilibili.py|wc -l`
        sleep 120;
    done
done

