PACKAGE = shadow
ORG = amylum

BUILD_DIR = /tmp/$(PACKAGE)-build
RELEASE_DIR = /tmp/$(PACKAGE)-release
RELEASE_FILE = /tmp/$(PACKAGE).tar.gz

PACKAGE_VERSION = $$(git --git-dir=upstream/.git describe --tags | sed 's/upstream\///')
PATCH_VERSION = $$(cat version)
VERSION = $(PACKAGE_VERSION)-$(PATCH_VERSION)

PATH_FLAGS = --prefix=/usr --bindir=/usr/bin --sbindir=/usr/bin --sysconfdir=/etc
CFLAGS = -static -static-libgcc -Wl,-static

.PHONY : default submodule source deps manual container build version push local

default: container

submodule:
	git submodule update --init

manual:
	./meta/launch /bin/bash || true

container:
	./meta/launch

build: submodule
	rm -rf $(BUILD_DIR)
	cp -R upstream $(BUILD_DIR)
	cd $(BUILD_DIR) && autoreconf -i
	cd $(BUILD_DIR) && CC=musl-gcc CFLAGS='$(CFLAGS)' ./configure $(PATH_FLAGS)
	cd $(BUILD_DIR) && make
	cd $(BUILD_DIR) && make DESTDIR=$(RELEASE_DIR) install
	rm -rf $(RELEASE_DIR)/usr/bin/nologin
	mkdir -p $(RELEASE_DIR)/usr/share/licenses/$(PACKAGE)
	cp $(BUILD_DIR)/COPYING $(RELEASE_DIR)/usr/share/licenses/$(PACKAGE)/LICENSE
	cd $(RELEASE_DIR) && tar -czvf $(RELEASE_FILE) *

version:
	@echo $$(($(PATCH_VERSION) + 1)) > version

push: version
	git commit -am "$(VERSION)"
	ssh -oStrictHostKeyChecking=no git@github.com &>/dev/null || true
	git tag -f "$(VERSION)"
	git push --tags origin master
	@sleep 3
	targit -a .github -c -f $(ORG)/$(PACKAGE) $(VERSION) $(RELEASE_FILE)
	@sha512sum $(RELEASE_FILE) | cut -d' ' -f1

local: build push

