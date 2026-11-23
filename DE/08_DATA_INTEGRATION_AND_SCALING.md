# 7. Data Integrity, Performance Considerations & Scalability

## A. Constraints and Data Validation

### 1. Database-Enforced Constraints
- **Primary Keys**: Every table uses non-nullable UUID primary keys.
- **NOT NULL Constraints**: Critical columns (`questionText`, `difficulty`, `idealAnswer`, `answerText`, foreign keys) are strictly `NOT NULL`.
- **Unique Constraints**:
  - `Subject.name`: Prevents duplicate curriculum subjects.
  - `Topic(subjectId, name)`: Prevents duplicate topics within a subject.
  - `PostSkill(postId, skillName)`: Prevents duplicate competency definitions on a job vacancy.
  - `CandidateSkill(candidateId, skillName)`: Enforces idempotent candidate skill ingestion.
  - `Response(sessionId, questionId, isReask)`: Prevents the same question from being answered twice in an interview.
  - `Report(sessionId, version)`: Enforces immutable versioning of evaluation reports.
- **Foreign Key Actions**:
  - `ON DELETE CASCADE`: Used along hierarchical ownership paths (`Candidate -> Session -> Response`, `Subject -> Topic`). Deleting a candidate cascades to sessions, responses, logs, and reports.
  - `ON DELETE RESTRICT`: Used on `Response.questionId -> Question.id`. Prevents accidental deletion of questions that have historical candidate evaluation responses.
- **Enums**:
  - `Difficulty`: `EASY`, `MEDIUM`, `HARD`
  - `LevelTag`: `TECHNICAL`, `MANAGERIAL`, `ICEBREAKER`
  - `Role`: `ADMIN`, `EXAMINER`

### 2. Application-Level Validations
- **Anti-Gaming Rules**: Handled in `logicScorer.js` (detecting `NO_ANSWER`, `TOO_SHORT`, `KEYWORD_STUFFING`, and `OFF_TOPIC` input).
- **Early Stop Limits**: Enforced in `adaptiveEngine.js` (capping consecutive irrelevant answers at 3, maximum technical questions at 10).

---

## B. Indexing Strategy

| Table | Index Columns | Index Type | Query Supported | Write Overhead Justification |
| :--- | :--- | :--- | :--- | :--- |
| **`Question`** | `(topicId, difficulty)` | Composite B-Tree | `SELECT ... WHERE topicId = X AND difficulty = Y` (adaptive question selection). | Critical read path; question bank writes are infrequent. |
| **`Question`** | `(parentQId)` | Single-column B-Tree | `SELECT ... WHERE parentQId = X` (follow-up chain lookup). | Fast recursive question lookup. |
| **`Response`** | `(sessionId)` | Single-column B-Tree | Filtering responses by session when building dossiers. | Essential for multi-answer joins. |
| **`DecisionLog`** | `(sessionId, step)` | Composite B-Tree | `SELECT ... WHERE sessionId = X ORDER BY step ASC` (boardroom timeline). | Eliminates in-memory sorting. |
| **`PostSkill`** | `(postId)` | Single-column B-Tree | Loading job post requirements during screening. | Essential for skill match calculations. |

### Indexes Deliberately Avoided:
- Large free-text columns like `Question.questionText`, `Question.idealAnswer`, and `Response.answerText` are **not** indexed. Because free-text answers are only read by ID when generating reports and never queried via search filters, indexing them would introduce severe write latency and memory bloat.

---

## C. 100x Scalability Plan

If nationwide DRDO candidate volumes grow 100x (hundreds of thousands of concurrent candidates):

### 1. What Would Break First?
- Write contention and connection pool exhaustion on the `Response` and `DecisionLog` tables, as thousands of concurrent oral responses write to the database simultaneously.
- Slower analytic report aggregations locking candidate tables.

### 2. Architectural Mitigations:
1. **Horizontal Table Partitioning**:
   - Partition `Response` and `DecisionLog` by date range or hash partition by `postId`. This keeps individual partition index sizes small and memory-resident.
2. **Read-Write Splitting with Read Replicas**:
   - The primary database handles transactional writes (`INSERT Response`, `UPDATE SessionState`).
   - Read replicas handle dashboard rendering, candidate search, and report viewing.
3. **Caching with Redis**:
   - Cache curriculum questions, topics, and job post competencies in Redis.
   - Buffer active `SessionState` and topic progress counters in Redis during the interview, writing to PostgreSQL upon question completion or session conclusion.
4. **Connection Pooling via PgBouncer**:
   - Deploy PgBouncer in transaction-pooling mode to multiplex thousands of client connections onto a controlled pool of PostgreSQL backend processes.
