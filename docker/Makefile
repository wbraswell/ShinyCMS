#
# makefile to help find your way around
#

NAMESPACE := ShinyCMS
LC_NAMESPACE := $(shell echo $(NAMESPACE) | tr 'A-Z' 'a-z')
PID_FILE := /var/$(LC_NAMESPACE)_app_server.pid
STATUS_FILE := /var/$(LC_NAMESPACE)_app_server.status
PERL := perl -Ilib
PROVE := prove -lvr

# Base settings for the web server, these setting are fine for
# development but might need to be adjusted for production.

WEB_SERVER_PORT ?= 5000
export WEB_SERVER_PORT
WEB_SERVER_PORT_MAP ?= $(WEB_SERVER_PORT):$(WEB_SERVER_PORT)
export WEB_SERVER_PORT_MAP
SERVER_MAX_WORKERS ?= 3 # set low for development
SERVER_TIMEOUT ?= 900 # probably too high for production

# Create an environment variable that points to the host machine IP
# Works on my mac, might need to be adjusted for other systems. You
# might need this in docker-compose.yml for development or if there's
# services running on the host that need to be accessed from the container.

SHINYCMS_ENV ?= dev
export SHINYCMS_ENV

ENV_FILE ?= .env.$(SHINYCMS_ENV)
DOCKER = docker compose --env-file $(ENV_FILE) -f docker-compose.yml -f docker-compose.$(SHINYCMS_ENV).yml

.PHONY: help update-cpanlib update-db update-all dependencies \
        server-start server-stop server-restart stack-start stack-stop stack-restart \
        up stop restart build app-shell db-shell db-psql \
        app-update-all app-server-restart app-server-stop app-server-start app-prove db-demo \
				

help:
	@echo ""
	@echo "Available commands"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'
	@echo ""

#### Maintain the CPAN libraries and the database
#### NOTE: These really should be run inside the container via 'make app-*'

update-cpanlib: ## Install CPAN libs
	@echo "Installing CPAN libs..."
	cpanm --mirror http://cpan.cpantesters.org/ --mirror-only --notest  \
		--with-feature=postgres \
		--with-feature=xml_support \
		--with-feature=docker
	@echo "Done!"

update-all: update-cpanlib  ## Install CPAN libs 

init-db: ## Initialize the database
	@echo "Initializing the database..."
	@if psql -h $(DB_HOST) -p $(DB_PORT) -U $(POSTGRES_USER) -d $(POSTGRES_DB) -tAc "SELECT to_regclass('public.users')" | grep -q 'users'; then \
		echo "Users table exists. Skipping DB initialization."; \
	else \
		echo "Initializing the database..."; \
		$(PERL) -I lib bin/database/deploy-schema; \
		$(PERL) -I lib bin/database/data/insert-required-data; \
		echo "Done!"; \
	fi

install-demodb: ## Install Demo data
	@echo "Installing demo data..."

	@$(PERL) -I lib bin/database/data/insert-pages-demo-data
	@echo "Inserted demo data for: Pages"

	@$(PERL) -I lib bin/database/data/insert-shared-content-demo-data
	@echo "Inserted demo data for: Shared Content"

	@$(PERL) -I lib bin/database/data/insert-shop-demo-data
	@echo "Inserted demo data for: Shop"

	@$(PERL) -I lib bin/database/data/insert-newsletter-demo-data
	@echo "Inserted demo data for: Newsletter"

	@$(PERL) -I lib bin/database/data/insert-news-demo-data
	@echo "Inserted demo data for: News"

	@$(PERL) -I lib bin/database/data/insert-blog-demo-data
	@echo "Inserted demo data for: Blog"

	@$(PERL) -I lib bin/database/data/insert-forums-demo-data
	@echo "Inserted demo data for: Forums"

	@$(PERL) -I lib bin/database/data/insert-fileserver-demo-data
	@echo "Inserted demo data for: Fileserver"

	@$(PERL) -I lib bin/database/data/insert-events-demo-data
	@echo "Inserted demo data for: Events"

	@$(PERL) -I lib bin/database/data/insert-poll-demo-data
	@echo "Inserted demo data for: Polls"

	@echo "Done!"

#### Control the application server

server-start: ## Start the web application (current shell)
	@echo "Starting web application..."
	@start_server --port $(WEB_SERVER_PORT) --pid-file=$(PID_FILE) --status-file=$(STATUS_FILE) -- \
		$(PERL) \
			-I lib \
		  lib/$(NAMESPACE)/PSGI.pm run \
		    --server Starman \
				--max-workers $(SERVER_MAX_WORKERS) \
				--preload-app $(NAMESPACE) \
		    --timeout $(SERVER_TIMEOUT) \
		    --max-reqs-per-child 1000 \
		    --min-reqs-per-child 800
	@echo "Started."

server-stop: ## Stop the web application (current shell)
	@echo "Stopping web application..."
	@start_server --pid-file=$(PID_FILE) --status-file=$(STATUS_FILE) --stop
	@echo "Stopped."

server-restart: ## Restart the web application (current shell)
	@echo "Restarting web application..."
	@start_server --pid-file=$(PID_FILE) --status-file=$(STATUS_FILE) --restart
	@echo "Restarted."

#### Stack commands

debug-env: ## Show the current environment
	@echo "Environment:"
	@env | sort

stack-start: debug-env update-all init-db server-start ## Start the stack

stack-stop: server-stop ## Stop the stack

stack-restart: update-all server-restart ## Restart the stack

#### The rest of these run on the host machine and allow 
#### you to interact with the docker containers.  Its best
#### practice to limit what actually runs on the host and
#### instead run commands inside the containers.

#### Container build and control

start: up ## Alias for 'up'

down: stop ## Alias for 'stop'

up: prune ## Start the docker containers
	DOCKER_BUILDKIT=1 $(DOCKER) up -d --build --force-recreate 
	@echo "Started application. Visit http://localhost:$(WEB_SERVER_PORT)/"

stop: ## Stop the docker containers
	@$(DOCKER) stop

restart: stop up ## Restart the docker containers

build: prune ## Rebuild the docker image
	@echo "Building the docker image..."
	@DOCKER_BUILDKIT=0 $(DOCKER) build

prune:  ## Prune the docker system
	@echo "Pruning the docker system..."
	@docker system prune -f --volumes

#### Open shells and similar in the containers

app-shell: ## Open a shell in the app container
	@$(DOCKER) exec app_$(LC_NAMESPACE) bash

db-shell: ## Open a shell in the db container
	@$(DOCKER) exec db_$(LC_NAMESPACE) bash

# Open a psql shell in the container

db-psql: ## Open a psql shell in the db container
	@$(DOCKER) exec db_$(LC_NAMESPACE) psql -U $(LC_NAMESPACE)_dbuser agendum

#### Server control

app-update-all: ## Run 'make update-all' inside the app container
	@$(DOCKER) exec app_$(LC_NAMESPACE) make update-all

app-server-restart: ## Run 'make server-restart' inside the app container
	@echo "Issue server restart into app_$(LC_NAMESPACE)..."
	@$(DOCKER) exec app_$(LC_NAMESPACE) make server-restart

app-server-stop: ## Run 'make server-stop' inside the app container
	@$(DOCKER) exec app_$(LC_NAMESPACE) make server-stop

app-server-start: ## Run 'make server-start' inside the app container
	@$(DOCKER) exec app_$(LC_NAMESPACE) make server-start

#### Testing

app-install-demodb: ## Run 'make db-demo' inside the app container
	@$(DOCKER) exec app_$(LC_NAMESPACE) make -f docker/Makefile install-demodb

prove: ## Run 'prove' inside the app container
	$(DOCKER) exec app_$(LC_NAMESPACE) $(PROVE) $(filter-out prove,$(MAKECMDGOALS))
