binprogs = tmpfiles
bindir = /bin
binmode = 0755
install = install

all:

install:
	$(install) -d $(DESTDIR)$(bindir)
	$(install) -m $(binmode) $(binprogs) $(DESTDIR)$(bindir)
