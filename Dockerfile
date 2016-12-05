FROM nginx:1.11-alpine

RUN apk --no-cache add openssl

RUN wget -O /home/consul-template.zip \
    https://releases.hashicorp.com/consul-template/0.16.0/consul-template_0.16.0_linux_386.zip && \
  unzip /home/consul-template.zip -d /usr/bin && \
  chmod +x /usr/bin/consul-template && \
  rm /home/consul-template.zip && \
  mkdir /var/log/consul-template

COPY nginx.conf /etc/consul-template/nginx.conf
COPY run.sh /home/run.sh

VOLUME [ "/var/log/nginx", "/var/log/consul-template" ]

ENTRYPOINT [ "/home/run.sh" ]

