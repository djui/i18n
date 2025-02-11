% vim: set filetype=erlang shiftwidth=4 tabstop=4 expandtab tw=80:

%%% =====================================================================
%%%   Copyright 2011 Uvarov Michael 
%%%
%%%   Licensed under the Apache License, Version 2.0 (the "License");
%%%   you may not use this file except in compliance with the License.
%%%   You may obtain a copy of the License at
%%%
%%%       http://www.apache.org/licenses/LICENSE-2.0
%%%
%%%   Unless required by applicable law or agreed to in writing, software
%%%   distributed under the License is distributed on an "AS IS" BASIS,
%%%   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
%%%   See the License for the specific language governing permissions and
%%%   limitations under the License.
%%%
%%% $Id$
%%%
%%% @copyright 2010-2011 Michael Uvarov
%%% @author Michael Uvarov <freeakk@gmail.com>
%%% =====================================================================

%%% @private
-module(i18n_regex_tests).
-include_lib("i18n/include/i18n.hrl").


-ifdef(TEST).
-include_lib("eunit/include/eunit.hrl").
-include_lib("triq/include/triq.hrl").

split_url_fun() ->
	Pattern = ?ISTR("\\."), % \\.\
	Re = i18n_regex:open(Pattern),
    fun(Url) ->
    	i18n_regex:split(Re, Url)
    end.

replace_fun() ->
	Pattern = ?ISTR("lang[^ ]*"),
	Do = ?ISTR("Erlang"),
	Re = i18n_regex:open(Pattern),

    fun(S) ->
    	i18n_regex:replace(Re, Do, S)
    end.

split_url_test_() ->
    F = split_url_fun(),

    [?_assertEqual(F(?ISTR("doc.erlang.org")), 
            [?ISTR("doc"), ?ISTR("erlang"), ?ISTR("org")])
    ].
	

replace_all_test_() ->
    F = replace_fun(),

    [?_assertEqual(F(?ISTR("Coding on this language for fun.")),
            ?ISTR("Coding on this Erlang for fun."))
    ].
    
-endif.
