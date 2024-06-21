#!/bin/bash

if [ -z "$SERVER" ] || [ -z "$EMAIL" ]; then
  echo "Missing SERVER or EMAIL"
  exit 1
fi

ssh -T -i .mysecrets/id_rsa.hetzner piwigo@${SERVER} <<EOF

sudo -i

echo "
server {
    listen              80;
    server_name         ${SERVER};
    root                /usr/share/nginx/html;
    location / {
        return 301 https://${SERVER}\\\$request_uri;
    }
    location /.well-known {
    }
}
server {
    listen              443 ssl;
    server_name         ${SERVER};
    ssl_certificate     /etc/letsencrypt/live/${SERVER}/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/${SERVER}/privkey.pem;
    location / {
        proxy_set_header    Host              \\\$host;
        proxy_set_header    X-Forwarded-Proto https;
        proxy_set_header    X-Forwarded-For   \\\$proxy_add_x_forwarded_for;
        proxy_pass          http://piwigo:80;
    }
}
" > /data/proxy/conf.d/app.conf

if [ ! -d /data/proxy/letsencrypt/live/${SERVER} ]; then
  docker run --rm \
    -v /data/proxy/webroot:/webroot \
    -v /data/proxy/letsencrypt:/etc/letsencrypt \
    certbot/certbot certonly --agree-tos --renew-by-default \
      --webroot --webroot-path=/webroot \
      --email ${EMAIL} --non-interactive \
      -d ${SERVER}
   docker exec proxy service nginx restart
else
  docker run  --rm \
    -v /data/proxy/webroot:/webroot \
    -v /data/proxy/letsencrypt:/etc/letsencrypt \
    certbot/certbot renew --webroot --webroot-path=/webroot
  docker exec proxy service nginx reload  
fi
EOF