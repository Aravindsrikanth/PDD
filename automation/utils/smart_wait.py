from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.common.exceptions import TimeoutException, StaleElementReferenceException
import time

class SmartWait:
    @staticmethod
    def wait_and_interact(driver, locator, timeout=20, retries=3):
        """Advanced wait mechanism for Flutter Web's dynamic DOM."""
        last_exception = None
        for i in range(retries):
            try:
                element = WebDriverWait(driver, timeout).until(
                    EC.element_to_be_clickable(locator)
                )
                return element
            except (TimeoutException, StaleElementReferenceException) as e:
                last_exception = e
                time.sleep(1) # Small delay before retry
        raise last_exception
