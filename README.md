# nct_util
![nct_util](https://github.com/nomasystems/nct_util/actions/workflows/build.yml/badge.svg)

`nct_util` is an OTP library that provides utilities to orchestrate a Common Test SUITE. It automates several tasks like starting/stopping applications, loading env vars, and setting `dbg` traces via a Common Test config file.

## Installation

Add `nct_util` to your test dependencies.

```erl
%%% e.g., rebar.config
{profiles, [
    {test, [
        {deps, [
            {nct_util, {git, "git@github.com:nomasystems/nct_util.git", {tag, "1.0.0"}}}
        ]}
    ]}
]}.
```

## Usage

`nct_util` public API looks as follows:
- `setup_suite(Conf) -> Conf when Conf :: ct_suite:ct_config()`
- `teardown_suite(Conf) -> Conf when Conf :: ct_suite:ct_config()`
- `end_traces(Case) -> ok when Case :: ct_suite::ct_testname()`
- `init_traces(Case) -> ok when Case :: ct_suite::ct_testname()`

It has been designed to be invoked during suite/testcase init/end callbacks in a ct_suite. e.g.,
```erl
init_per_suite(Conf) ->
    nct_util:setup_suite(Conf).

end_per_suite(Conf) ->
    nct_util:teardown_suite(Conf).

init_per_testcase(Case, Conf) ->
    nct_util:init_traces(Case),
    Conf.

end_per_testcase(Case, Conf) ->
    nct_util:end_traces(Case),
    Conf.
```

## Configuration

The behavior of these functions is parameterized using the aforementioned Common Test configuration file. Within this file, `nct_util` recognizes four keys:

- `apps`: Its value is the list of applications `nct_util` will start and stop when invoking the `setup_suite/1` and `teardown_suite/1` functions, respectively.
- `env`: Its value will be set as `env` when invoking the `setup_suite/1` function.
- `tp_cases`: Its value is the list of `tp` call traces that `nct_util` will enable/disable when invoking the `init_traces/1` and `end_traces/1`, respectively.
- `tpl_cases`: Its value is the list of `tpl` call traces that `nct_util` will enable/disable when invoking the `init_traces/1` and `end_traces/1`, respectively.

This means `nct_util` recognizes the following syntax:
```erl
{apps, Apps}.
{env, Env}.
{tp_cases, TpCases}.
{tpl_cases, TplCases}.
```
where:
```erl
Apps = [App :: atom()]
Env = [{Par :: atom(), Val :: term()}]
TpCases = [{Case :: atom(), Traces :: [Trace]}].
TplCases = [{Case :: atom(), Traces :: [Trace]}].
Trace = Module | {Module, Function} | {Module, Function, MatchSpec}
Module = atom() | '_'
Function = atom() | '_'
```
> When no MatchSpec is specified, it defaults to `'_'`.

> For a definition of `MatchSpec`, check [dbg in Erlang docs](https://www.erlang.org/doc/man/dbg.html)

## Support

Any doubt or suggestion? Please, check out [our issue tracker](https://github.com/nomasystems/nct_util/issues).
