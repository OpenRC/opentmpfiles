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

install:
	$(install) -d $(DESTDIR)$(bindir)
	$(install) -m $(binmode) $(binprogs).sh $(DESTDIR)$(bindir)/$(binprogs)

clean:
	rm -f *.o

.PHONY: all clean install
