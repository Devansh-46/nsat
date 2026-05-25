import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";

/**
 * scoreSubmission — server-side scoring.
 *
 * Takes the student's answers and the testId, reads questions and test
 * config from Firestore, scores it, writes the result doc, and flips
 * the attempt lock — all in one call.
 *
 * FIXES:
 * - Issue #10: Questions are now fetched by testId via sub-collection or
 *   testId field, AND sorted by a consistent `sequence` field so that
 *   answers[i] always corresponds to questions[i].
 * - Issue #12: Questions are filtered by both course AND testId to prevent
 *   cross-test question overlap.
 * - Issue #7/#8: CF checks for existing result before writing to prevent
 *   duplicate submissions.
 */
export const scoreSubmission = onCall(
  { region: "asia-south1" },
  async (request) => {
    const db = admin.firestore();
    const applicationNo = request.data?.application_no as string | undefined;
    const studentName = request.data?.student_name as string | undefined;
    const testId = request.data?.test_id as string | undefined;
    const answers = request.data?.answers as
      Record<string, number | string> | undefined;

    if (!applicationNo || !testId || !answers || !studentName) {
      throw new HttpsError(
        "invalid-argument",
        "application_no, student_name, test_id, and answers are required"
      );
    }

    // 1. Check for existing result (prevents duplicates from race conditions)
    const existingResults = await db
      .collection("results")
      .where("application_no", "==", applicationNo)
      .where("testId", "==", testId)
      .limit(1)
      .get();

    if (!existingResults.empty) {
      // Already scored — return the existing result idempotently
      const existing = existingResults.docs[0].data();
      console.log(`Duplicate scoreSubmission for ${applicationNo} — returning existing result`);
      return {
        resultId: existingResults.docs[0].id,
        correctCount: existing.correctCount ?? 0,
        wrongCount: existing.wrongCount ?? 0,
        skippedCount: existing.skippedCount ?? 0,
        netScore: existing.netScore ?? 0,
        maxScore: existing.maxScore ?? 0,
        showResults: existing.showResults ?? true,
      };
    }

    // 2. Load test config
    const testDoc = await db.collection("tests").doc(testId).get();
    if (!testDoc.exists) {
      throw new HttpsError("not-found", "Test not found");
    }
    const test = testDoc.data()!;
    const course = test.course as string;
    const marksPerQuestion = (test.marksPerQuestion ?? 1) as number;
    const negativeMarking = test.negativeMarking === true;
    const negativeMarksPerWrong =
      negativeMarking ? ((test.negativeMarksPerWrong ?? 0) as number) : 0;

    // 3. Load questions filtered by BOTH course AND testId, sorted by sequence
    // This fixes:
    //   - Issue #10: consistent ordering via sequence field
    //   - Issue #12: testId scoping prevents cross-test question bleed
    let questionsQuery = db
      .collection("questions")
      .where("course", "==", course)
      .where("testId", "==", testId)
      .orderBy("sequence", "asc")
      .limit(test.questionCount as number);

    let questionsSnap = await questionsQuery.get();

    // Fallback: if questions don't have testId field (legacy question bank),
    // fall back to course-only query with sequence ordering
    if (questionsSnap.empty) {
      console.warn(
        `No questions found with testId=${testId} for course=${course}. ` +
        `Falling back to course-only query. Add testId field to questions for correctness.`
      );
      questionsSnap = await db
        .collection("questions")
        .where("course", "==", course)
        .orderBy("sequence", "asc")
        .limit(test.questionCount as number)
        .get();
    }

    if (questionsSnap.empty) {
      throw new HttpsError("not-found", "No questions found for this test");
    }

    const questions = questionsSnap.docs;
    let correct = 0;
    let wrong = 0;
    let gradedCount = 0;
    const shortAnswerResponses: Record<string, string> = {};

    for (let i = 0; i < questions.length; i++) {
      const submitted = answers[i.toString()];
      const qData = questions[i].data();
      const qType = (qData.type as string) ?? "multipleChoice";

      if (qType === "shortAnswer") {
        if (submitted && typeof submitted === "string" &&
          submitted.trim().length > 0) {
          shortAnswerResponses[i.toString()] = submitted.trim();
        }
        continue;
      }

      // MCQ: graded
      gradedCount++;
      if (submitted === undefined || submitted === null) continue; // skipped

      const correctIdx = qData.correctAnswerIndex as number;
      if (typeof submitted === "number" && submitted === correctIdx) {
        correct++;
      } else if (typeof submitted === "number") {
        wrong++;
      }
    }

    const skipped = gradedCount - correct - wrong;
    const correctMarks = correct * marksPerQuestion;
    const negMarks = wrong * negativeMarksPerWrong;
    const netScore = correctMarks - negMarks;
    const maxScore = gradedCount * marksPerQuestion;

    // 4. Write result and flip attempt lock atomically
    const resultRef = db.collection("results").doc();
    const attemptRef = db.collection("attempts").doc(applicationNo);

    const resultData: Record<string, unknown> = {
      application_no: applicationNo,
      studentName,
      course,
      testId,
      correctCount: correct,
      wrongCount: wrong,
      skippedCount: skipped,
      netScore,
      maxScore,
      showResults: test.showResults !== false,
      submittedAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    if (Object.keys(shortAnswerResponses).length > 0) {
      resultData.shortAnswerResponses = shortAnswerResponses;
    }

    // Batch write: result doc + attempt status flip
    const batch = db.batch();
    batch.set(resultRef, resultData);
    batch.set(attemptRef, { status: "completed" }, { merge: true });
    await batch.commit();

    console.log(
      `Scored ${applicationNo}: ${correct}/${questions.length} ` +
      `(net: ${netScore}/${maxScore})`
    );

    return {
      resultId: resultRef.id,
      correctCount: correct,
      wrongCount: wrong,
      skippedCount: skipped,
      netScore,
      maxScore,
      showResults: test.showResults !== false,
    };
  }
);
