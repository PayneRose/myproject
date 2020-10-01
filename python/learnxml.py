
import xml.etree.ElementTree as ET

## from file.xml
#tree = ET.parse('country_data.xml')
#root = tree.getroot()
#
## or from string
## root = ET.fromstring(country_data_as_string)
#
#print("that is master tag: ", root.tag)
#
#print("that is master attrib: ", root.attrib)
#
#for child in root:
#    print("that is child tag: ", child.tag, "and that is child attrib: ", child.attrib)
#
#
#print("that is year in xml[0][1]: ", root[0][1].text)
#
#for neighbor in root.iter('neighbor'):
#    print(neighbor.attrib)


tree = ET.parse('sql.xml')
root = tree.getroot()

for child in root:
    print("that is child tag: ",child.tag, "and that is child attrib: ", child.attrib)


end = {}
for child in root:
    if child.attrib['name'] == 'updatesomtime':
        for nextchild in child:
            end[nextchild.tag] = nextchild.text
else:
    print end