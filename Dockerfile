FROM node:6-alpine
ENV LANG C.UTF-8
# install java (for closure compiler)
RUN { \
		echo '#!/bin/sh'; \
		echo 'set -e'; \
		echo; \
		echo 'dirname "$(dirname "$(readlink -f "$(which javac || which java)")")"'; \
	} > /usr/local/bin/docker-java-home \
	&& chmod +x /usr/local/bin/docker-java-home
ENV JAVA_HOME /usr/lib/jvm/java-1.8-openjdk/jre
ENV PATH $PATH:/usr/lib/jvm/java-1.8-openjdk/jre/bin:/usr/lib/jvm/java-1.8-openjdk/bin
ENV JAVA_VERSION 8u111
ENV JAVA_ALPINE_VERSION 8.111.14-r0
RUN set -x \
	&& apk add --no-cache \
		openjdk8-jre="$JAVA_ALPINE_VERSION" \
	&& [ "$JAVA_HOME" = "$(docker-java-home)" ]
# install for node-gyp
RUN apk add --no-cache make gcc g++ python git
# install global command
RUN npm install -g bower gulp gulp-cli
ADD ./santa-tracker /var/santa
WORKDIR /var/santa
# install dependencies
RUN bower install --allow-root \
	&& npm install
# patch bugs
RUN ln -s /var/santa/components/closure-compiler/closure-compiler-v20161201.jar /var/santa/components/closure-compiler/compiler.jar
RUN rm /var/santa/third_party/externs/web-animations-old.js \
	&& sed -i -e s/iron-icons/iron-icon/g  /var/santa/scenes/tracker/city-feed/city-feed.html
# build santa
ARG baseurl
RUN gulp dist --baseurl="$baseurl" --pretty && mkdir -p /usr/share/nginx/html && cp -R ./dist_pretty/* /usr/share/nginx/html/
VOLUME /usr/share/nginx/html

