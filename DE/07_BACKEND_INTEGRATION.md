# 6. Database and Application Integration

## A. Integration Architecture
The database layer connects to our Node.js / Express backend via **Prisma ORM (v6.x)**, backed by a singleton connection pool:

```
[React + Tailwind UI]
        │
   HTTP │ (JSON REST API)
        ▼
[Express Router] (src/routes/)
        │
        ▼
[Service Layer] (src/services/)
  - interviewService.js
  - questionService.js
  - sessionService.js
  - skillMatchService.js
  - reportService.js
        │
        ▼
[Prisma Client Singleton] (src/db/prismaClient.js)
        │
  TCP / │ PostgreSQL Connection Pool (DATABASE_URL)
  TLS   ▼
[PostgreSQL Database] (15 Relational Tables)
```

---

## B. Core Service Implementations

### 1. Connection Pool (`server/src/db/prismaClient.js`)
```javascript
const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient({
  log: process.env.NODE_ENV === 'development' ? ['query', 'error', 'warn'] : ['error'],
});
module.exports = prisma;
```

### 2. Transactional Answer Submission (`server/src/services/interviewService.js`)
Demonstrates how database operations insert responses, update session state, and log decision audit trails within an atomic transaction:
```javascript
// Atomically update state and log decision within a Prisma transaction
await prisma.$transaction(async (tx) => {
  // Update state machine cursor
  await tx.sessionState.update({
    where: { sessionId },
    data: {
      currentTopicId: nextQuestionEntity ? nextQuestionEntity.topicId : null,
      currentDifficulty: nextQuestionEntity ? nextQuestionEntity.difficulty : null,
      currentQuestionId: nextQuestionEntity ? nextQuestionEntity.id : null,
      phase: nextPhase,
      technicalCount: updatedTechnicalCount,
      icebreakerCount: updatedIcebreakerCount,
      consecutiveIrrelevant: updatedConsecutiveIrrelevant,
      topicProgress: updatedTopicProgress,
      status: isInterviewEnding ? 'COMPLETED' : 'ACTIVE',
      endReason: isInterviewEnding && decision.end ? decision.end.reason : null,
    },
  });

  // Append to decision audit log
  await tx.decisionLog.create({
    data: {
      sessionId,
      step: stepCount,
      questionId: question.id,
      verdict,
      fromDifficulty: question.difficulty,
      toDifficulty: nextQuestionEntity ? nextQuestionEntity.difficulty : null,
      action: decision.action,
      reason: decision.reason,
    },
  });

  if (isInterviewEnding) {
    await tx.session.update({
      where: { id: sessionId },
      data: { endTime: new Date() },
    });
  }
});
```

### 3. Curriculum Retrieval & Follow-Up Tree (`server/src/services/questionService.js`)
```javascript
// Retrieves next question matching difficulty, excluding asked questions
async function getNextQuestion(topicId, difficulty, excludeIds = []) {
  return prisma.question.findFirst({
    where: {
      topicId,
      difficulty,
      levelTag: { not: 'ICEBREAKER' },
      id: { notIn: excludeIds },
      status: 'ACTIVE',
    },
    orderBy: { createdAt: 'asc' },
    include: { topic: true },
  });
}

// Retrieves recursive follow-up questions linked via parentQId
async function getFollowupQuestions(parentQId) {
  return prisma.question.findMany({
    where: { parentQId, status: 'ACTIVE' },
    orderBy: { difficulty: 'asc' },
  });
}
```

### 4. Idempotent Skill Association (`server/src/services/skillMatchService.js`)
```javascript
// Upserts candidate skills safely without creating duplicates
for (const skillName of cleanSkills) {
  const record = await prisma.candidateSkill.upsert({
    where: {
      candidateId_skillName: { candidateId, skillName },
    },
    update: {},
    create: { candidateId, skillName },
  });
  results.push(record);
}
```

---

## C. Verification & API Flow
When an examiner triggers an interview session from the React dashboard:
1. `POST /api/interviews/start`: Backend creates a `Session`, computes skill suitability, initializes `SessionState`, and records Step 0 in `DecisionLog`.
2. `POST /api/interviews/:id/answer`: Scorer evaluates answer text, writes to `Response`, updates `SessionState`, and records the decision.
3. `GET /api/interviews/:id/state`: Fetches full session progress and decision logs for the live examiner console.
4. `GET /api/reports`: Queries `Report` joined with `Candidate` and `Post` to display candidate rankings.
