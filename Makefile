all: compile
	
compile:
	erlc +debug_info facein.erl
	erl facein.erl

test:
	erlc +debug_info tester.erl
	erl tester.erl