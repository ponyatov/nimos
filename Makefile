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
ISL_VER = 0.16.1
# 0.18 autotools error
CLOOG_VER = 0.18.1
# GNU toolchain
BINUTILS_VER = 2.34
# 2.33.1
GCC_VER = 10.1.0
# 9.3.0
# bootloaders
SYSLINUX_VER = 6.03



CWD     = $(CURDIR)
MODULE  = $(notdir $(CWD))
OS     ?= $(shell uname -s)

NOW = $(shell date +%d%m%y)
REL = $(shell git rev-parse --short=4 HEAD)

WGET = wget -c --no-check-certificate



TCC = $(TARGET)-gcc
TLD = $(TARGET)-ld
TAS = $(TARGET)-as



TMP     = $(CWD)/tmp
SRC     = $(TMP)/src
GZ      = $(HOME)/gz
FWARE   = $(CWD)/firmware
CROSS   = $(CWD)/$(TARGET)
SYSROOT = $(CROSS)/sysroot

.PHONY: dirs
dirs:
	mkdir -p $(TMP) $(SRC) $(GZ) $(FWARE) $(CROSS) $(SYSROOT)

XPATH = PATH=$(CROSS)/bin:$(PATH)



.PHONY: all
all: hello
	./$(MODULE)

.PHONY: hello
hello: $(TMP)/multiboot.o
	nimble build

$(TMP)/%.o: src/%.S Makefile
	$(XPATH) $(TAS) -o $@ $<

src/multiboot.S:
	$(WGET) -O $@ https://github.com/dom96/nimkernel/raw/master/boot.s



GMP      = gmp-$(GMP_VER)
MPFR     = mpfr-$(MPFR_VER)
MPC      = mpc-$(MPC_VER)
ISL      = isl-$(ISL_VER)
CLOOG    = cloog-$(CLOOG_VER)
BINUTILS = binutils-$(BINUTILS_VER)
GCC      = gcc-$(GCC_VER)

GMP_GZ      = $(GMP).tar.xz
MPFR_GZ     = $(MPFR).tar.xz
MPC_GZ      = $(MPC).tar.gz
ISL_GZ		= $(ISL).tar.bz2
CLOOG_GZ    = $(CLOOG).tar.gz
BINUTILS_GZ = $(BINUTILS).tar.xz
GCC_GZ      = $(GCC).tar.xz

.PHONY: cross
cross: dirs gz cclibs binutils gcc0

CPU_NUM = $(shell grep processor /proc/cpuinfo|wc -l)

XMAKE = $(MAKE) -j$(CPU_NUM)

CFG = configure --disable-nls --prefix=$(CROSS)



.PHONY: cclibs
cclibs: gmp mpfr mpc isl cloog

CFG_CCLIBS = --disable-shared
CFG_GMP = $(CFG_CCLIBS)

.PHONY: gmp
gmp: $(CROSS)/lib/libgmp.a
$(CROSS)/lib/libgmp.a: $(SRC)/$(GMP)/README
	rm -rf $(TMP)/$(GMP) ; mkdir $(TMP)/$(GMP) ; cd $(TMP)/$(GMP) ;\
		$(XPATH) $(SRC)/$(GMP)/$(CFG) $(CFG_GMP) &&\
		$(XMAKE) && $(MAKE) install-strip
	rm -rf $(TMP)/$(GMP) $(SRC)/$(GMP)/* ; touch $@ $<

CFG_MPFR = $(CFG_CCLIBS)

.PHONY: mpfr
mpfr: $(CROSS)/lib/libmpfr.a
$(CROSS)/lib/libmpfr.a: $(SRC)/$(MPFR)/README
	rm -rf $(TMP)/$(MPFR) ; mkdir $(TMP)/$(MPFR) ; cd $(TMP)/$(MPFR) ;\
		$(XPATH) $(SRC)/$(MPFR)/$(CFG) $(CFG_MPFR) &&\
		$(XMAKE) && $(MAKE) install-strip
	rm -rf $(TMP)/$(MPFR) $(SRC)/$(MPFR)/* ; touch $@ $<

CFG_MPC = $(CFG_CCLIBS) --with-mpfr=$(CROSS)

.PHONY: mpc
mpc: $(CROSS)/lib/libmpc.a
$(CROSS)/lib/libmpc.a: $(SRC)/$(MPC)/README
	rm -rf $(TMP)/$(MPC) ; mkdir $(TMP)/$(MPC) ; cd $(TMP)/$(MPC) ;\
		$(XPATH) $(SRC)/$(MPC)/$(CFG) $(CFG_MPC) &&\
		$(XMAKE) && $(MAKE) install-strip
	rm -rf $(TMP)/$(MPC) $(SRC)/$(MPC)/* ; touch $@ $<


CFG_ISL = $(CFG_CCLIBS)

.PHONY: isl
isl: $(CROSS)/lib/libisl.a
$(CROSS)/lib/libisl.a: $(SRC)/$(ISL)/README
	rm -rf $(TMP)/$(ISL) ; mkdir $(TMP)/$(ISL) ; cd $(TMP)/$(ISL) ;\
		$(XPATH) $(SRC)/$(ISL)/$(CFG) $(CFG_ISL) &&\
		$(XMAKE) && $(MAKE) install-strip
	rm -rf $(TMP)/$(ISL) $(SRC)/$(ISL)/* ; touch $@ $<

CFG_CLOOG = $(CFG_CCLIBS)

.PHONY: cloog
cloog: $(CROSS)/lib/libcloog.a
$(CROSS)/lib/libcloog.a: $(SRC)/$(CLOOG)/README
	rm -rf $(TMP)/$(CLOOG) ; mkdir $(TMP)/$(CLOOG) ; cd $(TMP)/$(CLOOG) ;\
		$(XPATH) $(SRC)/$(CLOOG)/$(CFG) $(CFG_CLOOG) &&\
		$(XMAKE) && $(MAKE) install-strip
	rm -rf $(TMP)/$(CLOOG) $(SRC)/$(CLOOG)/* ; touch $@ $<



CFG_WITHCCLIBS = --with-gmp=$(CROSS) --with-mpfr=$(CROSS) --with-mpc=$(CROSS) \
				--with-isl=$(CROSS) --with-cloog=$(CROSS)

CFG_BINUTILS = --target=$(TARGET) $(CFG_ARCH) $(CFG_CPU) $(CFG_WITHCCLIBS) \
				--with-sysroot=$(SYSROOT) --with-native-system-header-dir=/include \
				--enable-lto --disable-multilib $(CFG_WITHCCLIBS)

.PHONY: binutils
binutils: $(CROSS)/bin/$(TLD)
$(CROSS)/bin/$(TLD): $(SRC)/$(BINUTILS)/README $(CROSS)/lib/libisl.a
	rm -rf $(TMP)/$(BINUTILS) ; mkdir $(TMP)/$(BINUTILS) ; cd $(TMP)/$(BINUTILS) ;\
		$(XPATH) $(SRC)/$(BINUTILS)/$(CFG) $(CFG_BINUTILS) &&\
		$(XMAKE) && $(MAKE) install-strip
	rm -rf $(TMP)/$(BINUTILS) $(SRC)/$(BINUTILS)/* ; touch $@ $<


CFG_GCC0 = $(CFG_BINUTILS) $(CFG_WITHCCLIBS) --disable-bootstrap \
			--disable-shared --disable-threads \
			--without-headers --with-newlib \
			--enable-languages="c"

.PHONY: gcc0
gcc0: $(CROSS)/bin/$(TCC)
$(CROSS)/bin/$(TCC): $(SRC)/$(GCC)/README $(CROSS)/lib/libisl.a $(CROSS)/lib/libisl.a
	rm -rf $(TMP)/$(GCC) ; mkdir $(TMP)/$(GCC) ; cd $(TMP)/$(GCC) ;\
		$(XPATH) $(SRC)/$(GCC)/$(CFG) $(CFG_GCC0)
	cd $(TMP)/$(GCC) ; $(XMAKE) all-gcc
	cd $(TMP)/$(GCC) ; $(XMAKE) install-gcc
	cd $(TMP)/$(GCC) ; $(XMAKE) all-target-libgcc
	cd $(TMP)/$(GCC) ; $(XMAKE) install-target-libgcc
	rm -rf $(TMP)/$(GCC) $(SRC)/$(GCC)/* ; touch $@ $<



.PHONY: gz
gz: $(GZ)/$(GMP_GZ) $(GZ)/$(MPFR_GZ) $(GZ)/$(MPC_GZ)	\
	$(GZ)/$(ISL_GZ) $(GZ)/$(CLOOG_GZ)					\
	$(GZ)/$(BINUTILS_GZ) $(GZ)/$(GCC_GZ)

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
$(GZ)/$(ISL_GZ):
	$(WGET) -O $@ $(WGET) ftp://gcc.gnu.org/pub/gcc/infrastructure/$(ISL_GZ)
$(GZ)/$(CLOOG_GZ):
	$(WGET) -O $@ $(WGET) ftp://gcc.gnu.org/pub/gcc/infrastructure/$(CLOOG_GZ)
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
