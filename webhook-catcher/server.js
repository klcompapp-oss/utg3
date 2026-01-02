const express = require('express');
const fs = require('fs');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 8080;
const LOGFILE = path.join(__dirname, 'requests.log');

app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

function logRequest(obj) {
  const line = `[${new Date().toISOString()}] ${JSON.stringify(obj)}\n`;
  process.stdout.write(line);
  fs.appendFile(LOGFILE, line, () => {});
}

app.all('*', (req, res) => {
  const fullUrl = `${req.protocol}://${req.get('host')}${req.originalUrl}`;
  const data = {
    method: req.method,
    url: fullUrl,
    path: req.originalUrl,
    query: req.query,
    headers: req.headers,
    body: req.body
  };

  logRequest(data);

  res.json({ ok: true, received: data });
});

app.listen(PORT, () => {
  console.log(`Webhook catcher listening on port ${PORT}`);
  console.log(`Log file: ${LOGFILE}`);
});
