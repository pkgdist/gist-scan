#!/bin/bash
if [ ! -f .envcrypt ]
then
  #export $(cat .env | xargs)
  export $(sed 's/=.*//' .envcrypt)
fi

set -a && source .envcrypt && set +a

