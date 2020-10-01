#! /usr/bin/env python
#coding=utf-8
__metaclass__ = type

if __name__ == '__main__' :
    passwdall = open("/root/Documents/python/operation/operatmp/passwdall.txt","r")
    a = list(passwdall)
    a = ''.join(a)
    a = a.split("\n")
    long = len(a)
    passwdall.close()
    for i in range(0,long-1) :
        for x in range(i+1,long) :
            if int(a[i]) - int(a[x]) > 0 :
                a.insert(i,a[x])
                del a[x+1]
            else:
                pass
    print a
    a = '\n'.join(a)
    fileline = open('/root/Documents/python/operation/operatmp/passwdpaixu.txt','w')
    fileline.write(a)
    fileline.close()

