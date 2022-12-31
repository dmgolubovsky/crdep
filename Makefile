# The toplevel Makefile for the crdep project.

TOPDIRS=docker scripts kernel xtrafiles

all:	crdep 

crdep:	crdep-pre.sh crdep.shar 
	( cat crdep-pre.sh crdep.shar ; echo '}' ) > crdep
	chmod +x crdep

crdep.shar: $(shell find $(TOPDIRS) | grep -v '~' )
	shar -M -C xz docker/* kernel/* scripts/* xtrafiles/* > crdep.shar


