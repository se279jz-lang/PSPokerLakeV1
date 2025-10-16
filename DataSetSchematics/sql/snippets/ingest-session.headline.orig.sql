INSERT INTO Sessions (
    session_code, game_format, gametype, limit_type, stakes, currency,
    tablename, max_players, seats, buy_in, rake, starting_stack,
    start_time, end_time, xml_content
)
VALUES (
    @session_code, @game_format, @gametype, @limit_type, @stakes, @currency,
    @tablename, @max_players, @seats, @buy_in, @rake, @starting_stack,
    @start_time, @end_time, @xml_content
);

/*
✅ Outcome
You now have a faithful relational mirror of <session.general>.

No loss of fidelity.

No premature optimisation.

Full flexibility to decide later which attributes drive your tactical comparisons
*/