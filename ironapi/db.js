//db.js

const mongoose = require('mongoose');
mongoose.Promise = global.Promise;

if (process.env.NODE_ENV !== 'production') {
  require('dotenv').load();
}

var dburl = process.env.dburl;
var dbuser = process.env.dbuser;
var dbpassword = process.env.dbpassword;

// Fix MongoDB connection string if password contains special characters
if (dburl && dburl.includes('@')) {
  try {
    // Try to parse the URL to see if it's valid
    const url = require('url');
    new url.URL(dburl);
  } catch (err) {
    // If parsing fails, it might be due to unescaped characters in password
    // Extract and encode the password part
    const match = dburl.match(/mongodb:\/\/([^:]+):([^@]+)@(.+)/);
    if (match) {
      const username = match[1];
      const password = match[2];
      const rest = match[3];
      // Encode all special characters in password for MongoDB connection string
      // MongoDB requires percent-encoding for: : / ? # [ ] @ ! $ & ' ( ) * + , ; = and space
      const encodedPassword = password
        .replace(/#/g, '%23')
        .replace(/\*/g, '%2A')
        .replace(/\(/g, '%28')
        .replace(/\)/g, '%29')
        .replace(/:/g, '%3A')
        .replace(/\//g, '%2F')
        .replace(/\?/g, '%3F')
        .replace(/\[/g, '%5B')
        .replace(/\]/g, '%5D')
        .replace(/@/g, '%40')
        .replace(/!/g, '%21')
        .replace(/\$/g, '%24')
        .replace(/&/g, '%26')
        .replace(/'/g, '%27')
        .replace(/\+/g, '%2B')
        .replace(/,/g, '%2C')
        .replace(/;/g, '%3B')
        .replace(/=/g, '%3D')
        .replace(/ /g, '%20');
      dburl = `mongodb://${username}:${encodedPassword}@${rest}`;
      console.log('Fixed MongoDB connection string (encoded password)');
    }
  }
}

const authData = {
 // "user": dbuser,
  //"pass": dbpassword,
  "useNewUrlParser": true,
  //"useCreateIndex": true
};

var connection;

if (process.env.NODE_ENV !== 'production') {
  connection = mongoose.connect(dburl, authData).catch(function (err) { // { auth: { user: dbuser, password: dbpassword }, useNewUrlParser: true, useUnifiedTopology: true }).catch(function (err) {
    console.error(err);

  });
} else {

  connection = mongoose.connect(dburl, { useNewUrlParser: true }).catch(function (err) {
    console.error(err);

  });
}

function dbReady() {
  return connection;
}

module.exports = {
  dbReady
};

//= mongoose.createConnection(imgurl);




