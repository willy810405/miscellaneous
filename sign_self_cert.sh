#!/bin/bash

read -p "Input Your FQDN, e.g. abc.helloworld.com: " fqdn_input
read -p "Input Your DNS Domain Name, e.g. helloworld.com": dns_domain_name
mkdir cert && cd cert
openssl genrsa -out ca.key 4096

openssl req -x509 -new -nodes -sha512 -days 3650 \
 -subj "/C=TW/ST=Taipei/L=Taipei/O=hpe/OU=cic/CN=$fqdn_input" \
 -key ca.key \
 -out ca.crt

openssl genrsa -out $fqdn_input.key 4096

openssl req -sha512 -new \
    -subj "/C=TW/ST=Taipei/L=Taipei/O=hpe/OU=cic/CN=$fqdn_input" \
    -key $fqdn_input.key \
    -out $fqdn_input.csr

cat > v3.ext <<-EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
DNS.1=$dns_domain_name
DNS.2=$fqdn_input
EOF

openssl x509 -req -sha512 -days 3650 \
    -extfile v3.ext \
    -CA ca.crt -CAkey ca.key -CAcreateserial \
    -in $fqdn_input.csr \
    -out $fqdn_input.crt

openssl x509 -inform PEM -in $fqdn_input.crt -out $fqdn_input.cert

mkdir -p /etc/docker/certs.d/$fqdn_input

cp $fqdn_input.cert $fqdn_input.key ca.crt /etc/docker/certs.d/$fqdn_input/ 

