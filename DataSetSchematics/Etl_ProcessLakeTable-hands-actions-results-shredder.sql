-- Inside the WHILE loop, after inserting Session and Players

-- Insert Hands
INSERT INTO dbo.Hands (session_id, hand_number, pot_size)
OUTPUT inserted.hand_id, h.value('@id','BIGINT')
INTO #HandMap(hand_id, hand_number)
SELECT @session_id,
       h.value('@id','BIGINT'),
       h.value('@pot','DECIMAL(18,2)')
FROM @Xml.nodes('/session/hands/hand') AS t(h)
WHERE NOT EXISTS (
    SELECT 1 FROM dbo.Hands hh
    WHERE hh.session_id = @session_id
      AND hh.hand_number = h.value('@id','BIGINT')
);

-- Insert Actions
INSERT INTO dbo.Actions (hand_id, player_id, street, action_type, amount, action_order)
SELECT hm.hand_id,
       p.player_id,
       a.value('@street','VARCHAR(20)'),
       a.value('@type','VARCHAR(20)'),
       a.value('@amount','DECIMAL(18,2)'),
       ROW_NUMBER() OVER (PARTITION BY hm.hand_id ORDER BY a.value('@order','INT'))
FROM @Xml.nodes('/session/hands/hand') AS t(h)
JOIN #HandMap hm ON hm.hand_number = h.value('@id','BIGINT')
CROSS APPLY h.nodes('actions/action') AS act(a)
JOIN dbo.Players p
  ON p.session_id = @session_id
 AND p.player_name = a.value('@player','NVARCHAR(100)');

-- Insert Results
INSERT INTO dbo.Results (hand_id, player_id, hand_rank, is_winner, winnings)
SELECT hm.hand_id,
       p.player_id,
       r.value('@handrank','VARCHAR(50)'),
       CASE r.value('@winner','VARCHAR(5)') WHEN 'true' THEN 1 ELSE 0 END,
       r.value('@winnings','DECIMAL(18,2)')
FROM @Xml.nodes('/session/hands/hand') AS t(h)
JOIN #HandMap hm ON hm.hand_number = h.value('@id','BIGINT')
CROSS APPLY h.nodes('results/result') AS res(r)
JOIN dbo.Players p
  ON p.session_id = @session_id
 AND p.player_name = r.value('@player','NVARCHAR(100)');


/*
his completes the end‑to‑end ETL: XML → Lake staging → Sessions/Players → Hands/Actions/Results → Global identity.*/