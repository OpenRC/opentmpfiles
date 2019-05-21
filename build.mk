# Compile flags for building the project.
DEFAULT_FLAGS = -O2 -g
COMMON_FLAGS = -Wall -fvisibility=hidden -fdiagnostics-color=auto
CFLAGS ?= $(DEFAULT_FLAGS)
CFLAGS += $(COMMON_FLAGS) -std=c11
CXXFLAGS ?= $(DEFAULT_FLAGS)
CXXFLAGS += $(COMMON_FLAGS) -std=c++14
CPPFLAGS += -Isrc -D_ISOC11_SOURCE -D_POSIX_C_SOURCE=201401L
LDFLAGS += -L.

# Generic compiler invocation settings.
DRIVER_CC = $(CC) $(CFLAGS)
DRIVER_CXX = $(CXX) $(CXXFLAGS)
COMPILE_CC = $(DRIVER_CC) $(CPPFLAGS) -c -o $@ $<
COMPILE_CXX = $(DRIVER_CXX) $(CPPFLAGS) -c -o $@ $<
LINK_CC = $(DRIVER_CC) $(LDFLAGS) $(LDFLAGS-$@) -o $@ $^ $(LDLIBS) $(LDLIBS-$@)
LINK_CXX = $(DRIVER_CXX) $(LDFLAGS) $(LDFLAGS-$@) -o $@ $^ $(LDLIBS) $(LDLIBS-$@)

# General pattern rules.
%.o: %.c ; $(COMPILE_CC)
%.o: %.cc ; $(COMPILE_CXX)
