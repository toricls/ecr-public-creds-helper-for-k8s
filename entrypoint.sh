#!/usr/bin/env bash

REGISTRY=https://public.ecr.aws
AUTH_USER=AWS
AUTH_TOKEN=`aws ecr-public get-authorization-token --region us-east-1 --output=text --query 'authorizationData.authorizationToken' | base64 -d | cut -d: -f2`

for n in $(echo ${TARGET_NAMESPACES})
do
    kubectl delete secret ecr-public-token \
        -n "${n}" \
        --ignore-not-found
    kubectl create secret docker-registry ecr-public-token \
        -n "${n}" \
        --docker-server=${REGISTRY} \
        --docker-username=${AUTH_USER} \
        --docker-password=${AUTH_TOKEN}
    # Uncomment the following lines if you want to make all pods use this token without specifying it in each PodSpec.
    #kubectl patch serviceaccount default \
    #    -n "${n}"
    #    -p '{"imagePullSecrets":[{"name":"ecr-public-token"}]}'
done
