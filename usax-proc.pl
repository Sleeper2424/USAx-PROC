%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% USAx-PROC v1.0 — Full Constitutional Adjudication Engine
%% Frozen Snapshot
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% CORE ENTITIES
%%%%%%%%%%%%%%%%%%%%%%%%%%%%

government(federal).
government(state).

court(supreme_court).
court(circuit_court(C)).
court(district_court(D)).

higher(supreme_court, circuit_court(_)).
higher(circuit_court(_), district_court(_)).

actor(government).
actor(challenger).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% CASE BASICS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%

case(C).
law_at_issue(C, L).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% JURISDICTION GATES
%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Standing
standing(P, C) :-
    injury(P, C),
    causation(P, C),
    redressable(P, C).

% Mootness
moot(C) :-
    issue_resolved(C).

moot(C) :-
    challenged_law_repealed(C),
    \+ collateral_consequences(C).

% Ripeness
ripe(C) :-
    fitness_for_judicial_review(C),
    present_hardship(C).

unripe(C) :-
    future_contingency(C),
    \+ present_hardship(C).

% Political Question
political_question(C) :-
    issue(C, I),
    textually_committed(I, _).

political_question(C) :-
    issue(C, I),
    lack_judicially_manageable_standards(I).

% Justiciability
justiciable(C) :-
    standing(_, C),
    \+ moot(C),
    ripe(C),
    \+ political_question(C),
    challenge_scope(C).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% SCOPE (FACIAL / AS-APPLIED)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%

facial_challenge(C).
as_applied_challenge(C).

challenge_scope(C) :-
    facial_challenge(C),
    \+ as_applied_challenge(C).

challenge_scope(C) :-
    as_applied_challenge(C),
    \+ facial_challenge(C).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% RIGHTS & SCRUTINY
%%%%%%%%%%%%%%%%%%%%%%%%%%%%

scrutiny_level(speech, strict).
scrutiny_level(religion, strict).
scrutiny_level(race, strict).
scrutiny_level(sex, intermediate).
scrutiny_level(economic, rational).

scrutiny_level(R, rational) :-
    \+ scrutiny_level(R, strict),
    \+ scrutiny_level(R, intermediate).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% PRESUMPTIONS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%

presumed(L, constitutional) :-
    law_affects_right(L, R),
    scrutiny_level(R, rational).

presumed(L, unconstitutional) :-
    law_affects_right(L, R),
    scrutiny_level(R, strict).

presumed(L, unconstitutional) :-
    law_affects_right(L, R),
    scrutiny_level(R, intermediate).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% BURDENS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%

burden(challenger, irrational(L)) :-
    presumed(L, constitutional).

burden(government, strict_test(L, I)) :-
    presumed(L, unconstitutional),
    law_affects_right(L, R),
    scrutiny_level(R, strict),
    government_interest(L, I).

burden(government, intermediate_test(L, I)) :-
    presumed(L, unconstitutional),
    law_affects_right(L, R),
    scrutiny_level(R, intermediate),
    government_interest(L, I).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% BURDEN SATISFACTION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%

burden_met(government, strict_test(L, I)) :-
    compelling_interest(I),
    narrowly_tailored(L, I).

burden_met(government, intermediate_test(L, I)) :-
    important_interest(I),
    substantially_related(L, I).

burden_met(challenger, irrational(L)) :-
    \+ rationally_related(L, _).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% CONSTITUTIONAL OUTCOMES
%%%%%%%%%%%%%%%%%%%%%%%%%%%%

constitutional(L) :-
    case(C),
    law_at_issue(C, L),
    justiciable(C),
    presumed(L, constitutional),
    \+ burden_met(challenger, irrational(L)).

unconstitutional(L) :-
    case(C),
    law_at_issue(C, L),
    justiciable(C),
    presumed(L, constitutional),
    burden_met(challenger, irrational(L)).

unconstitutional(L) :-
    case(C),
    law_at_issue(C, L),
    justiciable(C),
    presumed(L, unconstitutional),
    \+ burden_met(government, _).

constitutional(L) :-
    case(C),
    law_at_issue(C, L),
    justiciable(C),
    presumed(L, unconstitutional),
    burden_met(government, _).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% OVERBREADTH
%%%%%%%%%%%%%%%%%%%%%%%%%%%%

overbreadth_doctrine_applies(L) :-
    law_affects_right(L, speech).

overbroad(L) :-
    overbreadth_doctrine_applies(L),
    substantial_overbreadth(L).

unconstitutional(L) :-
    overbroad(L).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% VAGUENESS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%

vague(L) :-
    \+ fair_notice(L).

vague(L) :-
    arbitrary_enforcement_risk(L).

unconstitutional(L) :-
    vague(L).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% SEVERABILITY
%%%%%%%%%%%%%%%%%%%%%%%%%%%%

statute(L).
provision(L, P).

severable(L) :-
    statute(L),
    \+ inseverable(L).

invalid_provision(P) :-
    violates_provision(P).

invalid_provision(P2) :-
    invalid_provision(P1),
    dependent(P2, P1).

valid_provision(P) :-
    provision(_, P),
    \+ invalid_provision(P).

invalidate_entire_statute(L) :-
    inseverable(L).

invalidate_entire_statute(L) :-
    statute(L),
    \+ valid_provision(_).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% PRECEDENT
%%%%%%%%%%%%%%%%%%%%%%%%%%%%

decided_case(Case).
deciding_court(Case, Court).
holding(Case, Proposition).
overruled(Case).

binding_precedent(Case, TargetCourt) :-
    decided_case(Case),
    deciding_court(Case, Court1),
    higher(Court1, TargetCourt),
    \+ overruled(Case).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% CHEVRON / SKIDMORE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%

chevron_applicable(Reg) :-
    ambiguous(Statute),
    interprets(Reg, Statute),
    delegated_authority(Statute, _),
    reasonable(Reg),
    \+ major_question(Reg).

skidmore_applicable(Reg) :-
    \+ chevron_applicable(Reg),
    persuasive(Reg).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% QUALIFIED IMMUNITY
%%%%%%%%%%%%%%%%%%%%%%%%%%%%

qualified_immunity_applies(Officer, Case) :-
    official(Officer),
    individual_capacity(Officer),
    constitutional_violation(Case),
    \+ clearly_established(_, _, _).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% RETROACTIVITY
%%%%%%%%%%%%%%%%%%%%%%%%%%%%

apply_rule(Rule, Case) :-
    new_rule(Rule),
    direct_review(Case).

apply_rule(Rule, Case) :-
    new_rule(Rule),
    substantive_rule(Rule),
    collateral_review(Case).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% REMEDIES
%%%%%%%%%%%%%%%%%%%%%%%%%%%%

remedy(invalidate(L)) :-
    unconstitutional(L),
    invalidate_entire_statute(L).

remedy(sever(P)) :-
    invalid_provision(P).

remedy(injunction(L)) :-
    unconstitutional(L).

remedy(damages(Officer)) :-
    \+ qualified_immunity_applies(Officer, _).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% END USAx-PROC v1.0
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
