#!/usr/bin/env bash

set -e

circuit=$1
iterations=$2
network=$3
copies=$4
id=$5
output_file="benchmarks/$(hostname)/${id}/${circuit}_${network}_${copies}.txt"
output_dir=$(dirname "$output_file")

server_hostname="SERVER_HOSTNAME"
client_hostname="CLIENT_HOSTNAME"
server_ip="SERVER_IP"
client_ip="CLIENT_IP"

case $(hostname) in
    "$server_hostname")
	my_id="0"
	;;
    "$client_hostname")
	my_id="1"
	;;
    *)
	echo "Hostname not recognized"
	exit 1
	;;
esac

mkdir -p "$output_dir"
true > "$output_file"

for i in $(seq "$iterations")
do
    ../ba-aby/build/bin/uc_circuit_test -e "${circuit}.prog" -f "${circuit}" -a "$server_ip" -r "$my_id" -i "$copies" | tee -a "$output_file"
done
