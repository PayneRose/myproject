#! /usr/bin/env python
#coding:utf-8
#TCP的简单应用
__metaclass__ = type

from socket import *
from time import ctime,sleep

HOST = ''   #接受所有IP请求
PORT = 21567
BUFSIZ = 1024
ADDR = (HOST, PORT)

tcpSerSock = socket(AF_INET, SOCK_STREAM)
tcpSerSock.bind(ADDR)  #将地址端口绑定到套接字上
tcpSerSock.listen(5)

while True:
    print 'waiting for connection...'
    tcpCliSock, addr = tcpSerSock.accept()   #被动接受连接，当存在请求时赋值，空闲时暂停
    print '...connected from: ', addr

    while True:
        data = tcpCliSock.recv(BUFSIZ)   #获取用户输入
        if not data:    #当用户输入为空时退出循环
            break
        tcpCliSock.send('[%s] %s' % (ctime(), data))     #发生TCP消息
    
    tcpCliSock.close()
tcpSerSock.close()

