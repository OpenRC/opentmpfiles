SRC-tmpfiles := \
	main.c \

SRC-libtmpfiles.so := \

all: tmpfiles
tmpfiles: $(SRC-libtmpfiles.so:.c=.o) $(SRC-tmpfiles:.c=.o)
	$(LINK_CC)
.deps.c: $(SRC-libtmpfiles.so) $(SRC-tmpfiles)
