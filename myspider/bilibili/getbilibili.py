#!/usr/bin/env python 

import json,pymysql,requests,random,threading,time,sys
from fake_useragent import UserAgent


# create database webcrawler DEFAULT character set utf8;
# create table if not exists bilibilifans
#   (id int(12) not null primary key, name varchar(600) not null, sex varchar(8) not null, fans int(12) not null, createdate datetime NOT NULL DEFAULT CURRENT_TIMESTAMP());

class Bilibili:
    conn = pymysql.connect(host="localhost",user="root",passwd="000000",db="webcrawler",charset="utf8")
    cur = conn.cursor()

    HOST = 'https://api.bilibili.com/x/web-interface/card?mid='
    #HOST = 'https://api.bilibili.com/x/relation/stat?vmid={0}&jsonp=jsonp'
    
    def ip_pool_proxies(self):
        proxies = {}
        proxies_list = []
        GETPOOLPROXYSQL = 'select type, host from web_ip_pools where id = {0};'
        GETPOOLIDSQL = 'select id from web_ip_pools;'
        proxies_class = self.cur.execute(GETPOOLIDSQL)
        proxies_tuple = self.cur.fetchall()
        for i in proxies_tuple:
            proxies_list.append(i[0])
        proxies_int = random.choice(proxies_list)
        proxies_class = self.cur.execute(GETPOOLPROXYSQL.format(proxies_int))
        proxies_line = self.cur.fetchone()
        proxies[proxies_line[0]] = proxies_line[1]
        return proxies
    
    def insert_bilibilifans(self, id, name, sex, fans):
        REPLACESQL = 'replace into bilibilifans(id, name, sex, fans) values("{0}", "{1}", "{2}", "{3}");'
        self.cur.execute(REPLACESQL.format(id, name, sex, fans))
        self.conn.commit()

    def exists_id(self):
        existsid = []
        EXISTSSQL = 'select id from bilibilifans;'
        self.cur.execute(EXISTSSQL)
        for id in self.cur.fetchall():
            existsid.append(id[0])
        return existsid
        
    def get_line(self):
        STRNUMBER = 1
        ENDNUMBER = 471379880
        existsid = self.exists_id()
        for id in range(STRNUMBER+int(sys.argv[1]), ENDNUMBER, 10):
            if id in existsid:
                continue
            while True:
                proxies = self.ip_pool_proxies()
                url = self.HOST + str(id)
                ua = UserAgent()
                headers = {'User-Agent': ua.random}
                try:
                    r = requests.get(url, headers=headers, proxies=proxies, timeout=10)
                except:
                    print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()), ';', 'id:', str(id), ';', proxies, ';', '连接超时;')
                    continue
                if r.status_code == 200:
                    try:
                        load_dict = r.json()
                        name = load_dict['data']['card']['name']
                        sex = load_dict['data']['card']['sex']
                        fans = load_dict['data']['card']['fans']
                    except:
                        print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()), ';', 'id:', str(id), ';', proxies, ';', '数据为空;')
                    else:
                        self.insert_bilibilifans(id, name, sex, fans)
                        print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()), ';', 'id:', str(id), ';', proxies, ';', '插入正常;')
                    break
                elif r.status_code == 412:
                    print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()), ';', 'id:', str(id), ';', proxies, ';', '状态异常;')
        else:
            self.conn.close()
        
if __name__ == "__main__":
    a = Bilibili()
    a.get_line()


