FROM nginx

RUN apt-get update
RUN apt-get install -y wget unzip

RUN wget -O /home/consul-template.zip https://releases.hashicorp.com/consul-template/0.16.0/consul-template_0.16.0_linux_386.zip
RUN unzip /home/consul-template.zip -d /usr/bin
RUN chmod +x /usr/bin/consul-template
RUN rm /home/consul-template.zip

COPY nginx.conf /etc/consul-template/nginx.conf
COPY run.sh /home/run.sh

ENTRYPOINT [ "/home/run.sh" ]

