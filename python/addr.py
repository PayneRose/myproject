#! /usr/bin/env python2
#coding:utf-8
__metaclass__ = type


import os, sys


class Addr():
    ADDR_PATH = '/etc/sysconfig/network-scripts'
    def get_device(self):
        tl_device = []
        for a, b, files in os.walk(self.ADDR_PATH):
            pass
        for file in files:
            if 'ifcfg' in file and file != 'ifcfg-lo':
                tl_device.append(file.split('-')[1])
        return tl_device

    def reload_device(self, tl_device):
        for device in tl_device:
            stop_cmd = 'ifdown ' + device
            start_cmd = 'ifup ' + device
            os.system(stop_cmd)
            os.system(start_cmd)
        return

    def get_uuid(self, device):
        file = self.ADDR_PATH + '/ifcfg-' + device
        for line in open(file, 'r').readlines():
            if 'UUID' in line:
                line = line.split('=')[1]
                line = line.strip('"')
                line = line.strip('\n')
                line = line.strip('"')
                uuid = line.strip('\n')
        return uuid

    def get_gateway(self, ipaddr):
        if '192.168.1' in ipaddr:
            gateway = '192.168.1.1'
        else:
            gateway = '.'.join(ipaddr.split('.')[0:3]) + '.2'
        return gateway
    
    def get_dns(self, ipaddr):
        if '192.168.1' in ipaddr:
            dns = '8.8.8.8'
        else:
            dns = '.'.join(ipaddr.split('.')[0:3]) + '.12'
        return dns
 

    def analyse_addr_config_files(self):
        tl_device = self.get_device()
        self.reload_device(tl_device)
        td_devices = {}
        for device in tl_device:
            cmd = 'ifconfig -v ' + device
            cmd_ifconfig = os.popen(cmd).readlines()
            for line in cmd_ifconfig:
                if 'inet' in line and 'inet6' not in line:
                    ipaddr = ''.join([x for x in line.split('netmask')[0].split('inet')[1] if x != ' '])
                    netmask = ''.join([x for x in line.split('netmask')[1].split('broadcast')[0] if x != ' '])
                    td_devices[device] = {'IPADDR': ipaddr, 'NETMASK': netmask}
                if 'ether' in line:
                    hwaddr = ''.join([x for x in line.split('ether')[1].split('txqueuelen')[0] if x != ' '])
                    td_devices[device]['HWADDR'] = hwaddr
            uuid = self.get_uuid(device)
            td_devices[device]['UUID'] = uuid
            td_devices[device]['TYPE'] = 'Ethernet'
            td_devices[device]['BOOTPROTO'] = 'static'
            td_devices[device]['NAME'] = device
            td_devices[device]['DEVICE'] = device
            td_devices[device]['ONBOOT'] = 'yes'
            td_devices[device]['NM_CONTROLLED'] = 'yes'
            td_devices[device]['GATEWAY'] = self.get_gateway(td_devices[device]['IPADDR'])
            td_devices[device]['DNS1'] = self.get_dns(td_devices[device]['IPADDR'])
        return td_devices
                    
    def create_addr_dict(self):
        td_devices = self.analyse_addr_config_files()
        for device in td_devices:
            file = self.ADDR_PATH + '/ifcfg-' + device
            bak_file = open('/tmp/ifcfg-' + device, 'w')
            for line in open(file, 'r').readlines():
                bak_file.write(line)
            bak_file.close()
            after_file = open(file, 'w')
            td_device = td_devices[device]
            for colum in td_device:
                after_file.write(colum + '=' + td_device[colum] + '\n')
            after_file.close()


if '__main__' == __name__:
    a = Addr()
    a.create_addr_dict()

