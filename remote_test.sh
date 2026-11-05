#!/bin/bash
cd ~
rm -rf pbd-projekt19-mapreduce
git clone -q https://github.com/mgawlak/pbd-projekt19-mapreduce.git
export AIRFLOW_HOME=~/airflow
export AIRFLOW_VERSION=3.3.1
export AIRFLOW__CORE__LOAD_EXAMPLES=False
export PATH=$PATH:~/.local/bin
PYTHON_VERSION="$(python -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')"
CONSTRAINT_URL="https://raw.githubusercontent.com/apache/airflow/constraints-${AIRFLOW_VERSION}/constraints-${PYTHON_VERSION}.txt"
if [ ! -x ~/.venv/bin/airflow ]; then
  echo "#### Instalacja Airflow"
  curl -LsSf https://astral.sh/uv/install.sh | sh >/dev/null 2>&1
  uv venv -q
  source ~/.venv/bin/activate
  uv pip install -q "apache-airflow==${AIRFLOW_VERSION}" --constraint "${CONSTRAINT_URL}"
fi
source ~/.venv/bin/activate
airflow db migrate >/dev/null 2>&1
rm -rf ~/airflow/dags && mkdir -p ~/airflow/dags/project_files
cd ~/pbd-projekt19-mapreduce
cp projekt1.py ~/airflow/dags/
cp mapper.py combiner.py reducer.py run_mr.sh hive.hql run_hive.sh ~/airflow/dags/project_files/
chmod +x ~/airflow/dags/project_files/*
IN=gs://pbd-26-10-mg/projekt19/test2026-10/input
CONF="{\"dags_home\": \"$HOME/airflow/dags\", \"input_dir\": \"$IN\"}"
for i in 1 2; do
  echo "#### Uruchomienie $i"
  airflow dags test project1-workflow -c "$CONF" < /dev/null > ~/run$i.log 2>&1
  echo "#### RUN$i exit=$? json_w_get_output=$(grep -c '"region"' ~/run$i.log) failed=$(grep -ci 'Task failed' ~/run$i.log)"
done
echo "#### MR wierszy: $(hadoop fs -cat /project1/output_mr3/part-* 2>/dev/null | wc -l) (oczekiwane 1830)"
echo "#### Hive wierszy: $(hadoop fs -cat /project1/output6/* 2>/dev/null | wc -l) (oczekiwane 610)"
echo "#### Wzorzec Hive:"
hadoop fs -cat /project1/output6/* 2>/dev/null | grep 'Dolno' | grep '"2021-10"' | cut -c1-200
