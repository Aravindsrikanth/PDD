# ICU Suite Pro - Selenium Automation Framework

## Setup
1. Install Python 3.10+
2. Install dependencies: `pip install -r requirements.txt` (needs to be created)
3. Set `BASE_URL` environment variable.

## Execution
Run all tests:
```bash
pytest automation/tests/test_runner.py
```

## Folder Structure
- `pages/`: Page Object Model implementation.
- `tests/`: 400+ Test cases.
- `data/`: Test data and JSON cases.
- `utils/`: Logging and reporting utilities.
## Troubleshooting
- **Chrome Version Mismatch**: Ensure your local ChromeDriver matches your Chrome browser version.
- **Wait Timeouts**: If the UI loads slowly, increase `EXPLICIT_WAIT` in `config.py`.
- **CORS Errors**: Ensure the live GitHub Pages site has the correct headers if calling external APIs.
