# base Docker on main Perl Docker image
# https://github.com/Perl/docker-perl/tree/master/5.040.001-main-bookworm
FROM perl:5.40.1-bookworm
MAINTAINER William N. Braswell, Jr. <william.braswell@autoparallel.com>


# Set some general config stuff

ENV APP_NAME=ShinyCMS  \
	APP_PORT=6174       \
	APP_USER=shinycms    \
	APP_DIR=/opt/shinycms \
	SHINYCMS_CONFIG=/opt/shinycms/config/shinycms.conf


# Install required Debian packages

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


# Install required CPAN modules

RUN cpanm --quiet --notest --no-man-pages Module::Install::Catalyst Module::Build DBD::mysql \
#\
#    && cpanm Net::Akismet module --sudo --force  # NEED DELETE, OLD POSSIBLY-INCORRECT COMMANDS
#    && cpanm Net::Akismet --force  # NEED CHECK IF ACTUALLY REQUIRED???
\
	&& cpanm --quiet --notest --no-man-pages --installdeps . \
\
	&& rm -rf /root/.cpan /root/.cpanm


# Copy the webapp files into place and make sure our webapp user owns them

RUN mkdir $APP_DIR

COPY . $APP_DIR

RUN groupadd -r $APP_USER && useradd -r -g $APP_USER $APP_USER

RUN chown -R $APP_USER.$APP_USER $APP_DIR


# Run the webapp!

EXPOSE $APP_PORT

WORKDIR $APP_DIR

USER $APP_USER

CMD script/shinycms_server.pl --port 6174

