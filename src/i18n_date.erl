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

-module(i18n_date).
-compile({no_auto_import,[now/0]}).

-include("i18n.hrl").
-export([now/0]).
-export([add/1, add/2, add/3]).
-export([difference/3, difference/4]).
-export([set/1, set/2, set/3]). 
-export([get/1, get/2, get/3]). 
-export([new/3, new/4, new/6, new/7]).
-export([roll/1, roll/2, roll/3]).
-export([clear/2, clear/3]).


-type resource() :: <<>>.   
-type i18n_calendar() :: resource().   

-type i18n_date_field() :: 
      era          
    | year         
    | month   
    | week_of_year
    | date    
    | day_of_year  
    | day_of_week  
    | am_pm        
    | hour    
    | hour_of_day 
    | minute       
    | second    
    | millisecond  
    | zone_offset  
    | dst_offset
    | day_of_week_in_month.
    
    
-type double() :: number().
-type i18n_date() :: double().
-type fields() :: [{i18n_date_field(), double()}].

%% @doc Return the timestamp 
%%		(count of milliseconds from starting of the 1970 year).

-spec now() -> i18n_date().
now() ->
	?TRY_NUM(?IM:date_now()).



%% @doc Append `double()' to the field value.

-spec add(fields()) -> i18n_date().

add(Fields) ->
    Cal = i18n_calendar:open(),
    Date = now(),
	add(Cal, Date, Fields).


-spec add(i18n_calendar() | i18n_date(), fields()) -> i18n_date().

add(Date, Fields)
    when is_number(Date) ->
    Cal = i18n_calendar:open(),
	add(Cal, Date, Fields);
add(Cal, Fields)
    when is_binary(Cal) ->
    Date = now(),
	add(Cal, Date, Fields).


-spec add(i18n_calendar(), i18n_date(), fields()) -> i18n_date().

add(Cal, Date, Fields) ->
	?TRY_NUM(?IM:date_add(Cal, Date, Fields)).




%% @doc This function and `add' function are same, but
%%      `roll' will not modify more significant fields in the calendar. 
-spec roll(fields()) -> i18n_date().

roll(Fields) ->
    Cal = i18n_calendar:open(),
    Date = now(),
	roll(Cal, Date, Fields).


-spec roll(i18n_calendar() | i18n_date(), fields()) -> i18n_date().

roll(Date, Fields)
    when is_number(Date) ->
    Cal = i18n_calendar:open(),
	roll(Cal, Date, Fields);
roll(Cal, Fields)
    when is_binary(Cal) ->
    Date = now(),
	roll(Cal, Date, Fields).


-spec roll(i18n_calendar(), i18n_date(), fields()) -> i18n_date().

roll(Cal, Date, Fields) ->
	?TRY_NUM(?IM:date_roll(Cal, Date, Fields)).





%% @doc Set the value of the field or fields for now().

-spec set(fields()) -> i18n_date().

set(Fields) ->
    Cal = i18n_calendar:open(),
    Date = now(),
	set(Cal, Date, Fields).



%% @doc Set the value of the field or fields for date.
-spec set(i18n_calendar() | i18n_date(), fields()) -> i18n_date().

set(Date, Fields)
    when is_number(Date) ->
    Cal = i18n_calendar:open(),
	set(Cal, Date, Fields);
set(Cal, Fields)
    when is_binary(Cal) ->
    Date = now(),
	set(Cal, Date, Fields).


%% @doc Set the value of the field or fields for date.
%%      Take a calendar as argument.
-spec set(i18n_calendar(), i18n_date(), fields()) -> i18n_date().

set(Cal, Date, Fields) 
    when is_list(Fields) ->
	?TRY_NUM(?IM:date_set(Cal, Date, Fields)).









%% @doc Get the value of the field or fields.

-spec get([i18n_date_field()] | i18n_date_field()) -> 
        [integer()] | integer().

get(Fields) ->
    Cal = i18n_calendar:open(),
    Date = now(),
	get(Cal, Date, Fields).


-spec get(i18n_calendar() | i18n_date(), 
         [i18n_date_field()] | i18n_date_field()) -> 
        [integer()] | integer().

get(Date, Fields)
    when is_number(Date) ->
    Cal = i18n_calendar:open(),
	get(Cal, Date, Fields);
get(Cal, Fields)
    when is_binary(Cal) ->
    Date = now(),
	get(Cal, Date, Fields).


-spec get(i18n_calendar(), i18n_date(), 
    [i18n_date_field()] | i18n_date_field()) -> 
        [integer()] | integer().

get(Cal, Date, Fields) 
    when is_list(Fields) ->
	?TRY_LIST(?IM:date_get_fields(Cal, Date, Fields));

get(Cal, Date, Field) 
    when is_atom(Field) ->
	?TRY_NUM(?IM:date_get_field(Cal, Date, Field)).







difference(FromDate, ToDate, Fields) ->
    Cal = i18n_calendar:open(),
    difference(Cal, FromDate, ToDate, Fields).


-spec difference(i18n_calendar(), i18n_date(), i18n_date(), 
    [i18n_date_field()] | i18n_date_field()) -> 
        [{i18n_date_field(), integer()}] | integer().

difference(Cal, FromDate, ToDate, Field) 
    when is_atom(Field) ->
	?TRY_NUM(?IM:date_diff_field(Cal, FromDate, ToDate, Field));

difference(Cal, FromDate, ToDate, Fields) 
    when is_list(Fields) ->
	?TRY_NUM(?IM:date_diff_fields(Cal, FromDate, ToDate, Fields)).







%% @doc Create date from fields' values (YMD).
-spec new(integer(), integer(), integer()) -> i18n_date().

new(Year, Month, Day) ->
    Cal = i18n_calendar:open(),
    ?TRY_NUM(?IM:date_get(Cal, Year, Month, Day)).


%% @doc Create date from fields' values (YMD).
-spec new(i18n_calendar(), integer(), integer(), integer()) -> i18n_date().

new(Cal, Year, Month, Day) ->
    ?TRY_NUM(?IM:date_get(Cal, Year, Month, Day)).


%% @doc Create date from fields' values (YMDHMS).
-spec new(integer(), integer(), integer(), integer(), 
            integer(), integer()) -> i18n_date().

new(Year, Month, Day, Hour, Minute, Second) ->
    Cal = i18n_calendar:open(),
    ?TRY_NUM(?IM:date_get(Cal, Year, Month, Day, Hour, Minute, Second)).


%% @doc Create date from fields' values (YMDHMS).
-spec new(i18n_calendar(), integer(), integer(), integer(), integer(), 
            integer(), integer()) -> i18n_date().

new(Cal, Year, Month, Day, Hour, Minute, Second) ->
    ?TRY_NUM(?IM:date_get(Cal, Year, Month, Day, Hour, Minute, Second)).


-spec clear(i18n_date(), [i18n_date_field()]) -> i18n_date().

%% @doc Clear the field value (values).
clear(Date, Fields)
    when is_number(Date) ->
    Cal = i18n_calendar:open(),
	clear(Cal, Date, Fields).


%% @doc Clear the field value (values).
-spec clear(i18n_calendar(), i18n_date(), [i18n_date_field()]) -> i18n_date().

clear(Cal, Date, Fields) ->
	?TRY_NUM(?IM:date_clear(Cal, Date, Fields)).

