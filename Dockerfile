FROM debian:bookworm-slim

ARG BUILD_SERIES=dev
ARG BUILD_ID=0

# Install dependencies

RUN install -d -m 755 /snikket;

ADD tools/smtp-url-to-msmtp.lua /usr/local/bin/smtp-url-to-msmtp
RUN chmod 550 /usr/local/bin/smtp-url-to-msmtp

ADD docker/entrypoint.sh /bin/entrypoint.sh
RUN chmod 770 /bin/entrypoint.sh
ENTRYPOINT ["/bin/entrypoint.sh"]

HEALTHCHECK CMD /usr/bin/prosodyctl shell "portcheck ${SNIKKET_TWEAK_INTERNAL_HTTP_INTERFACE:-127.0.0.1}:${SNIKKET_TWEAK_INTERNAL_HTTP_PORT:-5280}"

ADD ansible /opt/ansible

ADD snikket-modules /usr/local/lib/snikket-modules

# Required for idn2 to work, and probably generally good
ENV LANG=C.UTF-8

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        software-properties-common ca-certificates \
        gpg gpg-agent \
        ansible python3-passlib \
        libcap2-bin build-essential\
    && c_rehash \
    && ansible-playbook -c local -i localhost, --extra-vars "ansible_python_interpreter=/usr/bin/python3" /opt/ansible/snikket.yml \
    && apt-get remove --purge -y \
         ansible \
         software-properties-common \
         gpg gpg-agent \
         python3-passlib \
         libcap2-bin build-essential \
    && apt-get autoremove -y \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /var/cache/*

RUN echo "Snikket $BUILD_SERIES $BUILD_ID" > /usr/lib/prosody/snikket.version

VOLUME ["/snikket"]
