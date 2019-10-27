#!/usr/bin/env python 

import requests,re,random,psycopg2,logging,threading,time,sys
from fake_useragent import UserAgent
from os import path
from queue import Queue


# create database webcrawler DEFAULT character set utf8;
# create table if not exists bilibilifans
#   (id int(12) not null primary key, name varchar(600) not null, sex varchar(8) not null, fans int(12) not null, createdate datetime NOT NULL DEFAULT CURRENT_TIMESTAMP());

class Bilibili:

    #区间范围
    STR_ID = sys.argv[1]
    END_ID = sys.argv[2]  #475379880
    BLANK = sys.argv[3]

    #程序路径初始化
    program_path = path.dirname(path.dirname(path.abspath(__file__)))
    
    #网址链接初始化
    GET_URL = 'https://api.bilibili.com/x/web-interface/card?mid='

    #数据库模块初始化
    INSERT_BILIBILI = "INSERT INTO SPIDER_BILIBILI_FANS_COUNT(ID, NAME, SEX, FANS) VALUES('{0}', '{1}', '{2}', '{3}');"
    SELECT_BILIBILI = "SELECT 1 FROM spider_bilibili_fans_count WHERE ID='{0}';"
    SELECT_PROXY_POOL_URL = "SELECT TYPE, URL FROM spider_ip_pools_active WHERE ID = {0} and STATUS != 'US99';"
    SELECT_PROXY_POOL_URLS = "SELECT ID FROM spider_ip_pools_active;"
    UPDATE_PROXY_POOL_URL = "UPDATE spider_ip_pools_active SET STATUS = 'US99' WHERE TYPE = '{0}' AND URL = '{1}'";
    conn = psycopg2.connect(host="127.0.0.1", user="root", password="000000", dbname="mysite", port=9527)
    
    cur = conn.cursor()
    
    #日志模块初始化
    logfile = program_path + '/log/bilibili.log'
    logger = logging.getLogger(__name__)
    logger.setLevel(level = logging.DEBUG)
    handler = logging.FileHandler(logfile)
    formatter = logging.Formatter('%(asctime)s - %(levelname)s - %(process)d - %(message)s')
    handler.setFormatter(formatter)
    handler.setLevel(logging.INFO)
    logger.addHandler(handler)
   
    def get_proxy_pools_dict(self):
        while True:
            try:
                proxy_pools_dict = {}
                proxy_pools_tuple = ()
                self.cur.execute(self.SELECT_PROXY_POOL_URLS)
                proxy_pools_tuple = self.cur.fetchall()
                proxy_id = random.choice(list(proxy_pools_tuple))[0]
                self.cur.execute(self.SELECT_PROXY_POOL_URL.format(proxy_id))
                proxy = self.cur.fetchone()
            except:
                continue
            else:
                if proxy:
                    proxy_pools_dict = {proxy[0]:proxy[1]}
                    break
        return proxy_pools_dict            

    def insert_bilibilifans(self, id, name, sex, fans):
        try:
            conn2 = psycopg2.connect(host="127.0.0.1", user="root", password="000000", dbname="mysite", port=9527)
            cur2 = conn2.cursor()
            cur2.execute(self.INSERT_BILIBILI.format(id, name, sex, fans))
            self.logger.info("插入数据成功, id: " + id + ", 名字: " + name + ", 性别: " + sex + ", 粉丝数量: " + fans + ".")
        except psycopg2.errors.UniqueViolation:
            pass
        except:
            self.logger.info("插入数据失败, id: " + str(id))
            conn2.rollback()
            raise
        else:
            conn2.commit()
        finally:
            conn2.commit()
            conn2.close()
    
    def update_ip_pools_active(self, type, url):
        try:
            self.cur.execute(self.UPDATE_PROXY_POOL_URL.format(type, url))
        except:
            self.conn.rollback()
        else:
            self.conn.commit()
        finally:
            self.conn.commit()

    def get_bilibili_id(self, first_id, last_id):
        for id in range(first_id, last_id):
            while True:
                proxies = self.get_proxy_pools_dict()
                for type in proxies:
                    url = proxies[type]
                #self.logger.debug("获取proxies成功, type: " + type + ", url: " + url)
                ua = UserAgent()
                headers = {'User-Agent': ua.random}
                try:
                    GET_URL = self.GET_URL + str(id)
                    r = requests.get(GET_URL, headers=headers, proxies=proxies, timeout=10)
                    self.logger.debug("获取数据成功...")
                except:
                    self.logger.debug("连接超时...")
                    continue
                if r.status_code == 200:
                    try:
                        load_dict = r.json()
                        name = load_dict['data']['card']['name']
                        sex = load_dict['data']['card']['sex']
                        fans = load_dict['data']['card']['fans']
                        self.logger.debug("解析数据成功...")
                    except:
                        if str(load_dict['code']) == '-404':
                            self.logger.debug("解析数据失败，状态404...")
                            break
                        else:
                            #print(load_dict)
                            self.logger.debug("解析数据失败...")
                    else:
                        t = self.insert_bilibilifans(str(id), str(name), str(sex), str(fans))
                        break
                elif r.status_code == 412:
                    pass
                    #self.update_ip_pools_active(type, url)

    def main(self):
        self.logger.info("开始进行爬虫.....目标对象: bilibili")
        str_id = int(self.STR_ID)
        end_id = int(self.END_ID)
        blank = int(int(self.END_ID)/int(self.BLANK))
        self.logger.info("开始进入循环，准备添加线程")
        threads = []
        for first_id in range(str_id, end_id, blank):
            last_id = first_id + blank
            t = threading.Thread(target=self.get_bilibili_id,args=(first_id, last_id))
            t.start()
            self.logger.info("启动线程: " + str(first_id) + "至" + str(last_id))
        self.logger.info("启动线程结束，开始守候线程")

if __name__ == "__main__":
    a = Bilibili()
    a.main()
    


