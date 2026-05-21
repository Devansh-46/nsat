import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";

/**
 * scoreSubmission — server-side scoring.
 *
 * Takes the student's answers and the testId, reads questions and test
 * config from Firestore, scores it, writes the result doc, and flips
 * the attempt lock. Returns the score breakdown.
 *
 * This replaces the client-side ScoringService.scoreSubmission body.
 * The client sends answers + testId; never sees correctAnswerIndex.
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

    // 1. Load test config
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

    // 2. Load questions for this course
    const questionsSnap = await db
      .collection("questions")
      .where("course", "==", course)
      .limit(test.questionCount as number)
      .get();

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
        // Short answer: ungraded descriptive response — save it, don't score
        if (submitted && typeof submitted === "string" &&
          submitted.trim().length > 0) {
          shortAnswerResponses[i.toString()] = submitted.trim();
        }
        // Not counted in gradedCount, correct, or wrong
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

    // 3. Write result
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
      submittedAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    // Save short answer responses for admissions review (if any)
    if (Object.keys(shortAnswerResponses).length > 0) {
      resultData.shortAnswerResponses = shortAnswerResponses;
    }

    const resultRef = await db.collection("results").add(resultData);

    // 4. Flip attempt lock to completed
    await db.collection("attempts").doc(applicationNo).update({
      status: "completed",
    });

    console.log(
      `Scored ${applicationNo}: ${correct}/${questions.length} ` +
      `(net: ${netScore}/${maxScore})`
    );

    // Whether students should see their score breakdown.
    // Defaults to true for backward compat with tests that don't have the field.
    const showResults = test.showResults !== false;

    return {
      resultId: resultRef.id,
      correctCount: correct,
      wrongCount: wrong,
      skippedCount: skipped,
      netScore,
      maxScore,
      showResults,
    };
  }
);