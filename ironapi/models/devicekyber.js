const mongoose = require('mongoose');

var DeviceKyberSchema = new mongoose.Schema({
  deviceID: { type: String },
  pk: { type: Buffer },
  sk: { type: Buffer },
  ss: { type: Buffer },
  users: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],
}, { timestamps: { createdAt: 'created', updatedAt: 'lastUpdate' } }, { collection: 'devicekyber' });

mongoose.model('DeviceKyber', DeviceKyberSchema);

module.exports = mongoose.model('DeviceKyber');