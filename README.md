# Projekt 19 — MapReduce (Hadoop Streaming)

Zestaw 19 (stations-weather): agregacja pomiarów per stacja i miesiąc (`YYYY-MM`).

Wynik (tab-separated): `station_id  month  avg_temp  max_wind_speed  no_measurements  stormy_count`

## Pliki
- `mapper.py` – parsuje CSV, emituje `station_id|YYYY-MM \t temp,1,wind,stormy`
- `combiner.py` – częściowa agregacja (suma, licznik, max, suma stormy)
- `reducer.py` – agregacja końcowa, średnia z zaokrągleniem do 0.01 (ROUND_HALF_UP)
- `run_mr.sh` – uruchomienie: `./run_mr.sh <input_dir1> <output_dir3>`

## Test lokalny
```bash
cat dane/*.csv | python3 mapper.py | sort -k1,1 | python3 combiner.py | sort -k1,1 | python3 reducer.py
```
