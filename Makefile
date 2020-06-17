# see also https://github.com/ponyatov/L/blob/master/mk/cross.mk

HW = qemu386

include hw/$(HW).mk
include cpu/$(CPU).mk
include arch/$(ARCH).mk

# cross toools versions

## cc libs for gcc build
GMP_VER = 6.1.2
MPFR_VER = 4.0.2
MPC_VER = 1.1.0
ISL_VER = 0.11.1
CLOOG_VER = 0.18.1
# GNU toolchain
BINUTILS_VER = 2.33.1
GCC_VER = 9.3.0
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



TMP   = $(CWD)/tmp
SRC   = $(TMP)/src
GZ    = $(HOME)/gz
FWARE = $(CWD)/firmware
CROSS = $(CWD)/$(TARGET)

.PHONY: dirs
dirs:
	mkdir -p $(TMP) $(SRC) $(GZ) $(FWARE) $(CROSS) $(CROSS)/sysroot



TCC = $(TARGET)-gcc
TLD = $(TARGET)-ld
TAS = $(TARGET)-as



GMP      = gmp-$(GMP_VER)
MPFR     = mpfr-$(MPFR_VER)
MPC      = mpc-$(MPC_VER)
BINUTILS = binutils-$(BINUTILS_VER)
GCC      = gcc-$(GCC_VER)

GMP_GZ      = $(GMP).tar.xz
MPFR_GZ     = $(MPFR).tar.xz
MPC_GZ      = $(MPC).tar.gz
BINUTILS_GZ = $(BINUTILS).tar.xz
GCC_GZ      = $(GCC).tar.xz

.PHONY: cross
cross: dirs cclibs binutils gcc0

XPATH = PATH=$(CROSS)/bin:$(PATH)

CPU_NUM = $(shell grep processor /proc/cpuinfo|wc -l)

XMAKE = $(MAKE) -j$(CPU_NUM)

CFG = configure --disable-nls --prefix=$(CROSS)



.PHONY: cclibs
cclibs: gmp mpfr mpc

CFG_CCLIBS = --disable-shared
CFG_GMP = $(CFG_CCLIBS)

.PHONY: gmp
gmp: $(CROSS)/lib/libgmp.a
$(CROSS)/lib/libgmp.a: $(SRC)/$(GMP)/README
	rm -rf $(TMP)/$(GMP) ; mkdir $(TMP)/$(GMP) ; cd $(TMP)/$(GMP) ;\
		$(XPATH) $(SRC)/$(GMP)/$(CFG) $(CFG_GMP) &&\
		$(XMAKE) && $(MAKE) install-strip

CFG_MPFR = $(CFG_CCLIBS)

.PHONY: mpfr
mpfr: $(CROSS)/lib/libmpfr.a
$(CROSS)/lib/libmpfr.a: $(SRC)/$(MPFR)/README
	rm -rf $(TMP)/$(MPFR) ; mkdir $(TMP)/$(MPFR) ; cd $(TMP)/$(MPFR) ;\
		$(XPATH) $(SRC)/$(MPFR)/$(CFG) $(CFG_MPFR) &&\
		$(XMAKE) && $(MAKE) install-strip

CFG_MPC = $(CFG_CCLIBS) --with-mpfr=$(CROSS)

.PHONY: mpc
mpc: $(CROSS)/lib/libmpc.a
$(CROSS)/lib/libmpc.a: $(SRC)/$(MPC)/README
	rm -rf $(TMP)/$(MPC) ; mkdir $(TMP)/$(MPC) ; cd $(TMP)/$(MPC) ;\
		$(XPATH) $(SRC)/$(MPC)/$(CFG) $(CFG_MPC) &&\
		$(XMAKE) && $(MAKE) install-strip



CFG_WITHCCLIBS = --with-gmp=$(CROSS) --with-mpfr=$(CROSS) --with-mpc=$(CROSS)

CFG_BINUTILS = --target=$(TARGET) $(CFG_ARCH) $(CFG_CPU) $(CFG_WITHCCLIBS) \
				--with-sysroot=$(CROSS)/sysroot --with-native-system-header-dir=/include \
				--enable-lto --disable-multilib $(CFG_WITHCCLIBS)

.PHONY: binutils
binutils: $(CROSS)/bin/$(TLD)
$(CROSS)/bin/$(TLD): $(SRC)/$(BINUTILS)/README
	rm -rf $(TMP)/$(BINUTILS) ; mkdir $(TMP)/$(BINUTILS) ; cd $(TMP)/$(BINUTILS) ;\
		$(XPATH) $(SRC)/$(BINUTILS)/$(CFG) $(CFG_BINUTILS) &&\
		$(XMAKE) && $(MAKE) install-strip


CFG_GCC0 = $(CFG_BINUTILS) $(CFG_WITHCCLIBS) --disable-bootstrap \
			--disable-shared --disable-threads \
			--without-headers --with-newlib \
			--enable-languages="c"

.PHONY: gcc0
gcc0: $(CROSS)/bin/$(TCC)
$(CROSS)/bin/$(TCC): $(SRC)/$(GCC)/README
	rm -rf $(TMP)/$(GCC) ; mkdir $(TMP)/$(GCC) ; cd $(TMP)/$(GCC) ;\
		$(XPATH) $(SRC)/$(GCC)/$(CFG) $(CFG_GCC0)
	cd $(TMP)/$(GCC) ; $(XMAKE) all-gcc
	cd $(TMP)/$(GCC) ; $(XMAKE) install-gcc
	cd $(TMP)/$(GCC) ; $(XMAKE) all-target-libgcc
	cd $(TMP)/$(GCC) ; $(XMAKE) install-target-libgcc



.PHONY: gz
gz: $(GZ)/$(BINUTILS_GZ) $(GZ)/$(GCC_GZ) $(GZ)/$(GMP_GZ)

$(SRC)/%/README: $(GZ)/%.tar.gz
	cd $(SRC) ;  zcat $< | tar x && touch $@
$(SRC)/%/README: $(GZ)/%.tar.bz2
	cd $(SRC) ; bzcat $< | tar x && touch $@
$(SRC)/%/README: $(GZ)/%.tar.xz
	cd $(SRC) ; xzcat $< | tar x && touch $@

$(GZ)/$(GMP_GZ):
	$(WGET) -O $@ $(WGET) ftp://ftp.gmplib.org/pub/gmp/$(GMP_GZ)
$(GZ)/$(MPFR_GZ):
	$(WGET) -O $@ $(WGET) http://www.mpfr.org/mpfr-current/$(MPFR_GZ)
$(GZ)/$(MPC_GZ):
	$(WGET) -O $@ $(WGET) https://ftp.gnu.org/gnu/mpc/$(MPC_GZ)
$(GZ)/$(BINUTILS_GZ):
	$(WGET) -O $@ $(WGET) http://ftp.gnu.org/gnu/binutils/$(BINUTILS_GZ)
$(GZ)/$(GCC_GZ):
	$(WGET) -O $@ $(WGET) http://mirror.linux-ia64.org/gnu/gcc/releases/$(GCC)/$(GCC_GZ)



.PHONY: debian
debian:
	sudo apt update
	sudo apt install -u `cat apt.txt`



MERGE  = Makefile README.md .gitignore .vscode apt.txt
MERGE += src
MERGE += hw cpu arch firmware

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
