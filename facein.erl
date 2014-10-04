-module(facein).
-export([start/1,name/1,add_friend/2,friends/1,broadcast/3,received_messages/1]).



start(Person) -> spawn(fun () -> 
	loop(dict:store(messageRefs,[],
		 dict:store(messages,[],
		 dict:store(friend_list,[],
		 dict:store(name, Person, 
		 dict:new()))))) end).

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
	{ok, Name} = name(P),
	rpc_no_response(P, {broadcast_msg, {Name,MessageRef, M, R}}).

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
			% io:format("MessageRef: ~p~n", [MessageRef]),
			{ok,MessageRefList} = dict:find(messageRefs,PersonDatabase),
			% io:format("MessageRef: ~p~n", [MessageRefList]),
			%first chcek the radius for resending
			case R > 0 of
				true -> 	
					%send to friends with (R-1)
					{ok, FriendList} = dict:find(friend_list, PersonDatabase),
					lists:map(fun({FriendName,Pid}) -> Pid ! {self(), {broadcast_msg, {P,MessageRef, M, R-1}}}  end, FriendList),
					true;

				false -> false
				%stop sending
			end,

			%then check if the message is already in the list to stop resending it
			case lists:member(MessageRef,MessageRefList) of
				false ->
					NewMessageListRef = [MessageRef | MessageRefList],
					{ok, MessageList} = dict:find(messages, PersonDatabase),
					NewMessageList = [{P,M} | MessageList],
					loop(dict:store(messageRefs,NewMessageListRef,
						 dict:store(messages, NewMessageList, PersonDatabase)));
				true ->
					loop(PersonDatabase)
			end;
			{From, get_messages} ->
				{ok, MessageList} = dict:find(messages, PersonDatabase), 
				% io:format("MessageList: ~p~n", MessageList),
				From ! {self(), MessageList},
				loop(PersonDatabase);
		{From, Other} ->
			From ! {self(), {error, {Other}}},
			loop(PersonDatabase)
	end.