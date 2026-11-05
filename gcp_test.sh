#!/bin/bash
REGION=europe-west4
CLUSTER=pbd-cluster
PROJECT_ID=$(gcloud config get-value project 2>/dev/null)
RAW=https://raw.githubusercontent.com/mgawlak/pbd-projekt19-mapreduce/test-airflow

if ! gcloud dataproc clusters describe $CLUSTER --region $REGION >/dev/null 2>&1; then
  gcloud dataproc clusters create $CLUSTER --enable-component-gateway \
    --region $REGION --subnet default --public-ip-address \
    --master-machine-type n2-standard-4 --master-boot-disk-size 50 \
    --num-workers 2 --worker-machine-type n2-standard-2 --worker-boot-disk-size 50 \
    --image-version 3.0-debian13 --project $PROJECT_ID --max-age=2h --quiet
fi
ZONE=$(gcloud dataproc clusters describe $CLUSTER --region $REGION --format="value(config.gceClusterConfig.zoneUri.basename())")
gcloud compute ssh $CLUSTER-m --zone $ZONE --quiet --command "curl -fsSL $RAW/remote_test.sh -o remote_test.sh && bash remote_test.sh"
echo "#### Usuwam klaster"
gcloud dataproc clusters delete $CLUSTER --region $REGION --quiet
echo "#### KONIEC"
