#!/bin/bash
ENABLE="$SNAP/microk8s-enable.wrapper"
KUBECTL="$SNAP/microk8s-kubectl.wrapper"

echo "Enable DNS addon"
$ENABLE dns

echo "Install TAYGA - NAT64 for Linux"
if ! systemctl list-unit-files tayga.service &>/dev/null; then
	apt-get update
	apt-get -y install tayga
fi
[[ -f /etc/tayga.conf-orig ]] || cp /etc/tayga.conf /etc/tayga.conf-orig
cat <<EOT >/etc/tayga.conf
tun-device nat64
ipv4-addr 100.64.0.1
prefix 64:ff9b::/96
dynamic-pool 100.64.0.0/10
data-dir /var/spool/tayga
EOT
systemctl enable --now tayga.service

# https://coredns.io/plugins/dns64/
# microk8s kubectl -n kube-system edit configmap/coredns
echo "Configure CoreDNS with dns64 plugin"
COREDNS=$($KUBECTL -n kube-system get configmap/coredns -o json)

if ! $(echo "$COREDNS" | grep -q 'dns64'); then
	COREFILE=$(echo "$COREDNS" | jq -r '.data.Corefile' | sed '/^}/i\    dns64 {
      translate_all
      prefix 64:ff9b::/96
      allow_ipv4
    }')
	jq --arg COREFILE "$COREFILE" '.data.Corefile = $COREFILE' <(echo "$COREDNS") | \
		$KUBECTL -n kube-system apply -f - --dry-run=client
fi

#touch "${SNAP_DATA}/var/lock/nat64.enabled"
