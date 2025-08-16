
.PHONY: default
default:
	false

.PHONY: docker-image
docker-image:
	docker build --network host -t pancache --build-arg UV_DEFAULT_INDEX=$(UV_DEFAULT_INDEX) .
