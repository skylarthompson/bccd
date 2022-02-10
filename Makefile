SHELL				=	/bin/bash
export MKDIR_P		:=	mkdir -p
export SVN_REV 		=	no_svn_rev
export VERSION		:=	3.4.0
# KERN_REV needs to be set to a version supported by aufs (see /usr/src/aufs-xxx/dkms.conf)
export KERN_REV		:=	4.16.0-2-amd64

.PHONY: install-iso 

# Archive this in Jenkins so that downstream projects have the correct ordering b/w target/bccd.noarch.deb and build/etc/bccd-revision
# GIT MIGRATION: COMMENT OUT UNTIL WE CAN GET THE GIT COMMIT ID
#build/etc/bccd-revision: 
#	/bin/mkdir -p "$(WORKSPACE)"/build/etc
#	@echo "$(VERSION).$(SVN_REVISION)" > "$(WORKSPACE)"/build/etc/bccd-revision
#	# Set modification time of bccd-revision to bccd.noarch.deb if it is available, to avoid
#	# unnecessary rebuild of bccd.noarch.deb if it is copied in from another build
#	find "$(WORKSPACE)"/target -type f -name bccd.noarch.deb -exec touch -r "{}" "$@" \;
build/etc/bccd-revision:
	/bin/mkdir -p "$(WORKSPACE)"/build/etc
	@echo "$(VERSION).nonce" > "$(WORKSPACE)"/$@

target/bccd.noarch.deb: build/etc/bccd-revision 
	cp $< "$(WORKSPACE)/src/etc"
	# Dependency on gnupg2 is required by apt-key
	fpm \
		-n bccd \
		-C "$(WORKSPACE)"/src \
		-s dir \
		-t deb \
		-d gnupg2 \
		-p "$(WORKSPACE)"/target/bccd.noarch.deb \
		-v "$(VERSION)" \
		--iteration nonce \
		-x '*/.svn*' \
		--before-install "$(WORKSPACE)/bin/deb/bccd_deb_before_install" \
		--after-remove "$(WORKSPACE)/bin/deb/bccd_deb_after_remove" \
		--after-install "$(WORKSPACE)/bin/deb/bccd_deb_after_install"

debootstrap: 
	# Script will either create a new debootstrap (if executing a debootstrap project) or extract the imported
	# debootstrap.tar.bz2 artifact
	"$(WORKSPACE)"/bin/prepare_debootstrap

target/debootstrap-bccd.tar.bz2: target/bccd.noarch.deb debootstrap
	/bin/cp -v "$<" "$(WORKSPACE)/debootstrap/tmp"
	"$(WORKSPACE)/bin/bccd_install_pkgs"
	# Using pbzip2 takes a couple minutes but saves 50% / 2+GB of space
	/bin/tar -C "$(WORKSPACE)" --exclude='debootstrap/proc/*' --exclude='debootstrap/sys/*' -cf - debootstrap | nice /usr/bin/pbzip2 -c > "$(@)"
	# Virtual filesystems might not be mounted, but try before rm runs
	-/bin/umount "$(WORKSPACE)/debootstrap/dev"
	-/bin/umount "$(WORKSPACE)/debootstrap/sys"
	/bin/rm --one-file-system -rf "$(WORKSPACE)/debootstrap"

target/debootstrap.tar.bz2: debootstrap
	mkdir -p "$(WORKSPACE)"/target
	/bin/tar -C "$(WORKSPACE)" --exclude="$<"'/proc/*' --exclude="$<"'/sys/*' -cf - "$<" | nice /usr/bin/pbzip2 -c > "$(@)"
	# Virtual filesystems might not be mounted, but try before rm runs
	-/bin/umount "$(WORKSPACE)/debootstrap/dev"
	-/bin/umount "$(WORKSPACE)/debootstrap/sys"
	/bin/rm --one-file-system -rf "$(WORKSPACE)/$<"

iso/live/initrd.img: debootstrap
	/usr/bin/sudo /usr/sbin/chroot "$(WORKSPACE)/debootstrap" mkinitramfs \
		-o "/boot/initrd-$(KERN_REV).diskless" "$(KERN_REV)"
	/bin/cp "$(WORKSPACE)/debootstrap/boot/initrd-$(KERN_REV).diskless" "$(WORKSPACE)/$@"

iso/live/vmlinuz: debootstrap
	/bin/cp "$(WORKSPACE)/debootstrap/boot/vmlinuz-$(KERN_REV)" "$(WORKSPACE)/$@"

iso/live/filesystem.squashfs: target/debootstrap-bccd.tar.bz2
	nice "$(WORKSPACE)"/bin/make_filesystem_squashfs -o "$@" < "$<"

# Added to test ISO w/o bccd deb #1008
nobccd-filesystem.squashfs: target/debootstrap.tar.bz2
	"$(WORKSPACE)/bin/bccd_install_pkgs"
	nice "$(WORKSPACE)"/bin/make_filesystem_squashfs -o iso/live/filesystem.squashfs < "$<"

iso/boot/isolinux/isolinux.bin:
	cp /usr/lib/ISOLINUX/isolinux.bin $@

iso/boot/isolinux/ldlinux.c32:
	cp /usr/lib/syslinux/modules/bios/ldlinux.c32 $@

target/bccd.amd64.iso: iso/boot/isolinux/isolinux.bin iso/boot/isolinux/ldlinux.c32 iso/live/filesystem.squashfs iso/live/initrd.img iso/live/vmlinuz
	nice /usr/bin/genisoimage \
		-pad \
		-l \
		-r \
		-J \
		-v \
		-V "BCCDv3-$(SVN_REV)" \
		-no-emul-boot \
		-boot-load-size 4 \
		-boot-info-table \
		-b boot/isolinux/isolinux.bin \
		-c boot/isolinux/boot.cat \
		-hide-rr-moved \
		-o $@ \
		iso
	/bin/rm -rf --one-file-system "$(WORKSPACE)/iso"

target/nobccd.amd64.iso: iso/boot/isolinux/isolinux.bin iso/boot/isolinux/ldlinux.c32 nobccd-filesystem.squashfs iso/live/initrd.img iso/live/vmlinuz
	nice /usr/bin/genisoimage \
		-pad \
		-l \
		-r \
		-J \
		-v \
		-V "BCCDv3-$(SVN_REV)" \
		-no-emul-boot \
		-boot-load-size 4 \
		-boot-info-table \
		-b boot/isolinux/isolinux.bin \
		-c boot/isolinux/boot.cat \
		-hide-rr-moved \
		-o $@ \
		iso
	/bin/rm -rf --one-file-system "$(WORKSPACE)/iso"

target/bccd.amd64.iso.md5: target/bccd.amd64.iso
# Change directory to make md5sum print just the filename
	cd $(dir $<) && md5sum $(notdir $<) > $(notdir $@)

# Added to test ISO w/o bccd deb #1008
target/nobccd.amd64.iso.md5: target/nobccd.amd64.iso
# Change directory to make md5sum print just the filename
	cd $(dir $<) && md5sum $(notdir $<) > $(notdir $@)

install-iso: target/bccd.amd64.iso.md5
# Move the MD5 file target, and the associaetd ISO file, to ISO_INSTALL_DIR
ifdef ISO_INSTALL_DIR
	/bin/mv -v "$<" $(<:.md5=) "$(ISO_INSTALL_DIR)"
endif

# Added to test ISO w/o bccd deb #1008
nobccd-install-iso: target/nobccd.amd64.iso.md5
# Move the MD5 file target, and the associaetd ISO file, to ISO_INSTALL_DIR
ifdef ISO_INSTALL_DIR
	/bin/mv -v "$<" $(<:.md5=) "$(ISO_INSTALL_DIR)"
endif
