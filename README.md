## NGINX proxy server for docker containers.

This is a simple nginx proxy server setup to map web apps running independently on seperate containers.

![Image](proxy/nginx-proxy-containers.png  "Figure: Nginx Proxy server workflow.")

For instance, if we are running more than one web apps on docker containers then obviously, we will not be able to expose same external port for the app.
``` 
for example:
- http://my-site-a:80/
- http://my-site-b:81/
- http://my-site-c:82/
```

By using, nginx proxy server we can request respective servers irrespective to the exposed port to host.

### Network

Docker containers need to be in same network in order to identify each other. Therefore, we will have to create a bridge network and assign that network to every docker container we wish to put in the proxy network.

```sh
docker network create -d bridge nginx-proxy
```

Include, network config in docker compose file, for example:

```yaml
version: '3.5'
services:
  service_1:
    container_name: my_container_1
    image: nginx:alpine
    networks:
      - nginx-proxy
networks:
  nginx-proxy:
    name: nginx-proxy
```

### NGINX config

Your server configs has to be configured in `nginx.conf` file.

#### [upstream directive](http://nginx.org/en/docs/http/ngx_http_upstream_module.html#upstream)

Upstream directive is used to define a server or group of servers for HTTP loadbalancing or proxying against.

```config
    upstream site_a { server site_a; }

```

Here `site_a` is name of active container where your app is running.

### [server directive](http://nginx.org/en/docs/http/ngx_http_upstream_module.html#server)

Defines server configs including location (path), listening port, server name and the origin server to request on behalf of client.

```config
server {
        listen 80;
        server_name my-site-a;
        location / {
            proxy_pass http://site_a;
            proxy_redirect off;
        }
    }
```

Here `site_a` is again a name of active container which is mentioned in `upstream` directive. `sever_name my-site-a` is the host name that is requested from client which is received by the proxy server and requests `http://site_a` on behalf of client and sends back the response from origin to client.


### Test

This repo consists of a working proxy server and sample web app `site_a` and `site_b`.

Steps:

1. `cd site-A/ && docker-compose up --build -d` : Spin up `site_a` container.
2. `cd site-B/ && docker-compose up --build -d` : Spin up `site_b` container.
3. `cd proxy/ && docker-compose up --build -d` : Spins up the `the_proxy` container.

**Note**: `site_a` and `site_b` both containers do not have any exposed [ports](site-A/docker-compose.yaml). However, docker can internally identify the service.

Add hostnames entries in your host machine's `/etc/hosts` file.
```
127.0.0.1 my-site-a
127.0.0.1 my-site-b
```

Now, lets do a http request on one of these host.
```
➜ curl -I my-site-a
HTTP/1.1 200 OK
Server: nginx/1.15.8
Date: Sun, 27 Jan 2019 12:01:02 GMT
Content-Type: text/plain
Content-Length: 18
Connection: keep-alive
```