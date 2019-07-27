#!/usr/bin/env bash

update_nginx_wrkr_ps() {
    # Tweak nginx to match the workers of cpu's
    procs=$(grep -c processor </proc/cpuinfo)
    sed -i -e "s/worker_processes  1/worker_processes $procs/" /etc/nginx/nginx.conf
}

build_server_directives() {
    if ! [[ -f ./servers.json ]]; then
        echo "Proxy servers settings not found. Aboting!"
        exit 1
    fi

    # install jq
    apk --update add jq

    jq -r '.[] | keys[]' <./servers.json | while read server_container; do

        # Host availability check.
        if ping -c 1 "$server_container" &>/dev/null; then
            echo "$server_container is available."
        else
            echo "$server_container is not available, skipping this host..."
            continue
        fi

        server_name=$(jq -r ".[].$server_container | .server_name" <./servers.json)
        app_port=$(jq -r ".[].$server_container | select(.app_port !=null) | .app_port" <./servers.json)
        proxy_port=$(jq -r ".[].$server_container | select(.proxy_port !=null) | .proxy_port" <./servers.json)
        proxy_url="http://$server_container"

        server=$(
            printf '
            upstream %s { server %s:%d; }
            server {
                listen %d;
                server_name %s;
                location / {
                    proxy_pass %s;
                    proxy_redirect off;
                }
            }' "$server_container" "$server_container" "${app_port:-80}" "${proxy_port:-80}" "$server_name" "$proxy_url"
        )

        echo "$server" >/etc/nginx/conf.d/"$server_container".conf

    done
}

build_server_directives

# Start nginx.
nginx -g "daemon off;"
exec "$@"
exit 0
