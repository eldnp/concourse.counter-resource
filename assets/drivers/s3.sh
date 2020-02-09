#!/bin/sh
# vim: set ft=sh


S3_ALIAS=s3

configure_minio_client() {
  set -e
  local endpoint=$(jq -r '.source.endpoint // "undefined-host"' < $1)
  local access_key_id=$(jq -r '.source.access_key_id // "undefined-access_key_id"' < $1)
  local secret_access_key=$(jq -r '.source.secret_access_key // "undefined-secret_access_key"' < $1)
  mc config host add ${S3_ALIAS} ${endpoint} ${access_key_id} ${secret_access_key} >/dev/null
}

pullCounter() {
  set -e
  configure_minio_client $1
  local bucket=$(jq -r '.source.bucket // "undefined-bucket"' < $1)
  local key=$(jq -r '.source.key // "undefined-key"' < $1)
  local initial_value=$(jq -r '.source.initial_value // 0' < $1)

  mc stat $S3_ALIAS/$bucket > /dev/null
  local node=$S3_ALIAS/$bucket/$key
  if ! number=$(mc cat $node 2>/dev/null); then
    local number=$initial_value
  fi
  echo $number
}

pushCounter() {
  set -e
  configure_minio_client $1
  local bucket=$(jq -r '.source.bucket // "undefined-bucket"' < $1)
  local key=$(jq -r '.source.key // "undefined-key"' < $1)
  local number=$2
  local node=$S3_ALIAS/$bucket/$key
  configure_minio_client $1
  echo "$number" | mc pipe $node
}
