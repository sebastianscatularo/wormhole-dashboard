#!/bin/bash
source .env
set -e

# Install and authorize the gcloud CLI: https://cloud.google.com/sdk/docs/install

# SET ENV VARIABLES
# export env variables required below
# or source .env
# make sure you npm run build in the root folder before trying to deploy :D

if [ -z "$BIGTABLE_INSTANCE_ID" ]; then
    echo "BIGTABLE_INSTANCE_ID must be specified"
    exit 1
fi

if [ -z "$BIGTABLE_TABLE_ID" ]; then
    echo "BIGTABLE_TABLE_ID must be specified"
    exit 1
fi

if [ -z "$BIGTABLE_SIGNED_VAAS_TABLE_ID" ]; then
    echo "BIGTABLE_SIGNED_VAAS_TABLE_ID must be specified"
    exit 1
fi

if [ -z "$BIGTABLE_VAAS_BY_TX_HASH_TABLE_ID" ]; then
    echo "BIGTABLE_VAAS_BY_TX_HASH_TABLE_ID must be specified"
    exit 1
fi

if [ -z "$CLOUD_FUNCTIONS_NUM_ROWS" ]; then
    echo "CLOUD_FUNCTIONS_NUM_ROWS must be specified"
    exit 1
fi

if [ -z "$CLOUD_FUNCTIONS_REFRESH_TIME_INTERVAL" ]; then
    echo "CLOUD_FUNCTIONS_REFRESH_TIME_INTERVAL be specified"
    exit 1
fi

if [ -z "$CLOUD_FUNCTIONS_BLOCK_INCREMENT" ]; then
    echo "CLOUD_FUNCTIONS_BLOCK_INCREMENT must be specified"
    exit 1
fi

if [ -z "$PG_USER" ]; then
    echo "PG_USER must be specified"
    exit 1
fi

if [ -z "$PG_PASSWORD" ]; then
    echo "PG_PASSWORD must be specified"
    exit 1
fi

if [ -z "$PG_DATABASE" ]; then
    echo "PG_DATABASE must be specified"
    exit 1
fi

if [ -z "$PG_HOST" ]; then
    echo "PG_HOST must be specified"
    exit 1
fi

if [ -z "$PG_TOKEN_TRANSFER_TABLE" ]; then
    echo "PG_TOKEN_TRANSFER_TABLE must be specified"
    exit 1
fi

if [ -z "$PG_ATTEST_MESSAGE_TABLE" ]; then
    echo "PG_ATTEST_MESSAGE_TABLE must be specified"
    exit 1
fi

if [ -z "$PG_TOKEN_METADATA_TABLE" ]; then
    echo "PG_TOKEN_METADATA_TABLE must be specified"
    exit 1
fi

if [ -z "$PUBSUB_SIGNED_VAA_TOPIC" ]; then
    echo "PUBSUB_SIGNED_VAA_TOPIC must be specified"
    exit 1
fi

if [ -z "$FIRESTORE_LATEST_COLLECTION" ]; then
    echo "FIRESTORE_LATEST_COLLECTION must be specified"
    exit 1
fi

if [ -z "$PG_TOKEN_PRICE_HISTORY_TABLE" ]; then
    echo "PG_TOKEN_PRICE_HISTORY_TABLE must be specified"
    exit 1
fi

if [ -z "$FIRESTORE_TVL_COLLECTION" ]; then
    echo "FIRESTORE_TVL_COLLECTION must be specified"
    exit 1
fi

if [ -z "$FIRESTORE_TVL_HISTORY_COLLECTION" ]; then
    echo "FIRESTORE_TVL_HISTORY_COLLECTION must be specified"
    exit 1
fi

if [ -z "$FIRESTORE_MESSAGE_COUNT_HISTORY_COLLECTION" ]; then
    echo "FIRESTORE_MESSAGE_COUNT_HISTORY_COLLECTION must be specified"
    exit 1
fi

# Hack to make these packages available in the GCP build until they're published
npm pack --silent --workspace @wormhole-foundation/wormhole-monitor-common --pack-destination ./dist/src
npm pack --silent --workspace @wormhole-foundation/wormhole-monitor-database --pack-destination ./dist/src

gcloud functions deploy messages --entry-point getMessages --runtime nodejs16 --trigger-http --allow-unauthenticated --timeout 300 --memory 1GB --region europe-west3 --set-env-vars BIGTABLE_TABLE_ID=$BIGTABLE_TABLE_ID,BIGTABLE_INSTANCE_ID=$BIGTABLE_INSTANCE_ID,CLOUD_FUNCTIONS_NUM_ROWS=$CLOUD_FUNCTIONS_NUM_ROWS,CLOUD_FUNCTIONS_REFRESH_TIME_INTERVAL=$CLOUD_FUNCTIONS_REFRESH_TIME_INTERVAL,CLOUD_FUNCTIONS_BLOCK_INCREMENT=$CLOUD_FUNCTIONS_BLOCK_INCREMENT
gcloud functions deploy message-counts --entry-point getMessageCounts --runtime nodejs16 --trigger-http --allow-unauthenticated --timeout 300 --memory 256MB --region europe-west3
gcloud functions deploy compute-message-counts --entry-point computeMessageCounts --runtime nodejs16 --trigger-http --allow-unauthenticated --timeout 300 --memory 4GB --region europe-west3 --set-env-vars BIGTABLE_TABLE_ID=$BIGTABLE_TABLE_ID,BIGTABLE_INSTANCE_ID=$BIGTABLE_INSTANCE_ID,CLOUD_FUNCTIONS_REFRESH_TIME_INTERVAL=$CLOUD_FUNCTIONS_REFRESH_TIME_INTERVAL
gcloud functions deploy latest-blocks --entry-point getLatestBlocks --runtime nodejs16 --trigger-http --allow-unauthenticated --timeout 300 --memory 256MB --region europe-west3 --set-env-vars CLOUD_FUNCTIONS_REFRESH_TIME_INTERVAL=$CLOUD_FUNCTIONS_REFRESH_TIME_INTERVAL,FIRESTORE_LATEST_COLLECTION=$FIRESTORE_LATEST_COLLECTION
gcloud functions deploy compute-missing-vaas --entry-point computeMissingVaas --runtime nodejs16 --trigger-http --allow-unauthenticated --timeout 300 --memory 2GB --region europe-west3 --set-env-vars BIGTABLE_TABLE_ID=$BIGTABLE_TABLE_ID,BIGTABLE_INSTANCE_ID=$BIGTABLE_INSTANCE_ID,CLOUD_FUNCTIONS_REFRESH_TIME_INTERVAL=$CLOUD_FUNCTIONS_REFRESH_TIME_INTERVAL
gcloud functions deploy missing-vaas --entry-point getMissingVaas --runtime nodejs16 --trigger-http --allow-unauthenticated --timeout 300 --memory 256MB --region europe-west3
gcloud functions deploy vaas-by-tx-hash --entry-point getVaasByTxHash --runtime nodejs16 --trigger-http --allow-unauthenticated --timeout 300 --memory 256MB --region europe-west3 --set-env-vars BIGTABLE_INSTANCE_ID=$BIGTABLE_INSTANCE_ID,BIGTABLE_SIGNED_VAAS_TABLE_ID=$BIGTABLE_SIGNED_VAAS_TABLE_ID,BIGTABLE_VAAS_BY_TX_HASH_TABLE_ID=$BIGTABLE_VAAS_BY_TX_HASH_TABLE_ID
gcloud functions deploy process-vaa --entry-point processVaa --runtime nodejs16 --timeout 300 --memory 256MB --region europe-west3 --trigger-topic $PUBSUB_SIGNED_VAA_TOPIC --set-env-vars BIGTABLE_INSTANCE_ID=$BIGTABLE_INSTANCE_ID,BIGTABLE_SIGNED_VAAS_TABLE_ID=$BIGTABLE_SIGNED_VAAS_TABLE_ID,BIGTABLE_VAAS_BY_TX_HASH_TABLE_ID=$BIGTABLE_VAAS_BY_TX_HASH_TABLE_ID,PG_USER=$PG_USER,PG_PASSWORD=$PG_PASSWORD,PG_DATABASE=$PG_DATABASE,PG_HOST=$PG_HOST,PG_TOKEN_TRANSFER_TABLE=$PG_TOKEN_TRANSFER_TABLE,PG_ATTEST_MESSAGE_TABLE=$PG_ATTEST_MESSAGE_TABLE,PG_TOKEN_METADATA_TABLE=$PG_TOKEN_METADATA_TABLE
gcloud functions deploy refresh-todays-token-prices --entry-point refreshTodaysTokenPrices --runtime nodejs16 --trigger-http --no-allow-unauthenticated --timeout 300 --memory 256MB --region europe-west3 --set-env-vars PG_USER=$PG_USER,PG_PASSWORD=$PG_PASSWORD,PG_DATABASE=$PG_DATABASE,PG_HOST=$PG_HOST,PG_TOKEN_METADATA_TABLE=$PG_TOKEN_METADATA_TABLE,PG_TOKEN_PRICE_HISTORY_TABLE=$PG_TOKEN_PRICE_HISTORY_TABLE
gcloud functions deploy compute-tvl --entry-point computeTVL --runtime nodejs16 --trigger-http --no-allow-unauthenticated --timeout 300 --memory 1GB --region europe-west3 --set-env-vars PG_USER=$PG_USER,PG_PASSWORD=$PG_PASSWORD,PG_DATABASE=$PG_DATABASE,PG_HOST=$PG_HOST,PG_ATTEST_MESSAGE_TABLE=$PG_ATTEST_MESSAGE_TABLE,PG_TOKEN_METADATA_TABLE=$PG_TOKEN_METADATA_TABLE,PG_TOKEN_TRANSFER_TABLE=$PG_TOKEN_TRANSFER_TABLE,FIRESTORE_TVL_COLLECTION=$FIRESTORE_TVL_COLLECTION
gcloud functions deploy tvl --entry-point getTVL --runtime nodejs16 --trigger-http --allow-unauthenticated --timeout 300 --memory 256MB --region europe-west3 --set-env-vars FIRESTORE_TVL_COLLECTION=$FIRESTORE_TVL_COLLECTION
gcloud functions deploy compute-tvl-history --entry-point computeTVLHistory --runtime nodejs16 --trigger-http --no-allow-unauthenticated --timeout 540 --memory 1GB --region europe-west3 --set-env-vars PG_USER=$PG_USER,PG_PASSWORD=$PG_PASSWORD,PG_DATABASE=$PG_DATABASE,PG_HOST=$PG_HOST,PG_ATTEST_MESSAGE_TABLE=$PG_ATTEST_MESSAGE_TABLE,PG_TOKEN_METADATA_TABLE=$PG_TOKEN_METADATA_TABLE,PG_TOKEN_TRANSFER_TABLE=$PG_TOKEN_TRANSFER_TABLE,FIRESTORE_TVL_HISTORY_COLLECTION=$FIRESTORE_TVL_HISTORY_COLLECTION,PG_TOKEN_PRICE_HISTORY_TABLE=$PG_TOKEN_PRICE_HISTORY_TABLE
gcloud functions deploy tvl-history --entry-point getTVLHistory --runtime nodejs16 --trigger-http --allow-unauthenticated --timeout 300 --memory 256MB --region europe-west3 --set-env-vars FIRESTORE_TVL_HISTORY_COLLECTION=$FIRESTORE_TVL_HISTORY_COLLECTION
gcloud functions deploy message-count-history --entry-point getMessageCountHistory --runtime nodejs16 --trigger-http --allow-unauthenticated --timeout 300 --memory 256MB --region europe-west3 --set-env-vars FIRESTORE_MESSAGE_COUNT_HISTORY_COLLECTION=$FIRESTORE_MESSAGE_COUNT_HISTORY_COLLECTION
gcloud functions deploy compute-message-count-history --entry-point computeMessageCountHistory --runtime nodejs16 --trigger-http --no-allow-unauthenticated --timeout 300 --memory 1GB --region europe-west3 --set-env-vars BIGTABLE_INSTANCE_ID=$BIGTABLE_INSTANCE_ID,BIGTABLE_SIGNED_VAAS_TABLE_ID=$BIGTABLE_SIGNED_VAAS_TABLE_ID,FIRESTORE_MESSAGE_COUNT_HISTORY_COLLECTION=$FIRESTORE_MESSAGE_COUNT_HISTORY_COLLECTION
