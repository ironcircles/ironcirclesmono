const Log = require('../models/log');


module.exports.getIP = function(request) {

  try {
    let ipAddr = request.connection.remoteAddress;

    if (request.headers && request.headers['x-forwarded-for']) {
      [ipAddr] = request.headers['x-forwarded-for'].split(',');
    }

    return ipAddr;
  } catch (err) {
    logUtil.logError(err, true);
    return '';
  }
}
module.exports.logError = async function (err, saveToLog, ip, userID) {
  var msg;

  try {

    if (err instanceof Error) msg = err.message;
    else msg = err;

    var log = new Log({
      message: msg, type: "error", timeStamp: new Date()
    });

    if (ip != undefined && ip != null) {
      log.source = ip;
      console.error(err + ": " + ip);
    } else {
      console.log(err);
    }

    if (userID != undefined && userID != null) log.userID = userID;

    if (err.stack != undefined) log.stack = err.stack;

    //don't log spammed errors due to cell network connectivity
    if (this.skipLog(log)) return msg;
    await log.save();

  } catch (err) {
    console.log(err);
  }

  return msg;

}

module.exports.skipLog = function (log) {

  try {

    if (log.message.toLowerCase().includes('bad file descriptor')) return true;
    if (log.message.toLowerCase().includes('connection closed')) return true;
    if (log.message.toLowerCase().includes('connection reset')) return true;
    if (log.message.toLowerCase().includes('exception: no phrase entered')) return true;
    if (log.message.toLowerCase().includes('handshakeexception:')) return true;
    if (log.message.toLowerCase().includes('failed host lookup:')) return true;
    if (log.message.toLowerCase().includes('socketexception')) return true;
    if (log.message.toLowerCase().includes('software caused connection abort')) return true;
    if (log.message.toLowerCase().includes('databaseexception(unique constraint')) return true;
    if (log.message.toLowerCase().includes('backup key is empty for')) return true;
    if (log.message.toLowerCase().includes('global event refresh')) return true;
    if (log.message.toLowerCase().includes('unique constraint failed: memberbyuser.memberid')) return true;
    if (log.message.toLowerCase().includes('multiple devices in sqllite')) return true;


  } catch (err) {
    console.log(err);
  }

  return false;

}

module.exports.logAlert = async function (alert, ip, userID) {

  try {

    console.log(alert);

    var log = new Log({
      message: alert, type: "alert", timeStamp: new Date()
    });

    if (ip != undefined && ip != null) log.source = ip;

    if (userID != undefined && userID != null) log.user = userID;

    await log.save();

  } catch (err) {
    console.log(err);
  }

}