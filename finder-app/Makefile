DIR=

ifeq ($(CROSS_COMPILE), aarch64-linux-gnu-)
	CC=aarch64-linux-gnu-gcc
else
	CC=gcc
endif


.phony:	clean
.phony:	all

all:
	$(CC) -o $(DIR)writer $(DIR)writer.c

clean:
	rm $(DIR)writer 