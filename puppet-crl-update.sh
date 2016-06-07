#!/usr/bin/env bash

# This script will connect to the REST API of the Puppet CA listed in your
# Puppet config and update the local copy of the certificate revocation list.
#
# This is used to update the CRL which is used by the OpenVPN server.
#
# https://docs.puppetlabs.com/guides/rest_api.html#certificate-revocation-list
# https://ask.puppetlabs.com/question/3843/multiple-puppet-masters-with-single-ca-server/

status='NOTSET'

puppetuser=`puppet config print user`
puppetgroup=`puppet config print group`

ssldir=`puppet config print ssldir`
certname=`hostname -f`
puppetca=`puppet config print --section agent ca_server`

environment=`puppet config print environment`
headers="Accept: s"
caendpoint="https://${puppetca}:8140/${environment}/certificate_revocation_list/ca"

local_crl_file=`puppet config print hostcrl`
newtmp_local_crl_file="/tmp/puppet_ca_crlpem.tmp"

curl --output "${newtmp_local_crl_file}" \
--cacert "${ssldir}/certs/ca.pem" \
--cert "${ssldir}/certs/${certname}.pem" \
--key "${ssldir}/private_keys/${certname}.pem" \
-H "${headers}" "${caendpoint}"

openssl crl -text -in "${newtmp_local_crl_file}" -CAfile "${ssldir}/certs/ca.pem" -noout && status='VALID'

if [ "x${status}" == "xVALID" ]; then
  mv -f "${newtmp_local_crl_file}" "${local_crl_file}"
  chown ${puppetuser}:${puppetgroup} "${local_crl_file}"
fi
