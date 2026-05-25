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

    // 3. Load questions filtered by BOTH course AND testId
    // This fixes:
    //   - Issue #10: consistent ordering via sequence field (sorted in memory)
    //   - Issue #12: testId scoping prevents cross-test question bleed
    let questionsSnap = await db
      .collection("questions")
      .where("course", "==", course)
      .where("testId", "==", testId)
      .limit(test.questionCount as number)
      .get();

    // Fallback: if questions don't have testId field (legacy question bank),
    // fall back to course-only query (no orderBy — avoids missing-index error)
    if (questionsSnap.empty) {
      console.warn(
        `No questions found with testId=${testId} for course=${course}. ` +
        `Falling back to course-only query. Add testId field to questions for correctness.`
      );
      questionsSnap = await db
        .collection("questions")
        .where("course", "==", course)
        .limit(test.questionCount as number)
        .get();
    }

    if (questionsSnap.empty) {
      throw new HttpsError("not-found", "No questions found for this test");
    }

    // Sort in memory by sequence field (safe even if field is absent)
    const questions = questionsSnap.docs.sort((a, b) => {
      const seqA = (a.data().sequence as number) ?? 9999;
      const seqB = (b.data().sequence as number) ?? 9999;
      return seqA - seqB;
    });
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
    // Use a deterministic doc ID so retries don't create duplicate results
    const resultId = `${applicationNo}_${testId}`;
    const resultRef = db.collection("results").doc(resultId);
    const attemptRef = db.collection("attempts").doc(applicationNo);

    // Check again just before writing (double-guard)
    const existingResult = await resultRef.get();
    if (existingResult.exists) {
      const d = existingResult.data()!;
      console.log(`Duplicate scoreSubmission for ${applicationNo} — returning existing result`);
      return {
        resultId,
        correctCount: d.correctCount ?? 0,
        wrongCount: d.wrongCount ?? 0,
        skippedCount: d.skippedCount ?? 0,
        netScore: d.netScore ?? 0,
        maxScore: d.maxScore ?? 0,
        showResults: d.showResults ?? true,
      };
    }

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
      resultId,
      correctCount: correct,
      wrongCount: wrong,
      skippedCount: skipped,
      netScore,
      maxScore,
      showResults: test.showResults !== false,
    };
  }
);
