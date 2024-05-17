var express = require('express');

// Constants
var PORT = 2000;

// App
var app = express();
app.get('/', function (req, res){
  res.send('Hello world');
});

app.listen(PORT);
console.log('Running on http://localhost:' + PORT);
