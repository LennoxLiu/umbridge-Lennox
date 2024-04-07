#! /bin/bash

#HQ --resource model=1
#HQ --time-request=1m
#HQ --time-limit=2m

# Launch model server, send back server URL
# and wait to ensure that HQ won't schedule any more jobs to this allocation.
load_balancer_dir="./"
# Write port to file identified by HQ job ID.
mkdir -p "$load_balancer_dir/ports"

function get_avaliable_port {
    # Define the range of ports to select from
    MIN_PORT=49152
    MAX_PORT=65535

    # Generate a random port number
    port=$(shuf -i $MIN_PORT-$MAX_PORT -n 1)

    # Check if the port is in use
    while lsof -Pi :$port -t; do
        # If the port is in use, generate a new random port number
        port=$(shuf -i $MIN_PORT-$MAX_PORT -n 1)

    done

    echo "$port" > "$load_balancer_dir/ports/$HQ_JOB_ID-1.txt"
    echo $port
}


port=$(get_avaliable_port)
# sleep 1 # Wait for the port to be correctly assigned, otherwise it will sometimes get strange value in $port

echo "$port" > "$load_balancer_dir/ports/$HQ_JOB_ID-2.txt"

export PORT=$port && ./server & # Assume that server sets the port according to the environment variable 'PORT'.


host=$(hostname -I | awk '{print $1}')

# Wait for model server to start
while ! curl -s "http://$host:$port/Info" > /dev/null; do
    sleep 1
done

# Write server URL to file identified by HQ job ID.
mkdir -p "$load_balancer_dir/urls"
echo "http://$host:$port" > "$load_balancer_dir/urls/url-$HQ_JOB_ID.txt"

sleep infinity # keep the job occupied