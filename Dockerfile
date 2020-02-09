FROM minio/mc:RELEASE.2019-07-09T23-57-06Z
RUN apk --no-cache add jq

ADD assets /opt/resource
RUN chmod +x /opt/resource/*
WORKDIR /

ENTRYPOINT ["/bin/sh"]
