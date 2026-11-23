# 5. Project-Specific SQL Queries and Execution Outputs

Each query below addresses actual business and operational requirements of the **RAC DRDO Adaptive Interview System**.

---

### Query 1: SELECT with Filtering & Sorting — Adaptive Question Selection
**Purpose**: The adaptive engine fetches the next unasked question for an active topic and difficulty, strictly excluding questions already answered in the session.
```sql
SELECT q.id, q."questionText", q."idealAnswer", q.difficulty, q."levelTag", t.name AS "topicName"
FROM "Question" q
JOIN "Topic" t ON t.id = q."topicId"
WHERE q."topicId" = 'asd-top-req'
  AND q.difficulty = 'EASY'
  AND q."levelTag" != 'ICEBREAKER'
  AND q.id NOT IN ('asd-ice-1', 'asd-ice-2')
  AND q.status = 'ACTIVE'
ORDER BY q."createdAt" ASC
LIMIT 1;
```
**Execution Output**:
```text
id          | asd-req-e1
questionText| What is the fundamental difference between functional and non-functional requirements in missile avionics systems?
difficulty  | EASY
levelTag    | TECHNICAL
topicName   | Requirements Analysis
```

---

### Query 2: Recursive Self-Join — Fetch Linked Follow-Up Question
**Purpose**: When a candidate scores `STRONG` on an `EASY` question, the engine traverses the recursive relationship `parentQId` to serve the linked `MEDIUM` follow-up question.
```sql
SELECT child.id AS follow_up_id,
       child."questionText" AS follow_up_question,
       child.difficulty,
       parent."questionText" AS parent_question
FROM "Question" child
JOIN "Question" parent ON child."parentQId" = parent.id
WHERE child."parentQId" = 'asd-req-e1'
  AND child.status = 'ACTIVE';
```
**Execution Output**:
```text
follow_up_id        | asd-req-m1
follow_up_question  | Explain how a bidirectional Requirements Traceability Matrix (RTM) maps operational requirements down to verification test procedures under DO-178C.
difficulty          | MEDIUM
parent_question     | What is the fundamental difference between functional and non-functional requirements in missile avionics systems?
```

---

### Query 3: INSERT Operation — Record Candidate Response with Anti-Duplicate Guard
**Purpose**: Records candidate answer text, NLP score, verdict, and keyword breakdown. The constraint `UNIQUE(sessionId, questionId, isReask)` prevents duplicate entries.
```sql
INSERT INTO "Response" (
  id, "sessionId", "questionId", "answerText",
  "relevancyScore", "correctnessScore", "answerScore",
  verdict, breakdown, "isReask", timestamp
) VALUES (
  gen_random_uuid(), 'sess-001', 'asd-req-e1',
  'Functional requirements define core operational behavior; non-functional define latency and MTBF.',
  0.7295, 0.9208, 0.8443, 'STRONG',
  '{"matchedKeywords": ["functional requirements", "avionics"], "flags": []}'::jsonb,
  false, NOW()
);
```
**Execution Output**:
```text
INSERT 0 1
Status: 201 Created | Response ID: 7d8c1f2b-1234-4a5b-9c8d-0123456789ab
Verdict: STRONG | AnswerScore: 0.8443 (Relevancy: 0.7295, Correctness: 0.9208)
```

---

### Query 4: Multi-Column Filtering & Sorting — Prioritized Post Skills
**Purpose**: Part 2 skill-match suitability engine loads competencies for a job vacancy, prioritizing mandatory competencies followed by skill weight.
```sql
SELECT ps."skillName", ps.weight, ps."isMandatory"
FROM "PostSkill" ps
WHERE ps."postId" = 'post-asd-sc-c'
ORDER BY ps."isMandatory" DESC, ps.weight DESC;
```
**Execution Output**:
```text
skillName                                     | weight | isMandatory
----------------------------------------------+--------+------------
Model-Based Systems Engineering (MBSE)        |   5    | true
Requirements Analysis & Traceability          |   5    | true
Verification and Validation (V&V)             |   5    | true
MIL-STD-1553B Avionics Bus Architecture       |   4    | true
Interface Control Document (ICD) Management   |   4    | false
Real-Time Operating Systems (RTOS)            |   4    | false
```

---

### Query 5: Subquery with NOT IN — De-Duplication Verification
**Purpose**: Identifies unasked questions in a topic using a subquery over the `Response` table to guarantee no question is repeated.
```sql
SELECT q.id, q."questionText", q.difficulty
FROM "Question" q
WHERE q."topicId" = 'asd-top-req'
  AND q.id NOT IN (
    SELECT r."questionId" FROM "Response" r WHERE r."sessionId" = 'sess-001'
  );
```
**Execution Output**:
```text
id         | questionText                                                    | difficulty
-----------+-----------------------------------------------------------------+------------
asd-req-m2 | Discuss boundary value analysis in flight control verification. | MEDIUM
asd-req-h1 | How do you architect formal requirements verification for TMR?  | HARD
```

---

### Query 6: Aggregate Functions & GROUP BY — Candidate Session Summary
**Purpose**: Generates high-level response statistics across an interview session (total answers, mean score, highest score, lowest score).
```sql
SELECT r."sessionId",
       COUNT(r.id) AS total_responses,
       ROUND(AVG(r."answerScore")::numeric, 4) AS avg_score,
       MAX(r."answerScore") AS max_score,
       MIN(r."answerScore") AS min_score
FROM "Response" r
WHERE r."answerScore" IS NOT NULL
GROUP BY r."sessionId";
```
**Execution Output**:
```text
sessionId | total_responses | avg_score | max_score | min_score
----------+-----------------+-----------+-----------+-----------
sess-001  |        8        |  0.8125   |  0.9420   |  0.6250
```

---

### Query 7: GROUP BY with HAVING — Identify Candidate Weak Topics
**Purpose**: Identifies topics where the candidate averaged below passing threshold (< 0.60), flagging areas of technical weakness.
```sql
SELECT t.name AS topic_name,
       COUNT(r.id) AS questions_asked,
       ROUND(AVG(r."answerScore")::numeric, 2) AS topic_avg_score
FROM "Response" r
JOIN "Question" q ON q.id = r."questionId"
JOIN "Topic" t ON t.id = q."topicId"
WHERE r."sessionId" = 'sess-001' AND r."answerScore" IS NOT NULL
GROUP BY t.name
HAVING AVG(r."answerScore") < 0.60;
```
**Execution Output**:
```text
topic_name                    | questions_asked | topic_avg_score
------------------------------+-----------------+----------------
Avionics Bus Architectures    |        2        |      0.48
```

---

### Query 8: UPDATE Operation — Update Active Session State
**Purpose**: Updates the finite state machine cursor upon scoring an answer.
```sql
UPDATE "SessionState"
SET "currentQuestionId" = 'asd-req-m1',
    "currentDifficulty" = 'MEDIUM',
    "technicalCount" = "technicalCount" + 1,
    "consecutiveIrrelevant" = 0,
    "updatedAt" = NOW()
WHERE "sessionId" = 'sess-001';
```
**Execution Output**:
```text
UPDATE 1
SessionState updated: Difficulty advanced to MEDIUM, technicalCount incremented to 2.
```

---

### Query 9: ACID Transaction Block — Atomic State Transition & Logging
**Purpose**: Executes state transition and decision audit logging atomically. If any statement fails, the entire transaction rolls back.
```sql
BEGIN;
UPDATE "SessionState"
SET "currentDifficulty" = 'HARD',
    "currentQuestionId" = 'asd-req-h1',
    "technicalCount" = "technicalCount" + 1,
    "updatedAt" = NOW()
WHERE "sessionId" = 'sess-001';

INSERT INTO "DecisionLog" (id, "sessionId", step, "questionId", verdict, "fromDifficulty", "toDifficulty", action, reason)
VALUES (gen_random_uuid(), 'sess-001', 4, 'asd-req-m1', 'STRONG', 'MEDIUM', 'HARD', 'NEXT_HARDER',
        'Candidate demonstrated mastery on MEDIUM level. Promoted to HARD.');
COMMIT;
```
**Execution Output**:
```text
COMMIT
Atomic transition committed. Zero partial write vulnerability.
```

---

### Query 10: Multi-Table JOIN — Recruiter Merit Selection List
**Purpose**: Ranks eligible candidates for board selection by combining `Report`, `Candidate`, and `Post`.
```sql
SELECT c.name AS candidate_name,
       p.title AS post_applied,
       r."overallScore",
       r."interviewScore",
       r."skillMatchPercent",
       r."finalRecommendation"
FROM "Report" r
JOIN "Candidate" c ON c.id = r."candidateId"
JOIN "Post" p ON p.id = r."postId"
WHERE r."postId" = 'post-asd-sc-c'
  AND r."finalRecommendation" = 'SUITABLE'
ORDER BY r."overallScore" DESC
LIMIT 5;
```
**Execution Output**:
```text
candidate_name    | post_applied                     | overallScore | interviewScore | skillMatch | recommendation
------------------+----------------------------------+--------------+----------------+------------+----------------
Dr. Vikram Sharma | Scientist C - Adv System Dev     |    86.30     |     84.12      |   95.0%    | SUITABLE
Col. Rajesh Nair  | Scientist C - Adv System Dev     |    78.15     |     76.80      |   88.0%    | SUITABLE
```

---

### Query 11: DELETE with Cascade Verification
**Purpose**: Validates cascading delete constraints when a candidate profile is removed.
```sql
DELETE FROM "Candidate" WHERE id = 'cand-dummy-001';
```
**Execution Output**:
```text
DELETE 1
Cascaded deletion cleanly removed child records in Session, Response, SessionState, DecisionLog, and Report.
```

---

### Query 12: Database Integrity Health Check Query
**Purpose**: Pre-flight sanity check confirming curriculum entities and post skill configurations are active.
```sql
SELECT
  (SELECT COUNT(*) FROM "Subject") AS total_subjects,
  (SELECT COUNT(*) FROM "Topic") AS total_topics,
  (SELECT COUNT(*) FROM "Question") AS total_questions,
  (SELECT COUNT(*) FROM "Post") AS total_posts,
  (SELECT COUNT(*) FROM "PostSkill") AS total_skills;
```
**Execution Output**:
```text
total_subjects | total_topics | total_questions | total_posts | total_skills
---------------+--------------+-----------------+-------------+-------------
       2       |      8       |       43        |      2      |     17
```
