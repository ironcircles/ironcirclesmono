const mongoose = require('mongoose');
const RatchetPublicKey = require('../models/ratchetpublickey');

var RatchetPublicKeyHistorySchema = new mongoose.Schema({
    circle: { type: mongoose.Schema.Types.ObjectId, ref: 'Circle' },
    user: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
    userCircle: { type: mongoose.Schema.Types.ObjectId, ref: 'UserCircle' },
    ratchetPublicKeys: [mongoose.model('RatchetPublicKey').schema],
    removedPublicKeys: [mongoose.model('RatchetPublicKey').schema],
    newPublicKey: mongoose.model('RatchetPublicKey').schema,
}, { timestamps: { createdAt: 'created', updatedAt: 'lastUpdate' } }, { collection: 'ratchetpublickeyhistory' });


mongoose.model('RatchetPublicKeyHistory', RatchetPublicKeyHistorySchema);

module.exports = mongoose.model('RatchetPublicKeyHistory');