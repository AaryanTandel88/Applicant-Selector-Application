# 2. Entity-Relationship (ER) Diagram & Data Modelling

## A. Entity Overview & Cardinalities

The database consists of **15 relational tables** organized into 5 functional domains:

```
[Subject] 1 ────< N [Topic] 1 ────< N [Question] (Self-ref: parentQId)
   │                                         │
   │ 1                                       │ 1
   │                                         │
   ▼ N                                       ▼ N
 [Post] 1 ────< N [PostSkill]             [Response] N >──── 1 [Session] 1 ─── 1 [SessionState]
   │                                                              │
   │ 1                                                            │ 1
   ▼ N                                                            ▼ N
[SkillMatchResult] N >──── 1 [Candidate] 1 ───────────────────< N [DecisionLog]
                                  │
                                  │ 1
                                  ▼ N
                           [CandidateSkill]
```

---

## B. Complete Entity Specifications

### 1. Curriculum & Question Bank Domain
- **`Subject`**: Academic / defence engineering domain.
  - `id` (PK, UUID), `name` (VARCHAR, UNIQUE), `createdAt`, `updatedAt`.
  - Cardinality: `1:N` with `Topic`, `1:N` with `Post`.
- **`Topic`**: Sub-discipline within a subject.
  - `id` (PK, UUID), `subjectId` (FK -> `Subject.id`, ON DELETE CASCADE), `name` (VARCHAR), `createdAt`, `updatedAt`.
  - Constraint: `UNIQUE(subjectId, name)`.
  - Cardinality: `1:N` with `Question`.
- **`Question`**: Technical or icebreaker assessment prompt.
  - `id` (PK, UUID), `topicId` (FK -> `Topic.id`, ON DELETE SET NULL), `parentQId` (FK -> `Question.id`, ON DELETE SET NULL), `difficulty` (`EASY | MEDIUM | HARD`), `levelTag` (`TECHNICAL | MANAGERIAL | ICEBREAKER`), `questionText` (TEXT), `simplifiedText` (TEXT), `idealAnswer` (TEXT), `keywords` (TEXT[]), `source` (`BANK | EXPERT`), `status` (`ACTIVE | ARCHIVED`), `aspectKeywords` (TEXT[]).
  - Indices: `INDEX(topicId, difficulty)`, `INDEX(parentQId)`.
  - Cardinality: Self-referencing `1:N` via `parentQId`; `1:N` with `Response`.

### 2. Candidate & Session Domain
- **`Candidate`**: Applicant undergoing DRDO evaluation.
  - `id` (PK, UUID), `name` (VARCHAR), `postApplied` (VARCHAR), `experienceLevel` (VARCHAR), `createdAt`, `updatedAt`.
  - Cardinality: `1:N` with `Session`, `1:N` with `CandidateSkill`, `1:N` with `SkillMatchResult`, `1:N` with `Report`.
- **`Session`**: A single scheduled or completed interview.
  - `id` (PK, UUID), `candidateId` (FK -> `Candidate.id`, ON DELETE CASCADE), `startTime` (TIMESTAMP), `endTime` (TIMESTAMP, nullable), `createdAt`, `updatedAt`.
  - Cardinality: `1:N` with `Response`, `1:1` with `SessionState`, `1:N` with `DecisionLog`, `1:1` with `CandidateAccess`.
- **`Response`**: Answer provided by candidate to a question in a session.
  - `id` (PK, UUID), `sessionId` (FK -> `Session.id`, ON DELETE CASCADE), `questionId` (FK -> `Question.id`, ON DELETE RESTRICT), `answerText` (TEXT), `relevancyScore` (FLOAT), `correctnessScore` (FLOAT), `answerScore` (FLOAT), `verdict` (`STRONG | PARTIAL | IRRELEVANT`), `breakdown` (JSON), `isReask` (BOOLEAN DEFAULT false), `timestamp` (TIMESTAMP).
  - Constraint: `UNIQUE(sessionId, questionId, isReask)`.

### 3. Skill Matching Domain (M:N Resolution)
- **`Post`**: Job vacancy advertisement (e.g. Scientist 'C' - ASD).
  - `id` (PK, UUID), `subjectId` (FK -> `Subject.id`, ON DELETE CASCADE), `title` (VARCHAR), `level` (VARCHAR), `createdAt`, `updatedAt`.
- **`PostSkill`**: Resolves `Post <-> Skill` M:N.
  - `id` (PK, UUID), `postId` (FK -> `Post.id`, ON DELETE CASCADE), `skillName` (VARCHAR), `weight` (INT, 1-5), `isMandatory` (BOOLEAN), `createdAt`, `updatedAt`.
  - Constraint: `UNIQUE(postId, skillName)`.
- **`CandidateSkill`**: Resolves `Candidate <-> Skill` M:N.
  - `id` (PK, UUID), `candidateId` (FK -> `Candidate.id`, ON DELETE CASCADE), `skillName` (VARCHAR), `createdAt`.
  - Constraint: `UNIQUE(candidateId, skillName)`.
- **`SkillMatchResult`**: Pre-interview suitability scoring result.
  - `id` (PK, UUID), `candidateId` (FK -> `Candidate.id`, ON DELETE CASCADE), `postId` (FK -> `Post.id`, ON DELETE CASCADE), `matchPercent` (FLOAT), `band` (`STRONG | MODERATE | WEAK`), `breakdown` (JSON), `createdAt`.

### 4. Adaptive Engine State Machine
- **`SessionState`**: Active cursor of the interview state machine.
  - `id` (PK, UUID), `sessionId` (FK -> `Session.id`, ON DELETE CASCADE, UNIQUE), `currentTopicId` (VARCHAR), `currentDifficulty` (`EASY | MEDIUM | HARD`), `currentQuestionId` (VARCHAR), `phase` (`ICEBREAKER | TECHNICAL | COMPLETED`), `technicalCount` (INT), `icebreakerCount` (INT), `consecutiveIrrelevant` (INT), `topicProgress` (JSON), `status` (`ACTIVE | COMPLETED`), `endReason` (VARCHAR), `expertQueue` (JSON).
- **`DecisionLog`**: Step-by-step audit log of adaptive state machine decisions.
  - `id` (PK, UUID), `sessionId` (FK -> `Session.id`, ON DELETE CASCADE), `step` (INT), `questionId` (VARCHAR), `verdict` (VARCHAR), `fromDifficulty` (VARCHAR), `toDifficulty` (VARCHAR), `action` (VARCHAR), `reason` (TEXT), `createdAt`.
  - Indices: `INDEX(sessionId, step)`.

### 5. Final Report & Governance Domain
- **`Report`**: Immutable final evaluation dossier.
  - `id` (PK, UUID), `sessionId` (FK -> `Session.id`, ON DELETE CASCADE), `candidateId` (FK -> `Candidate.id`, ON DELETE CASCADE), `postId` (FK -> `Post.id`, ON DELETE CASCADE), `version` (INT DEFAULT 1), `skillMatchPercent` (FLOAT), `interviewScore` (FLOAT), `overallScore` (FLOAT), `systemRecommendation` (`SUITABLE | BORDERLINE | NOT_SUITABLE`), `finalRecommendation` (VARCHAR), `topicScores` (JSON), `flags` (JSON), `boardRemarks` (TEXT), `overriddenBy` (VARCHAR), `overrideReason` (TEXT).
  - Constraint: `UNIQUE(sessionId, version)`.
- **`User`**: Board examiner or administrator.
  - `id` (PK, UUID), `name` (VARCHAR), `username` (VARCHAR, UNIQUE), `passwordHash` (VARCHAR), `role` (`ADMIN | EXAMINER`), `isActive` (BOOLEAN).
- **`AuditLog`**: System and user audit trail.
  - `id` (PK, UUID), `userId` (FK -> `User.id`), `action` (VARCHAR), `entityType` (VARCHAR), `entityId` (VARCHAR), `details` (JSON).

---

## C. Relationship Categorization
1. **One-to-One (1:1)**:
   - `Session` -> `SessionState`: Guaranteed by `UNIQUE(sessionId)` on `SessionState`. Ensures an active interview has exactly one state cursor.
   - `Session` -> `CandidateAccess`: One login access token per interview session.
2. **One-to-Many (1:N)**:
   - `Subject` -> `Topic`
   - `Topic` -> `Question`
   - `Candidate` -> `Session`
   - `Session` -> `Response`
   - `Post` -> `PostSkill`
   - `Candidate` -> `CandidateSkill`
   - `Session` -> `DecisionLog`
3. **Self-Referencing 1:N**:
   - `Question` -> `Question` via `parentQId`. Chains parent questions to follow-ups.
4. **Many-to-Many (M:N) Resolution**:
   - `Post <-> Skill` resolved via associative entity `PostSkill`.
   - `Candidate <-> Skill` resolved via associative entity `CandidateSkill`.
   - `Candidate <-> Post` evaluation resolved via `SkillMatchResult` and versioned `Report`.
