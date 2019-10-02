FROM nginx:alpine

RUN apk --update add --no-cache --update jq;

# cleanup cache.
RUN rm -rf /root/.cache && rm -rf /var/cache/apk/*

# cleanup nginx configs.
# RUN  find /etc/nginx/conf.d/ ! -name 'default.conf' -type f -exec rm -f {} +
