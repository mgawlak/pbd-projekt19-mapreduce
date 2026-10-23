#!/usr/bin/env python3

import sys
import re
from decimal import Decimal, InvalidOperation

p = re.compile(r'^(\d{4}-\d{2})-\d{2}T\d{2}:\d{2}')
STATION_ID_COL = 1
MEASUREMENT_DATE_COL = 2
TEMPERATURE_COL = 3
WIND_SPEED_COL = 5
CONDITION_COL = 7

for line in sys.stdin:
    values = line.strip().split(",")
    if len(values) != 8:
        continue

    station_id = values[STATION_ID_COL].strip()
    m = p.match(values[MEASUREMENT_DATE_COL].strip())

    if station_id and m:
        try:
            temperature = Decimal(values[TEMPERATURE_COL].strip())
            wind_speed = Decimal(values[WIND_SPEED_COL].strip())
        except InvalidOperation:
            continue
        if not (temperature.is_finite() and wind_speed.is_finite()):
            continue
        stormy = 1 if values[CONDITION_COL].strip() == "Stormy" else 0
        month = m.group(1)
        print(f"{station_id}|{month}\t{temperature},1,{wind_speed},{stormy}")
