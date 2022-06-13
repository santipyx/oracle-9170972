#!/bin/bash

#
# Setting extra environment variables
#
if [ -r ~/setenv.sh ]; then
  source ~/setenv.sh
fi

#
# Adding debug support
#
if [ "$DEBUG_ENABLED" = "true" ]; then
  export JAVA_OPTS="-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=*:5005 $JAVA_OPTS"
fi

#
# Adding java.security.egd
#
export JAVA_OPTS="$JAVA_OPTS -Djava.security.egd=file:/dev/./urandom"

#
# Coping extra init libraries into Spring Boot libraries structure and register
#  them as part of the custom-extensions layer
#
for LIB_PATH in `find $HOME/init/lib -maxdepth 1 -name '*.jar'`; do
  cp $LIB_PATH $HOME/BOOT-INF/lib
  LIB=`basename $LIB_PATH`
  echo "  - \"BOOT-INF/lib/$LIB\"" >> $HOME/BOOT-INF/layers.idx
  echo "- \"BOOT-INF/lib/$LIB\"" >> $HOME/BOOT-INF/classpath.idx
done

java $JAVA_OPTS org.springframework.boot.loader.JarLauncher