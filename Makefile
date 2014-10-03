all: compile
	
compile:
	erlc +debug_info facein.erl
	erl facein.erl