# Projekt 19 — MapReduce (Hadoop Streaming)

Zestaw 19 (stations-weather): agregacja pomiarów per stacja i miesiąc (`YYYY-MM`).

Wynik MapReduce (tab-separated): `station_id  month  avg_temp  max_wind_speed  no_measurements  stormy_count  temp_sum`

`temp_sum` to dodatkowy atrybut (suma temperatur), dzięki któremu Hive liczy średnie regionów dokładnie po wszystkich pomiarach.

## Pliki
- `mapper.py` – parsuje CSV, emituje `station_id|YYYY-MM \t temp,1,wind,stormy`
- `combiner.py` – częściowa agregacja (suma, licznik, max, suma stormy)
- `reducer.py` – agregacja końcowa, średnia z zaokrągleniem do 0.01 (ROUND_HALF_UP)
- `run_mr.sh` – uruchomienie: `./run_mr.sh <input_dir1> <output_dir3>`
- `hive.hql` – program Hive: złączenie z `datasource4`, średnie regionu i miesiąca, ranking stacji, wynik w JSON
- `run_hive.sh` – uruchomienie: `./run_hive.sh <input_dir3> <input_dir4> <output_dir6>`

## Test lokalny
```bash
cat dane/*.csv | python3 mapper.py | sort -k1,1 | python3 combiner.py | sort -k1,1 | python3 reducer.py
```

## Uruchomienie na BigData25

### 1. Terminal gospodarza – środowisko, kod, dane
```bash
cd ~/BigData25 && docker compose up -d
cd ~/BigData25/work
git clone https://github.com/mgawlak/pbd-projekt19-mapreduce.git || (cd pbd-projekt19-mapreduce && git pull)
cd pbd-projekt19-mapreduce
mkdir -p dane19 && cd dane19
wget https://www.cs.put.poznan.pl/kjankiewicz/bigdata/projekty/test2026-05/zestaw19.zip -O test19.zip
unzip -o test19.zip -d test
ls test/input/datasource1 | wc -l
```
Ostrzeżenie `appears to use backslashes as path separators` można zignorować (zip z Windowsa). Powinno być 50 plików.

Dane leżą w `pbd-projekt19-mapreduce/dane19` – katalog jest w `.gitignore`, więc nie trafi na GitHub.

### 2. Master
```bash
cd ~/BigData25 && docker compose exec -it master bash
```
`~` na masterze (`/home/hadoop`) to katalog `~/BigData25/work` gospodarza.

### 3. Dane do HDFS
```bash
hadoop fs -mkdir -p projekt/input/datasource1 projekt/input/datasource4
hadoop fs -put -f ~/pbd-projekt19-mapreduce/dane19/test/input/datasource1/* projekt/input/datasource1/
hadoop fs -put -f ~/pbd-projekt19-mapreduce/dane19/test/input/datasource4/* projekt/input/datasource4/
hadoop fs -ls projekt/input/datasource1 | wc -l
```

### 4. MapReduce i Hive
```bash
cd ~/pbd-projekt19-mapreduce && chmod +x *.sh *.py
./run_mr.sh projekt/input/datasource1 projekt/output3
./run_hive.sh projekt/output3 projekt/input/datasource4 projekt/output6
```

### 5. Weryfikacja (zbiór test2026-05)
```bash
hadoop fs -cat projekt/output3/part-* | wc -l
hadoop fs -cat projekt/output3/part-* | grep 03b6ada2-ed28-4f56-8fc0-99ce603b6bfe | grep 2021-05
hadoop fs -cat projekt/output6/* | wc -l
hadoop fs -cat projekt/output6/* | grep 'Kujawsko-Pomorskie' | grep '2021-05'
```
Oczekiwane:
- MapReduce: 1830 wierszy, `03b6ada2-… 2021-05 -0.18 98.2 15 5`
- Hive: 549 wierszy, `region_month_avg_temp` ≈ 10.5682, `region_avg_temp` ≈ 6.30278, `avg_temp_deviation` ≈ 4.2654, ranking `cef035b0…` = 1, `bef1b196…` = 2

### 6. Zapis wyników i koniec
```bash
mkdir -p ~/wyniki
hadoop fs -getmerge projekt/output3 ~/wyniki/output3.tsv
hadoop fs -getmerge projekt/output6 ~/wyniki/output6.json
exit
cd ~/BigData25 && docker compose stop
```
Wyniki są w `~/BigData25/work/wyniki/`. `docker compose stop` zachowuje HDFS; `docker compose down -v` go kasuje.

### Podgląd HDFS
```bash
docker compose exec -it master bash
hadoop fs -ls -R projekt | head -40
hadoop fs -cat projekt/output6/* | head -3
```
lub w przeglądarce: `BigData25-Interfaces.html` → HDFS NameNode → Utilities → Browse the file system → `/user/hadoop/projekt`.

## Airflow na BigData25 (`projekt1.py`)

W `projekt1.py` uzupełnione są tylko operatory `hadoop_streaming` i `hive` (te same polecenia co w `run_mr.sh` i `run_hive.sh`, ścieżki z parametrów przepływu).

### 1. Port 8080 (gospodarz)
W `~/BigData25/docker-compose.yml`, w `services/master/ports` dopisz:
```yaml
      - "8080:8080" # Apache Airflow
```
```bash
cd ~/BigData25 && docker compose up -d && docker compose exec -it master bash
```

### 2. Instalacja i start Airflow (master)
```bash
export AIRFLOW_HOME=~/airflow
export AIRFLOW_VERSION=3.3.1
PYTHON_VERSION="$(python -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')"
CONSTRAINT_URL="https://raw.githubusercontent.com/apache/airflow/constraints-${AIRFLOW_VERSION}/constraints-${PYTHON_VERSION}.txt"
export AIRFLOW__CORE__LOAD_EXAMPLES=False
export PATH=$PATH:~/.local/bin
curl -LsSf https://astral.sh/uv/install.sh | sh
uv venv
source ~/.venv/bin/activate
uv pip install "apache-airflow==${AIRFLOW_VERSION}" --constraint "${CONSTRAINT_URL}"
airflow db migrate
sed -i 's/^refresh_interval\s*=.*/refresh_interval = 15/' $AIRFLOW_HOME/airflow.cfg
setsid airflow standalone < /dev/null > ~/airflow/standalone.log 2>&1 &
disown
cat ~/airflow/simple_auth_manager_passwords.json.generated
```
Interfejs: http://localhost:8080 (login i hasło z ostatniego polecenia).

### 3. Pliki projektu do `dags` (master)
```bash
mkdir -p ~/airflow/dags/project_files
cd ~/pbd-projekt19-mapreduce && git pull
cp projekt1.py ~/airflow/dags/
cp mapper.py combiner.py reducer.py run_mr.sh hive.hql run_hive.sh ~/airflow/dags/project_files/
chmod +x ~/airflow/dags/project_files/*
```

### 4. Dane wejściowe w HDFS (master)
```bash
hadoop fs -mkdir -p /tmp
hadoop fs -put -f ~/pbd-projekt19-mapreduce/dane19/test/input /tmp/
hadoop fs -ls /tmp/input
```

### 5. Uruchomienie
W Airflow: przepływ `project1-workflow` → **Trigger** z parametrami:
- `dags_home` = `/home/hadoop/airflow/dags`
- `input_dir` = `/tmp/input`

W logu taska `get_output` ma być wynik JSON. Uruchom przepływ drugi raz, żeby sprawdzić powtarzalność.

### 6. Paczka do oddania
```bash
pkill -f "airflow"
pgrep -af airflow
sudo apt-get update && sudo apt-get install -y zip
cd ~/airflow && rm -rf dags/__pycache__ && zip -r ~/projekt1.zip dags
unzip -l ~/projekt1.zip
```
`~/projekt1.zip` w kontenerze to `~/BigData25/work/projekt1.zip` na gospodarzu.
