[AP-Assignment4](https://github.com/tudorgk/AP-Assignment4)
================

Communication On FaceIn - This assignment is about how parts of FaceIn could be implemented in Erlang (see also the Prolog assignment about FaceIn).


Implementation
--------------

####`start(N)` function
```erlang
start(Person) -> spawn(fun () -> 
	loop(dict:store(messageRefs,[],
		 dict:store(messages,[],
		 dict:store(friend_list,[],
		 dict:store(name, Person, 
		 dict:new()))))) end).
```
The `start` function spawns a new process that stores a database represented by a dictionary. The loop function is a blocking function that waits for requests from other processes. 

####`add_friend(P,F)` function
```erlang
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
```

The `add_friend` function gets the name of the `F` process to store it into the friend list. After it receives the response, it send a request to process `P` to add the name and PID to the freind list.

####`broadcast(P, M, R)` function
```erlang
%broadcast a message (M) to all of (P) friends within radius (R)
broadcast(P, M, R) ->
	MessageRef = make_ref(),
	{ok, Name} = name(P),
	rpc_no_response(P, {broadcast_msg, {Name,MessageRef, M, R}}).
```

The `broadcast` function creates a distinct message reference and passes to every connected friend,which in turn pass along until the radius `R` is 0.

###Request handling

The `get_friends`, `add_friends` are pretty straight forward, the first one gets the friend list from the dictionary, and the second one add a friend to the friend list. The database is updated by creating a new dictionary from the old one and recursively calling `loop` with the new dictionary.

The most important part is probably the `brodcast_msg` request. Every process receives apackage woth the process that sent the message, the message reference so that we don't add duplicates to the message list, the actual message string, and the TTL represented by the radius R.

We check that the radius `R` is greateer than 0. If it is, we pass the message on by submiting a request to all the friends from the process who received the message.
```erlang
case R > 0 of
				true -> 	
					%send to friends with (R-1)
					{ok, FriendList} = dict:find(friend_list, PersonDatabase),
					lists:map(fun({FriendName,Pid}) -> Pid ! {self(), {broadcast_msg, {P,MessageRef, M, R-1}}}  end, FriendList),
					true;

				false -> false
				%stop sending
			end,
```
After that we check if the message is already in the list. If it's not, we append the message to the message list and keep the reference as well in a separate list.
```erlang
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
```

Testing
-------

###Usage:

####1.
```bash
user:shell$ make test
```
####2.
```erlang
1> tester:test().
```

