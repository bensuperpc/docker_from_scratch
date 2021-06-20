#//////////////////////////////////////////////////////////////
#//   ____                                                   //
#//  | __ )  ___ _ __  ___ _   _ _ __   ___ _ __ _ __   ___  //
#//  |  _ \ / _ \ '_ \/ __| | | | '_ \ / _ \ '__| '_ \ / __| //
#//  | |_) |  __/ | | \__ \ |_| | |_) |  __/ |  | |_) | (__  //
#//  |____/ \___|_| |_|___/\__,_| .__/ \___|_|  | .__/ \___| //
#//                             |_|             |_|          //
#//////////////////////////////////////////////////////////////
#//                                                          //
#//  Script, 2021                                            //
#//  Created: 17, June, 2021                                 //
#//  Modified: 19, June, 2021                                //
#//  file: -                                                 //
#//  -                                                       //
#//  Source: https://github.com/metal3d/bashsimplecurses     //
#//		https://superuser.com/questions/281573/what-are-the-best-options-to-use-when-compressing-files-using-7-zip
#//		https://code-maven.com/create-temporary-directory-on-linux-using-bash
#//		https://askubuntu.com/questions/1259819/debootstrap-does-not-resolve-dependencies
#//		https://stackoverflow.com/a/8157973/10152334
#//		https://github.com/RPi-Distro/pi-gen
#//		https://bugs.launchpad.net/ubuntu/+source/synaptic/+bug/1522675
#//		https://www.docker.com/blog/advanced-dockerfiles-faster-builds-and-smaller-images-using-buildkit-and-multistage-builds/
#//		https://github.com/archlinux/archlinux-docker
#//		https://github.com/tokland/arch-bootstrap
#//		https://enix.io/fr/blog/cherie-j-ai-retreci-docker-part3/
#//  OS: ALL                                                 //
#//  CPU: ALL                                                //
#//                                                          //
#//////////////////////////////////////////////////////////////
PROJECT_NAME := scripts
SHELL := bash
VERSION := 1.0.0
RM := rm
TMP_DIR := $(shell mktemp -d -t debootstrap-$(shell date +%Y-%m-%d-%H-%M-%S)-XXXXXXXXXXXXXX)
#USER := $(shell echo $$USER)
USER := bensuperpc

DEBIAN_UBUNTU_VERS := trusty xenial bionic focal jessie stretch buster bullseye sid
ALPINE_VERS := v3.11 v3.12 v3.13 v3.14

all: ubuntu alpine debian

# Latest version
alpine: v3.14
ubuntu: focal
debian: bullseye


sync-submodule:
	git submodule update --init --recursive
	git submodule update --recursive --remote

arch-rootfs:
	$(RM) -f arch-bootstrap.sh
	wget https://raw.githubusercontent.com/tiredofit/arch-bootstrap/support-zst/arch-bootstrap.sh \
	&& echo 'f3aa2e7f6b683dd817e44c7a81aa103218e275d7  arch-bootstrap.sh' | sha1sum -c || exit 1
	chmod +x arch-bootstrap.sh

archlinux: arch-rootfs
	sudo mount -o remount,exec,dev /tmp
	sudo mkdir $(TMP_DIR)/$@
	sudo chown -R $(USER) $(TMP_DIR)
	sudo chmod -R 744 $(TMP_DIR)
	sudo ./arch-bootstrap.sh -a x86_64 $(TMP_DIR)/$@
	#-r "ftp://ftp.archlinux.org" 
	
	# Test chroot
	sudo chroot $(TMP_DIR)/$@ /bin/bash -c "pacman -Scc --noconfirm"
	sudo chroot $(TMP_DIR)/$@ /bin/bash -c "ls -la /"

	# Create tar.xz archive
	tar --exclude='var/log/*.log' --exclude='var/lib/apt/*' --numeric-owner --xattrs --acls -C $(TMP_DIR)/$@ -c . -f $(TMP_DIR)/$@.tar.xz
	cat $(TMP_DIR)/$@.tar.xz | docker import - test/$@
	docker run --rm test/$@ /bin/bash -c "ls -la /"
	docker run --rm test/$@ /bin/sh -c "pacman -S python3 --noconfirm && python3 -V"
	docker rmi test/$@

	# Build from scratch
	cp Dockerfile-arch $(TMP_DIR)/Dockerfile
	cp .dockerignore $(TMP_DIR)/.dockerignore
	echo "$@/*" >> $(TMP_DIR)/.dockerignore
	
	docker build $(TMP_DIR) -f $(TMP_DIR)/Dockerfile -t $(USER)/$@ --build-arg ROOTFS="$@.tar.xz"
	
	@echo "Build: done"
	@echo "You can found build rootfs in: $(TMP_DIR)"
	
	sudo mount -o remount,defaults,noexec,nosuid,noatime /tmp

alpine-make-rootfs: alpine-make-rootfs
	$(RM) -f alpine-make-rootfs
	wget https://raw.githubusercontent.com/alpinelinux/alpine-make-rootfs/v0.5.1/alpine-make-rootfs \
	&& echo 'a7159f17b01ad5a06419b83ea3ca9bbe7d3f8c03  alpine-make-rootfs' | sha1sum -c || exit 1
	chmod +x alpine-make-rootfs

$(ALPINE_VERS): alpine-make-rootfs
	sudo mount -o remount,exec,dev /tmp
	sudo chown -R $(USER) $(TMP_DIR)
	sudo chmod -R 744 $(TMP_DIR)
	sudo ./alpine-make-rootfs --branch $@ --timezone 'Europe/Prague' --packages 'apk-tools bash' --script-chroot $(TMP_DIR)/rootfs_alpine-$@.tar.xz
	
	# Test if docker image work (Useless stage ?)
	cat $(TMP_DIR)/rootfs_alpine-$@.tar.xz | docker import - test/$@
	docker run --rm test/$@ /bin/sh -c "ls -la /"
	docker run --rm test/$@ /bin/sh -c "apk update && apk upgrade && apk add python3 && python3 -V"
	docker rmi test/$@
	
	# Build from scratch
	cp Dockerfile-alpine $(TMP_DIR)/Dockerfile
	docker build $(TMP_DIR) -f $(TMP_DIR)/Dockerfile -t $(USER)/$@ --build-arg ROOTFS="rootfs_alpine-$@.tar.xz"
	
	@echo "Build: done"
	@echo "You can found build rootfs in: $(TMP_DIR)"
	sudo mount -o remount,defaults,noexec,nosuid,noatime /tmp
	
debootstrap_check:
	debootstrap --version || @echo "You need to install <debootstrap> package (and debian-archive-keyring, ubuntu-keyring)" && exit 1
	
$(DEBIAN_UBUNTU_VERS): debootstrap_check
	sudo mount -o remount,exec,dev /tmp
	sudo mkdir $(TMP_DIR)/$@
	sudo chown -R $(USER) $(TMP_DIR)
	sudo chmod -R 744 $(TMP_DIR)
	sudo debootstrap --variant=minbase --arch amd64 $@ $(TMP_DIR)/$@ # > /dev/null --include=g++

	# Test chroot
	sudo chroot $(TMP_DIR)/$@ /bin/bash -c "/bin/ls -la /"
	sudo chroot $(TMP_DIR)/$@ /bin/bash -c "apt-get update"

	# Create tar.xz archive
	tar --exclude='var/cache/apt/archives/*.deb' --exclude='var/cache/apt/archives/partial/*.deb' --exclude='var/log/*.log' --exclude='var/lib/apt/*' --numeric-owner --xattrs --acls -C $(TMP_DIR)/$@ -c . -f $(TMP_DIR)/$@.tar.xz

	# Test tar.xz archive
	#sudo tar -xf $(TMP_DIR)/$@.tar.xz | tar -t > /dev/null

	# Test if docker image work (Useless stage ?)
	cat $(TMP_DIR)/$@.tar.xz | docker import - test/$@
	docker run --rm test/$@ /bin/bash -c "ls -la /"
	docker run --rm test/$@ /bin/bash -c "apt-get update && apt-get dist-upgrade -y && apt-get install -y hello && hello"
	docker rmi test/$@

	# Build from scratch
	cp Dockerfile-debian $(TMP_DIR)/Dockerfile
	cp .dockerignore $(TMP_DIR)/.dockerignore
	echo "$@/*" >> $(TMP_DIR)/.dockerignore
	docker build $(TMP_DIR) -f $(TMP_DIR)/Dockerfile -t $(USER)/$@ --build-arg ROOTFS="$@.tar.xz"
	
	@echo "Build: done"
	@echo "You can found build rootfs in: $(TMP_DIR)"
	
	sudo mount -o remount,defaults,noexec,nosuid,noatime /tmp


dist: clean sync-submodule
	mkdir -p package_build
	rsync -azh --progress --exclude='package_build/' --exclude='*.gitignore' --exclude='*.git/' --exclude='*.circleci/' --exclude='*.github/' . package_build/
	7z a -t7z $(PROJECT_NAME)-$(VERSION).7z package_build/ -m0=lzma2 -mx=9 -mfb=273 -ms -md=31 -myx=9 -mtm=- -mmt -mmtf -md=1536m -mmf=bt3 -mmc=10000 -mpb=0 -mlc=0
	sha384sum $(PROJECT_NAME)-$(VERSION).7z > $(PROJECT_NAME)-$(VERSION).sha384
	sha384sum --check $(PROJECT_NAME)-$(VERSION).sha384
	@echo "$(PROJECT_NAME)-$(VERSION).7z done"

dist-full: clean sync-submodule
	mkdir -p package_build
	rsync -azh --progress --exclude='package_build/' . package_build/
	#7z a $(PROJECT_NAME)-full-$(VERSION).7z package_build/ -m0=lzma2 -mx=9 -mmt -ms
	XZ_OPT=-e9 tar cJf $(PROJECT_NAME)-full-$(VERSION).tar.xz package_build/
	sha384sum $(PROJECT_NAME)-full-$(VERSION).tar.xz > $(PROJECT_NAME)-full-$(VERSION).sha384
	sha384sum --check $(PROJECT_NAME)-full-$(VERSION).sha384
	@echo "$(PROJECT_NAME)-full-$(VERSION).tar.xz done"

clean:
	$(RM) -rf package_build/
	$(RM) -f $(PROJECT_NAME)-$(VERSION).7z
	$(RM) -f $(PROJECT_NAME)-full-$(VERSION).7z
	$(RM) -rf /tmp/debootstrap-*
	@echo "Clean OK"

.PHONY: clean dist-full dist sync-submodule $(DEBIAN_UBUNTU_VERS) debootstrap_check $(ALPINE_VERS) alpine arch-rootfs archlinux
