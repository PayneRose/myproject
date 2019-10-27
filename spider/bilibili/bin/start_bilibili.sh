l=50
for ((i=1;i<=475380000;i+=${l}))
do
    endnum=`expr ${i} + ${l}`
    python bilibili.py ${i} ${endnum} 5 &
    sleep 1;
    num=`ps -ef |grep -v grep |grep bilibili.py|wc -l`
    while [[ ${num} -gt 100 ]]
    do
        num=`ps -ef |grep -v grep |grep bilibili.py|wc -l`
    done
done

