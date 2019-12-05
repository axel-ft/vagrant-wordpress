# Adding certificate files

You can add a full Let's Encrypt (or other, but not tested). Let's Encrypt will provide you the following files, which are required if you use HTTPS :

- `cert.pem`
- `chain.pem`
- `fullchain.pem`
- `options-ssl-nginx.conf`
- `privkey.pem`
- `ssl-dhparams.pem`

HAProxy uses also a different file for HTTPS which can be created from the above certificate (or another certificate). For the first solution the command is `if [ ! -f ./haproxy.pem ]; then cat ./fullchain.pem ./privkey.pem > ./haproxy.pem; fi;`
