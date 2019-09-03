import requests,re,random,time,pymysql
from fake_useragent import UserAgent
from getbilibili import Bilibili


#create table if not exists web_ip_pools
#  (type varchar(8) not null, host varchar(60) not null , primary key (host), createdate datetime NOT NULL DEFAULT CURRENT_TIMESTAMP());


class Proxy_pools:
    proxy_url = "https://raw.githubusercontent.com/fate0/proxylist/master/proxy.list"
    check_url = "http://httpbin.org/ip"
    INSERTSQL = 'replace into web_ip_pools(type, host) values("{0}", "{1}")'
    conn = pymysql.connect(host="localhost",user="root",passwd="000000",db="webcrawler",charset="utf8")
    cur = conn.cursor()
    
    def getHeaders(self):
        ua = UserAgent()
        headers = {'User-Agent': ua.random}
        return headers
        
    def getProxies(self):
        id = 1
        proxys = {}
        headers = self.getHeaders()
        htmls = requests.get(self.proxy_url, headers=headers, timeout=10).text
        htmls = htmls.split('\n')
        for html in htmls:
            try:
                proxys[id] = eval(html)
            except:
                pass
            finally:
                id += 1    
        else:
            return proxys

    def goingCheckUrl(self):
        proxys = self.getProxies()
        for id in proxys:
            type = proxys[id]['type']
            host = proxys[id]['host']
            port = proxys[id]['port']
            if type == 'http':
                urls = "http://" + str(host) + ":" + str(port)
                proxy = {type:"%s"%(urls)}
            elif type == 'https':
                urls = "https://" + str(host) + ":" + str(port)
                proxy = {type:"%s"%(urls)}
            headers = self.getHeaders()
            try:
                res = requests.get(self.check_url, headers=headers, proxies=proxy,timeout=10)
            except:
                pass
            else:
                if res.status_code == 200 and res.json()['origin']:
                    print("验证通过, 准备插入数据库...")
                    self.cur.execute(self.INSERTSQL.format(type, urls))
                    self.conn.commit()


if __name__ == "__main__":
    a = Proxy_pools()
    a.goingCheckUrl()


