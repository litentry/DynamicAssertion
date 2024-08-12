#!/bin/bash

set -eo pipefail

# ------------------------------
# Some global setting
# ------------------------------

WORKER_COUNT=1
WORKER_ID=0
PARACHAIN_TAG=latest
WORKER_TAG=latest
BASEDIR="/opt/litentry"
WORKER_BASEDIR="$BASEDIR/worker"
PARACHAIN_BASEDIR="$BASEDIR/parachain"

function main {
  sudo mkdir -p $PARACHAIN_BASEDIR
  sudo chown -R 1000:1000 $PARACHAIN_BASEDIR
  sudo mkdir -p $WORKER_BASEDIR
  sudo chown -R 1000:1000 $WORKER_BASEDIR

  PARACHAIN_CONTAINER_ID=$(restart_parachain_services)
  echo "Parachain container ID: $PARACHAIN_CONTAINER_ID"
  sleep 300 # wait for parachain to start

  WORKER_CONTAINER_ID=$(restart_worker_services)
  echo "Worker container ID: $WORKER_CONTAINER_ID"
  sleep 120 # wait for worker to start

  docker ps

  echo "Showing parachain logs:"
  docker logs -f $PARACHAIN_CONTAINER_ID &
  PARACHAIN_LOGS_PID=$!

  echo "Showing worker logs:"
  docker logs -f $WORKER_CONTAINER_ID &
  WORKER_LOGS_PID=$!

  sleep 300
  exit 0
}

function print_divider {
  echo "------------------------------------------------------------"
}

function restart_worker_services {
  echo "Restarting worker-${WORKER_ID} services ..."

  if [ "$PRODUCTION" = "true" ]; then
    commands=(
      "-T ws:localhost -P 2000 -p 9944 -r 3443 -w 2001 -h 4545 --enable-metrics --parentchain-start-block 947410 run --skip-ra --dev"
    )
  else 
    # staging example
    commands=(
      "-T ws:localhost -P 2000 -p 9944 -r 3443 -w 2001 -h 4545 --parentchain-start-block 0 run --skip-ra --dev"
    )
  fi 
  docker run -d \
      --name litentry-worker-${WORKER_ID} \
      --restart always \
      --net=host \
      --env RUST_LOG=info,litentry_worker=debug,ws=warn,sp_io=error,substrate_api_client=warn,itc_parentchain_light_client=info,jsonrpsee_ws_client=warn,jsonrpsee_ws_server=warn,enclave_runtime=debug,ita_stf=debug,its_rpc_handler=warn,itc_rpc_client=warn,its_consensus_common=debug,its_state=warn,its_consensus_aura=warn,aura*=warn,its_consensus_slots=warn,itp_attestation_handler=debug,http_req=debug,lc_mock_server=warn,itc_rest_client=debug,lc_credentials=debug,lc_identity_verification=debug,lc_stf_task_receiver=debug,lc_stf_task_sender=debug,lc_data_providers=debug,itp_top_pool=debug,itc_parentchain_indirect_calls_executor=debug,bc_task_receiver=debug \
      --env DATA_DIR='/data' \
      --env-file /opt/worker_configs/worker_env \
      --volume ${WORKER_BASEDIR}/w${WORKER_ID}:/data \
      --workdir /data \
      litentry/identity-worker:${WORKER_TAG} ${commands[${WORKER_ID}]}
}

function restart_parachain_services {
    echo "Restarting parachain services ..."

    docker run -d \
    --name para-aio \
    --restart always \
    --net=host \
    --env CHAIN="rococo" \
    --volume $PARACHAIN_BASEDIR:$PARACHAIN_BASEDIR \
    litentry/litentry-chain-aio:${PARACHAIN_TAG}
}

main