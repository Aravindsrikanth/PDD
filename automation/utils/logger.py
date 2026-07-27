import logging
import os

def setup_logger(log_name):
    logger = logging.getLogger(log_name)
    logger.setLevel(logging.INFO)

    formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')

    file_handler = logging.FileHandler(os.path.join("automation/logs", f"{log_name}.log"))
    file_handler.setFormatter(formatter)

    logger.addHandler(file_handler)
    return logger
