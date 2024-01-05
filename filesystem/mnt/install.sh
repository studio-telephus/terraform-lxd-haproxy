#!/usr/bin/env bash
: "${NODE_VARIABLE_PREFIX?}"
: "${BIND_PORT?}"

# env > /tmp/env.out

NODE_ARRAY=()
for pair in "${!$NODE_VARIABLE_PREFIX@}"; do
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

cat >/tmp/my_haproxy.cfg.append <<EOF
listen my-haproxy-tcp
  bind :$BIND_PORT
  mode tcp
  option log-health-checks
  timeout client 3h
  timeout server 3h
  $server_node_lines
  balance roundrobin
EOF

apt-get update
apt-get install -y openssl net-tools haproxy

cp -pr /etc/haproxy/haproxy.cfg /etc/haproxy/haproxy.cfg.orig
cat /tmp/my_haproxy.cfg.append >> /etc/haproxy/haproxy.cfg

systemctl restart haproxy

echo "HAProxy is ready!"
