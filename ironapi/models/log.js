const mongoose = require('mongoose');

var LogSchema = new mongoose.Schema({
  user: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  circle: { type: mongoose.Schema.Types.ObjectId, ref: 'Circle' },
  type: { type: String },
  source: { type: String },
  message: { type: String },
  stack: { type: String },
  device: { type: String },
  serverSide: { type: Boolean, default: true },
  timeStamp: { type: Date, },

}, { timestamps: { createdAt: 'created', updatedAt: 'lastUpdate' } }, { collection: 'logs' });

LogSchema.statics.new = async function (json) {

  let object = this(json);
  return object;
}


mongoose.model('Log', LogSchema);

module.exports = mongoose.model('Log');