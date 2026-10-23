#!/usr/bin/env python3

import sys
from decimal import Decimal, InvalidOperation, ROUND_HALF_UP

current_key = None
current_temp_sum = Decimal(0)
current_count = 0
current_max_wind = None
current_stormy_count = 0


def print_result():
    station_id, month = current_key.split("|")
    avg_temp = (current_temp_sum / current_count).quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)
    print(f"{station_id}\t{month}\t{avg_temp}\t{current_max_wind}\t{current_count}\t{current_stormy_count}")


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
            print_result()
        current_key = key
        current_temp_sum = temp_sum
        current_count = count
        current_max_wind = max_wind
        current_stormy_count = stormy_count

if current_key:
    print_result()
