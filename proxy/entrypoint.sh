#!/usr/bin/env sh

update_nginx_wrkr_ps() {
    # Tweak nginx to match the workers of cpu's
    procs=$(cat /proc/cpuinfo | grep -c processor )
    sed -i -e "s/worker_processes  1/worker_processes $procs/" /etc/nginx/nginx.conf
}

build_server_directives() {
    if ! [[ -f ./servers.json ]]; then
        echo "Servers are not defined skipping custom server config..."
        return;
    fi

    # install jq
    apk --update --no-cache add jq curl;

    jq -r '.[] | keys[]' < ./servers.json | while read server_container;
    do
        # printf "Checking if container %s is reachable...%b" "$server_container" "\n"
        # ping -c 1 "$server_container" &> /dev/null

        http_resp=$(curl -s -o /dev/null -w "%{http_code}" "$server_container:3000" --connect-timeout 1)

        # if curl cannot connect then returns "000".
        if [[ "$http_resp" -eq "000" ]]; then 
            echo "Container $server_container is not available, skipping..."
            continue
        fi


        server_name=$(jq -r ".[].$server_container | .server_name" < ./servers.json )
        proxy_url="http://$server_container"

        server=$(
            printf '
            upstream %s { server %s:3000; }
            server {
                listen %d;
                server_name %s;
                location / {
                    proxy_pass %s;
                    proxy_redirect off;
                }
            }' "$server_container" "$server_container" 80 "$server_name" "$proxy_url"
        );

        echo "$server" > /etc/nginx/conf.d/"$server_container".conf

    done
}


build_server_directives

nginx -g "daemon off;"
exec "$@"
exit 0
