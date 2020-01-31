.PHONY: all docker

all: docker

docker:
	docker build -t snikket -f docker/Dockerfile .
