#!/bin/bash
# Script to create self signed certificate
# Usage ./gen-cert.sh bookinfo bookinfo.tetrate.com .

APP=bookinfo
DNS=bookinfo.tetrate.com
DIR=.

mkdir -p ${DIR}

# Create openssl config file
cat <<EOF | envsubst > ${DIR}/${APP}.cnf
[req]
default_bits       = 2048
prompt             = no
distinguished_name = req_distinguished_name
req_extensions     = san_reqext

[ req_distinguished_name ]
countryName         = US
stateOrProvinceName = CA
organizationName    = Tetrateio

[ san_reqext ]
subjectAltName      = @alt_names

[alt_names]
DNS.0 = ${DNS}
EOF

openssl req \
    -x509 \
    -sha256 \
    -nodes \
    -days 365 \
    -newkey rsa:4096 \
    -subj "/C=US/ST=CA/O=Tetrateio/CN=${DNS}" \
    -keyout ${DIR}/${APP}-ca.key \
    -out ${DIR}/${APP}-ca.crt

# generate certificate
openssl req \
    -out ${DIR}/${APP}.csr \
    -newkey rsa:2048 -nodes \
    -keyout ${DIR}/${APP}.key \
    -config ${DIR}/${APP}.cnf

# sign certificate with CA
openssl x509 \
    -req \
    -days 365 \
    -CA ${DIR}/${APP}-ca.crt \
    -CAkey ${DIR}/${APP}-ca.key \
    -set_serial 0 \
    -in ${DIR}/${APP}.csr \
    -out ${DIR}/${APP}.crt \
    -extfile ${DIR}/${APP}.cnf \
    -extensions san_reqext

kubectl -n bookinfo create secret tls bookinfo-certs --key bookinfo.key --cert bookinfo.crt
