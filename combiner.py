#!/usr/bin/env python3

import sys
from decimal import Decimal, InvalidOperation

current_key = None
current_temp_sum = Decimal(0)
current_count = 0
current_max_wind = None
current_stormy_count = 0

for line in sys.stdin:
    try:
        key, value = line.strip().split("\t")
        temp_sum, count, max_wind, stormy_count = value.split(",")
        temp_sum, count = Decimal(temp_sum), int(count)
        max_wind, stormy_count = Decimal(max_wind), int(stormy_count)
    except (ValueError, InvalidOperation):
        continue

    if current_key == key:
        current_temp_sum += temp_sum
        current_count += count
        current_max_wind = max(current_max_wind, max_wind)
        current_stormy_count += stormy_count
    else:
        if current_key:
            print(f"{current_key}\t{current_temp_sum},{current_count},{current_max_wind},{current_stormy_count}")
        current_key = key
        current_temp_sum = temp_sum
        current_count = count
        current_max_wind = max_wind
        current_stormy_count = stormy_count

if current_key:
    print(f"{current_key}\t{current_temp_sum},{current_count},{current_max_wind},{current_stormy_count}")
