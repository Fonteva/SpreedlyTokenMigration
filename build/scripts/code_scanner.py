##
# Script to request a security code scan
# on security.force.com website
# @author mac anderson
##

from selenium import webdriver
from selenium.common.exceptions import TimeoutException
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.common.by import By
import argparse

def main(username):

    # Create a new instance of the Chrome driver
    driver = webdriver.Chrome()

    # go to the webpage containing the force.com code scan submission form
    driver.get("http://security.force.com/security/tools/forcecom/scanner")

    # username form input element
    username_input = driver.find_element_by_id("id_username")

    # type in the search
    username_input.send_keys(username)

    submit_button = driver.find_element_by_class_name("btn-primary")

    # submit form
    submit_button.click()

    # wait for terms and conditions popup
    accept_terms_button = WebDriverWait(driver,10).until(EC.element_to_be_clickable((By.XPATH,"//*[@id='fine_print']/div[3]/a[2]")))

    # accept terms and conditions
    accept_terms_button.click()

    # get success or error message element from sec-tool-messages div
    messages = WebDriverWait(driver,10).until(EC.presence_of_element_located((By.XPATH, "//*[@id='sec-tool-messages']/div")))

    # print the contents of the sec-tool-messages child div element
    print messages.text

    # quit the driver
    driver.quit()

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("username", help="username for the managed package org")
    args = parser.parse_args()
    username = args.username
    main(username)
