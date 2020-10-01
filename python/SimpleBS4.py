#! /usr/bin/python3
#date = 20180430
#writer = pangfaheng

from bs4 import BeautifulSoup
from urllib.request import urlopen

html = urlopen("https://lances.xyz/wordpress/?p=92")
bs_obj = BeautifulSoup(html.read(), 'html.parser')
test_line = bs_obj.find_all("div","post-92 post type-post status-publish format-standard hentry category-python post-container col-md-12")

for line in test_line :
    print(line.get_text())

html.close()

print("好了")

