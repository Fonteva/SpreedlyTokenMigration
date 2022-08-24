#!/usr/bin/env python
import xml.etree.ElementTree as ET
import argparse
import logging

def main(layout_version, file):
    logging.basicConfig(level=logging.WARNING)
    tree = ET.parse(file)
    root = tree.getroot()

    ns = "http://soap.sforce.com/2006/04/metadata"
    ET.register_namespace('', ns)

    for node in root.findall("{{{ns}}}{XML}".format(ns=ns, XML="types")):
        node_text = node.find("{{{ns}}}{XML}".format(ns=ns, XML="name")).text 
        if not "Layout" in node_text:
            logging.info("Removing node: {0}".format(node_text))
            root.remove(node)
        else:
            for elem in node.findall('.//'):
                logging.info("Parsing element: {0} @ {1}".format(elem.text, elem))
                if "name" in elem.tag:
                    continue
                if layout_version in elem.text:
                    node.remove(elem)
    tree.write('destructiveChanges.xml')

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Utility to generate a "
        "descrictiveChanges.xml file to remove old page layouts")
    parser.add_argument("layout", help="current layout to preserve")
    parser.add_argument("file", help="file to parse layouts for")
    args = parser.parse_args()
    layout = args.layout
    file = args.file
    main(layout, file)
