#!/usr/bin/env python3
"""Test script to upload and analyze food images."""

import os
import requests

BASE_URL = "http://localhost:5001"
TEST_PHONE = "+15305550000"
TEST_CODE = "123456"
APP_ID = "test_app"

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
TEST_IMAGES = [
    os.path.join(SCRIPT_DIR, "test_food", "burger_and_fries.jpg"),
    os.path.join(SCRIPT_DIR, "test_food", "spaghetti.jpg"),
    os.path.join(SCRIPT_DIR, "test_food", "dog.jpg"),
]


def get_auth_token():
    """Login and return auth token."""
    print(f"Logging in with {TEST_PHONE}...")

    # Send SMS code
    response = requests.post(
        f"{BASE_URL}/v1/send_sms_code",
        json={"phone_number": TEST_PHONE, "app_id": APP_ID}
    )
    if response.status_code != 200:
        print(f"  Failed to send SMS: {response.json()}")
        return None

    # Verify code
    response = requests.post(
        f"{BASE_URL}/v1/verify_code",
        json={"phone_number": TEST_PHONE, "app_id": APP_ID, "code": TEST_CODE}
    )
    if response.status_code != 200:
        print(f"  Failed to verify: {response.json()}")
        return None

    token = response.json()["token"]
    print(f"  Got token: {token[:20]}...")
    return token


def analyze_image(token, image_path):
    """Upload and analyze a single image."""
    image_name = os.path.basename(image_path)
    print(f"\n{'='*50}")
    print(f"Analyzing: {image_name}")
    print('='*50)

    # Step 1: Get upload URL
    print("\n1. Getting upload URL...")
    response = requests.get(
        f"{BASE_URL}/v1/food/upload_url",
        headers={"Authorization": f"Bearer {token}"}
    )
    if response.status_code != 200:
        print(f"   Failed: {response.json()}")
        return

    upload_url = response.json()["upload_url"]
    image_id = response.json()["image_id"]
    print(f"   Image ID: {image_id}")

    # Step 2: Upload image
    print("\n2. Uploading image to GCS...")
    with open(image_path, "rb") as f:
        image_data = f.read()

    response = requests.put(
        upload_url,
        data=image_data,
        headers={"Content-Type": "image/jpeg"}
    )
    if response.status_code not in (200, 201):
        print(f"   Failed to upload: {response.status_code} {response.text}")
        return
    print(f"   Upload successful!")

    # Step 3: Analyze image
    print("\n3. Analyzing image...")
    response = requests.get(
        f"{BASE_URL}/v1/food/analyze/{image_id}",
        headers={"Authorization": f"Bearer {token}"}
    )

    if response.status_code != 200:
        print(f"   Failed: {response.status_code} {response.json()}")
        return

    result = response.json()
    print("\n   Results:")
    print(f"   - Description: {result['description']}")
    print(f"   - Calories: {result['calories']}")
    print(f"   - Carbohydrates: {result['carbohydrates_grams']}g")
    print(f"   - Protein: {result['protein_grams']}g")
    print(f"   - Confidence: {result['confidence']}")


def main():
    # Get auth token
    token = get_auth_token()
    if not token:
        print("Failed to authenticate")
        return

    # Analyze each test image
    for image_path in TEST_IMAGES:
        if os.path.exists(image_path):
            analyze_image(token, image_path)
        else:
            print(f"\nImage not found: {image_path}")

    print(f"\n{'='*50}")
    print("Done!")


if __name__ == "__main__":
    main()
