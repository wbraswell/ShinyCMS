# base Docker on main Perl Docker image
# https://github.com/Perl/docker-perl/tree/master/5.040.001-main-bookworm

# KAI 20250325: Due to the inability to install DBD:mysql from cpan, using the debian package libdbd-mysql-perl
# introduced binary incompatiblities between the perl libraries. Therefore, attempting a pure debian install.
FROM perl:5.40.1-bookworm
# FROM perl:5.36-bookworm
# FROM debian:bookworm
MAINTAINER William N. Braswell, Jr. <william.braswell@autoparallel.com>

# WBRASWELL 20250311: moved all environmental variables from Dockerfile to docker-compose.yml

# KAI 20250318: Apparently, the build and runtime environments are separate and
# the build needs the environment variables provided.
# Hardcoded environment variables
# ENV APP_DIR=/opt/shinycms
# ENV APP_USER=shinycms
# ENV APP_PORT=6174
# ENV APP_NAME=ShinyCMS
# ENV SHINYCMS_CONFIG=/opt/shinycms/config/shinycms.conf
# ENV PERL5LIB=/usr/lib/x86_64-linux-gnu/perl5/5.36:$PERL5LIB

# install required Debian packages

RUN apt update \
\
	&& apt install -y     \
		cpanminus             \
		gcc                   \
		libexpat-dev          `# Required by XML::Parser for XML::Feed` \
		# KAI 20250324: repository name was changed to default-*
		# libmysqlclient-dev    `# Required by DBD::mysql`                \
		default-libmysqlclient-dev \
		libpq-dev             `# Required by DBD::Pg`                   \
		libxml2-dev           `# Required by XML::LibXML for XML::Feed` \
		make                  \
		zlib1g-dev            `# Required by XML::LibXML for XML::Feed` \
		# KAI 20250318: Added additional installs for mariadb
		mariadb-common mariadb-server mariadb-client libmariadb-dev \
		# Kai 20250318: A drop-in debian package replacement for the DBD::mysql perl module 
		# libdbd-mysql-perl \
		# libdbi-perl \
		# KAI 20250325: Installing perl and needed dependencies since this build won't be using a perl-debian base
		# perl \
		# perl-modules \
		# libssl-dev \
		# zlib1g-dev \
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
# Kai -- perl modules ShinyCMS needs installed
COPY cpanfile* .
RUN cat cpanfile
# starting with this line, getting an error

RUN cpanm --verbose --notest --no-man-pages --installdeps .
RUN cpanm --quiet --notest --force --no-man-pages XML::Feed
RUN cpanm --quiet --notest --force --no-man-pages Net::Akismet
RUN cpanm --quiet --notest --no-man-pages XML::LibXML
# KAI 20250324: Package was reported not found when building, so added to the list of installs
RUN cpanm --quiet --notest --no-man-pages Sub::Identify
RUN cpanm --quiet --notest --no-man-pages Catalyst::Plugin::Session::Store::DBIC
# KAI 20250325: Let's try using DBD::MaridaDB instead of DBD::mysql and see if ShinyCMS accepts it
RUN cpanm --quiet --notest --no-man-pages DBD::MariaDB
# RUN cpanm --quiet --notest --no-man-pages DBD::mysql@4.053
RUN cpanm --quiet --notest --no-man-pages Catalyst::Model::DBIC::Schema

# KAI 20250325: Added the perl5/5.36 directory so perl environment variable @INC was able to find where DBD:mysql was installed by apt
# ENV PERL5LIB=/usr/lib/x86_64-linux-gnu/perl5/5.36:$PERL5LIB
# RUN DBD_PATH=$(dpkg -L libdbd-mysql-perl | grep -m 1 '/perl5/5.36') && \
# 	echo "DBD modules located at: $DBD_PATH" && \
# 	echo "export PERL5LIB=\$PERL5LIB:/usr/share/perl5:/usr/lib/x86_64-linux-gnu/perl5:$DBD_PATH" >> ./perl_export.sh && \
#     chmod +x ./perl_export.sh && \
# 	export PERL5LIB="$PERL5LIB:/usr/share/perl5:/usr/lib/x86_64-linux-gnu/perl5:$DBD_PATH"
# ---------
# copy the webapp files into place and make sure our webapp user owns them

RUN mkdir $APP_DIR

COPY . $APP_DIR

RUN groupadd -r $APP_USER && useradd -r -g $APP_USER $APP_USER

# KAI 20250318: changed the dot between APP_USER's to a colon, ':'
RUN chown -R $APP_USER:$APP_USER $APP_DIR

# KAI 20250324: Ensure MariaDB directories exist and have correct permissions
RUN mkdir -p /var/run/mysqld && \
    chown -R mysql:mysql /var/run/mysqld && \
    chmod 777 /var/run/mysqld

# COPY ./script/shinycms_create.pl .
# RUN chmod +x shinycms_create.pl && \
# 	shinycms_create.pl model MariaDB DBIC::Schema PerlJobs::Schema create=static

# WBRASWELL 20250304: all database creation & initialization commands below were copied from the old now-deprecated install.sh
# create database and database user
# RUN sudo mysql -uroot -e 'create database if not exists shinycms character set utf8 collate utf8_general_ci'
# RUN sudo mysql -uroot -e "create user if not exists 'shinyuser'@'localhost' identified by 'shinypass'"
# RUN sudo mysql -uroot -e "grant all privileges on shinycms.* to 'shinyuser'@'localhost'"

# KAI 20250324: copying 
COPY ./bin/database/build-with-demo-data .

# KAI 20250318: Removing sudo from commands and linking them together
RUN service mariadb start && \
    # Wait a moment for MariaDB to fully initialize
    sleep 3 && \
    # Create database and user
    mariadb -uroot -e 'create database if not exists shinycms character set utf8 collate utf8_general_ci' && \
    mariadb -uroot -e "create user if not exists 'shinyuser'@'localhost' identified by 'shinypass'" && \
    mariadb -uroot -e "grant all privileges on shinycms.* to 'shinyuser'@'localhost'" && \
    # Initialize the database with demo data
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

# KAI: 20250324: Create startup script for runtime
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
cd $APP_DIR\n\
exec script/shinycms_server.pl --port $APP_PORT\n\
' > /start.sh && \
    chmod +x /start.sh

# run ShinyCMS web application

EXPOSE $APP_PORT

WORKDIR $APP_DIR

# KAI: 20250324: Run the custom startup script when container starts
# This script will start both MariaDB and ShinyCMS
CMD ["/start.sh"]

# USER $APP_USER

# CMD script/shinycms_server.pl --port 6174

