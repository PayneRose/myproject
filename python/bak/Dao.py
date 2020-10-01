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

    # @staticmethod
    def select(self, column, table, condition=""):

        '''
        用于查询
        '''

        with self.db_connect.cursor() as cursor:
            try:
                if condition:
                    query = """ select {0} from {1} where {2}""".format(column, table, condition)
                    cursor.execute(query)
                    query_result = cursor.fetchall()
                    return query_result
                else:
                    query = """ select {0} from {1}""".format(column, table)
                    cursor.execute(query)
                    query_result = cursor.fetchall()
                    return query_result

            except pymysql.MySQLError as error_select:
                print(error_select)

    def insert(self, table, column, value):
        
        '''
        用于插入
        '''

        with self.db_connect.cursor() as cursor:
            try:
                query_insert = """ INSERT INTO {0} ({1}) values ({2})""".format(table, column, value)
                cursor.execute(query_insert)
                self.db_connect.commit()
                return cursor.lastrowid
            except pymysql.MySQLError as error_insert:
                print(error_insert)

    def delete(self, table, condition):
        
        '''
        用于删除
        '''

        with self.db_connect.cursor() as cursor:
            try:
                query_delete = """ DELETE FROM {0} WHERE {1}""".format(table, condition)
                cursor.execute(query_delete)
                self.db_connect.commit()
            except pymysql.MySQLError as error_delete:
                print(error_delete)

    def update(self, table, column, condition):
        
        '''
        用于更新
        '''
        
        with self.db_connect.cursor() as cursor:
            try:
                query_update = """ UPDATE {0} SET {1} WHERE {2}""".format(table, column, condition)
                cursor.execute(query_update)
                self.db_connect.commit()
                return cursor.lastrowid
            except pymysql.MySQLError as error_update:
                print(error_update)


    def complex(self, query, type):
        
        '''
        用于执行复杂语句，拥有两种类型：select（返回查询结果） 和 merge（用于提交功能）
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
                    

