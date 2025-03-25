# base Docker on main Perl Docker image
# https://github.com/Perl/docker-perl/tree/master/5.040.001-main-bookworm

# KAI 20250325: Due to the inability to install DBD:mysql from cpan, using the debian package libdbd-mysql-perl
# introduced binary incompatiblities between the perl libraries. Therefore, attempting a pure debian install.
FROM perl:5.40.1-bookworm
# FROM perl:5.36-bookworm
# FROM debian:bookworm
MAINTAINER William N. Braswell, Jr. <william.braswell@autoparallel.com>

# KBAKER 20250325: ShinyCMS's environment variables are defined in docker-compose.yml,
# and are imported to this Dockerfile below for use during the docker build process
# as automatically initiated by the command `docker compose up`
ARG APP_DIR
ARG APP_USER
ARG APP_PORT
ARG APP_NAME
ARG SHINYCMS_CONFIG
# install required Debian packages

RUN apt update \
\
	&& apt install -y     \
		cpanminus             \
		gcc                   \
		libexpat-dev          `# Required by XML::Parser for XML::Feed` \
		# KBAKER 20250324: repository name was changed to default-*
		# libmysqlclient-dev    `# Required by DBD::mysql`                \
		default-libmysqlclient-dev \
		libpq-dev             `# Required by DBD::Pg`                   \
		libxml2-dev           `# Required by XML::LibXML for XML::Feed` \
		make                  \
		zlib1g-dev            `# Required by XML::LibXML for XML::Feed` \
		# KBAKER 20250318: Added additional installs for mariadb
		mariadb-common mariadb-server mariadb-client libmariadb-dev \
\
	&& apt clean \
\
	&& rm -rf /var/cache/apt/archives/*

# install required CPAN modules

# WBRASWELL 20250304: NEED DELETE? are Module::Install::Catalyst & Module::Build permanently removed???
#RUN cpanm --quiet --notest --no-man-pages Module::Install::Catalyst Module::Build DBD::mysql \
# RUN cpanm --quiet --notest --no-man-pages DBD::mysql \
# \
    # install ShinyCMS manual dependencies from cpanfile
	# && cpanm --quiet --notest --no-man-pages --installdeps . \
# \
	# && rm -rf /root/.cpan /root/.cpanm

# ----------
# KBAKER 20250318 -- perl modules ShinyCMS needs installed
COPY cpanfile* .
RUN cat cpanfile

# KBAKER 20250325: Checking perl versions to verify the same perl is used in the docker image
RUN perl -V
#9 1.094 This is perl 5, version 40, subversion 1 (v5.40.1) built for x86_64-linux-gnu
RUN which perl
#10 [app_shinycms  6/23] RUN which perl
#10 1.447 /usr/local/bin/perl

RUN cpanm --verbose --notest --no-man-pages --installdeps .
RUN cpanm --quiet --notest --force --no-man-pages XML::Feed
RUN cpanm --quiet --notest --force --no-man-pages Net::Akismet
RUN cpanm --quiet --notest --no-man-pages XML::LibXML
# KBAKER 20250324: Package was reported not found when building, so added to the list of installs
RUN cpanm --quiet --notest --no-man-pages Sub::Identify
RUN cpanm --quiet --notest --no-man-pages Catalyst::Plugin::Session::Store::DBIC
# KBAKER 20250325: Next steps, try configuring Catalyst to use DBD::MaridaDB instead of DBD::mysql
RUN cpanm --quiet --notest --no-man-pages DBD::MariaDB
# KBAKER 20250325: Installing Catalyst's Schema used to switch different databases
RUN cpanm --quiet --notest --no-man-pages Catalyst::Model::DBIC::Schema


# copy the webapp files into place and make sure our webapp user owns them
RUN mkdir $APP_DIR

COPY . $APP_DIR

RUN groupadd -r $APP_USER && useradd -r -g $APP_USER $APP_USER

# KBAKER 20250318: changed the dot between APP_USER's to a colon, ':'
RUN chown -R $APP_USER:$APP_USER $APP_DIR

# KBAKER 20250324: Ensure MariaDB directories exist and have correct permissions
RUN mkdir -p /var/run/mysqld && \
    chown -R mysql:mysql /var/run/mysqld && \
    chmod 777 /var/run/mysqld

# KBAKER 20250325: Will attempt to run the shinycms create script with the parameters to change databases
# COPY ./script/shinycms_create.pl .
# RUN chmod +x shinycms_create.pl && \
# 	shinycms_create.pl model MariaDB DBIC::Schema PerlJobs::Schema create=static

# WBRASWELL 20250304: all database creation & initialization commands below were copied from the old now-deprecated install.sh
# create database and database user
# RUN sudo mysql -uroot -e 'create database if not exists shinycms character set utf8 collate utf8_general_ci'
# RUN sudo mysql -uroot -e "create user if not exists 'shinyuser'@'localhost' identified by 'shinypass'"
# RUN sudo mysql -uroot -e "grant all privileges on shinycms.* to 'shinyuser'@'localhost'"

# KBAKER 20250324: copying 
COPY ./bin/database/build-with-demo-data .

# KBAKER 20250318: Removing sudo from commands and chained them together. Otherwise, the commands are on separate layers
RUN service mariadb start && \
    # Wait a moment for MariaDB to fully initialize
    sleep 3 && \
    # Create database and user
    mariadb -uroot -e 'create database if not exists shinycms character set utf8 collate utf8_general_ci' && \
    mariadb -uroot -e "create user if not exists 'shinyuser'@'localhost' identified by 'shinypass'" && \
    mariadb -uroot -e "grant all privileges on shinycms.* to 'shinyuser'@'localhost'" && \
    cd $APP_DIR && \
    ./bin/database/build-with-demo-data

	# insert initialization data into database
# WBRASWELL 20250304: NEED FIX, how to handle following logic copied from old now-deprecated install.sh???
#if [ "$SHINYCMS_DEMO" != '' ]; then
    # set database up for demo site
    # RUN ./bin/database/build-with-demo-data
#else
    # set database up for new (empty) site
#    RUN ./bin/database/build
#fi

# KBAKER: 20250324: Create startup script for runtime
RUN echo '#!/bin/bash\n\
#export PERL5LIB="$PERL5LIB:/usr/share/perl5:/usr/lib/x86_64-linux-gnu/perl5"\n\
echo "Starting MariaDB service..."\n\
service mariadb start\n\
status=$?\n\
if [ $status -ne 0 ]; then\n\
    echo "Failed to start MariaDB: $status"\n\
    exit $status\n\
fi\n\
echo "MariaDB service started successfully"\n\
\n\
# Give some time for MariaDB to initialize\n\
sleep 2\n\
\n\
# Start ShinyCMS\n\
echo "Starting ShinyCMS on port $APP_PORT"\n\
#/usr/local/bin/perl
which perl\n\
perl -V\n\
cd $APP_DIR\n\
exec script/shinycms_server.pl --port $APP_PORT\n\
' > /start.sh && \
    chmod +x /start.sh

# run ShinyCMS web application

EXPOSE $APP_PORT

WORKDIR $APP_DIR

# KBAKER: 20250324: Run the custom startup script when container starts
# This script will start both MariaDB and ShinyCMS
CMD ["/start.sh"]

# USER $APP_USER

# CMD script/shinycms_server.pl --port 6174

