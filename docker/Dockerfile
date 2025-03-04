# base Docker on main Perl Docker image
# https://github.com/Perl/docker-perl/tree/master/5.040.001-main-bookworm
FROM perl:5.40.1-bookworm
MAINTAINER William N. Braswell, Jr. <william.braswell@autoparallel.com>


# set some general config stuff

ENV APP_NAME=ShinyCMS  \
	APP_PORT=6174       \
	APP_USER=shinycms    \
	APP_DIR=/opt/shinycms \
	SHINYCMS_CONFIG=/opt/shinycms/config/shinycms.conf


# install required Debian packages

RUN apt update \
\
	&& apt install -y     \
		cpanminus             \
		gcc                   \
		libexpat-dev          `# Required by XML::Parser for XML::Feed` \
		libmysqlclient-dev    `# Required by DBD::mysql`                \
		libpq-dev             `# Required by DBD::Pg`                   \
		libxml2-dev           `# Required by XML::LibXML for XML::Feed` \
		make                  \
		zlib1g-dev            `# Required by XML::LibXML for XML::Feed` \
\
	&& apt clean \
\
	&& rm -rf /var/cache/apt/archives/*


# install required CPAN modules

# WBRASWELL 20250304: NEED DELETE? are Module::Install::Catalyst & Module::Build permanently removed???
#RUN cpanm --quiet --notest --no-man-pages Module::Install::Catalyst Module::Build DBD::mysql \
RUN cpanm --quiet --notest --no-man-pages DBD::mysql \
\
    # install ShinyCMS manual dependencies from cpanfile
	&& cpanm --quiet --notest --no-man-pages --installdeps . \
\
	&& rm -rf /root/.cpan /root/.cpanm


# copy the webapp files into place and make sure our webapp user owns them

RUN mkdir $APP_DIR

COPY . $APP_DIR

RUN groupadd -r $APP_USER && useradd -r -g $APP_USER $APP_USER

RUN chown -R $APP_USER.$APP_USER $APP_DIR


# WBRASWELL 20250304: all database creation & initialization commands below were copied from the old now-deprecated install.sh
# create database and database user
RUN sudo mysql -uroot -e 'create database if not exists shinycms character set utf8 collate utf8_general_ci'
RUN sudo mysql -uroot -e "create user if not exists 'shinyuser'@'localhost' identified by 'shinypass'"
RUN sudo mysql -uroot -e "grant all privileges on shinycms.* to 'shinyuser'@'localhost'"

# insert initialization data into database
# WBRASWELL 20250304: NEED FIX, how to handle following logic copied from old now-deprecated install.sh???
#if [ "$SHINYCMS_DEMO" != '' ]; then
    # set database up for demo site
    RUN ./bin/database/build-with-demo-data
#else
    # set database up for new (empty) site
#    RUN ./bin/database/build
#fi


# run ShinyCMS web application

EXPOSE $APP_PORT

WORKDIR $APP_DIR

USER $APP_USER

CMD script/shinycms_server.pl --port 6174

