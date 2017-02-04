FROM nginx

ENV KUBECTL_VERSION v1.3.0

RUN apt-get update && apt-get install -y git wget cron bc

RUN mkdir -p /letsencrypt/challenges/.well-known/acme-challenge
RUN git clone https://github.com/certbot/certbot /letsencrypt/app
WORKDIR /letsencrypt/app
RUN ./letsencrypt-auto; exit 0

# You should see "OK" if you go to http://<domain>/.well-known/acme-challenge/health

RUN echo "OK" > /letsencrypt/challenges/.well-known/acme-challenge/health

# Install kubectl
RUN wget https://storage.googleapis.com/kubernetes-release/release/$KUBECTL_VERSION/bin/linux/amd64/kubectl
RUN chmod +x kubectl
RUN mv kubectl /usr/local/bin/

# Add our nginx config for routing through to the challenge results
RUN rm /etc/nginx/conf.d/*.conf
COPY nginx/nginx.conf /etc/nginx/
COPY nginx/letsencrypt.conf /etc/nginx/conf.d/

# Add some helper scripts for getting and saving scripts later
COPY fetch_certs.sh save_certs.sh refresh_certs.sh start.sh /letsencrypt/

COPY nginx/letsencrypt.conf /etc/nginx/snippets/letsencrypt.conf

RUN ln -s /root/.local/share/letsencrypt/bin/letsencrypt /usr/local/bin/letsencrypt

WORKDIR /letsencrypt

ENTRYPOINT ./start.sh
