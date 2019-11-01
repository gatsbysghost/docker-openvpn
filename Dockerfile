# Original credit: https://github.com/jpetazzo/dockvpn
# Forked from: https://github.com/kylemanna/docker-openvpn

# Smallest base image
FROM alpine:latest

LABEL maintainer="Scott Reu <scott@reu.dev>"

# Testing: pamtester
RUN echo "http://dl-cdn.alpinelinux.org/alpine/edge/testing/" >> /etc/apk/repositories && \
    apk add --update openvpn iptables bash easy-rsa openvpn-auth-pam google-authenticator pamtester && \
    ln -s /usr/share/easy-rsa/easyrsa /usr/local/bin && \
    rm -rf /tmp/* /var/tmp/* /var/cache/apk/* /var/cache/distfiles/*

# Needed by scripts
ENV OPENVPN /etc/openvpn
ENV EASYRSA /usr/share/easy-rsa
ENV EASYRSA_PKI $OPENVPN/pki
ENV EASYRSA_VARS_FILE $OPENVPN/vars

# Prevents refused client connection because of an expired CRL
ENV EASYRSA_CRL_DAYS 3650

VOLUME ["/etc/openvpn"]

# Internally uses port 1194/udp, remap using `docker run -p 443:1194/tcp`
EXPOSE 1194/udp

ADD ./bin /usr/local/bin
RUN chmod a+x /usr/local/bin/*

# Add support for OTP authentication using a PAM module
ADD ./otp/openvpn /etc/pam.d/

# OKTA INTEGRATION (New Stuff Starts Here)
RUN apk add --update gcc make libc-dev python py-pip git python-dev libffi-dev openssl-dev

cd ~
RUN git clone https://github.com/gatsbysghost/okta-openvpn.git
cd ~/okta-openvpn
RUN make
RUN pip install -r requirements.txt
RUN make install

# Have to move this to here so that the server.conf lines pointing to the okta integration stuff can be interpreted
cd /etc/openvpn
CMD ["ovpn_run"]
