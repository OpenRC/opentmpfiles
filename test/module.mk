# The unittests.
LDFLAGS-tmpfiles_test = -pthread
LDLIBS-tmpfiles_test = -lgtest
SRC-tmpfiles_test := \
	set_test.cc \
	xfuncs_test.cc \

OBJ-tmpfiles_test := $(SRC-tmpfiles_test:.cc=.o)
tmpfiles_test: $(OBJ-tmpfiles_test) $(SRC-libtmpfiles.so:.c=.o)
	$(LINK_CXX)
.deps.cc: $(SRC-tmpfiles_test)

# Helper settings for local build of googletest in case the distro doesn't
# support system installs.  People can run `make gtest`.
GTEST_VER := 1.8.1
GTEST := test/googletest-release-$(GTEST_VER)
GTEST_TAR := $(GTEST).tar.gz
.PHONY: gtest
gtest: libgtest.a
libgtest.a: $(GTEST)/gtest-all.o $(GTEST)/gtest_main.o
	$(AR) rc $@ $^
$(GTEST)/gtest-all.o: $(GTEST_TAR)
	$(CXX) $(CXXFLAGS) $(CPPFLAGS) -pthread \
		-isystem $(GTEST)/googletest/include/ -I$(GTEST)/googletest/ \
		$(GTEST)/googletest/src/gtest-all.cc -c -o $@
$(GTEST)/gtest_main.o: $(GTEST_TAR)
	$(CXX) $(CXXFLAGS) $(CPPFLAGS) -pthread \
		-isystem $(GTEST)/googletest/include/ -I$(GTEST)/googletest/ \
		$(GTEST)/googletest/src/gtest_main.cc -c -o $@
$(GTEST_TAR):
	wget -nv \
		"https://github.com/google/googletest/archive/release-${GTEST_VER}.tar.gz" \
		-O "$(GTEST_TAR).tmp" && \
		mv "$(GTEST_TAR).tmp" "$(GTEST_TAR)"
	tar -zxf "$(GTEST_TAR)" -C test

$(OBJ-tmpfiles_test): CPPFLAGS += -I$(GTEST)/googletest/include
