% =====================================================================
% server.pl -- HTTP interface for deployment (Render). Reasoning stays in
% Prolog; pages are rendered by web.pl.
%   GET /            home page with case selector
%   GET /health      health check
%   GET /results     full evaluation report
%   GET /demo?id=c001  (or /demo/c001)  diagnosis page for one case
% =====================================================================
:- use_module(library(http/thread_httpd)).
:- use_module(library(http/http_dispatch)).
:- [main, web].

:- http_handler(root(.),       home_h,    []).
:- http_handler(root(health),  health,    []).
:- http_handler(root(results), results_h, [time_limit(infinite)]).
:- http_handler(root(demo),    demo_h,    [prefix]).

home_h(_)    :- with_mutex(krr, home_page).
health(_)    :- format("Content-Type: text/plain~n~nok~n").
results_h(_) :- catch(with_mutex(krr, results_page), E, (print_message(error, E))).

% the reasoner keeps per-case state in dynamic predicates, so serialise requests
demo_h(Request) :-
    (  request_id(Request, Id) -> true ; Id = none ),
    catch(with_mutex(krr, render_case(Id)), E, (print_message(error, E))).

request_id(Request, Id) :- memberchk(search(S), Request), memberchk(id=Id0, S), Id0 \== '', !, atom_string(Id, Id0).
request_id(Request, Id) :- memberchk(path_info(PI), Request), sub_atom(PI, 1, _, 0, Id0), Id0 \== '', !, atom_string(Id, Id0).

start :-
    (  getenv('PORT', A), atom_number(A, Port) -> true ; Port = 10000 ),
    http_server(http_dispatch, [port(Port)]),
    format(user_error, "KRR31 listening on port ~w~n", [Port]),
    thread_get_message(never_arrives).

:- initialization(start, main).
