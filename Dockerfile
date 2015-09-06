FROM nginx
MAINTAINER Markus Mayer <awesome@wundercart.de>

ENV APP_BASE /var/www
ENV APP_BRANCH master
ENV DEBIAN_VERSION jessie
ENV HHVM_VERSION 3.9.1~$DEBIAN_VERSION

# Install HHVM
RUN apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0x5a16e7281be7a449 && \
   echo deb http://dl.hhvm.com/debian $DEBIAN_VERSION main | tee /etc/apt/sources.list.d/hhvm.list && \
   apt-get update && \
   apt-get install -y --no-install-recommends hhvm=$HHVM_VERSION

# Install git and the database connectors
RUN apt-get install -y --no-install-recommends git \
                                               php5-mysql php5-sqlite

# Clone the project
RUN rm -rf $APP_BASE && \
    git clone --depth 1 --single-branch -b $APP_BRANCH https://github.com/Daniel15/simple-nuget-server.git $APP_BASE && \
    rm -rf $APP_BASE/.git && \
    chown www-data:www-data $APP_BASE/db $APP_BASE/packagefiles && \
    chown 0770 $APP_BASE/db $APP_BASE/packagefiles

# Install supervisord
RUN apt-get install -y --no-install-recommends supervisor
COPY conf/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Activate the nginx configuration
RUN rm /etc/nginx/conf.d/default*.conf
COPY conf/nuget.conf /etc/nginx/conf.d/ 

# Set randomly generated API key
RUN echo $(date +%s | sha256sum | base64 | head -c 32; echo) > $APP_BASE/.api-key && \
    echo "Auto-Generated NuGet API key: $(cat $APP_BASE/.api-key)" && \
    sed -i $APP_BASE/inc/config.php -e "s/ChangeThisKey/$(cat $APP_BASE/.api-key)/"

# Add the scripts
COPY scripts/* /tmp/
RUN chmod +x /tmp/*.sh

# Start HHVM
CMD ["supervisord", "-n"]