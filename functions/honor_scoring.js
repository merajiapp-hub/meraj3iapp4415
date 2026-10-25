function countCorrectAnswers(questions, answers) {
  if (!Array.isArray(questions) || !answers || typeof answers !== "object" ||
      Array.isArray(answers)) {
    return null;
  }

  let correctAnswers = 0;
  for (const [rawIndex, rawAnswer] of Object.entries(answers)) {
    const questionIndex = Number.parseInt(rawIndex, 10);
    const selectedIndex = typeof rawAnswer === "number" ?
      rawAnswer :
      (typeof rawAnswer === "string" && /^\d+$/.test(rawAnswer) ?
        Number(rawAnswer) :
        Number.NaN);
    if (!/^\d+$/.test(rawIndex) ||
        !Number.isInteger(questionIndex) ||
        rawIndex !== String(questionIndex) ||
        questionIndex < 0 || questionIndex >= questions.length ||
        !Number.isInteger(selectedIndex) ||
        selectedIndex < 0 ||
        selectedIndex >= questions[questionIndex].options.length) {
      return null;
    }
    if (selectedIndex === questions[questionIndex].correctIndex) {
      correctAnswers++;
    }
  }
  return correctAnswers;
}

function improvementOverBest(previousBest, currentResult) {
  return Math.max(0, currentResult - previousBest);
}

module.exports = {countCorrectAnswers, improvementOverBest};
