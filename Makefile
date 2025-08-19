
.PHONY: default
default:
	false

.PHONY: docker-image
docker-image:
	docker build -t pancache --build-arg UV_DEFAULT_INDEX='$(UV_DEFAULT_INDEX)' --build-arg UV_INSECURE_HOST='$(UV_INSECURE_HOST)' --build-arg APT_OPTS='$(APT_OPTS)' .
