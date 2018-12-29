SELF_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
PHP_SERVICE := docker-compose exec webapp sh -c

# Define a static project name that will be prepended to each service name
export COMPOSE_PROJECT_NAME := symfony

# Create configuration files needed by the environment
SETUP_ENV := $(shell (test -f $(SELF_DIR).env || cp $(SELF_DIR).env.dist $(SELF_DIR).env))

# Extract environment variables needed by the environment
export DB_DIR := $(shell grep DB_DIR $(SELF_DIR).env | awk -F '=' '{print $$NF}')


##
## ----------------------------------------------------------------------------
##   Environment
## ----------------------------------------------------------------------------
##

backup: ## Backup the "db" volume
	docker run --rm \
		--volumes-from $$(docker-compose ps -q db) \
		-v $(dir $(SELF_DIR))backup:/backup \
		busybox sh -c "tar cvf /backup/backup.db.tar $(DB_DIR)"

build: ## Build the environment
	docker-compose build

cache: ## Flush the Symfony cache
	$(PHP_SERVICE) "bin/console cache:clear"

logs: ## Follow logs generated by all containers + 10 most recent entries.
	docker-compose logs -f --tail=10

logs-full: ## Follow logs generated by all containers + 50 most recent entries.
	docker-compose logs -f --tail=50

nginx: ## Open a terminal in the "nginx" container
	docker-compose exec nginx sh

app: ## Open a terminal in the "app" container
	docker-compose exec app sh

db: ## Open a terminal in the "db" container
	docker-compose exec db sh

redis: ## Open a terminal in the "redis" container
	docker-compose exec redis sh

rabbit: ## Open a terminal in the "rabbitmq" container
	docker-compose exec rabbitmq sh

elk: ## Open a terminal in the "elk" container
	docker-compose exec elk sh

ps: ## List all containers managed by the environment
	docker-compose ps

restore: ## Restore the "db" volume
	docker run --rm \
		--volumes-from $$(docker-compose ps -q db) \
		-v $(dir $(SELF_DIR))backup:/backup \
		busybox sh -c "tar xvf /backup/backup.db.tar /var/lib/mysql"
	docker-compose restart db

start: ## Start the environment
	docker-compose build
	docker-compose up -d --remove-orphans

stats: ## Print real-time statistics about containers ressources usage
	docker stats $(docker ps --format={{.Names}})

stop: ## Stop the environment
	docker-compose stop

.PHONY: backup build cache composer logs logs-full nginx web db redis rabbit elk ps restore start stats stop

.DEFAULT_GOAL := help
help:
	@grep -E '(^[a-zA-Z_-]+:.*?##.*$$)|(^##)' $(MAKEFILE_LIST) \
		| sed -e 's/^.*Makefile://g' \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "\033[32m%-30s\033[0m %s\n", $$1, $$2}' \
		| sed -e 's/\[32m##/[33m/'
.PHONY: help