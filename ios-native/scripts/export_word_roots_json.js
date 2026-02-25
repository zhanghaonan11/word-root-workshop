const fs = require('fs');
const path = require('path');

const repoRoot = path.resolve(__dirname, '..', '..');
const wordRootsPath = path.join(repoRoot, 'js', 'wordData.js');
const outputPath = path.join(repoRoot, 'ios-native', 'WordRootWorkshop', 'Resources', 'wordRoots.json');

const roots = require(wordRootsPath);
if (!Array.isArray(roots) || roots.length === 0) {
  throw new Error('wordData.js did not export a non-empty array.');
}

fs.mkdirSync(path.dirname(outputPath), { recursive: true });
fs.writeFileSync(outputPath, JSON.stringify(roots, null, 2), 'utf8');

console.log(`Exported ${roots.length} roots to ${outputPath}`);
