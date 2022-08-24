#!/usr/bin/env python
import sys
import urllib
import logging

from selenium import webdriver
from selenium.common.exceptions import NoSuchElementException, TimeoutException
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.common.by import By
from selenium.webdriver.support import expected_conditions as EC

from sf_urls import get_urls

class OrgGuiTools(object):
    """This class provides tools to complete the undeploy scripts and prepare
    the org to have Fonteva software deployed to it."""
    def __init__(self, username, password, namespace=None,instance="production"):
        logging.basicConfig(level=logging.INFO)
        self.username = username
        self.password = password
        self.namespace = namespace
        self.ids = {"chatter_enable_checkbox_id": "j_id0:theForm:thePageBlock:collabPrefSection:collabPrefFieldSection:togglePref",
                    "chatter_settings_save_id": "j_id0:theForm:thePageBlock:btnPageBlock:save",
                    "chatter_settings_edit_id": "j_id0:theForm:thePageBlock:btnPageBlock:edit",
                    "package_install_continue": "InstallPackagePage:InstallPackageForm:InstallBtn",
                    "package_upload": "ViewAllPackage:theForm:packageDetailBlock:j_id157:upload"
                   }
        self.xpaths = {"custom_field_level_security": "//*/h4[text()='Custom Field-Level Security']/../../..//a[text()='View']"}
        self.js_alert_override = "window.confirm = function(msg) { return true; }"

        #self.driver = webdriver.PhantomJS()
        self.driver = webdriver.Chrome()
        self.driver.set_window_size(1400, 800)
        self.wait = WebDriverWait(self.driver, 20)
        self.instance = "login.salesforce.com"
        if "sandbox" == instance:
            self.instance = "test.salesforce.com"

        self.login_url = "https://{instance}/?un={username}&pw={password}".format(
                          instance=urllib.quote_plus(self.instance),
                          username=urllib.quote_plus(username),
                          password=urllib.quote_plus(password))
        self.driver.get(self.login_url)
        try:
            element = WebDriverWait(self.driver, 5).until(lambda x: x.find_element_by_id('userNavButton'))
        except:
            if "Your login attempt has failed" in self.driver.page_source:
                raise Exception("Could not login to org with username: "
                    "'{username}' & password: '{password}'".format(username=self.username,
                                                                  password=self.password))
            elif "Register for mobile verification" in self.driver.page_source:
                self.driver.find_element_by_partial_link_text("I don't want to use mobile verification").click()
            elif "Activation Required" in self.driver.page_source:
                raise Exception("Unable to login to Org because activation is required")
            else:
                raise Exception("Unable to login to Org for unknown reasons!")

        self.base_sf_url = self.driver.current_url[:self.driver.current_url.find("salesforce.com")] + "salesforce.com"
        self.urls = get_urls(self.base_sf_url)

    def set_ui_prefs(self):
        """Turns on the required UI preferences that the rest of the script depends on"""
        self.driver.get(self.urls['ui_preferences'])
        ids = ['enhancedProfileMgmt', 'useSetupV2', 'useSetupSearch']
        for id in ids:
            elem = self.driver.find_element_by_id(id)
            if elem.is_selected() != True:
                elem.click()
        self.driver.find_element_by_id('saveButton').click()

    def release_managed_package(self, package):
        self.driver.get(self.urls['packages_url'])
        self.driver.find_element_by_link_text(package).click()
        self.driver.find_element_by_id(self.ids['package_upload'])
        pass

    def install_managed_package(self, package_link):
        self.driver.get(package_link)
        self.driver.find_element_by_id(self.ids["package_install_continue"]).click()
        element = WebDriverWait(self.driver, 3).until(lambda x: x.find_element_by_name('goNext'))
        element.click()
        element = WebDriverWait(self.driver, 3).until(lambda x: x.find_element_by_id('p201FULL'))
        element.click()
        element = WebDriverWait(self.driver, 3).until(lambda x: x.find_element_by_name('goNext'))
        element.click()
        element = WebDriverWait(self.driver, 3).until(lambda x: x.find_element_by_name('save'))
        element.click()
        assert("Install Complete" in self.driver.page_source), "Install failed or need to handle 'email' scenario"

    def delete_assignment_rules(self):
        """can be depricated with release of new ant-salesforce.jar for api v30"""
        self._delete_case_rules(self.urls['case_assignment_rules_url'])

    def delete_escalation_rules(self):
        """can be depricated with release of new ant-salesforce.jar for api v30"""
        self._delete_case_rules(self.urls['case_escalation_rules_url'])

    def _delete_case_rules(self, url):
        """Deletes case assignment or escalation rules.
        delete_case_rules(url)
        url - url of case assignment or case escalation rules"""
        self.driver.get(url)
        #override window.confirm to always return true.  https://github.com/detro/ghostdriver/issues/20
        while True:
            try:
                self.driver.execute_script("window.confirm = function(msg){return true;};")
                self.driver.find_element_by_link_text('Del').click()
            except NoSuchElementException:
                break

    def delete_profile(self, profile):
        """Deletes a profile"""
        self.driver.get(self.urls['profile_url'])
        try:
            element = WebDriverWait(self.driver, 3).until(lambda x: x.find_element_by_link_text(profile))
            element.click()
            self.driver.execute_script(self.js_alert_override)
            element = WebDriverWait(self.driver, 3).until(lambda x: x.find_element_by_name('del'))
            element.click()
        except TimeoutException:
            logging.warning("profile: '{profile}' not found!  Already deleted?".format(profile=profile))

    def delete_custom_apps(self):
        self.driver.get(self.urls['create_apps'])
        for app in self.driver.find_elements_by_link_text('Del'):
            try:
                self.driver.execute_script(self.js_alert_override)
                app.click()
            except:
                logging.warning("Could not delete custom app")

    def open_profile_page(self, profile):
        self.driver.get(self.urls['profile_url'])
        try:
            element = WebDriverWait(self.driver, 20).until(lambda x: x.find_element_by_link_text(profile))
            element.click()
        except TimeoutException:
            self.driver.find_element_by_class_name("pageInput").send_keys(Keys.BACKSPACE)
            self.driver.find_element_by_class_name("pageInput").send_keys('2')
            self.driver.find_element_by_class_name("pageInput").send_keys(Keys.ENTER)
            element = WebDriverWait(self.driver, 20).until(lambda x: x.find_element_by_link_text(profile))
            element.click()

    def set_profile_default_app(self, profile, app="App Launcher Default"):
        """Sets a salesforce profile to a default app."""
        try:
            self.open_profile_page(profile)
        except TimeoutException:
            logging.warn("{profile} not found!!".format(profile=profile))
            return
        self.driver.find_element_by_name('edit').click()
        for web_element in self.driver.find_elements_by_name('tabSet_default'):
            if web_element.get_attribute("title") == app:
                web_element.click()
                break
        else:
            raise Exception("No default app: \"%s\" found!!" % app)
        self.driver.find_element_by_name('save').click()

    def set_field_level_security(self, fields=[], profile="System Administrator"):
        self.open_profile_page(profile)
        org_id = self.driver.current_url.split('/')[-1]
        field_sec_url_template = self.base_sf_url + "/setup/layout/flsdetail.jsp?id={id}&type={field}&retURL=%2F{id}"
        checked = 0
        for field in fields:
            element = WebDriverWait(self.driver, 20).until(lambda x: x.find_element_by_id("buddy_list_min_text"))
            self.driver.get(field_sec_url_template.format(id=org_id, field=field))
            checked += self._make_visible()
        logging.info("Checked {num} boxes for standard fields".format(num=checked))
        self.open_profile_page(profile)
        checked = 0
        for i in range(len(self.driver.find_elements_by_xpath(self.xpaths['custom_field_level_security']))):
            element = WebDriverWait(self.driver, 20).until(lambda x: x.find_element_by_id("buddy_list_min_text"))
            self.driver.find_elements_by_xpath(self.xpaths['custom_field_level_security'])[i].click()
            checked += self._make_visible()
            self.driver.find_element_by_name('profile').click()
        logging.info("Checked {num} boxes for custom fields".format(num=checked))

    def set_field_level_securityViaID(self,fields=[],profile=None):
        if profile == None:
             return 'Oh no! Danger! All run away!'
        self.driver.get( self.base_sf_url + "/"+profile)
        org_id = self.driver.current_url.split('/')[-1]
        field_sec_url_template = self.base_sf_url + "/setup/layout/flsdetail.jsp?id={id}&type={field}&retURL=%2F{id}"
        checked = 0
        for field in fields:
            element = WebDriverWait(self.driver, 20).until(lambda x: x.find_element_by_id("buddy_list_min_text"))
            self.driver.get(field_sec_url_template.format(id=org_id, field=field))
            checked += self._make_visible()
        logging.info("Checked {num} boxes for standard fields".format(num=checked))
        checked = 0
        self.driver.get( self.base_sf_url + "/"+profile)
        for i in range(len(self.driver.find_elements_by_xpath(self.xpaths['custom_field_level_security']))):
            element = WebDriverWait(self.driver, 20).until(lambda x: x.find_element_by_id("buddy_list_min_text"))
            self.driver.find_elements_by_xpath(self.xpaths['custom_field_level_security'])[i].click()
            checked += self._make_visible()
            self.driver.find_element_by_name('profile').click()
        logging.info("Checked {num} boxes for custom fields".format(num=checked))


    def _make_visible(self):
        self.driver.find_element_by_name('save').click()
        element = WebDriverWait(self.driver, 20).until(lambda x: x.find_element_by_id("buddy_list_min_text"))
        checked = 0
        for box in self.driver.find_elements_by_xpath("//*[@title='Visible']"):
            if box.is_selected() != True:
                box.click()
                checked += 1
        self.driver.find_element_by_name('save').click()
        return checked

    def set_namespace(self):
        if self.namespace == None:
            logging.error("SKIPPING SETTING NAMESPACE!!\n-- no namespace provided --")
            return
        try:
            self.driver.get(self.urls['packages_url'])
            self.driver.find_element_by_name('changeDevSettings').click()
            self.driver.find_element_by_name('proceed').click()
            self.driver.find_element_by_id('namespace').send_keys(self.namespace)
            self.driver.find_element_by_name('CheckNamespace').click()
            self.driver.find_element_by_name('goNext').click()
            self.driver.find_element_by_name('save').click()
        except:
            logging.critical("Unable to set namespace!!")

    def enable_translation_workbench(self):
        self.driver.get(self.urls['translation_settings_url'])
        buttons = self.driver.find_elements_by_class_name('btn')
        for btn in buttons:
            if btn.get_attribute('Value') == 'Enable':
                btn.click()
                break
            elif btn.get_attribute('Title') == 'Disable':
                #translation workbench is already enabled.
                break
        else:
            raise Exception("Could not locate/click 'Enable' button for Translation Workbench")

    def enable_chatter(self):
        self.driver.get(self.urls['chatter_settings_url'])
        self.driver.find_element_by_id(self.ids['chatter_settings_edit_id']).click()
        check_box = self.driver.find_element_by_id(self.ids['chatter_enable_checkbox_id'])
        if not check_box.is_selected():
            check_box.click()
            self.driver.find_element_by_id(self.ids['chatter_settings_save_id']).click()

    def disable_social_accounts_settings(self):
        self.driver.get(self.urls['social_accounts_contacts_url'])
        elem = self.driver.find_element_by_id('enable_social_profiles')
        if elem.is_selected():
            elem.click()
            element = WebDriverWait(self.driver, 20).until(lambda x: x.find_element_by_name('save'))
            element.click()

    def quit(self):
        self.driver.quit()
