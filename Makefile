UNISON_VERSION := af02bc9f417a9acbc972583f5e662f8485353632
BUILD_DIR ?= build
OUTPUT_DIR ?= output
ALPINE_IMAGE ?= alpine:3.4

VERSION ?= latest


# Add the following 'help' target to your Makefile
# And add help text after each target name starting with '\#\#'
# A category can be added with @category
HELP_HELPER = \
    %help; \
    while(<>) { push @{$$help{$$2 // 'options'}}, [$$1, $$3] if /^([a-zA-Z\-]+)\s*:.*\#\#(?:@([a-zA-Z\-]+))?\s(.*)$$/ }; \
    print "usage: make [target]\n\n"; \
    for (sort keys %help) { \
    print "${WHITE}$$_:${RESET}\n"; \
    for (@{$$help{$$_}}) { \
    $$sep = " " x (32 - length $$_->[0]); \
    print "  ${YELLOW}$$_->[0]${RESET}$$sep${GREEN}$$_->[1]${RESET}\n"; \
    }; \
    print "\n"; }
    
help: ##prints help
	@perl -e '$(HELP_HELPER)' $(MAKEFILE_LIST)    

get-unison-sources: ## Fetch unison sources
	@-rm -R  ${BUILD_DIR}/unison ${BUILD_DIR}/${UNISON_VERSION}.tar.gz
	@mkdir -p ${BUILD_DIR}/unison
	@cd ${BUILD_DIR} && wget https://github.com/bcpierce00/unison/archive/${UNISON_VERSION}.tar.gz
	@cd ${BUILD_DIR} && tar xfz ${UNISON_VERSION}.tar.gz -C unison --strip-components=1
	@rm ${BUILD_DIR}/${UNISON_VERSION}.tar.gz

unison-mac: ## Build unison for mac
	@make get-unison-sources
	@mkdir -p output/mac
	@cd ${BUILD_DIR}/unison && make UISTYLE=text NATIVE=true
	@cp ${BUILD_DIR}/unison/src/unison ${OUTPUT_DIR}/mac/

unison-alpine: ## Build unison for linux alpine image
	@docker run -ti -v ${PWD}:/data -w /data ${ALPINE_IMAGE} /bin/sh -c "apk --update-cache add make && make _unison-alpine"

_unison-alpine: ## Build unison on linux alpine image
	@apk update
	@apk add alpine-sdk openssh bash vim ncurses-dev
	@apk add ocaml --update-cache --repository http://dl-3.alpinelinux.org/alpine/edge/community/ --allow-untrusted
	@make get-unison-sources
	@mkdir -p ${OUTPUT_DIR}/alpine
	@cp unison_alpine.patch ${BUILD_DIR}/unison
	@PATCH_PATH=$${PWD} && cd ${BUILD_DIR}/unison && patch -p0 < unison_alpine.patch
	@cd ${BUILD_DIR}/unison && make UISTYLE=text NATIVE=true
	@cp ${BUILD_DIR}/unison/src/unison ${OUTPUT_DIR}/alpine/

publish:
	@docker build -t keepitcool/docker-sync:${VERSION} .
	@docker push keepitcool/docker-sync:${VERSION}

package-mac-unison:
	@-rm -R output/unison-${VERSION}-osx64
	@mkdir -p output/unison-${VERSION}-osx64
	@cp output/mac/unison output/unison-${VERSION}-osx64
	@cd output && tar cvzf unison-${VERSION}-osx64.tar.gz unison-${VERSION}-osx64/
	@-rm -R output/unison-${VERSION}-osx64

clean: ## Clean 
	@rm -R build