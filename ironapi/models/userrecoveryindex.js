const RatchetIndex = require('./ratchetindex');

const mongoose = require('mongoose');

var UserRecoveryIndexSchema = new mongoose.Schema({
    user: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
    ratchetIndex: mongoose.model('RatchetIndex').schema,

}, { timestamps: { createdAt: 'created', updatedAt: 'lastUpdate' } }, { collection: 'userrecoveryindex' });



mongoose.model('UserRecoveryIndex', UserRecoveryIndexSchema);

module.exports = mongoose.model('UserRecoveryIndex');