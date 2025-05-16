FROM perl:5.40.1-bookworm
WORKDIR /app

# Core OS setup.  Add a few bits that I often use for debugging

RUN apt-get update
RUN apt-get install -yV postgresql-client git vim build-essential \
	# KBAKER 20250516: temporarily add postfix to test SMTP errors in ShinyCMS
	libssl-dev dnsutils libxml2-dev zlib1g-dev libexpat-dev postfix

# Clean up

RUN apt-get clean
RUN rm -rf /var/lib/apt/lists/*

# Basic Perl dependencies needed to run makefile commands
# and other script not related to the application.  Do not
# add application dependencies here.  You add those to the
# cpanfile.

RUN cpanm --notest --reinstall App::cpanminus # Get lastest version

# Copy only the files needed for installing dependencies
# We do a two step process to avoid rebuilding the image
# when the application source code changes.

COPY cpanfile* .
RUN cpanm --version
RUN cpanm --installdeps --notest --with-feature=xml_support --with-feature=docker --with-feature=postgres .

# We ran the cpanm command above to install the dependencies
# first so that now its cached.  This way if we modify the
# Makefile (which is frequently) we don't have reload all of
# the dependencies.

COPY docker/Makefile .

# Copy the rest of the application source code

COPY . .

# Expose some environment variables
ARG POSTGRES_DB
ARG POSTGRES_USER
ARG POSTGRES_PASSWORD
ARG DB_PORT
ARG DB_HOST

ENV POSTGRES_DB=${POSTGRES_DB} POSTGRES_USER=${POSTGRES_USER} POSTGRES_PASSWORD=${POSTGRES_PASSWORD} DB_PORT=${DB_PORT} DB_HOST=${DB_HOST}

# Run the stack (starts web application)

CMD make -f docker/Makefile stack-start
