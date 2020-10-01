#! /usr/bin/env python
#coding=utf-8

"""
/usr/bin/time -f "time: user时间=%U  sys时间=%S 进程的平均总内存使用量=%K" python /root/Documents/python/operation/passwdguibing.py
"""

__metaclass__ = type

import math
passwdall = open("/root/Documents/python/operation/operatmp/passwdall.txt","r")
num = list(passwdall)
num = ''.join(num)
num = num.split("\n")
#num = map(str,range(80)*100)
#print num
longer = len(num)
times = int(math.ceil(math.log(longer,2)))
qian = []
hou = []
tmpnumall = []

for time in range(times) :
    step = pow(2,time+1)
    for i in range(0,longer,step) :
        qian = num[i:(i+step/2)]
        hou = num[(pow(2,time)+i):(pow(2,time)+i+step/2)]
        tmp = []
        for x in range(len(qian)) :
            for y in range(len(hou)) :
                if qian[x] == 0 or hou[y] == 0 :
                    continue
                elif int(qian[x]) - int(hou[y]) <= 0 :
                    tmp.append(qian[x])
                    qian[x] = 0
                    break
                elif int(qian[x]) - int(hou[y]) > 0 :
                    tmp.append(hou[y])
                    hou[y] = 0
        
        while 0 in qian :
            qian.remove(0)

        while 0 in hou :
            hou.remove(0)

        while 0 in tmp :
            tmp.remove(0)

        if len(hou) > 0 :
            tmp = tmp + hou
        elif len(qian) > 0 :
            tmp = tmp + qian

        tmpnumall = tmpnumall + tmp
    num = tmpnumall
    tmpnumall = []

print 'num=%s' % (num)

