#! /usr/bin/env python
#coding=utf-8
__metaclass__ = type
   
import os
import sys
import random
import string
#num1 = string.ascii_letters + string.digits
#num1 = string.digits


def test1():
    num1 = string.digits
    num1 = num1[0:6]
    long1 = len(num1)
    mima1 = []
    for i in range(long1):
        print i
        mima1 = mima1 + test2(i+1,num1)
    return mima1


def test2(times2,num2):
    mima2 = []
    long2 = pow(len(num2),times2)
    while True :
        one = []
        for i in range(times2) :
            c = ''.join(random.sample(num2,1))
            one.append(c)
        one = ''.join(one)
        if one not in mima2 :
            mima2.append(one)
        elif len(mima2) == long2 :
            return mima2
        


