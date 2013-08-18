%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% @author Josh Adams <josh@isotope11.com> %%%
%%% @copyright (c) 2013, Josh Adams         %%%
%%% @doc                                    %%%
%%% @end                                    %%%
%%%                                         %%%
%%% Created 2013-08-17 by Josh Adams        %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-module(chatserver).
-behaviour(gen_server).

%%% API
-export([start_link/0, join/2, nicklist/1, part/1]).

%%% gen_server callbacks
-export([init/1, handle_call/3, handle_info/2, handle_cast/2,
                 terminate/2, code_change/3]).

-include_lib("chatserver_records.hrl").

-ifdef(TEST).
-include_lib("eunit/include/eunit.hrl").
-endif.

%%%%%%%%%%%%%%%%%%
%%% Client API %%%
%%%%%%%%%%%%%%%%%%
start_link() ->
    gen_server:start_link(?MODULE, #state{}, []).

join(Pid, Username) ->
    gen_server:call(Pid, {join, Username}).

nicklist(Pid) ->
    gen_server:call(Pid, nicklist).

part(Pid) ->
    gen_server:call(Pid, part).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% gen_server callbacks %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%
init(State) -> {ok, State}. %% no treatment of info here!

handle_call({join, Username}, From, #state{}=State) ->
    NewState = add_user(Username, From, State),
    {reply, ok, NewState};
handle_call(nicklist, _From, #state{}=State) ->
    {reply, list_usernames(State), State};
handle_call(part, From, #state{}=State) ->
    NewState = remove_user(From, State),
    {reply, ok, NewState};
handle_call({send, Message}, _From, #state{}=State) ->
    {reply, { ok, Message }, State}.

handle_cast(_Ref, _Request) ->
    io:format("No idea", []).

handle_info(Msg, State) ->
    io:format("Unexpected message: ~p~n",[Msg]),
    {noreply, State}.

terminate(normal, _State) ->
    io:format("terminating..."),
    ok.

code_change(_OldVsn, State, _Extra) ->
    %% Code changing is not presently supported.  This
    %% function exists to satisfy the behaviour.
    {ok, State}.

%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Internal functions %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%
list_usernames(State) ->
    MapToUsername = fun(X) ->
        X#user.username
    end,
    lists:map(MapToUsername, State#state.listeners).

add_user(Username, {FromPid, _Ref}, State) ->
    NewUser = #user{username=Username, pid=FromPid},
    State#state{listeners=[NewUser|State#state.listeners]}.

remove_user({FromPid, _Ref}, State) ->
    OldListeners = State#state.listeners,
    NewListeners = lists:filter(fun(User) -> User#user.pid =/= FromPid end, OldListeners),
    State#state{listeners=NewListeners}.
