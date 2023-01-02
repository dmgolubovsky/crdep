# The toplevel Makefile for the crdep project.

TOPDIRS=docker scripts kernel xtrafiles

all:	crdep

# Create the installable script.

crdep:	crdep-pre.sh crdep.shar 
	( cat crdep-pre.sh crdep.shar ; echo '}' ) > crdep
	chmod +x crdep

# Create the shell archive with all files to be installed.

crdep.shar: $(shell find $(TOPDIRS) -type f | grep -v ~$$ | grep -v .*\.swp$$ )
	shar -M -C xz $^ > crdep.shar

# Force update of all files even if the script is installed.

update:
	rm -f $(HOME)/.crdep/scripts/crdep-main.sh
	rm -f crdep.shar
	make crdep
	./crdep -c

