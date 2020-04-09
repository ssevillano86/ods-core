#!/usr/bin/env bash

#Builds all jenkins-master jenkins-slave-base and webhook-proxy

set -ue

function usage {
   printf "usage: %s [options]\n" $0
   printf "\t--force\tIgnores warnings and error with tailor --force\n"
   printf "\t-h|--help\tPrints the usage\n"
   printf "\t-v|--verbose\tVerbose output\n"
   printf "\t-t|--tailor\tChanges the executable of tailor. Default: tailor\n"
   printf "\t-r|--ods-base-repository\tODS base repository. Overrides default in settings file\n"
   printf "\t-b|--ods-ref\tODS reference in repository. Overrides default in settings file\n"

}
TAILOR="tailor"
NAMESPACE="cd"
REPOSITORY=""
REF=""
while [[ "$#" -gt 0 ]]; do case $1 in

   -v|--verbose) set -x;;

   -h|--help) usage; exit 0;;

   -t=*|--tailor=*) TAILOR="${1#*=}";;
   -t|--tailor) TAILOR="$2"; shift;;

   -r=*|--ods-base-repository=*) REPOSITORY="${1#*=}";;
   -r|--ods-base-repository) REPOSITORY="$2"; shift;;

   -b=*|--ods-ref=*) REF="${1#*=}";;
   -b|--ods-ref) REF="$2"; shift;;

   *) echo "Unknown parameter passed: $1"; usage; exit 1;;
 esac; shift; done

if ! oc whoami > /dev/null; then
  echo "You must be logged into OpenShift to start builds"
  exit 1
fi

if ! oc project ${NAMESPACE}; then
  echo "The project '${NAMESPACE}' does not exist. Please setup the project using 'setup-ods-project.sh'"
  exit 1
fi

echo "Applying Tailorfile to project '${NAMESPACE}'"

if [ ! -z "${REF}" ]; then
REF_PARAM="--param=ODS_GIT_REF=${REF}"
fi

if [ ! -z "${REPOSITORY}" ]; then
REPOSITORY_PARAM="--param=REPO_BASE=${REPOSITORY}"
fi

cd ${BASH_SOURCE%/*}/../jenkins/ocp-config
${TAILOR} update --non-interactive -n ${NAMESPACE} ${REF_PARAM} ${REPOSITORY_PARAM}
cd -

${BASH_SOURCE%/*}/../ocp-scripts/start-and-follow-build.sh --build-config jenkins-master

${BASH_SOURCE%/*}/../ocp-scripts/start-and-follow-build.sh --build-config jenkins-slave-base

${BASH_SOURCE%/*}/../ocp-scripts/start-and-follow-build.sh --build-config jenkins-webhook-proxy
