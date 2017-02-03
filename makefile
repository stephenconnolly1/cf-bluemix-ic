CONTAINER=stephenconnolly/cf-bluemix-ic
TAG=1.0.0
.DEFAULT_GOAL := help

help: ## Print this help text
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

all: build test push ## Do everything

build: bluemix.sh Dockerfile ## Build the Docker image locally using the Dockerfile and tag it
	docker build . -t $(CONTAINER):$(TAG) -t $(CONTAINER):latest

push: build ## Push the image up to Dockerhub
	docker push $(CONTAINER)

test: build ## Test the shell script can be run from inside the Docker image, with env vars like those in Wercker
	docker run --rm -e CF_DEBUG=$(CF_DEBUG) \
	-e CF_ORG=$(CF_ORG) \
	-e CF_SPACE=$(CF_SPACE) \
	-e CF_API=$(CF_API) \
	-e CF_PASS='$(CF_PASS)' \
	-e CF_PORTS=$(CF_PORTS) \
	-e CF_USER=$(CF_USER) \
	-e CF_CONTAINER=$(CF_CONTAINER) \
	-e LAUNCH_CMD="$(LAUNCH_CMD)" \
	$(CONTAINER)
