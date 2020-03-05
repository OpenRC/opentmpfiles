SRC-tmpfiles := \
	cli.c \
	main.c \

SRC-libtmpfiles.so := \
	set.c \

all: tmpfiles
tmpfiles: $(SRC-libtmpfiles.so:.c=.o) $(SRC-tmpfiles:.c=.o)
	$(LINK_CC)
.deps.c: $(SRC-libtmpfiles.so) $(SRC-tmpfiles)
