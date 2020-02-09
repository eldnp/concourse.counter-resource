endpoint ?= https:\\/\\/undefined-s3-host
bucket ?= test.counter-resource
access_key_id ?= undefined-access-key
secret_access_key ?= undefined-secret-access-key
image ?= concourse-counter-resource

DEBUG_DIR = $(CURDIR)/.debug
SECTION_PREFIX = ===>
OUTPUT_PROMPT = "<<< output:"

define prepareTestData
	@(\
		if [ -f "$(DEBUG_DIR)/$(1)-request.json" ]; then \
	        echo "use existing request file \`$(DEBUG_DIR)/$(1)-request.json\`"; \
		else  \
    		echo "build request-file $(DEBUG_DIR)/$(1)-request.json"; \
			cat $(DEBUG_DIR)/$(1)-request.json.dist \
			| sed "s/ENDPOINT_PLACEHOLDER/$(endpoint)/" \
			| sed "s/BUCKET_PLACEHOLDER/$(bucket)/" \
			| sed "s/ACCESS_KEY_ID_PLACEHOLDER/$(access_key_id)/" \
			| sed "s/SECRET_ACCESS_KEY_PLACEHOLDER/$(secret_access_key)/" > $(DEBUG_DIR)/$(1)-request.json; \
		fi; \
	)
endef

all: run-check run-in run-out

check: show-env
	@echo "$(SECTION_PREFIX) check docker version"
	@(docker --version 2>&1 >/dev/null) || exit "Docker must be installed, and accessible via PATH"
	@echo "ok"

image: check 
	@echo "$(SECTION_PREFIX) check docker image"
ifeq ($(shell docker images -q $(image) 2> /dev/null),)
	@echo "build image"
	@docker build $(PWD) -f Dockerfile -t $(image)
else
	@echo "use existing image $(image)"
endif

clean:
	rm $(DEBUG_DIR)/*.json
	docker image rm $(image)

show-env:
	@echo "environments:"
	@echo "  s3:"
	@echo "    endpoint: $(endpoint)"
	@echo "    bucket: $(bucket)"
	@echo "    access_key_id: $(access_key_id)"
	@echo "    secret_access_key: $(secret_access_key)" 
	@echo "  docker:"
	@echo "    image: $(image)"
	@echo ""

run-check: image
	@echo "$(SECTION_PREFIX) run-check"
	$(call prepareTestData,check)
	@echo $(OUTPUT_PROMPT)
	@docker run \
		--rm -i \
		-v $(CURDIR)/assets:/opt/resource \
		--entrypoint=/bin/sh \
		$(image):latest \
		/opt/resource/check <$(DEBUG_DIR)/check-request.json 2>&1| sed 's/^/    /'

run-in: image
	@echo "$(SECTION_PREFIX) run-in"
	$(call prepareTestData,in)
	@echo $(OUTPUT_PROMPT)
	@docker run \
		--rm -i \
		-v $(CURDIR)/assets:/opt/resource \
		-v $(DEBUG_DIR)/docker-volume:/tmp/in-step \
		--entrypoint=/bin/sh \
		$(image):latest \
		/opt/resource/in /tmp/in-step < $(DEBUG_DIR)/in-request.json 2>&1| sed 's/^/    /'

run-out: image
	@echo "$(SECTION_PREFIX) run-out"
	$(call prepareTestData,out)
	@echo $(OUTPUT_PROMPT)
	@docker run \
		--rm -i \
		-v $(CURDIR)/assets:/opt/resource \
		-v $(DEBUG_DIR)/docker-volume:/tmp/out-step \
		--entrypoint=/bin/sh \
		$(image):latest \
		/opt/resource/out /tmp/out-step < $(DEBUG_DIR)/out-request.json 2>&1| sed 's/^/    /'
