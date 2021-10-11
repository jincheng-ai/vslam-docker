#!/usr/bin/make -f
IMAGE := camera
VERSION := latest

.PHONY: all build rebuild shell run

#--------------------------

all: build

# create image

build:
	docker build -t=$(IMAGE):$(VERSION) .

rebuild:
	docker build -t=$(IMAGE):$(VERSION) --no-cache .

shell:
	docker run --rm -it -p 7890:7890 $(IMAGE):$(VERSION) bash

# run
run:
	docker run --rm -it -p 7890:7890 $(IMAGE):$(VERSION)
