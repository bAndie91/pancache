
.PHONY: default
default:
	false

.PHONY: docker-image
docker-image:
	docker build --network host -t pancache .
