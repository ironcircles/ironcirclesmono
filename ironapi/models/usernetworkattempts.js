const mongoose = require('mongoose');
var Schema = mongoose.Schema;

var UserNetworkAttempts = new mongoose.Schema({
    user: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
    network: { type: mongoose.Schema.Types.ObjectId, ref: 'HostedFurnace' },
    attempts: { type: Number, default: 1 },
    lastAttempt: { type: Date },
}, { timestamps: { createdAt: 'created', updatedAt: 'lastUpdate' } });

mongoose.model('UserNetworkAttempts', UserNetworkAttempts);

module.exports = mongoose.model('UserNetworkAttempts');