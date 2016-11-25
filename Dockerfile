FROM nginx

COPY consul-template /usr/bin/consul-template
COPY nginx.conf /etc/consul-template/nginx.conf
COPY run.sh /home/run.sh

ENTRYPOINT [ "/home/run.sh" ]

