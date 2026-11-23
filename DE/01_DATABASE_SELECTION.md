# 1. Database Selection and Justification

## A. Database Selected
**PostgreSQL** (version 15+), interfaced via **Prisma ORM (v6.x)** in Node.js.

---

## B. Nature of the Stored Data
The data domain of the **RAC DRDO Adaptive Interview System** is structured, relational, and deeply interconnected:
1. **Hierarchical Curriculum Bank**: `Subject -> Topic -> Question`. Technical questions feature recursive self-referencing relationships (`parentQId`) where parent questions (e.g. EASY) link directly to follow-up questions (e.g. MEDIUM or HARD).
2. **Examination & Assessment State**: `Candidate -> Session -> Response`, coupled with a 1:1 `SessionState` tracking the finite state machine cursor and a historical audit trail in `DecisionLog`.
3. **Multi-Competency Mapping**: `Post -> PostSkill` mapped against `Candidate -> CandidateSkill` to produce `SkillMatchResult`.
4. **Assessment Dossier**: `Report` capturing multi-table analytical aggregations and board decision overrides.

While candidate scoring breakdowns and anti-gaming flags are semi-structured, they exist as attributes inside strongly typed records. PostgreSQL's native `JSONB`/`Json` type provides flexibility for scoring payloads without abandoning relational constraints on surrounding fields.

---

## C. Read and Write Workload Patterns
- **Write Patterns**: Latency-sensitive transactional writes occur upon each candidate response. A single answer submission triggers an atomic write across `Response`, an update to `SessionState`, and an insert into `DecisionLog`.
- **Read Patterns**: High-frequency filtered reads across `Question` (by `topicId` and `difficulty`, excluding previously answered questions in the session) and multi-table joins to generate evaluation dossiers.
- **Data Volume**: Each interview session produces ~10–15 `Response` records, 1 `SessionState`, ~10 `DecisionLog` entries, and 1 `Report`. Across government recruitment drives with hundreds of candidates, data easily scales into tens of thousands of records. PostgreSQL easily maintains sub-millisecond query latency under this workload.

---

## D. Strong Consistency & ACID Transactions
Strong consistency is a **strict operational requirement**. In an automated adaptive interview, question progression depends directly on the verdict of the previous response:
1. Score the answer (relevancy, correctness, verdict).
2. Insert `Response` row.
3. Update `SessionState` (topic progress, difficulty cursor, consecutive irrelevant count).
4. Append `DecisionLog` entry.
5. Optionally mark session as `COMPLETED`.

A dirty read or partial write would corrupt the state machine, causing difficulty jumps, orphaned decision records, or duplicate question delivery. PostgreSQL provides full ACID guarantees, implemented via Prisma's `$transaction`.

---

## E. Alternative Considered & Rejected: MongoDB
| Evaluation Criteria | PostgreSQL (Selected) | MongoDB (Rejected) |
| :--- | :--- | :--- |
| **Data Model Fit** | Native relational structure with foreign keys and cascade rules. | Document model forces self-referencing question trees and multi-table joins into application code. |
| **Schema Enforcement** | Strict DB-level types, enums (`Difficulty`, `LevelTag`), and unique keys. | Schema-less by default; invalid verdicts or orphaned records bypass validation. |
| **Transaction Overhead** | First-class ACID transactions natively optimized for high frequency. | Multi-document transactions are computationally heavier and less efficient. |
| **Integrity Guarantees** | `ON DELETE RESTRICT` protects questions that have existing candidate answers. | No native cascade/restrict protection; risks accidental deletion of test records. |
| **JSON Support** | Native `Json`/`JSONB` columns handle scoring blobs cleanly. | Native JSON/BSON, but lacks the relational integrity needed for the rest of the application. |

**Conclusion**: PostgreSQL was chosen because our core domain is fundamentally relational, write paths demand ACID transactions, and native JSON columns handle semi-structured scoring breakdowns without needing a separate document store.
