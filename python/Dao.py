#!/usr/bin/python
# -*- coding: utf-8 -*-


from config import config
import pymysql.cursors


class Dao:
    def __init__(self, case):
        
        '''
        输入需要连接的用例，必须在配置文件中存在该用例的参数
        '''
        
        self.db_connect = self.__connect(case)

    @staticmethod
    def __connect(case):
        
        '''
        获取配置文件参数，可以匹配多个数据库
        连接数据库
        '''
        
        host = config.get(case, "host")
        user = config.get(case, "user")
        password = config.get(case, "password")
        db = config.get(case, "db")
        timeout = int(config.get(case, "timeout"))
        charset = config.get(case, "charset")
        try:
            connection = pymysql.connect(host, user, password, db, autocommit=False, connect_timeout=timeout, charset=charset)
            return connection
        except pymysql.err.MySQLError as error_connect:
            print(error_connect)
            print("连接失败")
            return False           


    @staticmethod
    def __join_condition(condition, equal, unequal, greater, less, greater_equal, less_equal):
    
        """
        ---条件对应关系
        用于生成条件，支持字典，当条件为字符串时直接返回
        参数: condition; example: {region:'200',opnid:'SH1010001'} => 返回: "region='200' and opnid='SH1010001'"
        将字段添加在equal, unequal, greater, less, greater_equal, less_equal（可以为列表或元组），表示该字段在字典中对应的值的关系，如果不添加默认为等于关系
        """
        #最终返回的结果
        join_condition = []
    
        #如果条件为空，返回1=0
        if not condition:
            join_condition = ' 1 = 0 '
            return join_condition
        
        #如果条件为字符串，不做处理直接返回
        if isinstance(condition,str):
            join_condition = condition
            return join_condition
        
        if not isinstance(condition,dict):
            join_condition = ' 1 = 0 '
            return join_condition
            
        for i in condition:
            #如果字典里面的键和值有任意一个不为字符串，返回1=0
            if not isinstance(i,str) or not isinstance(condition[i],str):
                join_condition = ' 1 = 0 '
                return join_condition
            if i in equal:
                join_condition.append("{0} = '{1}'".format(i,condition[i]))
            elif i in greater:
                join_condition.append("{0} > '{1}'".format(i,condition[i]))        
            elif i in less:
                join_condition.append("{0} < '{1}'".format(i,condition[i]))   
            elif i in unequal:
                join_condition.append("{0} != '{1}'".format(i,condition[i]))
            elif i in greater_equal:
                join_condition.append("{0} >= '{1}'".format(i,condition[i]))
            elif i in less_equal:
                join_condition.append("{0} <= '{1}'".format(i,condition[i]))
            else:
                join_condition.append("{0} = '{1}'".format(i,condition[i]))
        else:
            join_condition = ' and '.join(join_condition)
            return join_condition   
    
    @staticmethod
    def __join_column(column):
        """
        插入时使用，用于合并字段，支持列表、元组，当输入为字符串时直接返回字符串
        """
        if isinstance(column,str):
            pass
        elif isinstance(column,list):
            column = ','.join(column)
        elif isinstance(column,tuple):
            column = ','.join(column)
        else:
            pass
        return column

    @staticmethod
    def __join_value(value):
        """
        插入时使用，用于合并参数，支持列表、元祖，当输入为字符串时直接返回字符串
        """
        if isinstance(value,str):
            pass
        elif isinstance(value,list):
            value = '"' + '","'.join(value) + '"'
        elif isinstance(value,tuple):
            value = '"' + '","'.join(value) + '"'
        else:
            pass
        return value

        

    def select(self, table, column, condition, equal=[], unequal=[], greater=[], less=[], greater_equal=[], less_equal=[]):

        '''
        用于查询，格式：select(表名称，字段(支持列表、元组)，条件(支持字符串、字典)，条件对应关系（可以为空）)
        '''

        column = self.__join_column(column)
        
        condition = self.__join_condition(condition,equal,unequal,greater,less,greater_equal,less_equal)
        with self.db_connect.cursor() as cursor:
            try:
                query = """ select {0} from {1} where {2}""".format(column, table, condition)
                cursor.execute(query)
                query_result = cursor.fetchall()
                return query_result
            except pymysql.MySQLError as error_select:
                print(error_select)

    def insert(self, table, column, value):
        
        '''
        用于插入，格式：insert(表名称，字段(支持列表、元组)，参数(支持列表、元组))
        '''
        
        column = self.__join_column(column)
        value = self.__join_value(value)

        with self.db_connect.cursor() as cursor:
            try:
                query_insert = """ INSERT INTO {0} ({1}) values ({2})""".format(table, column, value)
                print(query_insert)
                cursor.execute(query_insert)
                self.db_connect.commit()
                return cursor.lastrowid
            except pymysql.MySQLError as error_insert:
                print(error_insert)

    def delete(self, table, condition, equal=[], unequal=[], greater=[], less=[], greater_equal=[], less_equal=[]):
        
        '''
        用于删除
        格式：detele(表名称，条件，条件对应关系（可以为空）)
        '''

        condition = self.__join_condition(condition,equal,unequal,greater,less,greater_equal,less_equal)
        
        with self.db_connect.cursor() as cursor:
            try:
                query_delete = """ DELETE FROM {0} WHERE {1}""".format(table, condition)
                cursor.execute(query_delete)
                self.db_connect.commit()
            except pymysql.MySQLError as error_delete:
                print(error_delete)

    def update(self, table, condition_new, condition_old, equal=[], unequal=[], greater=[], less=[], greater_equal=[], less_equal=[]):
        
        '''
        用于更新
        格式: update(表名称，即将更新的字段和值（用字典表示），需要更新的字段和值（即条件，也用字典表示，可以带“条件对应关系”）
        '''
        
        if isinstance(condition_new,dict):
            condition_new = self.__join_condition(condition_new,equal=list(condition_new.keys()),unequal=[], greater=[], less=[], greater_equal=[], less_equal=[])
        else:
            pass
        
        condition_old = self.__join_condition(condition_old,equal,unequal,greater,less,greater_equal,less_equal)

        with self.db_connect.cursor() as cursor:
            try:
                query_update = """ UPDATE {0} SET {1} WHERE {2}""".format(table, condition_new, condition_old)
                cursor.execute(query_update)
                self.db_connect.commit()
                return cursor.lastrowid
            except pymysql.MySQLError as error_update:
                print(error_update)


    def complex(self, query, type):
        
        '''
        用于执行复杂语句，拥有两种类型：select（返回查询结果） 和 merge（拥有提交功能）
        '''

        if type == "merge":
            with self.db_connect.cursor() as cursor:
                try:
                    cursor.execute(query)
                    self.db_connect.commit()
                    return cursor.lastrowid
                except pymysql.MySQLError as error_merge:
                    print(error_merge)
        elif type == "select":
            with self.db_connect.cursor() as cursor:
                try:
                    cursor.execute(query)
                    query_result = cursor.fetchall()
                    return query_result
                except pymysql.MySQLError as error_select:
                    print(error_select)

                 
    




