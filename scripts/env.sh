#!/usr/bin/env bash
set -u
pushd . && cd scripts
envf="../.envcrypt"
if [ ! -f $envf ]
then
  export $(sed 's/=.*//' $envf)
fi

set -a && source $envf && set +a
popd