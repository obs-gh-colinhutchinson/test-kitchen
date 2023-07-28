PROVIDER ?= cloudformation

IMAGE_NAME ?= test-kitchen
CONTAINER_BASE_NAME ?= test-kitchen
CONTAINER_NAME ?= $(CONTAINER_BASE_NAME)-$(PROVIDER)
UID := $(shell id -u)
GID := $(shell id -g)
DOCKER_COMMAND ?= /bin/bash

OBSERVE_CUSTOMER := $(OBSERVE_CUSTOMER)
OBSERVE_TOKEN := $(OBSERVE_TOKEN)
OBSERVE_DOMAIN ?= observe-eng.com
AWS_ACCESS_KEY_ID := $(AWS_ACCESS_KEY_ID)
AWS_SECRET_ACCESS_KEY := $(AWS_SECRET_ACCESS_KEY)
AWS_SESSION_TOKEN := $(AWS_SESSION_TOKEN)
AWS_REGION ?= us-east-1

.PHONY: docker/clean
docker/clean: docker/test/clean
	docker kill $(CONTAINER_NAME) || true
	docker rm $(CONTAINER_NAME) || true
	docker rmi -f $(IMAGE_NAME) || true

.PHONY: docker/build
docker/build:
	docker build --build-arg UID=$(UID) --build-arg GID=$(GID) -t $(IMAGE_NAME) .

.PHONY: docker/%
docker/%:
	$(MAKE) docker/run DOCKER_COMMAND="make $*"

.PHONY: docker/run
docker/run: docker/build
	@if [ -z "`docker ps -q -f name=$(CONTAINER_NAME)`" ]; then \
		echo "Container is not running. Starting a new one."; \
		docker run -it --rm \
		--name $(CONTAINER_NAME) \
		-e PROVIDER=$(PROVIDER) \
		-e AWS_REGION=$(AWS_REGION) \
		-e USER=$(USER) \
		-e OBSERVE_CUSTOMER=$(OBSERVE_CUSTOMER) \
		-e OBSERVE_TOKEN=$(OBSERVE_TOKEN) \
		-e OBSERVE_DOMAIN=$(OBSERVE_DOMAIN) \
		-e AWS_ACCESS_KEY_ID=$(AWS_ACCESS_KEY_ID) \
		-e AWS_SECRET_ACCESS_KEY=$(AWS_SECRET_ACCESS_KEY) \
		-e AWS_SESSION_TOKEN=$(AWS_SESSION_TOKEN) \
		-v $(PWD):/workdir \
		-u $(UID):$(GID) \
		$(IMAGE_NAME) $(DOCKER_COMMAND); \
	else \
		echo "Container is already running. Executing command inside the container."; \
		docker exec -it $(CONTAINER_NAME) $(DOCKER_COMMAND); \
	fi

.PHONY: test
test: test/converge test/verify

.PHONY: test/prerequisites
test/prerequisites:
	./validate_deps.sh
	@if [ -z "$(USER)" ] ; then echo "USER is not set."; exit 1; fi
	@if [ -z "$(OBSERVE_CUSTOMER)" ] ; then echo "OBSERVE_CUSTOMER is not set."; exit 1; fi
	@if [ -z "$(OBSERVE_TOKEN)" ] ; then echo "OBSERVE_TOKEN is not set."; exit 1; fi
	@if [ -z "$(AWS_ACCESS_KEY_ID)" ] ; then echo "AWS_ACCESS_KEY_ID is not set."; exit 1; fi
	@if [ -z "$(AWS_SECRET_ACCESS_KEY)" ] ; then echo "AWS_SECRET_ACCESS_KEY is not set."; exit 1; fi

.PHONY: test/converge
test/converge: test/prerequisites
	kitchen converge

.PHONY: test/verify
test/verify: test/converge
	kitchen verify

.PHONY: test/clean
test/clean: test/prerequisites
	kitchen destroy || true
	rm -rf .kitchen/* || true
	aws logs delete-log-group --log-group-name /aws/lambda/spec-test-$(PROVIDER)-$(USER) || true
