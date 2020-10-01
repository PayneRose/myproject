#! /bin/bash
#time:2017/10/25/
#生成随机密码
randstr() {
read -p "请指出生成几位随机数： " n
index=0
str=""
#index ————> 索引 让i={a..Z}，通过index让$arr等于$i(a..z\A..Z\0..9)
for i in {a..z}; do arr[index]=$i; index=`expr ${index} + 1`; done
for i in {A..Z}; do arr[index]=$i; index=`expr ${index} + 1`; done
for i in {0..9}; do arr[index]=$i; index=`expr ${index} + 1`; done
#上述命令的原理：当i=a时,index=0,arr[0]=a,index+1=1;当i=b,index=1,arr[1]=b,以此类推......
a=1
while [ $a -le $n ] #a=1，n是随机数，做一个循环，让a++，-le即小于等于。即是a小于等于n，则一直循环
	do
		str="$str${arr[$RANDOM%$index]}"  #$RANDOM ————> 环境变量，可以随机获取$index的一个值
			let a++
	done

echo $str
}

echo `randstr`
