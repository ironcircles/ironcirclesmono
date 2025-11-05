var app = require('./app');
var port = process.env.PORT || 3001;

var server = app.listen(port, function() {

  //server.setTimeout(300000);
  console.log('Express server listening on port ' + port);
});