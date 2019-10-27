#! /usr/local/bin/python3.7
import tushare as ts
import sys,psycopg2,os

#sys.stdout.reconfigure(encoding='gbk')

conn = psycopg2.connect(host="127.0.0.1", user="root", password="000000", dbname="mysite", port=9527)
cur = conn.cursor()
INSERT_SQL = """ 
    INSERT INTO gupiao_tushare_today (code,name,changepercent,trade,open,high,low,settlement,volume,turnoverratio,amount,per,pb,mktcap,nmc) 
    VALUES('{0}', '{1}', '{2}', '{3}', '{4}', '{5}', '{6}', '{7}', '{8}', '{9}', '{10}', '{11}', '{12}', '{13}', '{14}');
"""

gp_today = ts.get_today_all()

for id in range(gp_today.index.stop):
    data = dict(gp_today.loc[id])
    code = data['code']
    name = data['name']
    changepercent = data['changepercent']
    trade = data['trade']
    open = data['open']
    high = data['high']
    low = data['low']
    settlement = data['settlement']
    volume = data['volume']
    turnoverratio = data['turnoverratio']
    amount = data['amount']
    per = data['per']
    pb = data['pb']
    mktcap = data['mktcap']
    nmc = data['nmc']
    cur.execute(INSERT_SQL.format(code,name,changepercent,trade,open,high,low,settlement,volume,turnoverratio,amount,per,pb,mktcap,nmc))

conn.commit()
conn.close()




