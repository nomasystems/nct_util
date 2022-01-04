%%% Copyright 2022 Nomasystems, S.L. http://www.nomasystems.com
%%
%% Licensed under the Apache License, Version 2.0 (the "License");
%% you may not use this file except in compliance with the License.
%% You may obtain a copy of the License at
%%
%%     http://www.apache.org/licenses/LICENSE-2.0
%%
%% Unless required by applicable law or agreed to in writing, software
%% distributed under the License is distributed on an "AS IS" BASIS,
%% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
%% See the License for the specific language governing permissions and
%% limitations under the License.
-module(nct_util).

%%% SETUP/TEARDOWN SUITE EXPORTS
-export([
    setup_suite/1,
    teardown_suite/1
]).

-export([
    end_traces/1,
    init_traces/1
]).

%%% MACROS
-define(MATCH_SPEC, [{'_', [], [{message, {return_trace}}]}]).

%%%-----------------------------------------------------------------------------
%%% SETUP/TEARDOWN SUITE EXPORTS
%%%-----------------------------------------------------------------------------
setup_suite(Conf) ->
    dbg:tracer(),
    dbg:p(all, [c, sos, sol]),
    Apps = ct:get_config(apps, []),
    Env = ct:get_config(env, []),
    lists:foreach(fun(App) -> ok = application:load(App) end, Apps),
    ok = application:set_env(Env),
    Started =
        lists:foldl(
            fun(App, Acc) ->
                {ok, Deps} = application:ensure_all_started(App),
                Acc ++ Deps
            end,
            [],
            Apps
        ),
    [{started, Started} | Conf].

teardown_suite(Conf) ->
    Apps = ct:get_config(apps, []),
    Started = lists:reverse(proplists:get_value(started, Conf)),
    Running = lists:map(fun({App, _Desc, _Vsn}) -> App end, application:which_applications()),
    Loaded = lists:map(fun({App, _Desc, _Vsn}) -> App end, application:loaded_applications()),
    ToStop = intersect_lists(Running, Apps ++ Started),
    ToUnload = intersect_lists(Loaded, Apps ++ Started),
    lists:foreach(fun(App) -> ok = application:stop(App) end, ToStop),
    lists:foreach(fun(App) -> ok = application:unload(App) end, ToUnload),
    dbg:stop(),
    ok.

%%%-----------------------------------------------------------------------------
%%% TRACING UTIL EXPORTS
%%%-----------------------------------------------------------------------------
end_traces(Case) ->
    TpCases = ct:get_config(tp_cases, []),
    Tps = proplists:get_value(Case, TpCases, []),
    lists:foreach(fun(Tp) -> del_trace(ctp, Tp) end, Tps),
    TplCases = ct:get_config(tpl_cases, []),
    Tpls = proplists:get_value(Case, TplCases, []),
    lists:foreach(fun(Tpl) -> del_trace(ctpl, Tpl) end, Tpls).

init_traces(Case) ->
    TpCases = ct:get_config(tp_cases, []),
    Tps = proplists:get_value(Case, TpCases, []),
    lists:foreach(fun(Tp) -> add_trace(tp, Tp) end, Tps),
    TplCases = ct:get_config(tpl_cases, []),
    Tpls = proplists:get_value(Case, TplCases, []),
    lists:foreach(fun(Tpl) -> add_trace(tpl, Tpl) end, Tpls).

%%%-----------------------------------------------------------------------------
%%% INTERNAL FUNCTIONS
%%%-----------------------------------------------------------------------------
add_trace(TpFun, {Mod, Fun, Spec}) ->
    dbg:TpFun(Mod, Fun, Spec);
add_trace(TpFun, {Mod, Fun}) ->
    dbg:TpFun(Mod, Fun, ?MATCH_SPEC);
add_trace(TpFun, Mod) ->
    dbg:TpFun(Mod, ?MATCH_SPEC).

del_trace(CtpFun, {Mod, Fun, _Spec}) ->
    dbg:CtpFun(Mod, Fun);
del_trace(CtpFun, {Mod, Fun}) ->
    dbg:CtpFun(Mod, Fun);
del_trace(CtpFun, Mod) ->
    dbg:CtpFun(Mod).

intersect_lists(List1, List2) ->
    sets:to_list(
        sets:intersection(
            sets:from_list(List1),
            sets:from_list(List2)
        )
    ).
