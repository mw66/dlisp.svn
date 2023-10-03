
# DFLAGS="-Wno-deprecated" 
all:
	dub

old:
	ldmd2 dle.d  ./dlisp/*.d ./dlisp/predefs/*.d

clean:
	dub clean --all-packages
