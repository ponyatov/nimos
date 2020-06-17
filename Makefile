# see also https://github.com/ponyatov/L/blob/master/mk/cross.mk

HW = qemu386

include hw/$(HW).mk
include cpu/$(CPU).mk
include arch/$(ARCH).mk

# cross toools versions

## cc libs for gcc build
GMP_VER = 5.1.3
MPFR_VER = 3.1.2
MPC_VER = 1.0.2
ISL_VER = 0.11.1
CLOOG_VER = 0.18.1
# GNU toolchain
BINUTILS_VER = 2.33.1
GCC_VER = 4.9.2
# bootloaders
SYSLINUX_VER = 6.03



CWD     = $(CURDIR)
MODULE  = $(notdir $(CWD))
OS     ?= $(shell uname -s)

NOW = $(shell date +%d%m%y)
REL = $(shell git rev-parse --short=4 HEAD)

WGET = wget -c --no-check-certificate



.PHONY: all
all: cross
# all: dirs cross

TMP   = $(CWD)/tmp
SRC   = $(TMP)/src
GZ    = $(HOME)/gz
FWARE = $(CWD)/firmware
CROSS = $(CWD)/$(TARGET)

.PHONY: dirs
dirs:
	mkdir -p $(TMP) $(SRC) $(GZ) $(FWARE) $(CROSS)



TCC = $(TARGET)-gcc
TLD = $(TARGET)-ld
TAS = $(TARGET)-as



BINUTILS = binutils-$(BINUTILS_VER)

BINUTILS_GZ = $(BINUTILS).tar.bz2

.PHONY: cross
cross: binutils

XPATH = PATH=$(CROSS)/bin:$(PATH)

CPU_NUM = $(shell grep processor /proc/cpuinfo|wc -l)

XMAKE = $(MAKE) -j$(CPU_NUM)

CFG = configure --disable-nls --prefix=$(CROSS)

CFG_BINUTILS = --target=$(TARGET) $(CFG_ARCH) $(CFG_CPU) \
				--with-sysroot=$(CROSS) --with-native-system-header-dir=/include \
				--enable-lto --disable-multilib $(CFG_WITHCCLIBS)

.PHONY: binutils
binutils: $(CROSS)/bin/$(TLD)
$(CROSS)/bin/$(TLD): $(SRC)/$(BINUTILS)/README
	rm -rf $(TMP)/$(BINUTILS) ; mkdir $(TMP)/$(BINUTILS) ; cd $(TMP)/$(BINUTILS) ;\
		$(XPATH) $(SRC)/$(BINUTILS)/$(CFG) $(CFG_BINUTILS) &&\
		$(XMAKE) && $(MAKE) install-strip



.PHONY: gz
gz: $(GZ)/$(BINUTILS_GZ)

$(SRC)/%/README: $(GZ)/%.tar.bz2
	cd $(SRC) ; bzcat $< | tar x && touch $@

$(GZ)/$(BINUTILS_GZ):
	$(WGET) -O $@ $(WGET) http://ftp.gnu.org/gnu/binutils/$(BINUTILS).tar.bz2

.PHONY: debian
debian:
	sudo apt update
	sudo apt install -u `cat apt.txt`



MERGE  = Makefile README.md .gitignore .vscode apt.txt
MERGE += src

master:
	git checkout $@
	git checkout shadow -- $(MERGE)

shadow:
	git checkout $@

release:
	git tag $(NOW)-$(REL)
	git push -v && git push -v --tags
	git checkout shadow

zip:
	git archive --format zip --output $(MODULE)_src_$(NOW)_$(REL).zip HEAD
