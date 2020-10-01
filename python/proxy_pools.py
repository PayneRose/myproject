import requests,re,random,psycopg2,logging,threading,time
from fake_useragent import UserAgent
from os import path
from queue import Queue

class Proxy_pools:
    
    #程序路径初始化
    program_path = path.dirname(path.dirname(path.abspath(__file__)))
    
    #网址链接初始化
    PROXY_URL = "https://raw.githubusercontent.com/fate0/proxylist/master/proxy.list"
    CHECK_URL1 = "https://www.baidu.com"
    CHECK_URL2 = "https://httpbin.org/ip"
    #数据库模块初始化
    INSERT_ACTIVE = "INSERT INTO IP_POOLS_ACTIVE(TYPE, URL, STATUS) VALUES('{0}', '{1}', '{2}');"
    SELECT_ACTIVE = "select 1 from IP_POOLS_ACTIVE where TYPE='{0}' and URL='{1}';" 
    conn = psycopg2.connect(host="127.0.0.1", user="root", password="000000", dbname="mysite", port=5432)
    cur = conn.cursor()
    #日志模块初始化
    logfile = program_path + '/log/proxy_poolls.log'
    logger = logging.getLogger(__name__)
    logger.setLevel(level = logging.INFO)
    handler = logging.FileHandler(logfile)
    formatter = logging.Formatter('%(asctime)s - %(levelname)s - %(process)d - %(message)s')
    handler.setFormatter(formatter)
    handler.setLevel(logging.INFO)
    logger.addHandler(handler)

    def getHeaders(self):
        ua = UserAgent()
        headers = {'User-Agent': ua.random}
        return headers

    def getexistsproxy(self, type, url):
        self.cur.execute(self.SELECT_ACTIVE.format(type, url))
        proxy_exists = self.cur.fetchone()
        if not proxy_exists:
            return 0
        else:
            return 1
            

    def getProxies(self):
        id = 1
        proxys_dict = {}
        headers = self.getHeaders()
        proxy = {'http':'http://167.71.161.102:8080'}
        try:
            htmls = requests.get(self.PROXY_URL, headers=headers,  proxies=proxy, timeout=20).text
        except:
            self.logger.warning("获取最新的proxys代理池失败")
            raise
        htmls = htmls.split('\n')[:-1]
        for html in htmls:
            try:
                proxy_dict_t = eval(html)    #验证是否可以转化为字典
            except:
                pass
            else:
                proxy_exists = self.getexistsproxy(proxy_dict_t['type'],proxy_dict_t['type'] + "://" + str(proxy_dict_t['host']) + ":" + str(proxy_dict_t['port']))
                if proxy_exists == 0:
                    proxys_dict[id] = eval(html)
                    id += 1
        self.logger.info("获取最新的proxys代理池成功, 一共获取{0}条数据".format(len(proxys_dict)))
        return proxys_dict

    def insertProxies(self, proxys_checked):
        for id in proxys_checked:
            type = proxys_checked[id][0]
            url = proxys_checked[id][1]
            status = proxys_checked[id][2]
            try:
                self.logger.info("执行sql: " + self.INSERT_ACTIVE.format(type, url, status))
                self.cur.execute(self.INSERT_ACTIVE.format(type, url, status))
            except psycopg2.errors.UniqueViolation:
                self.conn.rollback()
                self.logger.info("插入proxy失败, 失败原因: 主键冲突")
            except psycopg2.errors.InFailedSqlTransaction:
                self.conn.rollback()
                self.logger.info("插入proxy失败, 失败原因: 提交异常") 
            except:
                self.conn.rollback()
                self.logger.info("插入proxy失败, 失败原因: 未知异常")
                raise
            else:
                self.conn.commit()
                self.logger.info("插入proxy成功")
            finally:
                self.conn.commit()
                self.conn.rollback()
        return None
   
    def checkUrl(self, headers, status, id, type, host, port):
        if type == 'http':
            url = "http://" + str(host) + ":" + str(port)
            proxy = {type:url}
        elif type == 'https':
            url = "https://" + str(host) + ":" + str(port)
            proxy = {type:url}
        self.logger.info("生成proxy代理成功" + ",id=" + str(id) + ",type=" + type + ",url=" + url + "...准备测试")

        try:
            res = requests.get(self.CHECK_URL1, headers=headers, proxies=proxy,timeout=10)
        except:
            self.logger.info("测试proxy代理失败" + ",id=" + str(id) + ",type=" + type + ",url=" + url + "...无法使用")
        else:
            status = 'US10'
            if res.status_code == 200 and '<!--STATUS OK-->' in res.text:
                self.logger.info("测试proxy代理成功" + ",id=" + str(id) + ",type=" + type + ",url=" + url + "...可以使用")
                proxy = (type, url, status)
                return proxy
            else:
                self.logger.info("测试proxy代理失败" + ",id=" + str(id) + ",type=" + type + ",url=" + url + "...无法使用")
                
    def main(self):
        proxys_checked = {}
        #获取proxy代理池, 及相关数据
        self.logger.info("开始获取最新的proxys代理池")
        proxys_unchecked = self.getProxies()
        status = 'US99'                             #状态默认不通过
        headers = self.getHeaders()                 #头标识
        #创建多线程队列
        self.logger.info("开始创建校验proxy可用性线程队列")
        proxys_threads = []             #线程
        que = Queue()                   #队列
        for id in proxys_unchecked:
            type = proxys_unchecked[id]['type']
            host = proxys_unchecked[id]['host']
            port = proxys_unchecked[id]['port']
            proxys_threads.append(threading.Thread(target=lambda que, headers, status, id, type, host, port: que.put(self.checkUrl(headers, status, id, type, host, port)), args=(que, headers, status, id, type, host, port)))
            self.logger.info("插入" + "[type:" + type + ";host:" + host + ";port:" + str(port) +"]校验proxy可用性队列成功")
        self.logger.info("创建校验proxy可用性线程队列成功")
        self.logger.info("准备启动校验proxy可用性线程")
        for proxys_thread in proxys_threads:
            proxys_thread.setDaemon(True)
            proxys_thread.start()
        self.logger.info("开始守候校验proxy可用性线程...")
        for proxys_thread in proxys_threads:
            proxys_thread.join(timeout=12)
        self.logger.info("准备获取校验proxy可用性队列结束...")
        id = 1
        while not que.empty():
            result = que.get()
            if result:
                proxys_checked[id] = result
                id += 1
        self.logger.info("获取校验proxy可用性队列结果成功...")
        self.logger.info("准备将proxys插入数据库...")
        self.insertProxies(proxys_checked)
        self.conn.close()
        self.logger.info("proxys插入数据库结束...")

if __name__ == "__main__":
    while True:
        a = Proxy_pools()
        a.main()
        time.sleep(1000)

