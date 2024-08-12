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

  restart_parachain_services
  parachain_container_id=$(docker ps --filter "name=para-aio" --format "{{.ID}}")
  echo "Parachain container ID: $parachain_container_id"
  echo "Showing parachain logs:"
  timeout 300 docker logs -f --tail 200 $parachain_container_id &

  wait
  restart_worker_services
  worker_container_id=$(docker ps --filter "name=litentry-worker-0" --format "{{.ID}}")
  echo "Worker container ID: $worker_container_id"
  echo "Showing worker logs:"

  docker logs -f --tail 200 $worker_container_id &
  sleep 300 # wait for worker to start
  netstat -tuln | grep 9944
  netstat -tuln | grep 2000
  exit
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