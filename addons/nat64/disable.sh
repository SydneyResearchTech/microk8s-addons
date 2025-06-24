#!/bin/bash
ENABLE="$SNAP/microk8s-enable.wrapper"
KUBECTL="$SNAP/microk8s-kubectl.wrapper"

# Configure CoreDNS
COREDNS=$($KUBECTL -n kube-system get configmap/coredns -o json)
if $(echo "$COREDNS" | grep -q 'dns64'); then
	COREFILE=$(echo "$COREDNS" | jq -r '.data.Corefile' | sed '/dns64/,/}$/d')
	jq --arg COREFILE "$COREFILE" '.data.Corefile = $COREFILE' <(echo "$COREDNS") | \
		$KUBECTL -n kube-system apply -f -
fi

systemctl disable --now tayga.service

rm -f "${SNAP_DATA}/var/lock/nat64.enabled"
