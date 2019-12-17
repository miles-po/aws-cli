FROM alpine

RUN adduser -D awscli && \
    apk update && \
    apk add jq py3-pip groff sudo && \
    pip3 install --upgrade pip && \
    pip install --upgrade awscli

ENTRYPOINT ["/bin/sh", "-c"]

CMD ["aws --version"]
