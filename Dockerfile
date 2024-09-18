FROM nginx:mainline-alpine-slim

RUN apk --no-cache add openssl

# Add logrotate
RUN apk --no-cache add logrotate

# Download and install consul-template
RUN wget -O /home/consul-template.zip \
    https://releases.hashicorp.com/consul-template/0.16.0/consul-template_0.16.0_linux_386.zip && \
  unzip /home/consul-template.zip -d /usr/bin && \
  chmod +x /usr/bin/consul-template && \
  rm /home/consul-template.zip && \
  mkdir /var/log/consul-template

# Copy over configuration files and scripts
COPY nginx.conf /etc/nginx/nginx.conf
COPY openlmis.conf /etc/consul-template/openlmis.conf
COPY run.sh /home/run.sh

# Add a logrotate configuration file for nginx and consul-template
COPY logrotate.conf /etc/logrotate.d/nginx

# Change permissions for logrotate.conf
RUN chmod 644 /etc/logrotate.d/nginx

# Set volumes for log files
VOLUME [ "/var/log/nginx", "/var/log/consul-template" ]

ENTRYPOINT [ "/home/run.sh" ]
