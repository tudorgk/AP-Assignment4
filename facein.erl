-module(facein).
-export([start/1,get_name/1]).

start(Person) -> spawn(fun () -> loop(dict:store(name, Person, dict:new())) end).

rpc(Pid,Request) ->
	Pid ! {self(), Request},
	receive
		{Pid, Response} -> Response
	end.	

get_name(Pid) ->
	rpc(Pid, get_name).

loop(PersonDatabase) ->
	receive
		{From, get_name} ->
			From ! {self(), dict:find(name, PersonDatabase)},
			loop(PersonDatabase);
		{From, Other} ->
			From ! {self(), {error, {Other}}},
			loop(PersonDatabase)
	end.