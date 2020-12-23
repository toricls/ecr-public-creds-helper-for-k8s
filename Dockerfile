FROM amazon/aws-cli:2.1.12

RUN curl -o kubectl https://amazon-eks.s3.us-west-2.amazonaws.com/1.18.9/2020-11-02/bin/linux/amd64/kubectl \
    && chmod +x kubectl \
    && mv kubectl /usr/local/bin/kubectl

COPY entrypoint.sh /

ENTRYPOINT ["/entrypoint.sh"]
