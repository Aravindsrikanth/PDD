from .base_page import BasePage
from selenium.webdriver.common.by import By

class DashboardPage(BasePage):
    SYNC_BUTTON = (By.XPATH, "//div[@aria-label='SYNC SERVER']")
    EMERGENCY_BUTTON = (By.XPATH, "//div[@aria-label='EMERGENCY']")
    PATIENT_MANAGEMENT_TILE = (By.XPATH, "//div[@aria-label='Patient Management']")

    def sync_data(self):
        self.click(self.SYNC_BUTTON)
