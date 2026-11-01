IMAGE ?= novnc-browser:dev

.PHONY: build run test

build:
	docker build --tag $(IMAGE) .

run: build
	docker run --rm --publish 127.0.0.1:6080:6080 $(IMAGE)

test: build
	tests/smoke.sh $(IMAGE)
