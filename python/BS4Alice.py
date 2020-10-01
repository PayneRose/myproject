#! /usr/bin/python3
#date = 20180502
#writer = pangfaheng

from bs4 import BeautifulSoup

html_doc = """
<html><head><title>The Dormouse's story</title></head>
<body>
<p class="title"><b>The Dormouse's story</b></p>

<p class="story">Once upon a time there were three little sisters; and their names were
<a href="http://example.com/elsie" class="sister" id="link1">Elsie</a>,
<a href="http://example.com/lacie" class="sister" id="link2">Lacie</a> and
<a href="http://example.com/tillie" class="sister" id="link3">Tillie</a>;
and they lived at the bottom of a well.</p>

<p class="story">...</p>
"""

soup = BeautifulSoup(html_doc, 'html.parser')
# html.parser:网站源码分析器
print("*"*50,'\n')
print(soup.prettify())
# prettify:美化
print("*"*50,'\n')
print(soup.title)
#获取title标签的字段
print("*"*50,'\n')
print(soup.body)
#获取body标签的字段
print("*"*50,'\n')
print(soup.find_all('a'))
#获取所有含有'a'标签的字段
