import os

class Config:
    # UPDATED: Real live URL for your PDD project
    BASE_URL = os.getenv("BASE_URL", "https://aravi.github.io/PDD/")

    BROWSER = "chrome"
    HEADLESS = True
    IMPLICIT_WAIT = 15
    EXPLICIT_WAIT = 30 # Increased for 100% stability

    REPORTS_PATH = "automation/reports/"
    SCREENSHOTS_PATH = "automation/screenshots/"
    LOGS_PATH = "automation/logs/"
    DATA_PATH = "automation/data/"
