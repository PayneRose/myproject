#coding:utf-8
#!/usr/bin/env python
import json
import requests
import telnetlib
import re
from time import sleep
from multiprocessing.dummy import Pool as ThreadPool

proxy_url = "https://raw.githubusercontent.com/fate0/proxylist/master/proxy.list"

def verify(ip,port,types):
    proxies = {}
    try:
        telnet = telnetlib.Telnet(ip,port=port,timeout=3)
    except:
        print("Unconnected ---")
    else:
        print("Connect Successfully!!!!")
        proxies["ip"] = ip
        proxies["port"] = port
        proxies["types"] = types
        proxyJson = json.dumps(proxies)
        pro = json.loads(proxyJson)
        ip = pro.get("ip")
        port = pro.get("port")
#        print ip
#        print port
#        url = "http://"+str(ip)+":"+str(port)
#        print(url)
        
        lnk1 = ""
        urls = ""
        if proxies["types"] == "http":
            urls = "http://" + str(ip) + ":" + str(port)
            proxy = {"http":"%s"%(urls)}
            print(proxy)
            try:
                res = requests.get("http://2019.ip138.com/ic.asp",proxies=proxy,timeout=10)
                res.encoding = 'gb2312'
                locatetext = re.compile("<center>(.*?)</center>")
                locateip = re.findall(locatetext,res.text)
                for lnk in locateip:
                    lnk1 = lnk
                    print(lnk)
            except requests.exceptions.RequestException as e:
                print(e)
        else:
            urls =  str(ip) + ":" + str(port)
            proxy = {"https":"%s"%(urls)}
            print(proxy)
            urls = 'https://' + urls
            try:
                res = requests.get("https://ip.cn",proxies=proxy,timeout=10)
                res.encoding = 'utf-8'
                locatetext = re.compile("<div class=\"well\"><p>(.*?)<code>(.*?)</code></p><p>(.*?)<code>(.*?)</code>")
                locateip = re.findall(locatetext,res.text)
                for lnk in locateip:
                    lnk1 = lnk
                    print(lnk)
            except requests.exceptions.RequestException as e:
                print(e)
    
        with open('./verfy_proxy.json','a+') as f:
            print("**********")
                
            print("已写入文件：\n")
            print(urls + '\n')
            print(lnk1)
            print("**********")
            f.write(urls+'\t'+lnk1+'\n')



def getProxy(proxy_url):
    response = requests.get(proxy_url)
    proxies_list = response.text.split('\n')
    for proxy_str in proxies_list:
        proxy_json = json.loads(proxy_str)
        ip = proxy_json['host']
        port = proxy_json['port']
        types = proxy_json['type']
        verify(ip,port,types)


if __name__ == '__main__':
    pool = ThreadPool(processes=30)
    pool.apply_async(getProxy(proxy_url))
    pool.close()
    pool.join()
    print("程序结束")
#    getProxy(proxy_url)



