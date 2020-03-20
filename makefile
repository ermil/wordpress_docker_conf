IMAGES := mysql wordpress
BACKUP_DIR := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))/../backup
# get the current directory name (without path)
PROJECT_NAME := $(lastword  $(subst /, , $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))))
# PROJECT_NAME := $(shell echo $${PWD\#\#*/})


# il est possible de changer cette valeur en la définissant autrement dans un fichier
# .make.env ou par un argument passé au makefile.
DOCKER_COMPOSE_FILE ?= docker-compose.yml

# cible default value to image
c ?= $(IMAGES)
CIBLE = $(c)

reverse = $(if $(1),$(call reverse,$(wordlist 2,$(words $(1)),$(1)))) $(firstword $(1))
REV_CIBLE = $(call reverse,$(c))

TIMESTAMP := $(shell date +%Y%m%d%H%M%S)

MYSQL_DATABASE := "${MYSQL_DATABASE}"
init:
	if [ "$$(systemctl is-active docker)" != active ]; then sudo systemctl start docker.service; else echo "docker already running"; fi
	if [ "$$(docker network ls --filter "name=^traefik_network$$" --format '{{.Name}}')" != "traefik_network" ]; then docker network create traefik_network; else echo "traefik_network already exist"; fi
	sudo chown -R www-data:www-data wp_data

up:
	@docker-compose -f $(DOCKER_COMPOSE_FILE) up -d $(CIBLE)

stop:
	@docker-compose -f $(DOCKER_COMPOSE_FILE) stop $(REV_CIBLE)

down:
	@docker-compose -f $(DOCKER_COMPOSE_FILE) down

backup:
	tar -cJpvf $(BACKUP_DIR)/$(PROJECT_NAME)_$(TIMESTAMP)_wp_data.tar.xz -C $(CURDIR) wp_data docker-compose.yml makefile .env
	docker exec $(PROJECT_NAME)_mysql_1 /bin/bash -c '/usr/bin/mysqldump -u root -p"$${MYSQL_ROOT_PASSWORD}" "$${MYSQL_DATABASE}"' > $(BACKUP_DIR)/$(PROJECT_NAME)_$(TIMESTAMP)_database.sql

update:
	@docker-compose -f $(DOCKER_COMPOSE_FILE) pull $(CIBLE)
	@docker-compose -f $(DOCKER_COMPOSE_FILE) up -d $(CIBLE)
