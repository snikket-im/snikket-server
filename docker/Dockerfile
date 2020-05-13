FROM debian:buster-slim

ARG BUILD_SERIES=dev
ARG BUILD_ID=0

# Install dependencies

RUN install -d -m 755 /snikket;

ADD tools/smtp-url-to-msmtp.lua /usr/local/bin/smtp-url-to-msmtp
RUN chmod 550 /usr/local/bin/smtp-url-to-msmtp

ADD docker/entrypoint.sh /bin/entrypoint.sh
RUN chmod 770 /bin/entrypoint.sh
ENTRYPOINT ["/bin/entrypoint.sh"]

ADD ansible /opt/ansible

ADD snikket-modules /usr/local/lib/snikket-modules

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        software-properties-common \
        gpg gpg-agent \
        ansible python-passlib python3-passlib \
        libcap2-bin \
    && rm -rf /var/lib/apt/lists/* \
    && ansible-playbook -c local -i localhost, --extra-vars "ansible_python_interpreter=/usr/bin/python2" /opt/ansible/snikket.yml \
    && apt-get remove -y \
         ansible \
         software-properties-common \
         gpg gpg-agent \
         python-passlib python3-passlib \
         mercurial libcap2-bin \
    && apt-get autoremove -y \
    && rm -rf /var/cache/*

ADD www /var/www

RUN echo "Snikket $BUILD_SERIES.$BUILD_ID" > /usr/lib/prosody/prosody.version

VOLUME ["/snikket"]
