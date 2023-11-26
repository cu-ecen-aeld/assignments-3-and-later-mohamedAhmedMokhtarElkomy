CC = gcc
file = writer.c

ifdef CROSS_COMPILER
	compile = $(CROSS_COMPILER)$(CC)
endif

default: writer.c 				#The prerequisites are also file names, separated by spaces. These files need to exist before the commands for the target are run. These are also called dependencies
	$(CC) $(file) -o writer

clean:
	# rm *.o
	rm writer