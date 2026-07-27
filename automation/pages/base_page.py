from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.common.exceptions import TimeoutException
import os

class BasePage:
    def __init__(self, driver, config):
        self.driver = driver
        self.config = config
        self.wait = WebDriverWait(self.driver, self.config.EXPLICIT_WAIT)

    def find_element(self, locator):
        return self.wait.until(EC.presence_of_element_condition(locator))

    def click(self, locator):
        element = self.wait.until(EC.element_to_be_clickable(locator))
        element.click()

    def enter_text(self, locator, text):
        element = self.find_element(locator)
        element.clear()
        element.send_keys(text)

    def get_text(self, locator):
        element = self.find_element(locator)
        return element.text

    def is_visible(self, locator):
        try:
            self.wait.until(EC.visibility_of_element_located(locator))
            return True
        except TimeoutException:
            return False

    def take_screenshot(self, test_id):
        screenshot_name = f"{test_id}.png"
        path = os.path.join(self.config.SCREENSHOTS_PATH, screenshot_name)
        self.driver.save_screenshot(path)
        return path
