const assert = require("node:assert/strict");
const test = require("node:test");
const {countCorrectAnswers, improvementOverBest} =
  require("../honor_scoring");

const questions = [
  {options: ["A", "B", "C"], correctIndex: 1},
  {options: ["A", "B"], correctIndex: 0},
  {options: ["A", "B"], correctIndex: 1},
];

test("recalculates correct answers from the published questions", () => {
  assert.equal(countCorrectAnswers(questions, {"0": 1, "1": 0, "2": 0}), 2);
});

test("leaves unanswered questions out of the correct count", () => {
  assert.equal(countCorrectAnswers(questions, {"1": 0}), 1);
});

test("rejects malformed or out-of-range answer indexes", () => {
  assert.equal(countCorrectAnswers(questions, {"3": 0}), null);
  assert.equal(countCorrectAnswers(questions, {"0": true}), null);
  assert.equal(countCorrectAnswers(questions, {"x": 0}), null);
  assert.equal(countCorrectAnswers(questions, {"01": 1}), null);
});

test("awards only improvements over the previous best result", () => {
  assert.equal(improvementOverBest(0, 2), 2);
  assert.equal(improvementOverBest(2, 3), 1);
  assert.equal(improvementOverBest(3, 1), 0);
});
