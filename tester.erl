%Author: Tudor Dragan

-module(tester).
-import(facein,[start/1,name/1,add_friend/2,friends/1,broadcast/3,received_messages/1]).
-include_lib("eunit/include/eunit.hrl").

% process start test
start_test() ->
	And = facein:start("Andrzej"),
	?_assert(facein:name(And) == "Andrzej").

% adding a friend test
add_friend_test()->
	And = facein:start("Andrzej"),
	Ken = facein:start("Ken"),
	facein:add_friend(Ken,And),
	facein:add_friend(And,Ken),
	[?_assert(facein:friends(And) == [{"Ken", Ken}]),
	 ?_assert(facein:friends(And) == [{"Andrzej", And}])].

% the BIG graph test 
broadcast_test()->
	And = facein:start("Andrzej"),
	Ken = facein:start("Ken"),
	Sus = facein:start("Susan"),
	Jes = facein:start("Jessica"),
	Jen = facein:start("Jen"),
	Ton = facein:start("Tony"),
	Ree = facein:start("Reed"),

	facein:add_friend(Ken,And),
	facein:add_friend(And,Ken),

	facein:add_friend(And,Sus),
	facein:add_friend(Sus,And),

	facein:add_friend(Jen,Sus),
	facein:add_friend(Sus,Jen),

	facein:add_friend(Jen,Jes),
	facein:add_friend(Jes,Jen),

	facein:add_friend(Sus,Jes),
	facein:add_friend(Sus,Ree),

	facein:add_friend(Ree,Jes),
	facein:add_friend(Ree,Ton),

	facein:add_friend(Jen,Ton),

	facein:friends(And),
	facein:friends(Ken),
	facein:friends(Sus),
	facein:friends(Jes),
	facein:friends(Jen),
	facein:friends(Ton),
	facein:friends(Ree), 

	facein:broadcast(Jes,"First message From Jes", 2),
	facein:broadcast(Ken,"Second message From Ken", 3),

	facein:received_messages(Ton),
	facein:received_messages(Sus),
	facein:received_messages(Ree),

	[?_assert(list:member({"Jessica","First message From Jes"}, facein:received_messages(Ton))),	

	 ?_assert(list:member({"Jessica","First message From Jes"}, facein:received_messages(Sus))),
	 ?_assert(list:member({"Ken","Second message From Ken"}, facein:received_messages(Sus))),
	 ?_assert(list:member({"Ken","Second message From Ken"}, facein:received_messages(Ree)))].

