import xml.etree.ElementTree as ET
from Dao import Dao

database = 'test'
xmlfile = 'sql.xml'

sql = Dao(database)
tree = ET.parse(xmlfile)
root = tree.getroot()

class GetValues:
    pass

class GetSql:
    pass

class implement(GetValues,GetSql):
    pass












