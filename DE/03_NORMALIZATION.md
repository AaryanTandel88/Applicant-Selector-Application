# 3. Database Normalization Documentation

## A. Normalization Overview
The database design was developed by methodically eliminating data redundancy and anomalies (Insertion, Deletion, and Update Anomalies) up to **Third Normal Form (3NF)** and **Boyce-Codd Normal Form (BCNF)** for all core operational entities. Targeted denormalization was deliberately introduced for reporting snapshots.

---

## B. Step-by-Step Normalization Process

### 1. Unnormalized Form (UNF)
In an unnormalized interview system, a single wide spreadsheet or record would capture candidate evaluations:
`CandidateInterview(candidateId, candidateName, postTitle, requiredSkills, candidateSkills, questionId, questionText, topicName, subjectName, answerText, score, decisionHistory)`

**Anomalies in UNF**:
- **Redundancy**: Repeating candidate details and post skills for every question answered.
- **Insert Anomaly**: Cannot add a technical question without having a candidate session.
- **Delete Anomaly**: Deleting a candidate's session deletes the curriculum question definition.
- **Update Anomaly**: Changing a topic name requires updating thousands of individual response rows.

---

### 2. First Normal Form (1NF)
**Requirements**: Atomic attributes (no multi-valued attributes or repeating groups) and a designated primary key.

**Transformations**:
- Multi-valued required skills (`MBSE, V&V, RTOS`) decomposed into distinct rows in `PostSkill`.
- Multi-valued candidate declared skills decomposed into distinct rows in `CandidateSkill`.
- Decision history decomposed into individual step records in `DecisionLog`.
- Every table assigned a unique non-composite surrogate primary key (`id` UUID).

---

### 3. Second Normal Form (2NF)
**Requirements**: Must be in 1NF and contain **no partial dependencies** (every non-prime attribute must depend on the whole candidate key).

**Transformations**:
- In associative tables such as candidate skills, if candidate attributes like `candidateName` or `experienceLevel` were stored in `CandidateSkill(candidateId, skillName)`, they would depend solely on `candidateId`, a subset of the candidate key `{candidateId, skillName}`.
- Candidate profile data was isolated into the `Candidate` table.
- Job post details were separated from `PostSkill`.
- Because all primary entities utilize a single-attribute surrogate key (`id` UUID), partial key dependencies are mathematically impossible, fully satisfying 2NF.

---

### 4. Third Normal Form (3NF)
**Requirements**: Must be in 2NF and contain **no transitive dependencies** (no non-prime attribute should depend on another non-prime attribute: $X \to Y$ and $Y \to Z$).

**Transformations**:
- **Question -> Topic -> Subject Hierarchy**:
  - In a 2NF relation `Question(id, questionText, topicId, topicName, subjectId, subjectName)`, transitive dependencies exist:
    `id -> topicId` and `topicId -> topicName, subjectId` and `subjectId -> subjectName`.
  - Updating `subjectName` would cause update anomalies across all questions in that subject.
  - **Resolution**: Decomposed into three distinct relations:
    - `Subject(id, name)`
    - `Topic(id, subjectId, name)`
    - `Question(id, topicId, questionText, idealAnswer, ...)`
- **Response -> Question -> Topic**:
  - Storing topic or difficulty inside `Response` creates a transitive dependency through `questionId`.
  - `Response` strictly stores the candidate's answer and evaluation metrics, referencing `questionId`.

---

### 5. Boyce-Codd Normal Form (BCNF)
**Requirements**: For every functional dependency $X \to Y$, $X$ must be a superkey.

**Functional Dependency Analysis of `Topic` Table**:
- Attributes: `{id, subjectId, name, createdAt, updatedAt}`
- Candidate Keys: `id`, `{subjectId, name}` (enforced by `UNIQUE(subjectId, name)`)
- Functional Dependencies:
  1. `id -> subjectId, name, createdAt, updatedAt` (Determinant `id` is a superkey)
  2. `{subjectId, name} -> id, createdAt, updatedAt` (Determinant `{subjectId, name}` is a superkey)
- Since all determinants are superkeys, `Topic` is strictly in **BCNF**.

---

## C. Intentional Denormalization Justification

Denormalization was deliberately applied in two locations:

| Denormalized Table | Denormalized Fields | Justification & Correctness Mechanism |
| :--- | :--- | :--- |
| **`Report`** | `overallScore`, `interviewScore`, `skillMatchPercent`, `topicScores` (JSON), `configSnapshot` (JSON) | **Audit Immutability**: In a defence recruitment board (RAC DRDO), candidate evaluations must be legally immutable historical records. If weights, topic structures, or passing thresholds change in the future, past candidate scores must never change retroactively. Enforced via `UNIQUE(sessionId, version)`. Re-evaluations increment the version counter. |
| **`Response`** | `breakdown` (JSON) | **Latency Optimization**: Stores granular scoring details (keyword matches, overlap ratios, density scores) in one JSON payload rather than joining 4 separate micro-tables during an active oral interview. |
