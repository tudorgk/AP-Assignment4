-module(facein).
-export([start/1,name/1,add_friend/2,friends/1]).



start(Person) -> spawn(fun () -> 
	loop(dict:store(friend_list,[],dict:store(name, Person, dict:new()))) end).

rpc(Pid,Request) ->
	Pid ! {self(), Request},
	receive
		{Pid, Response} -> Response
	end.	

% get the name of a Pid
name(Pid) ->
	rpc(Pid, get_name).

friends(P) ->
	rpc(P, get_friends).

% add a pid (F) to a pid's (P) firend list
add_friend(P,F) ->
	F ! {self(), get_name},
	receive
		{F, {ok,Name}} -> 
			P ! {self(),{add_friend,{Name,F}}},
			receive
				{P, ok} -> "friend added";
				{P, {error,Reason2}} -> Reason2
			end;
		{F, {error,Reason1}} -> Reason1
	end.



loop(PersonDatabase) ->
	receive
		{From, get_name} ->
			From ! {self(), dict:find(name, PersonDatabase)},
			loop(PersonDatabase);
		{From, get_friends} ->
			{ok, FriendList} = dict:find(friend_list, PersonDatabase), 
			From ! {self(), FriendList},
			loop(PersonDatabase);
		{From, {add_friend,{Name,F}}} ->
			{ok,FriendList} = dict:find(friend_list, PersonDatabase),
			NewFriendList = [{Name,F} | FriendList],
			NewPersonDatabase = dict:store(friend_list,NewFriendList, PersonDatabase),
			From ! {self(), ok},
			loop(NewPersonDatabase);
		{From, Other} ->
			From ! {self(), {error, {Other}}},
			loop(PersonDatabase)
	end.