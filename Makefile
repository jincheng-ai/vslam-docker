#!/usr/bin/make -f
IMAGE := camera
VERSION := latest

.PHONY: all build-test build rebuild shell run test

#--------------------------

all: build

# create image

build-test:
	docker build -t=$(IMAGE)-test:$(VERSION) -f ./Dockerfile.Test .

build:
	docker build -t=$(IMAGE):$(VERSION) .

rebuild:
	docker build -t=$(IMAGE):$(VERSION) --no-cache .

shell:
	docker run --rm -it -p 7890:7890 --gpus all $(IMAGE):$(VERSION) bash

test:
	docker run --rm -it -p 7890:7890 --gpus all -e TZ=Asia/Shanghai $(IMAGE)-test:$(VERSION) bash

# run
run:
	docker run --rm -it -p 7890:7890 --gpus all $(IMAGE):$(VERSION)
