#!/usr/bin/env python
#
# This script takes a Salesforce custom object file and generates a map file (sdl)
#
import argparse
import xml.etree.ElementTree as ET

def main(obj, namespace):
    tree = ET.parse(obj)
    root = tree.getroot()
    name = obj.split('.')[0].split('__c')[0]

    with open('{name}.sdl'.format(name=name), 'w') as f:
        #write in the standard fields
        nf = root.find('{http://soap.sforce.com/2006/04/metadata}nameField')
        for elem in nf.getchildren():
            if elem.tag == '{http://soap.sforce.com/2006/04/metadata}label':
                nameField = elem.text
        std_fields = (("{nameField}".format(nameField=nameField), "Name"),
                      ("Created By", "CreatedBy"),
                      ("Last Modified By", "LastModifiedBy"),
                      ("Owner", "Owner"))

        for label, fullName in std_fields:
            f.write("{label}={fullName}\n".format(
                label=label.replace(' ', '\ '),
                namespace=namespace,
                fullName=fullName))

        for i in root.findall('{http://soap.sforce.com/2006/04/metadata}fields'):
            #parse the xml object
            label = i.find('{http://soap.sforce.com/2006/04/metadata}label').text
            fullName = i.find('{http://soap.sforce.com/2006/04/metadata}fullName').text
            #check if there is a parent reference
            ref =  i.find('{http://soap.sforce.com/2006/04/metadata}referenceTo')
            #check if the field is a formula field (which aren't included in a map)
            formula =  i.find('{http://soap.sforce.com/2006/04/metadata}formula')
            if ref is not None:
                 f.write("{label}={ns}__{field}\:{ns}__Data_Load_Key__c\n".format(
                    label=label.replace(' ', '\ '),
                     ns=namespace, 
                     field=fullName.replace('__c', '__r')))
            elif formula is not None:
                continue
            else:
                f.write("{label}={namespace}__{fullName}\n".format(
                    label=label.replace(' ', '\ '),
                    namespace=namespace,
                    fullName=fullName))

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="A utility to generate a salesforce"
             " maps file (sdl) from a Salesforce CUSTOM object")
    parser.add_argument("obj", help="The salesforce object to generate a map for")
    parser.add_argument("namespace", help="The namespace to prefix the maped objects for")
    args = parser.parse_args()
    obj = args.obj
    namespace = args.namespace
    main(obj, namespace)
