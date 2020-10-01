"""
数据库操作
create dabase test;
use test;
create table test_table
(xingming varchar(30),
nianling int(3), 
shenggao int(3));
"""


"""
python3操作
"""

from Dao import Dao
cur = Dao('test')
a = cur.delete('test_table',{'1':'1'})
a = cur.insert('test_table','xingming,nianling,shenggao','"zhangsan",18,175')
a = cur.insert('test_table',['xingming','nianling','shenggao'],['lisi','20','180'])
a = cur.select('test_table','nianling','1=1')
a = cur.select('test_table','nianling,shenggao',{'1':'1'})
a = cur.select('test_table',('nianling','shenggao'),{'xingming' : "zhangsan"})
a = cur.select('test_table',('nianling','shenggao'),{'xingming' : "zhangsan"},unequal=['xingming'])
a = cur.select('test_table',('nianling','shenggao'),{'nianling' : "19"},less=['xingming'])
a = cur.delete('test_table',{'xingming':'zhangsan'})
a = cur.delete('test_table',"xingming='lisi'")
a = cur.update('test_table',{'nianling':'30'},{'xingming':'lisi'})
a = cur.update('test_table',"nianling='40'",{'xingming':'lisi'})
a = cur.complex('select * from test_table where xingming="lisi"','select')
a = cur.complex('insert into test_table (xingming,nianling,shenggao) values ("zhaowu","50","190")','merge')
a = cur.delete('test_table','1=1')



