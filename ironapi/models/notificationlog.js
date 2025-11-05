const mongoose = require('mongoose');

//These are actually needed, ignore the compiler
var Device = require('../models/device');

var NotificationLogSchema = new mongoose.Schema({
  receiver: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  sender: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  circle: { type: mongoose.Schema.Types.ObjectId, ref: 'Circle' },
  circleObject: { type: mongoose.Schema.Types.ObjectId, ref: 'CircleObject' },
  devices: [mongoose.model('Device').schema],
  notification: { type: String },
  type: { type: Number },
  pushToken: { type: String },
  device: { type: String },
  object: { type: String },
  object1: { type: String },
  object2: { type: String },
  status: { type: Number },
  success: { type: Boolean, default: true },
  error: { type: String },
}, { timestamps: { createdAt: 'created', updatedAt: 'lastUpdate' } }, { collection: 'notificationlog' });

NotificationLogSchema.statics.new = async function (json) {

  let object = this(json);

  return object;
}

module.exports = mongoose.model('NotificationLog', NotificationLogSchema);