#! /bin/bash

function splitRamdiskImage
{
  local FILE=$1

  if [ ! -e ${FILE} ]
  then
    echo "${FILE} doesn't exist"
    return 1
  fi

  local OUT_DIR=$2

  if [ ! -e ${OUT_DIR} ]
  then
    mkdir -p ${OUT_DIR}
  fi

  (
    local BASE_FILE=$(basename ${FILE})
    local OFFSET=$(grep -Uboa $'\x1f\x8b\x08' \
      ${FILE} | \
      perl -pe 's/([0-9]+):.*/$1/' | head -n 2 | tail -n 1)
    dd count=${OFFSET} bs=1 if=${FILE} \
      of=${OUT_DIR}/${BASE_FILE}.1.cpio.gz
    dd skip=${OFFSET} bs=1 if=${FILE} \
      of=${OUT_DIR}/${BASE_FILE}.2.cpio.gz
  )

  return 0
}

function unpackRamdiskImage
{
  local FILE=$1

  if [ ! -e ${FILE} ]
  then
    echo "${FILE} doesn't exist"
    return 1
  fi

  local OUT_DIR=$2

  if [ -e ${OUT_DIR} ]
  then
    if [ -n "$(ls -A ${OUT_DIR})" ]
    then
      echo "${OUT_DIR} not empty (or is a file)"
      return 2
    fi
  else
    mkdir -p ${OUT_DIR}
  fi

  (
    gzip -cd ${FILE} | cpio -i -D ${OUT_DIR}
  ) || return $?

  return 0
}

function packRamdiskImage
{
  local IN_DIR=$1

  if [ ! -e ${IN_DIR} ]
  then
    echo "${IN_DIR} doesn't exist"
    return 1
  fi

  local FILE=$2

  if [ -e ${FILE} ]
  then
    echo "${FILE} already exists"
    return 2
  fi

  (    
    find ${IN_DIR} -printf '%P\n' | cpio -o -H newc --owner=root:root -D ${IN_DIR} | gzip > \
      ${FILE}
  ) || return 3

  return 0
}
