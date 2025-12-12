#!/usr/bin/env python3
"""
Generate synthetic Edmonton cafe data for RAP-1 testing

This script creates a realistic SQLite database with synthetic cafe data
for Square One Coffee's competition analysis pipeline.

Data includes:
- Cafe names, locations, and contact info
- Operating hours and menu offerings
- Pricing data and cafe characteristics
- Geographic coordinates (Edmonton area)
"""

import sqlite3
import random
from datetime import datetime
import os

# Ensure data-private/raw directory exists
os.makedirs("../../../data-private/raw", exist_ok=True)

# Database path
db_path = "../../../data-private/raw/edmonton_cafes.sqlite"

# Connect to database
conn = sqlite3.connect(db_path)
cursor = conn.cursor()

# Create cafes table
cursor.execute("""
CREATE TABLE IF NOT EXISTS cafes (
    cafe_id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    address TEXT,
    neighborhood TEXT,
    latitude REAL,
    longitude REAL,
    phone TEXT,
    website TEXT,
    cafe_type TEXT,
    ownership TEXT,
    avg_beverage_price REAL,
    has_food TEXT,
    has_wifi TEXT,
    seating_capacity INTEGER,
    ambiance TEXT,
    parking_availability TEXT,
    hours_weekday TEXT,
    hours_weekend TEXT,
    date_opened TEXT,
    instagram_handle TEXT,
    google_rating REAL,
    review_count INTEGER,
    created_at TEXT,
    updated_at TEXT
)
""")

# Edmonton neighborhoods
neighborhoods = [
    "Downtown", "Oliver", "Garneau", "Whyte Avenue", "Bonnie Doon",
    "Westmount", "Old Strathcona", "Ritchie", "Highlands", "Jasper Avenue",
    "Alberta Avenue", "124 Street", "Capilano", "Belgravia", "Riverdale"
]

# Cafe name components for variety
prefixes = ["The", "Cafe", "Coffee", "Brew", "Bean", "Roast", "Morning", "Daily"]
middles = ["Central", "House", "Bar", "Shop", "Co", "Collective", "Studio", "Lab"]
suffixes = ["Cafe", "Coffee", "Roasters", "Co.", "House", "Bar", "Kitchen"]

# Generate cafe names (including Square One locations)
soc_locations = [
    "Square One Coffee - Oliver",
    "Square One Coffee - Downtown",
    "Square One Coffee - Whyte Avenue",
    "Square One Coffee - Westmount",
    "Square One Coffee - 124 Street",
    "Square One Coffee - Ritchie"
]

# Generate additional competitor cafes
competitor_cafes = []
for i in range(24):  # 24 competitors + 6 SOC = 30 total cafes
    if random.random() < 0.3:
        name = f"{random.choice(prefixes)} {random.choice(middles)}"
    else:
        name = f"{random.choice(prefixes)} {random.choice(middles)} {random.choice(suffixes)}"
    competitor_cafes.append(name)

all_cafes = soc_locations + competitor_cafes

# Edmonton lat/long boundaries (approximate)
lat_min, lat_max = 53.45, 53.62
lng_min, lng_max = -113.65, -113.40

# Cafe types
cafe_types = ["specialty_coffee", "espresso_bar", "full_service_cafe", "coffee_shop", "roastery_cafe"]
ownerships = ["independent", "small_chain", "regional_chain", "national_chain"]
ambiances = ["modern_minimalist", "cozy_traditional", "industrial_chic", "community_hub", "grab_and_go"]
parking_options = ["street_only", "nearby_lot", "dedicated_parking", "no_parking"]

# Insert synthetic cafe data
cafes_data = []
for i, cafe_name in enumerate(all_cafes):
    is_soc = "Square One" in cafe_name
    
    # SOC cafes have consistent characteristics
    if is_soc:
        cafe_type = "specialty_coffee"
        ownership = "independent"
        avg_price = round(random.uniform(4.50, 6.00), 2)
        has_food = "sandwiches_pastries"
        has_wifi = "yes"
        seating = random.randint(20, 45)
        ambiance = "modern_minimalist"
        google_rating = round(random.uniform(4.3, 4.8), 1)
        review_count = random.randint(150, 500)
    else:
        cafe_type = random.choice(cafe_types)
        ownership = random.choice(ownerships)
        avg_price = round(random.uniform(3.00, 7.50), 2)
        has_food = random.choice(["pastries_only", "sandwiches_pastries", "full_menu", "none"])
        has_wifi = random.choice(["yes", "no", "limited"])
        seating = random.randint(10, 60)
        ambiance = random.choice(ambiances)
        google_rating = round(random.uniform(3.5, 4.9), 1)
        review_count = random.randint(20, 400)
    
    # Assign neighborhood
    neighborhood = neighborhoods[i % len(neighborhoods)]
    
    # Generate coordinates
    latitude = round(random.uniform(lat_min, lat_max), 6)
    longitude = round(random.uniform(lng_min, lng_max), 6)
    
    # Generate address
    street_num = random.randint(100, 9999)
    street_names = ["Jasper Ave", "Whyte Ave", "124 St", "104 St", "82 Ave", "Gateway Blvd", "Calgary Trail"]
    address = f"{street_num} {random.choice(street_names)}, Edmonton, AB"
    
    # Phone and website
    phone = f"780-{random.randint(100, 999)}-{random.randint(1000, 9999)}"
    website = f"https://{cafe_name.lower().replace(' ', '').replace('-', '')[:20]}.com" if random.random() > 0.3 else None
    
    # Hours
    hours_weekday = "7:00 AM - 6:00 PM" if random.random() > 0.3 else "6:30 AM - 7:00 PM"
    hours_weekend = "8:00 AM - 5:00 PM" if random.random() > 0.3 else "8:00 AM - 6:00 PM"
    
    # Opening date
    year = random.randint(2010, 2024)
    month = random.randint(1, 12)
    date_opened = f"{year}-{month:02d}-01"
    
    # Instagram
    instagram = f"@{cafe_name.lower().replace(' ', '').replace('-', '')[:20]}" if random.random() > 0.2 else None
    
    # Parking
    parking = random.choice(parking_options)
    
    # Timestamps
    created_at = datetime.now().isoformat()
    updated_at = created_at
    
    cafes_data.append((
        cafe_name, address, neighborhood, latitude, longitude, phone, website,
        cafe_type, ownership, avg_price, has_food, has_wifi, seating, ambiance,
        parking, hours_weekday, hours_weekend, date_opened, instagram,
        google_rating, review_count, created_at, updated_at
    ))

# Insert data
cursor.executemany("""
    INSERT INTO cafes (
        name, address, neighborhood, latitude, longitude, phone, website,
        cafe_type, ownership, avg_beverage_price, has_food, has_wifi,
        seating_capacity, ambiance, parking_availability, hours_weekday,
        hours_weekend, date_opened, instagram_handle, google_rating,
        review_count, created_at, updated_at
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
""", cafes_data)

conn.commit()

# Print summary
cursor.execute("SELECT COUNT(*) FROM cafes")
total_cafes = cursor.fetchone()[0]

cursor.execute("SELECT COUNT(*) FROM cafes WHERE name LIKE '%Square One%'")
soc_cafes = cursor.fetchone()[0]

print(f"✅ Synthetic data generated successfully!")
print(f"   Database: {db_path}")
print(f"   Total cafes: {total_cafes}")
print(f"   - Square One Coffee locations: {soc_cafes}")
print(f"   - Competitor cafes: {total_cafes - soc_cafes}")
print(f"   Neighborhoods covered: {len(neighborhoods)}")

conn.close()
