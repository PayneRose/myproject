
import requests,re,random,time
from fake_useragent import UserAgent
from getbilibili import Bilibili

#create table if not exists web_ip_pools
#  (id int unsigned not null auto_increment, primary key (id), type varchar(8) not null, host varchar(60) not null, createdate datetime NOT NULL DEFAULT CURRENT_TIMESTAMP());



def get_ip_list(url, headers, proxies):
    htmls = requests.get(url, headers=headers, proxies=proxies, timeout=2).text
    root_pattren = 'alt="Cn" /></td>([\d\D]*?)</tr>'
    root = re.findall(root_pattren, htmls)
    list_ip = []
    
    for i in range(len(root)):
        key = re.findall('<td>([\d\D]*?)</td>', root[i])
        list_ip.append(key[3].lower() + '://' + key[0] + ':' + key[1])
    return list_ip

def get_random_ip(list_ip):
    list_proxy = list_ip
    proxy = random.choice(list_proxy)
    if 'https' in proxy:
        return {'https': proxy}
    return {'http': proxy}
    
def get_proxy(proxies):
    url = 'https://www.xicidaili.com/wt'
    ua = UserAgent()
    headers = {'User-Agent': ua.random}
    list_ip = get_ip_list(url, headers, proxies)
    proxy = get_random_ip(list_ip)
    return proxy


if __name__ == "__main__":
    import pymysql
    INSERTSQL = 'insert into web_ip_pools(type, host) values("{0}", "{1}")'
    conn = pymysql.connect(host="localhost",user="root",passwd="000000",db="webcrawler",charset="utf8")
    cur = conn.cursor()
    a = Bilibili()
    proxies = a.ip_pool_proxies()
    for i in range(10000):
        proxy = get_proxy(proxies)
        for type in proxy:
            host = proxy[type]
            cur.execute(INSERTSQL.format(type, host))
            conn.commit()
        time.sleep(30)
    else:
        conn.close()
    



