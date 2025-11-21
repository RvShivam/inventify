import requests
import json
import random
import string
import os

BASE_URL = "http://localhost:8080"

def random_string(length=10):
    return ''.join(random.choices(string.ascii_letters + string.digits, k=length))

def signup_and_login():
    email = f"test_{random_string()}@example.com"
    password = "password123"
    name = f"Test User {random_string()}"
    shop_name = f"Test Shop {random_string()}"

    print(f"Signing up user: {email}")
    signup_resp = requests.post(f"{BASE_URL}/signup", json={
        "name": name,
        "email": email,
        "password": password,
        "shopName": shop_name
    })
    
    if signup_resp.status_code != 201:
        print(f"Signup failed: {signup_resp.text}")
        return None, None

    print("Logging in...")
    login_resp = requests.post(f"{BASE_URL}/login", json={
        "email": email,
        "password": password
    })

    if login_resp.status_code != 200:
        print(f"Login failed: {login_resp.text}")
        return None, None

    data = login_resp.json()
    return data["token"], data["orgId"]

def create_dummy_image():
    filename = "test_image.png"
    # Create a simple 1x1 pixel PNG
    with open(filename, "wb") as f:
        f.write(b'\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x06\x00\x00\x00\x1f\x15\xc4\x89\x00\x00\x00\nIDATx\x9cc\x00\x01\x00\x00\x05\x00\x01\r\n-\xb4\x00\x00\x00\x00IEND\xaeB`\x82')
    return filename

def test_create_product(token, org_id):
    print("Testing Create Product...")
    
    image_path = create_dummy_image()
    
    product_data = {
        "name": f"Test Product {random_string()}",
        "description": "This is a test product created via automation script.",
        "sku": f"SKU-{random_string(6)}",
        "brand": "TestBrand",
        "hsn": "123456",
        "countryOfOrigin": "IN",
        "category": "Electronics", # Assuming this category exists or is just a string
        "mrp": 1000.0,
        "salePrice": 800.0,
        "stockQuantity": 50,
        "length": 10.0,
        "width": 5.0,
        "height": 2.0,
        "weight": 0.5,
        "woo": {
            "enabled": True,
            "useCustomPrice": True,
            "customPrice": 850.0,
            "catalogVisibility": "visible"
        },
        "ondc": {
            "enabled": True,
            "returnable": True,
            "cancellable": False,
            "useCustomPrice": False,
            "fulfillmentType": "delivery",
            "timeToShip": "P1D",
            "cityCode": "HYD",
            "locationId": "loc_1"
        }
    }

    headers = {
        "Authorization": f"Bearer {token}",
        "X-Organization-Id": str(org_id)
    }

    # Prepare multipart/form-data
    # 'data' field contains the JSON
    # 'images' field contains the file
    
    files = {
        'data': (None, json.dumps(product_data), 'application/json'),
        'images': ('test_image.png', open(image_path, 'rb'), 'image/png')
    }

    try:
        resp = requests.post(f"{BASE_URL}/api/products", headers=headers, files=files)
        
        if resp.status_code == 201:
            print("✅ Product created successfully!")
            print(f"Response: {resp.json()}")
        else:
            print(f"❌ Product creation failed. Status: {resp.status_code}")
            print(f"Response: {resp.text}")

    finally:
        # Cleanup
        if os.path.exists(image_path):
            os.remove(image_path)

if __name__ == "__main__":
    token, org_id = signup_and_login()
    if token and org_id:
        test_create_product(token, org_id)
