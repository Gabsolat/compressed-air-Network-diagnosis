% =====================================================================
% server.pl -- HTTP interface for deployment (Render). Reasoning stays in
% Prolog; pages are rendered by web.pl.
%   GET /            input form (optionally prefilled)
%   GET /diagnose    diagnosis of the readings submitted from the form
%   GET /cases       list of built-in test cases
%   GET /demo?id=c001  (or /demo/c001)  diagnosis of one test case
%   GET /results     full evaluation report
%   GET /health      health check
% =====================================================================
:- use_module(library(http/thread_httpd)).
:- use_module(library(http/http_dispatch)).
:- [main, web].

% static assets (style.css, app.js) live in ./static next to this file
:- prolog_load_context(directory, Dir), atom_concat(Dir, '/static', S),
   asserta(user:file_search_path(krr_static, S)).

:- http_handler(root(.),        home_h,     []).
:- http_handler(root(diagnose), diagnose_h, []).
:- http_handler(root(cases),    cases_h,    []).
:- http_handler(root(demo),     demo_h,     [prefix]).
:- http_handler(root(results),  results_h,  [time_limit(infinite)]).
:- http_handler(root(health),   health,     []).
:- http_handler(root(static),   serve_files_in_directory(krr_static), [prefix]).

% the reasoner keeps per-case state in dynamic predicates, so serialise requests
safely(Goal) :- catch(with_mutex(krr, Goal), E, (print_message(error, E))).

home_h(Request)     :- safely(form_for_request(Request)).
diagnose_h(Request) :- safely(diagnose_request(Request)).
cases_h(_)          :- safely(cases_page).
results_h(_)        :- safely(results_page).
health(_)           :- format("Content-Type: text/plain~n~nok~n").

demo_h(Request) :-
    (  request_id(Request, Id) -> true ; Id = none ),
    safely(render_case(Id)).

request_id(Request, Id) :- memberchk(search(S), Request), memberchk(id=Id0, S), Id0 \== '', !, atom_string(Id, Id0).
request_id(Request, Id) :- memberchk(path_info(PI), Request), sub_atom(PI, 1, _, 0, Id0), Id0 \== '', !, atom_string(Id, Id0).

start :-
    (  getenv('PORT', A), atom_number(A, Port) -> true ; Port = 10000 ),
    http_server(http_dispatch, [port(Port)]),
    format(user_error, "KRR31 listening on port ~w~n", [Port]),
    thread_get_message(never_arrives).

:- initialization(start, main).
