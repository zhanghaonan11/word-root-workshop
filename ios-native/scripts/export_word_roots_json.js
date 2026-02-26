const fs = require('fs');
const path = require('path');

const iosRoot = path.resolve(__dirname, '..');
const wordRootsPath = path.join(iosRoot, 'data', 'wordData.js');
const outputPath = path.join(iosRoot, 'WordRootWorkshop', 'Resources', 'wordRoots.json');

const roots = require(wordRootsPath);
if (!Array.isArray(roots) || roots.length === 0) {
  throw new Error('wordData.js did not export a non-empty array.');
}

function isNonEmptyString(v) {
  return typeof v === 'string' && v.trim().length > 0;
}

function fail(message) {
  const err = new Error(message);
  err.name = 'WordRootsExportError';
  throw err;
}

// Validate schema + catch data issues early (before shipping to the app bundle).
const idCounts = new Map();
for (const [idx, r] of roots.entries()) {
  if (!r || typeof r !== 'object') {
    fail(`Invalid root entry at index ${idx}: expected object.`);
  }

  if (!Number.isInteger(r.id)) {
    fail(`Invalid root id at index ${idx}: expected integer, got ${JSON.stringify(r.id)}`);
  }

  idCounts.set(r.id, (idCounts.get(r.id) || 0) + 1);

  for (const k of ['root', 'origin', 'meaning', 'meaningEn', 'description']) {
    if (!isNonEmptyString(r[k])) {
      fail(`Missing/invalid field "${k}" for root id=${r.id}`);
    }
  }

  if (!Array.isArray(r.examples) || r.examples.length === 0) {
    fail(`Missing/invalid examples for root id=${r.id}: expected non-empty array.`);
  }

  for (const [exIdx, ex] of r.examples.entries()) {
    if (!ex || typeof ex !== 'object') {
      fail(`Invalid example at root id=${r.id}, examples[${exIdx}]: expected object.`);
    }
    for (const k of ['word', 'meaning', 'explanation']) {
      if (!isNonEmptyString(ex[k])) {
        fail(`Missing/invalid example field "${k}" at root id=${r.id}, examples[${exIdx}]`);
      }
    }
    if (!ex.breakdown || typeof ex.breakdown !== 'object') {
      fail(`Missing/invalid breakdown at root id=${r.id}, examples[${exIdx}]`);
    }
    for (const k of ['prefix', 'root', 'suffix']) {
      if (typeof ex.breakdown[k] !== 'string') {
        fail(`Missing/invalid breakdown field "${k}" at root id=${r.id}, examples[${exIdx}]`);
      }
    }
  }

  if (!r.quiz || typeof r.quiz !== 'object') {
    fail(`Missing/invalid quiz for root id=${r.id}: expected object.`);
  }

  if (!isNonEmptyString(r.quiz.question)) {
    fail(`Missing/invalid quiz.question for root id=${r.id}`);
  }

  if (!Array.isArray(r.quiz.options) || r.quiz.options.length === 0) {
    fail(`Missing/invalid quiz.options for root id=${r.id}: expected non-empty array.`);
  }

  for (const [optIdx, opt] of r.quiz.options.entries()) {
    if (!isNonEmptyString(opt)) {
      fail(`Missing/invalid quiz.options[${optIdx}] for root id=${r.id}`);
    }
  }

  if (!Number.isInteger(r.quiz.correctAnswer)) {
    fail(`Missing/invalid quiz.correctAnswer for root id=${r.id}: expected integer.`);
  }

  if (r.quiz.correctAnswer < 0 || r.quiz.correctAnswer >= r.quiz.options.length) {
    fail(
      `Invalid quiz.correctAnswer for root id=${r.id}: ${r.quiz.correctAnswer} out of bounds (0..${r.quiz.options.length - 1})`
    );
  }
}

const duplicateIDs = Array.from(idCounts.entries())
  .filter(([, c]) => c > 1)
  .map(([id, c]) => ({ id, count: c }));

if (duplicateIDs.length) {
  fail(`Duplicate root ids detected: ${JSON.stringify(duplicateIDs)}`);
}

fs.mkdirSync(path.dirname(outputPath), { recursive: true });
fs.writeFileSync(outputPath, JSON.stringify(roots, null, 2), 'utf8');

console.log(`Exported ${roots.length} roots to ${outputPath}`);
