#!/usr/bin/env python
##
## A utility to take the output of `ant deploy` failure,
## and add missing resources to the package.xml
##
import argparse

xml_map = {"classes": "<name>ApexClass</name>",
           "triggers": "<name>ApexTrigger</name>"}

def parse_log(file):
    with open(file, "r") as f:
        lines = f.readlines()
    start = lines.index("All Component Failures:\n") + 1
    finish = len(lines) - lines[::-1].index("*********** DEPLOYMENT FAILED ***********\n") - 1
    change_set = []
    for i in range(start, finish):
        if lines[i] == '\n':
            continue
        section = lines[i].split()[1].split('/')[0]
        entry = lines[i].split()[1].split('/')[-1].split('.')[0]
        change_set.append((section, entry))
    return change_set

def update_package_xml(mod, package_xml):
    """Takes a modification (section, entry)  and updates the package.xml"""
    with open(package_xml, "r") as f:
        lines = f.readlines()
        stripped = lines[:]
        for i in range(0, len(lines)):
            stripped[i] = stripped[i].strip()
    section, entry = mod
    index = stripped.index(xml_map[section])
    entry = "<members>{cdata}</members>\n".format(cdata=entry)
    lines.insert(index, entry)
    new_file = "".join(lines)
    with open("package.xml", "w") as fw:
        fw.write(new_file)

def main(log, package_xml):
    for mod in parse_log(log):
        update_package_xml(mod, package_xml)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="A utility to update a package.xml with"
             " missing resources in a package.")
    parser.add_argument("log", help="output file of failed build")
    parser.add_argument("package_xml", help="package.xml to update")
    args = parser.parse_args()
    log = args.log
    package_xml = args.package_xml
    main(log, package_xml)
