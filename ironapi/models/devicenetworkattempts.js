const mongoose = require('mongoose');
var Schema = mongoose.Schema;

var DeviceNetworkAttempts = new mongoose.Schema({
    device: { type: String, ref: 'Device' },
    network: { type: mongoose.Schema.Types.ObjectId, ref: 'HostedFurnace' },
    attempts: { type: Number, default: 1 },
    lastAttempt: { type: Date },
}, { timestamps: { createdAt: 'created', updatedAt: 'lastUpdate' }});

mongoose.model('DeviceNetworkAttempts', DeviceNetworkAttempts);

module.exports = mongoose.model('DeviceNetworkAttempts');