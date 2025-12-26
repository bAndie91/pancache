
.PHONY: default
default:
	false


.PHONY: image
image: buildah-image

.PHONY: docker-image
docker-image:
	http_proxy='$(DOCKER_PULL_http_proxy)' https_proxy='$(DOCKER_PULL_https_proxy)' \
	docker build -t pancache:$(TAG) \
		--build-arg http_proxy='$(DOCKER_BUILD_http_proxy)' --build-arg https_proxy='$(DOCKER_BUILD_https_proxy)' \
		--build-arg PIP_INDEX_URL='$(PIP_INDEX_URL)' --build-arg PIP_TRUSTED_HOST='$(PIP_TRUSTED_HOST)' \
		--build-arg UV_DEFAULT_INDEX='$(UV_DEFAULT_INDEX)' --build-arg UV_INSECURE_HOST='$(UV_INSECURE_HOST)' \
		--build-arg APT_OPTS='$(APT_OPTS)' .

TAG = $(shell git show -s --format=%h)

.PHONY: buildah-image
buildah-image:
	if buildah inspect pancache:$(TAG) >/dev/null ; then \
		echo "buildah image 'pancache:$(TAG)' already exists" ; \
	else \
		http_proxy='$(DOCKER_PULL_http_proxy)' https_proxy='$(DOCKER_PULL_https_proxy)' \
		buildah build-using-dockerfile --tag pancache:$(TAG) \
		--build-arg http_proxy='$(DOCKER_BUILD_http_proxy)' --build-arg https_proxy='$(DOCKER_BUILD_https_proxy)' \
		--build-arg PIP_INDEX_URL='$(PIP_INDEX_URL)' --build-arg PIP_TRUSTED_HOST='$(PIP_TRUSTED_HOST)' \
		--build-arg UV_DEFAULT_INDEX='$(UV_DEFAULT_INDEX)' --build-arg UV_INSECURE_HOST='$(UV_INSECURE_HOST)' \
		--build-arg APT_OPTS='$(APT_OPTS)' . ; \
	fi

pancache_$(TAG).tar: docker-image
#	buildah push pancache:$(TAG) docker-archive:$@
	docker image save -o $@ pancache:$(TAG)
#push: pancache_$(TAG).tar
#	skopeo copy docker-archive:$< docker://$(OCI_REGISTRY_ADDRESS)/$(OCI_REGISTRY_REPO)/pancache:$(TAG)

.PHONY: push
push: buildah-image
ifndef OCI_REGISTRY_REPO
	$(error Must set OCI_REGISTRY_REPO)
endif
	buildah push pancache:$(TAG) docker://$(OCI_REGISTRY_REPO)/pancache:$(TAG)
