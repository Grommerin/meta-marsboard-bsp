INCLUDEDIR = /usr/src/linux/include

CC = gcc
CFLAGS = -D__KERNEL__ -I$(INCLUDEDIR) -I. -DMODULE -Wall -Wstrict-prototypes -O2

OBJS = ussp.o



all: $(OBJS)


install: all
	@mkdir -p /lib/modules/`uname -r`/misc
	cp $(OBJS) /lib/modules/`uname -r`/misc
	depmod -e
	@sync

clean:
	rm -f $(OBJS)
	@sync
