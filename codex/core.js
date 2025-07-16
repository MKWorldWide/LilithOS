const fs = require('fs');
const path = require('path');

const codexDir = __dirname;
const entriesDir = path.join(codexDir, 'entries');
const logFile = path.join(codexDir, 'index.log');

function ensureDirectories() {
  if (!fs.existsSync(entriesDir)) {
    fs.mkdirSync(entriesDir, { recursive: true });
  }
}

function logCodexEvent({ source, action, result, mood, tone, effect }) {
  const timestamp = new Date().toISOString();
  const entry = { timestamp, source, action, result, mood, tone, effect };
  ensureDirectories();

  const line = `[${timestamp}] ${source} | ${action} => ${result} ` +
    `[mood:${mood}|tone:${tone}|effect:${effect}]\n`;
  fs.appendFileSync(logFile, line);

  const fileName = `${timestamp.replace(/[:]/g, '_')}.json`;
  const entryPath = path.join(entriesDir, fileName);
  fs.writeFileSync(entryPath, JSON.stringify(entry, null, 2));
}

module.exports = { logCodexEvent };
