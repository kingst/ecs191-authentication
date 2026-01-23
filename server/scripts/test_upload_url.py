#!/usr/bin/env python3
"""Test script to login and get a signed upload URL."""

import requests

BASE_URL = "http://localhost:5001"
TEST_PHONE = "+15305550000"
TEST_CODE = "123456"
APP_ID = "test_app"


def main():
    # Step 1: Send SMS code
    print(f"Sending SMS code to {TEST_PHONE}...")
    response = requests.post(
        f"{BASE_URL}/v1/send_sms_code",
        json={"phone_number": TEST_PHONE, "app_id": APP_ID}
    )
    print(f"  Status: {response.status_code}")
    print(f"  Response: {response.json()}")

    if response.status_code != 200:
        print("Failed to send SMS code")
        return

    # Step 2: Verify code and get token
    print(f"\nVerifying code {TEST_CODE}...")
    response = requests.post(
        f"{BASE_URL}/v1/verify_code",
        json={"phone_number": TEST_PHONE, "app_id": APP_ID, "code": TEST_CODE}
    )
    print(f"  Status: {response.status_code}")
    print(f"  Response: {response.json()}")

    if response.status_code != 200:
        print("Failed to verify code")
        return

    token = response.json()["token"]
    print(f"\nGot token: {token[:20]}...")

    # Step 3: Get upload URL
    print("\nGetting upload URL...")
    response = requests.get(
        f"{BASE_URL}/v1/food/upload_url",
        headers={"Authorization": f"Bearer {token}"}
    )
    print(f"  Status: {response.status_code}")
    print(f"  Response: {response.json()}")

    if response.status_code == 200:
        data = response.json()
        print(f"\nSuccess!")
        print(f"  Image ID: {data['image_id']}")
        print(f"  Upload URL: {data['upload_url'][:80]}...")


if __name__ == "__main__":
    main()
