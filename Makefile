# Disable implicit rules.  We'll specify everything.
MAKEFLAGS += -r
.SUFFIXES:

binprogs = tmpfiles
bindir = /bin
binmode = 0755
install = install

# Clear the default source file search path.  We'll add subdirs below.
VPATH :=

# This has to come first to define the default target.
all:

# The build machinery.
include ./build.mk

# Include generated dependencies.
-include ./.deps.c
-include ./.deps.cc
.deps.c:
	$(DRIVER_CC) $(CPPFLAGS) -MM $^ >$@
.deps.cc:
	$(DRIVER_CXX) $(CPPFLAGS) -MM $^ >$@

# The main program.
VPATH += src
include ./src/module.mk

# The tests.
VPATH += test
include ./test/module.mk
check: tmpfiles_test
	./tmpfiles_test

install:
	$(install) -d $(DESTDIR)$(bindir)
	$(install) -m $(binmode) $(binprogs) $(binprogs).sh $(DESTDIR)$(bindir)

clean:
	rm -f tmpfiles tmpfiles_test *.o

.PHONY: all check clean install
