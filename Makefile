CONFIG = .env
ifneq (,$(wildcard ${CONFIG}))
include ${CONFIG}
endif

DATE := $(shell date '+%Y%m%d%H%M%S')

.PHONY : all build
all : build

.ONESHELL:
SHELL = /bin/bash
build :
	DOCKER_IMAGE_TAG="1.8.9.2"
	docker buildx build \
		--progress=plain \
		--tag localhost:32000/xnat:1.8.9.2 . 2>&1 \
		|tee log-buildx-$(DATE)
	docker push localhost:32000/xnat:1.8.9.2
