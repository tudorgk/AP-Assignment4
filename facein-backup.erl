-module(facein).
-export([start/1,name/1,add_friend/2,friends/1,broadcast/3]).



start(Person) -> spawn(fun () -> 
	loop(dict:store(messages,dict:new(),
		 dict:store(friend_list,[],
		 dict:store(name, Person, 
		 dict:new())))) end).

rpc(Pid,Request) ->
	Pid ! {self(), Request},
	receive
		{Pid, Response} -> Response
	end.

rpc_no_response(Pid,Request) ->
	Pid ! {self(), Request}.

% get the name of a Pid
name(Pid) ->
	rpc(Pid, get_name).

%get friend list
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

%broadcast a message (M) to all of (P) friends within radius (R)
broadcast(P, M, R) ->
	MessageRef = make_ref(),
	rpc_no_response(P, {broadcast_msg, {P,MessageRef, M, R}}).

received_messages(P) ->
	rpc(P, get_messages).

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
		{From, {broadcast_msg, MessagePackage}} ->
			{P, MessageRef, M, R} = MessagePackage,
			MessageDict = dict:find(messages,PersonDatabase),
			%first chcek the radius for resending
			case R>0 of
				true -> 	
					% {ok, FriendList} = dict:find(friend_list, PersonDatabase),
					% map(fun({FriendName,Pid}) -> Pid ! {self(), {broadcast_msg, {P,MessageRef, M, R-1}}}  end, FriendList),
					 true;
				%send to friends with (R-1)

				false -> false
				%stop sending
			end,

			%then check if the message is already in the list to stop resending it
			case dict:is_key(MessageRef, MessageDict) of
				false ->
					From ! {self(), ok},
					NewMessageDict = dict:store(MessageRef, {P, M}, MessageDict),
					loop(dict:store(messages, NewMessageDict, PersonDatabase));
				true ->
					From ! {self(), {error, MessageRef, is_already_there}},
					loop(PersonDatabase)
			end;
			{From, get_friends} ->
				{ok, MessageList} = dict:find(messages, PersonDatabase), 
				From ! {self(), MessageList},
				loop(PersonDatabase);
		{From, Other} ->
			From ! {self(), {error, {Other}}},
			loop(PersonDatabase)
	end.