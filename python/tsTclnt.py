#! /usr/bin/env python
#coding:utf-8
#TCP的简单应用

__metaclass__ = type

from socket import *

HOST = 'localhost'
PORT = 21567
BUFSIZ = 1024
ADDR = (HOST, PORT)

tcpCliSock = socket(AF_INET, SOCK_STREAM)
tcpCliSock.connect(ADDR)    #主动发起连接

while True:
    data = raw_input('> ')
    if not data:     #当输入为空时退出
        break
    tcpCliSock.send(data)    #发送TCP消息
    data = tcpCliSock.recv(BUFSIZ)  #接受TCP消息
    if not data:
        break
    print data

tcpCliSock.close()
