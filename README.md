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

####Request handling
