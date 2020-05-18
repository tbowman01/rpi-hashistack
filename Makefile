define build_image
	rm ${PWD}/output-arm-image/$1.iso || true
	docker run \
		--rm \
		--privileged \
		-v ${PWD}:/build:ro \
		-v ${PWD}/packer_cache:/build/packer_cache \
		-v ${PWD}/output-arm-image:/build/output-arm-image \
		registry.gitlab.com/nosceon/rpi-images/build-tools:build "/build/packer/$1.json"

	mv ${PWD}/output-arm-image/image ${PWD}/output-arm-image/$1.iso
endef

.PHONY: all
all: consul vault nomad

.PHONY: consul
consul:
	$(call build_image,consul)

.PHONY: vault
vault:
	$(call build_image,vault)

.PHONY: nomad
nomad:
	$(call build_image,nomad)

.PHONY: nomad-client
nomad-client:
	$(call build_image,nomad-client)