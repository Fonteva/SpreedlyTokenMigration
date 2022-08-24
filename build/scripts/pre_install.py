#!/usr/bin/env python
import argparse

from OrgGuiTools import OrgGuiTools

def main(username, password, namespace,instance):
    setup = OrgGuiTools(username, password, namespace,instance)
    setup.set_ui_prefs()
    setup.delete_profile('Custom: Marketing Profile')
    setup.delete_profile('Custom: Sales Profile')
    setup.delete_profile('Custom: Support Profile')
    setup.set_profile_default_app("System Administrator")
    setup.set_profile_default_app("Service Cloud")
    setup.enable_translation_workbench()
    setup.enable_chatter()
    setup.disable_social_accounts_settings()
    setup.set_namespace()
    setup.delete_custom_apps()
    setup.quit()

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("username", help="salesforce username")
    parser.add_argument("password", help="salesforce password (no token)")
    parser.add_argument("-i","--instance", help="instance to update",default="production")
    parser.add_argument("-n", "--namespace", help="intended salesforce namespace")
    args = parser.parse_args()
    username = args.username
    password = args.password
    namespace = args.namespace
    instance = args.instance
    main(username, password, namespace,instance)
