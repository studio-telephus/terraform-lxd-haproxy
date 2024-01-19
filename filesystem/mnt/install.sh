#!/usr/bin/env bash
: "${BIND_PORT?}"
: "${HAPROXY_STATS_AUTH_USERNAME?}"
: "${HAPROXY_STATS_AUTH_PASSWORD?}"

# env > /tmp/env.out

NODE_ARRAY=()
for pair in "${!HAPROXY_NODE_@}"; do
  n=${!pair}
  if [ ! -z "$n" ]; then
    NODE_ARRAY+=($n)
  fi
done

if [ -z "$NODE_ARRAY" ]; then
    echo "No addresses found from environment variables. Exiting!"
    exit 1
fi

server_node_lines=$(
  for i in "${!NODE_ARRAY[@]}"; do
    echo "server node$i ${NODE_ARRAY[$i]} check check-ssl verify none inter 10000"
  done
)

apt-get update
apt-get install -y openssl net-tools

cat >/tmp/my-haproxy-tcp-passthrough.cfg.append <<EOF
listen my-haproxy-tcp-passthrough
  bind :$BIND_PORT
  mode tcp
  option log-health-checks
  timeout client 3h
  timeout server 3h
  $server_node_lines
  balance roundrobin
EOF

echo "create a self-signed SSL certificate in /etc/ssl/private"
openssl req -x509 \
  -newkey ec \
  -pkeyopt ec_paramgen_curve:secp384r1 \
  -days 3650 \
  -nodes -keyout /etc/ssl/private/server-haproxy.key \
  -out /etc/ssl/private/server-haproxy.crt \
  -subj "/CN=$(hostname)" \
  -addext "subjectAltName=DNS:$(hostname),DNS:*.$(hostname),IP:$(hostname -I)"

echo "Create a pem file by copying key and certificate to a file"
cat /etc/ssl/private/server-haproxy.key /etc/ssl/private/server-haproxy.crt > /etc/ssl/private/server-haproxy.pem

echo "Print details"
openssl x509 -noout -text -in /etc/ssl/private/server-haproxy.pem

cat >/tmp/my-haproxy-http-stats.cfg.append <<EOF
listen my-haproxy-http-stats
  bind :55443 ssl crt /etc/ssl/private/server-haproxy.pem
  mode http
  stats auth $HAPROXY_STATS_AUTH_USERNAME:$HAPROXY_STATS_AUTH_PASSWORD
  stats enable
  stats hide-version
  stats realm HAProxy\ Statistics
  stats uri /server-status
EOF

apt-get install -y haproxy

if [ ! -f "/etc/haproxy/haproxy.cfg.orig" ]
then
  echo "Backing up the original HAProxy config file."
  cp -pr /etc/haproxy/haproxy.cfg /etc/haproxy/haproxy.cfg.orig
fi

cat \
  /etc/haproxy/haproxy.cfg.orig \
  /tmp/my-haproxy-tcp-passthrough.cfg.append \
  /tmp/my-haproxy-http-stats.cfg.append \
  > /etc/haproxy/haproxy.cfg


systemctl restart haproxy
echo "HAProxy is ready!"
