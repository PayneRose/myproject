#! /usr/bin/env python
#coding=utf-8
__metaclass__ = type
import sys
if __name__ == "__main__" :
    x = input("你想插入什么数据？ ")
    passwdpaixu = open("/root/Documents/python/operation/operatmp/passwdpaixu.txt","r").read()
    passwdcharu = open("/root/Documents/python/operation/operatmp/passwdcharu.txt","w")
    a = passwdpaixu
    a = a.split("\n")
    start = 0
    end = len(a) - 1
    numOne = (end - start)/2
    numTwo = (end - start)/2 + 1
    for i in range(30):
        print "循环=",i
        if numOne == 0 :
           a.insert(0,str(x))
           a = '\n'.join(a)
           passwdcharu.write(a)
           sys.exit()
        elif numTwo > end :
            a.insert(numTwo,str(x))
            a = '\n'.join(a)
            passwdcharu.write(a)
            sys.exit()
        elif int(a[numOne]) < x < int(a[numTwo]) or int(a[numOne]) == x or int(a[numTwo]) == x :
            a.insert(numTwo,str(x))
            a = '\n'.join(a)
            passwdcharu.write(a)
            sys.exit()
        elif x < int(a[numOne]):
            end = numOne
            numOne = (end - start)/2 + start
            numTwo = (end - start)/2 + start + 1
        elif x > int(a[numTwo]) :
            start = numTwo
            numOne = (end - start)/2 + start
            numTwo = (end - start)/2 + start + 1
        else :
            print "sorry"
