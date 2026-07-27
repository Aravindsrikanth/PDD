import json
import os

def generate_cases():
    test_cases = []
    categories = {
        "Authentication": 40,
        "Authorization": 40,
        "Navigation": 30,
        "UI Validation": 50,
        "Forms": 50,
        "CRUD Operations": 50,
        "Input Validation": 40,
        "Error Handling": 20,
        "Session Management": 20,
        "File Upload": 20,
        "Accessibility": 20,
        "Responsive Design": 20,
        "Performance Smoke Tests": 20,
        "Regression": 50
    }

    id_counter = 1
    for category, count in categories.items():
        for i in range(count):
            test_cases.append({
                "Test Case ID": f"TC_{id_counter:03d}",
                "Module": category,
                "Test Name": f"Verify {category} Case {i+1}",
                "Priority": "High" if i < 10 else "Medium",
                "Preconditions": "Application is live",
                "Test Steps": ["Open URL", "Navigate to module", "Execute action"],
                "Expected Result": "Action successful",
                "Status": "Pending"
            })
            id_counter += 1

    with open("automation/data/test_cases.json", "w") as f:
        json.dump(test_cases, f, indent=4)

if __name__ == "__main__":
    generate_cases()
