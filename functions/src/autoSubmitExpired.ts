import { onSchedule } from "firebase-functions/v2/scheduler";
import * as admin from "firebase-admin";

/**
 * autoSubmitExpired — safety net for crashed/disconnected students.
 *
 * Runs every 2 minutes. Finds attempts that are still `in_progress`
 * where the test duration has elapsed since `attemptedAt`. For each:
 *   1. Reads saved answers from `saved_answers/{applicationNo}`
 *   2. Scores them using the same logic as scoreSubmission
 *   3. Writes the result and flips the attempt to `completed`
 *   4. Cleans up saved_answers
 *
 * This ensures no student is permanently stuck with an in_progress
 * attempt if their app crashed, lost network, or their phone died.
 */
export const autoSubmitExpired = onSchedule(
  {
    schedule: "every 2 minutes",
    region: "asia-south1",
    timeoutSeconds: 120,
    memory: "512MiB",
  },
  async () => {
    const db = admin.firestore();

    // 1. Find all in_progress attempts
    const attemptsSnap = await db
      .collection("attempts")
      .where("status", "==", "in_progress")
      .get();

    if (attemptsSnap.empty) {
      console.log("autoSubmitExpired: no in_progress attempts found");
      return;
    }

    console.log(`autoSubmitExpired: found ${attemptsSnap.size} in_progress attempts`);

    const now = Date.now();

    for (const attemptDoc of attemptsSnap.docs) {
      const applicationNo = attemptDoc.id;
      const attemptData = attemptDoc.data();
      const testId = attemptData.testId as string | undefined;
      const attemptedAt = attemptData.attemptedAt?.toDate?.() as Date | undefined;

      if (!testId || !attemptedAt) {
        console.warn(`autoSubmitExpired: skipping ${applicationNo} — missing testId or attemptedAt`);
        continue;
      }

      // 2. Load test config to get duration
      const testDoc = await db.collection("tests").doc(testId).get();
      if (!testDoc.exists) {
        console.warn(`autoSubmitExpired: test ${testId} not found for ${applicationNo}`);
        continue;
      }

      const test = testDoc.data()!;
      const durationMinutes = (test.durationMinutes ?? 60) as number;
      // Add 2-minute grace period so we don't race with the client's own submit
      const deadlineMs = attemptedAt.getTime() + (durationMinutes + 2) * 60 * 1000;

      if (now < deadlineMs) {
        // Test hasn't expired yet — skip
        continue;
      }

      console.log(`autoSubmitExpired: test expired for ${applicationNo} (started ${attemptedAt.toISOString()}, duration ${durationMinutes}min)`);

      // 3. Check if already scored (double-guard)
      const resultId = `${applicationNo}_${testId}`;
      const existingResult = await db.collection("results").doc(resultId).get();
      if (existingResult.exists) {
        // Already scored — just fix the attempt status if needed
        console.log(`autoSubmitExpired: ${applicationNo} already has result — fixing attempt status`);
        await attemptDoc.ref.update({ status: "completed" });
        continue;
      }

      // 4. Load saved answers (if any)
      const savedDoc = await db.collection("saved_answers").doc(applicationNo).get();
      const answers: Record<string, number | string> = {};
      if (savedDoc.exists) {
        const savedAnswers = savedDoc.data()?.answers as Record<string, unknown> | undefined;
        if (savedAnswers) {
          for (const [key, val] of Object.entries(savedAnswers)) {
            if (typeof val === "number" || typeof val === "string") {
              answers[key] = val;
            }
          }
        }
        console.log(`autoSubmitExpired: loaded ${Object.keys(answers).length} saved answers for ${applicationNo}`);
      } else {
        console.log(`autoSubmitExpired: no saved answers for ${applicationNo} — scoring with empty answers`);
      }

      // 5. Load questions and score (same logic as scoreSubmission)
      const course = test.course as string;
      const marksPerQuestion = (test.marksPerQuestion ?? 1) as number;
      const negativeMarking = test.negativeMarking === true;
      const negativeMarksPerWrong = negativeMarking
        ? ((test.negativeMarksPerWrong ?? 0) as number)
        : 0;

      const questionsSnap = await db
        .collection("questions")
        .where("course", "==", course)
        .limit(test.questionCount as number)
        .get();

      if (questionsSnap.empty) {
        console.warn(`autoSubmitExpired: no questions for course ${course} — skipping ${applicationNo}`);
        continue;
      }

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
          if (submitted && typeof submitted === "string" && submitted.trim().length > 0) {
            shortAnswerResponses[i.toString()] = submitted.trim();
          }
          continue;
        }

        gradedCount++;
        if (submitted === undefined || submitted === null) continue;

        const correctIdx = qData.correctAnswerIndex as number;
        if (typeof submitted === "number" && submitted === correctIdx) {
          correct++;
        } else if (typeof submitted === "number") {
          wrong++;
        }
      }

      const skipped = gradedCount - correct - wrong;
      const netScore = correct * marksPerQuestion - wrong * negativeMarksPerWrong;
      const maxScore = gradedCount * marksPerQuestion;

      // 6. Write result + flip attempt (batch)
      const resultRef = db.collection("results").doc(resultId);
      const resultData: Record<string, unknown> = {
        application_no: applicationNo,
        studentName: attemptData.studentName ?? applicationNo,
        course,
        testId,
        correctCount: correct,
        wrongCount: wrong,
        skippedCount: skipped,
        netScore,
        maxScore,
        showResults: test.showResults !== false,
        submittedAt: admin.firestore.FieldValue.serverTimestamp(),
        autoSubmitted: true, // Flag so admins know this was auto-scored
      };

      if (Object.keys(shortAnswerResponses).length > 0) {
        resultData.shortAnswerResponses = shortAnswerResponses;
      }

      const batch = db.batch();
      batch.set(resultRef, resultData);
      batch.update(attemptDoc.ref, { status: "completed" });
      // Clean up saved answers
      batch.delete(db.collection("saved_answers").doc(applicationNo));
      await batch.commit();

      console.log(
        `autoSubmitExpired: auto-scored ${applicationNo}: ${correct}/${gradedCount} ` +
        `(net: ${netScore}/${maxScore}, answers recovered: ${Object.keys(answers).length})`
      );
    }
  }
);
