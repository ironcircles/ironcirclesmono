const mongoose = require('mongoose');
const constants = require('../util/constants');

//These are actually needed, ignore the compiler
var RatchetIndex = require('../models/ratchetindex');

var InvitationSchema = new mongoose.Schema({
    invitee: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
    inviter: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
    circle: { type: mongoose.Schema.Types.ObjectId, ref: 'Circle' },
    lastReminderSent: { type: Date, default: Date.now() },
    ratchetIndex: mongoose.model('RatchetIndex').schema,
    dm: { type: Boolean, default: false },
    //systemmessage: { type: mongoose.Schema.Types.ObjectId, ref: 'CircleObject' },
    vote: { type: mongoose.Schema.Types.ObjectId, ref: 'CircleVote' },
    status: String  //constants.INVITATION_STATUS

}, { timestamps: { createdAt: 'created', updatedAt: 'lastUpdate' } }, { collection: 'invitations' });

mongoose.model('Invitation', InvitationSchema);

module.exports = mongoose.model('Invitation');