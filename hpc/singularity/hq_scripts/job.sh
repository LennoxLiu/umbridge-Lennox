#! /bin/bash

#HQ --resource model=1
#HQ --time-request=1m
#HQ --time-limit=2m
#HQ --stdout none
#HQ --stderr print

# Launch model server, send back server URL
# and wait to ensure that HQ won't schedule any more jobs to this allocation.

function get_avaliable_port {
    # Define the range of ports to select from
    MIN_PORT=1024
    MAX_PORT=65535

    # Generate a random port number
    port=$(shuf -i $MIN_PORT-$MAX_PORT -n 1)

    # Check if the port is in use
    while lsof -Pi :$port -sTCP:LISTEN -t >/dev/null; do
        # If the port is in use, generate a new random port number
        port=$(shuf -i $MIN_PORT-$MAX_PORT -n 1)
    done

    echo $port
}

port=$(get_avaliable_port)
export PORT=$port

# Assume that server sets the port according to the environment variable 'PORT'.
#singularity build --remote --sandbox l2-sea/ l2-sea.def && \
singularity run --writable --pwd /  l2-sea/ $port & # Run server in background

load_balancer_dir="./load-balancer" # Directory where load balancer stores its files


host=$(hostname -I | awk '{print $1}')

# Wait for model server to start
while ! curl -s "http://$host:$port/Info" > /dev/null; do
    sleep 1
done

# Write server URL to file identified by HQ job ID.
mkdir -p "$load_balancer_dir/urls"
echo "http://$host:$port" > "$load_balancer_dir/urls/url-$HQ_JOB_ID.txt"

sleep infinity # keep the job occupied