#!/bin/bash

DIR=$(realpath ${BASH_SOURCE%/*})
. ${DIR}/utils.sh

getopt --test > /dev/null
if [[ $? -ne 4 ]]
then
    exit 1
fi

SHORT=u:p:a:fh
LONG=unpack:,pack:,apply:,force,help

PARSED=$(getopt --options $SHORT --longoptions $LONG --name "$0" -- "$@")
if [[ $? -ne 0 ]]
then
    exit 1
fi

eval set -- "$PARSED"

while true
do
  case "$1" in
    -u|--unpack)
      OUT_DIR=$2
      shift 2
      ;;
    -p|--pack)
      IN_DIR=$2
      shift 2
      ;;
    -a|--apply)
      PATCH_FILE=$2
      shift 2
      ;;
    -f|--force)
      FORCE=1
      shift
      ;;
    -h|--help)
      HELP=1
      shift
      ;;
    --)
      shift
      break
      ;;
    *)
      exit 1
      ;;
  esac
done

if [[ $# -ne 1 ]]
then
  echo "No file supplied"
  HELP=1
fi

if [ "${HELP}" == "1" ]
then
  SCRIPT_FILE=$(basename $0)
  echo "Usage: ${SCRIPT_FILE}: [OPTIONS] [APK]"
  echo ""
  echo "Options:"
  echo "  -u, --unpack [DIRECTORY]  Unpack apk to [DIRECTORY]"
  echo "  -p, --pack   [DIRECTORY]  Pack [DIRECTORY] into [APK]"
  echo "  -a, --apply  [PATCH]      Apply [PATCH] to [APK]"
  echo "  -f, --force               Force overwrite"
  echo "  -h, --help                This help message"
  exit 1
fi

if [ ! -z ${PATCH_FILE} ]
then
  if [ ! -e ${PATCH_FILE} ]
  then
    echo "${PATCH_FILE} doesn't exist"
    exit 1
  fi

  if [ ! -z ${OUT_DIR} ] || [ ! -z ${IN_DIR} ]
  then
    echo "Can't unpack/pack when applying a patch"
    exit 1
  fi

  TEMP_DIR=$(mktemp -d)

  OUT_DIR=${TEMP_DIR}
  IN_DIR=${TEMP_DIR}
  FORCE=1
fi

FILE=$(realpath $1)
BASE_FILE=$(basename ${FILE})
FILE_DIR=$(dirname ${FILE})

if [ ! -z ${OUT_DIR} ]
then
  OUT_DIR=$(realpath ${OUT_DIR})

  if [ ! -e ${FILE} ]
  then
    echo "${FILE} doesn't exist"
    exit 1
  fi

  if [ -e ${OUT_DIR} ]
  then
    if [ "${FORCE}" == "1" ]
    then
      rm -rf ${OUT_DIR}/* ${OUT_DIR}/.git*
    elif [ -n "$(ls -A ${OUT_DIR})" ]
    then
      echo "${OUT_DIR} not empty (or is a file)"
      exit 1
    fi
  else
    mkdir -p ${OUT_DIR}
  fi

  echo "=== Extracting apk ============================================================="
  unzip -d ${OUT_DIR}/apk ${FILE} || exit $?
  echo "=== Extracting install-files.zip ==============================================="
  unzip -d ${OUT_DIR} \
    ${OUT_DIR}/apk/assets/install-files.zip || exit $?
  echo "=== Extracting 2nd-init.zip ===================================================="
  unzip -d \
    ${OUT_DIR}/2nd-init \
    ${OUT_DIR}/install-files/etc/safestrap/2nd-init.zip || exit $?

  echo "=== Extracting ramdisk-recovery.img ============================================"
  unpackRamdiskImage \
    ${OUT_DIR}/install-files/etc/safestrap/ramdisk-recovery.img \
    ${OUT_DIR}/ramdisk-recovery || exit $?

  if hash git 2>/dev/null
  then
    (
      echo "=== Making git repository ======================================================"
      cd ${OUT_DIR}
      git init && \
      git add apk install-files 2nd-init ramdisk-recovery && \
      git commit --quiet -m "Initial commit" || exit $?
    )
  fi
fi

if [ ! -z ${PATCH_FILE} ]
then
  echo "=== Patching ==================================================================="
  patch -d ${TEMP_DIR} -p0 < ${PATCH_FILE} || exit $?
fi

if [ ! -z ${IN_DIR} ]
then
  IN_DIR=$(realpath ${IN_DIR})

  if [ ! -e ${IN_DIR} ]
  then
    echo "${IN_DIR} doesn't exist"
    exit 1
  fi

  if [ -e ${FILE} ] && [ "${FORCE}" != "1" ]
  then
    echo "${FILE} already exists"
    exit 1
  fi

  rm ${IN_DIR}/install-files/etc/safestrap/ramdisk-recovery.img
  echo "=== Packing ramdisk-recovery.img ==============================================="
  packRamdiskImage \
    ${IN_DIR}/ramdisk-recovery \
    ${IN_DIR}/install-files/etc/safestrap/ramdisk-recovery.img || exit $?

  (
    cd ${IN_DIR}/2nd-init
    echo "=== Packing 2nd-init.zip ======================================================="
    zip -r9 ${IN_DIR}/install-files/etc/safestrap/2nd-init.zip \
      .
  ) || exit $?

  (
    cd ${IN_DIR}
    echo "=== Packing install-files.zip =================================================="
    zip -r9 ${IN_DIR}/apk/assets/install-files.zip \
      install-files
  ) || exit $?

  (
    cd ${IN_DIR}/apk
    echo "=== Packing apk ================================================================"
    zip -r9 ${FILE_DIR}/_${BASE_FILE} . || exit $?

    echo "=== Signing apk ================================================================"
    java -jar ${DIR}/signapk/signapk.jar ${DIR}/signapk/key.x509.pem \
      ${DIR}/signapk/key.pk8 ${FILE_DIR}/_${BASE_FILE} \
      ${FILE}
  ) || exit $?

  rm -f ${FILE_DIR}/_${BASE_FILE}
fi

if [ -e ${TEMP_DIR} ]
then
  rm -rf ${TEMP_DIR}
fi

echo "Done!"
