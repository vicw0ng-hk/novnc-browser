IMAGE ?= novnc-browser:dev

.PHONY: build test

build:
	docker build --tag $(IMAGE) .

test: build
	tests/smoke.sh $(IMAGE)
