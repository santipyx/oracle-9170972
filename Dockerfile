FROM maven:3.8.5-jdk-11 as build

WORKDIR /build

COPY . ./

RUN mvn clean package

RUN java -Djarmode=layertools -jar /build/target/spring-boot-hello-1.0.jar extract

RUN mkdir -p custom-extensions/BOOT-INF/lib
RUN echo "- \"custom-extensions\":" >> application/BOOT-INF/layers.idx

RUN mvn dependency:copy-dependencies -DoutputDirectory=./custom-extensions/BOOT-INF/lib

RUN for lib_path in `find custom-extensions/BOOT-INF/lib -maxdepth 1 -name '*.jar'`; do \
        lib=`basename $lib_path`; \
        echo "  - \"BOOT-INF/lib/$lib\"" >> application/BOOT-INF/layers.idx; \
        echo "- \"BOOT-INF/lib/$lib\"" >> application/BOOT-INF/classpath.idx; \
    done

RUN wget -q -c -O ecs-logging-core-1.4.0.jar https://repo1.maven.org/maven2/co/elastic/logging/ecs-logging-core/1.4.0/ecs-logging-core-1.4.0.jar && \
    echo "6d4d3ae7486049e63138660ac5e93cf8c66bec36  ecs-logging-core-1.4.0.jar" | sha1sum -c

RUN wget -q -O logback-ecs-encoder-1.4.0.jar https://repo1.maven.org/maven2/co/elastic/logging/logback-ecs-encoder/1.4.0/logback-ecs-encoder-1.4.0.jar && \
    echo "6447ae000560f0dc9bfc4259aa6a6f8abce0461b  logback-ecs-encoder-1.4.0.jar" | sha1sum -c

#
# Downloads bridge tracing required libraries
#

RUN wget -q -O opentracing-util-0.33.0.jar https://repo1.maven.org/maven2/io/opentracing/opentracing-util/0.33.0/opentracing-util-0.33.0.jar && \
    echo "132630f17e198a1748f23ce33597efdf4a807fb9  opentracing-util-0.33.0.jar" | sha1sum -c

RUN wget -q -O opentracing-api-0.33.0.jar https://repo1.maven.org/maven2/io/opentracing/opentracing-api/0.33.0/opentracing-api-0.33.0.jar && \
    echo "67336cfb9d93779c02e1fda4c87801d352720eda  opentracing-api-0.33.0.jar" | sha1sum -c

RUN wget -q -O opentracing-noop-0.33.0.jar https://repo1.maven.org/maven2/io/opentracing/opentracing-noop/0.33.0/opentracing-noop-0.33.0.jar && \
    echo "074b9950a587f53fbdb48c3f1f84f1ece8c10592  opentracing-noop-0.33.0.jar" | sha1sum -c

RUN wget -q -O apm-opentracing-1.31.0.jar https://repo1.maven.org/maven2/co/elastic/apm/apm-opentracing/1.31.0/apm-opentracing-1.31.0.jar && \
    echo "430448a0935e338b5a2e11fbd7dcba4d416a57db  apm-opentracing-1.31.0.jar" | sha1sum -c

#
# Downloads APM requiered library
#

RUN wget -q -O elastic-apm-agent.jar https://repo1.maven.org/maven2/co/elastic/apm/elastic-apm-agent/1.31.0/elastic-apm-agent-1.31.0.jar && \
    echo "9c9bd01e5bba4b210d076555f146a1147df176d3  elastic-apm-agent.jar"| sha1sum -c


FROM openjdk:11.0.15-slim

ENV TESTING_HOME=/home/testing

RUN groupadd -r testing && \
    useradd -g testing -d $TESTING_HOME -s /sbin/nologin -c "Testing user" testing && \
    mkdir -p $TESTING_HOME/init/lib && \
    mkdir -p $TESTING_HOME/init/extras && \
    chown -R testing:testing $TESTING_HOME

USER testing

WORKDIR $TESTING_HOME

COPY --from=build --chown=testing /build/ecs-logging-core-1.4.0.jar /home/testing/init/lib
COPY --from=build --chown=testing /build/logback-ecs-encoder-1.4.0.jar /home/testing/init/lib
COPY --from=build --chown=testing /build/opentracing-util-0.33.0.jar /home/testing/init/lib
COPY --from=build --chown=testing /build/opentracing-api-0.33.0.jar /home/testing/init/lib
COPY --from=build --chown=testing /build/opentracing-noop-0.33.0.jar /home/testing/init/lib
COPY --from=build --chown=testing /build/apm-opentracing-1.31.0.jar /home/testing/init/lib 
COPY --from=build --chown=testing /build/elastic-apm-agent.jar /home/testing/init/extras

COPY --from=build --chown=testing /build/setenv.sh ./

COPY --from=build --chown=testing /build/start.sh ./

COPY --from=build --chown=testing /build/dependencies/ ./

COPY --from=build --chown=testing /build/spring-boot-loader ./

COPY --from=build --chown=testing /build/snapshot-dependencies/ ./

RUN true

COPY --from=build --chown=testing /build/application/ ./

COPY --from=build --chown=testing /build/custom-extensions/ ./

ENTRYPOINT ["/bin/bash", "-e", "start.sh"]