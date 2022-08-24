#!/usr/bin/env python
import argparse
import logging

from OrgGuiTools import OrgGuiTools

def main(package, link):
    logging.basicConfig(level=logging.INFO)
    packages = ['framework', 'drive', 'pagesapi', 'orderapi', 'eventapi']
    password = "Fonteva703"
    for org in range(packages.index(package)+1, len(packages)):
        logging.info("Installing {package} in {org} org".format(package=package, org=packages[org]))
        gt = OrgGuiTools("integration@{package}.com".format(package=packages[org]), password)
        gt.install_managed_package(link)
        gt.quit()

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("package", help="QA managed packed to be released to other QA orgs")
    parser.add_argument("link", help="managed package install link")
    args = parser.parse_args()
    package = args.package.lower()
    link = args.link
    main(package, link)
