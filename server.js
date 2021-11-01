'use strict';

const express = require('express');
const db = require('./db');

// Constants
const port = process.env.PORT || 8080;
const host = process.env.HOST || '0.0.0.0';

// App
const app = express();
app.get('/', (req, res) => {
  db.helloCollection.findOne({}, '-_id', function(err, entity) {
    res.send(entity.toJSON().data);
  });
});

app.listen(port, host);
console.log(`Running on http://${host}:${port}`);
