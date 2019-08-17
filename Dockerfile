FROM maven:3.6-ibmjava-8-alpine AS builder
  WORKDIR /tmp
  RUN apk update && apk add git
  RUN git clone https://github.com/j-white/activemq-k8s-discovery.git
  RUN cd activemq-k8s-discovery && mvn clean package

FROM ibmjava:8-jre-alpine
  ARG RUNTIME_UID=1000
  ARG RUNTIME_GID=1000
  ARG RUNTIME_USR=activemq
  ARG RUNTIME_GRP=activemq
  ARG RUNTIME_HOME=/home/activemq
  ARG RUNTIME_SHELL=/bin/bash
  ENV ACTIVEMQ_HOME /opt/activemq
  ENV RUNTIME_UID $RUNTIME_UID
  ENV RUNTIME_GID $RUNTIME_GID
  ENV RUNTIME_USR $RUNTIME_USR
  ENV RUNTIME_GRP $RUNTIME_GRP
  ENV RUNTIME_HOME $RUNTIME_HOME
  ENV RUNTIME_SHELL $RUNTIME_SHELL

  USER root
  COPY bin/docker-entrypoint /usr/local/bin/docker-entrypoint
  RUN mkdir -p $RUNTIME_HOME
  RUN chown $RUNTIME_UID:$RUNTIME_GID $RUNTIME_HOME
  RUN addgroup -g $RUNTIME_GID -S $RUNTIME_GRP
  RUN adduser -h $RUNTIME_HOME -u $RUNTIME_UID -G $RUNTIME_GRP\
    -H -D -s /bin/ash $RUNTIME_USR
  RUN apk update && apk add wget
  RUN mkdir -p $ACTIVEMQ_HOME
  RUN chown $RUNTIME_USR:$RUNTIME_GRP $ACTIVEMQ_HOME
  RUN chmod +x /usr/local/bin/docker-entrypoint

  USER activemq
  WORKDIR /tmp
  RUN wget http://apache.hippo.nl//activemq/5.15.9/apache-activemq-5.15.9-bin.tar.gz 2>/dev/null
  RUN tar zxvf apache-activemq*.tar.gz -C .
  RUN cp -R apache-activemq*/* $ACTIVEMQ_HOME
  RUN rm -rf /tmp/*
  COPY --from=builder /tmp/activemq-k8s-discovery/target/activemq-k8s-discovery-1.0.2-jar-with-dependencies.jar\
    $ACTIVEMQ_HOME/lib/

  WORKDIR $ACTIVEMQ_HOME

ENTRYPOINT ["/usr/local/bin/docker-entrypoint"]
CMD ["/opt/activemq/bin/activemq", "console"]
