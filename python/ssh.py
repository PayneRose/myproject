#! /usr/bin/env python
#coding:utf-8
__metaclass__ = type

import os

class Ssh():
    def __init__(self,host,file):
        self.host = host
        self.commad = open(file,"rb").readlines()
        self.countline = len(self.commad)
    def ssh(self):
            commad = ';'.join(self.commad)
            os.environ["commad"] = commad
            os.environ["host"] = self.host
            result = os.system("ssh $host $commad")


a = Ssh(host="lances@192.168.1.113",file="/root/python/tmp/test")
a.ssh()

"""
class Sql():
    def __init__(self,execute,file):
        self.execute = execute
        self.commad = open(file,"rb").readlines()
        self.countline = len(self.commad)
    def sql(self):
        for line in range(self.countline):
            if line == '\n':
                continue
            else:
                os.environ["execute"] = self.execute
                os.environ["commad"] = self.commad[line]
                result = os.system("$execute $commad")


b = Sql(execute="",file="")
a.sql()
"""
