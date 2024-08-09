#!/bin/bash

set -eo pipefail

# This script is used to perform actions on the target host, including:
# - generate: generate the systemd service files from the template
# - restart: restart the parachain, or the worker, or both
# - upgrade-worker: uprade the worker0 to the rev in local repo
#
# TODO:
# the combinations of flags are not yet well verified/organised, especially the following:
# --only-worker
# --build
# --discard

# ------------------------------
# path setting
# ------------------------------

# CONFIG_DIR contains private configs. Need to prepare in advance.
WKDIR=$(dirname "$(readlink -f "$0")")
CONFIG_DIR="/opt/worker_configs"

BASEDIR="/opt/litentry"
DOWNLOAD_BASEDIR="$BASEDIR/download"
PARACHAIN_BASEDIR="$BASEDIR/parachain"
WORKER_BASEDIR="$BASEDIR/worker"
BACKUP_BASEDIR="$BASEDIR/backup"
LOG_BACKUP_BASEDIR="$BACKUP_BASEDIR/log"
WORKER_BACKUP_BASEDIR="$BACKUP_BASEDIR/worker"
RELAYCHAIN_ALICE_BASEDIR="$PARACHAIN_BASEDIR/relay-alice"
RELAYCHAIN_BOB_BASEDIR="$PARACHAIN_BASEDIR/relay-bob"
PARACHAIN_ALICE_BASEDIR="$PARACHAIN_BASEDIR/para-alice"

# ------------------------------
# default arg setting
# ------------------------------

BUILD=false
BRANCH="dev"
DISCARD=false
WORKER_CONFIG="$CONFIG_DIR/config.json"
WORKER_ENV="$CONFIG_DIR/worker_env"
INTEL_KEY="$CONFIG_DIR/key_production.txt"
INTEL_SPID="$CONFIG_DIR/spid_production.txt"
CHAIN=rococo
ONLY_WORKER=false
PARACHAIN_HOST=localhost
PARACHAIN_PORT=9944
COPY_FROM_DOCKER=false
PRODUCTION=false
ACTION=
CHECK=true
PARACHAIN_TAG=latest
WORKER_TAG=latest
# ------------------------------
# Some global setting
# ------------------------------

WORKER_COUNT=1
WORKER_ID=0
PARACHAIN_ID=
OLD_MRENCLAVE=
NEW_MRENCLAVE=
OLD_SHARD=
LATEST_FINALIZED_BLOCK=
RELEASE_VERSION=
REPO="litentry/litentry-parachain"
REPO_DIR="/tmp/dev_deploy_src_repo"

VERSION_PATTERN="\bp[0-9]+\.[0-9]+\.[0-9]+-[0-9]+-w[0-9]+\.[0-9]+\.[0-9]+-[0-9]+\b"

SGX_SDK=/opt/intel/sgxsdk
SGX_ENCLAVE_SIGNER=$SGX_SDK/bin/x64/sgx_sign

# ------------------------------
# main()
# ------------------------------

function main {

  # 0/ parse command lines
  # echo "Parsing command line ..."
#   while [ $# -gt 0 ]; do
#     case "$1" in
#       -h|--help)
#         display_help
#         exit 0
#         ;;
#       --worker-tag)
#         if [ -z "$2" ] || [[ "$2" == -* ]]; then
#             echo "Error: missing worker docker tag or code branch for --worker-tag option"
#             display_help
#             exit 1
#         fi
#         WORKER_TAG="$2"
#         if [ -z "$2" ] || [[ "$2" == -* ]]; then
#             echo "Error: missing worker image tag for --worker-tag option"
#             display_help
#             exit 1
#         fi
#         shift 2
#         ;;
#       --worker-id)
#         if [ -z "$2" ] || [[ "$2" == -* ]]; then
#             echo "Error: missing worker id for --worker-id option"
#             display_help
#             exit 1
#         fi
#         WORKER_ID="$2"
#         shift 2
#         ;;
#       --skip-check)
#         CHECK=false
#         echo "Skip inspection, please bear the risk yourself!"
#         shift
#         ;;
#       --prod)
#         PRODUCTION=true
#         echo "Using production environment parameters."
#         shift
#         ;;
#       restart|upgrade-worker|stop|status)
#         ACTION="$1"
#         shift
#         ;;
#       *)
#         echo "Error: unknown option or subcommand $1"
#         display_help
#         exit 1
#         ;;
#     esac
#   done

#   # 1/ check if $USER has sudo
#   if sudo -l -U $USER 2>/dev/null | grep -q 'may run the following'; then
#     source "$SGX_SDK/environment"
#   else
#     echo "$USER doesn't have sudo permission"
#     exit 1
#   fi

#   # 2/ create folders if missing
#   sudo mkdir -p "$BASEDIR"
#   sudo chown -R $USER:$GROUPS "$BASEDIR"
#   for d in "$LOG_BACKUP_BASEDIR" "$WORKER_BACKUP_BASEDIR" "$RELAYCHAIN_ALICE_BASEDIR" "$RELAYCHAIN_BOB_BASEDIR" \
#     "$PARACHAIN_ALICE_BASEDIR" "$WORKER_BASEDIR"; do
#     mkdir -p "$d"
#   done

#   echo "Worker count: $WORKER_COUNT"

  restart_parachain

  exit
}

# ------------------------------
# helper functions
# ------------------------------

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
  docker run -itd \
      --name litentry-worker-${WORKER_ID} \
      --restart always \
      --net=host \
      --device=/dev/sgx_enclave \
      --device=/dev/sgx_provision \
      --env RUST_LOG=info,litentry_worker=debug,ws=warn,sp_io=error,substrate_api_client=warn,itc_parentchain_light_client=info,jsonrpsee_ws_client=warn,jsonrpsee_ws_server=warn,enclave_runtime=debug,ita_stf=debug,its_rpc_handler=warn,itc_rpc_client=warn,its_consensus_common=debug,its_state=warn,its_consensus_aura=warn,aura*=warn,its_consensus_slots=warn,itp_attestation_handler=debug,http_req=debug,lc_mock_server=warn,itc_rest_client=debug,lc_credentials=debug,lc_identity_verification=debug,lc_stf_task_receiver=debug,lc_stf_task_sender=debug,lc_data_providers=debug,itp_top_pool=debug,itc_parentchain_indirect_calls_executor=debug,bc_task_receiver=debug \
      --env DATA_DIR='/data' \
      --env-file /opt/worker_configs/worker_env \
      --volume /var/run/aesmd:/var/run/aesmd \
      --volume ${WORKER_BASEDIR}/w${WORKER_ID}:/data \
      --workdir /data \
      litentry/identity-worker:${WORKER_TAG} ${commands[${WORKER_ID}]}
}

function restart_parachain {
    echo "Restarting parachain services ..."

    docker run -itd \
    --name para-aio \
    --restart always \
    --net=host \
    --env CHAIN="rococo" \
    --volume /opt/litentry/parachain:/opt/litentry/parachain \
    litentry/litentry-chain-aio:${PARACHAIN_TAG}
}

main