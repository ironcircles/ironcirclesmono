/***************************************************************************
 * 
 * Author: JC
 * 
 * Purpose: Model for a circle
 * 
 * items of note:
 *  type: current is only standard
 *  ownershipmodel - members or owner
 *  backgroundImage - can be null if users is using the default
 *  votingModel  - unanimous or majority (majority not built yet)
 *  owner - null if member owned
 *  
 ***************************************************************************/
const mongoose = require('mongoose');
const constants = require('../util/constants');


var CircleSchema = new mongoose.Schema({
  name: { type: String },
  type: { type: String, default: constants.CIRCLE_TYPE.STANDARD },     //versus future temporary
  ownershipModel: { type: String, default: constants.CIRCLE_OWNERSHIP.MEMBERS },  //versus owner controlled
  toggleMemberPosting: { type: Boolean, default: true }, //if wall or owner circle, can members post
  toggleMemberReacting: { type: Boolean, default: true }, //if wall or owner circle, can members react
  dm: { type: Boolean, default: false },
  background: { type: String },
  backgroundLocation: { type: String },
  backgroundColor: { type: Number },
  retention: { type: Number, default: constants.CIRCLE_RETENTION.DEVICE_ONLY },
  backgroundSize: { type: Number },
  privacyVotingModel: { type: String, default: constants.VOTE_MODEL.UNANIMOUS },
  privacyIncludeCircleName: { type: Boolean, default: false },
  privacyInvitationTimeout: { type: Number, default: 48 },
  privacyShareImage: { type: Boolean, default: false },
  privacyShareURL: { type: Boolean, default: true },
  privacyShareGif: { type: Boolean, default: true },
  privacyCopyText: { type: Boolean, default: true },
  toggleEntryVote: { type: Boolean, default: true },
  securityVotingModel: { type: String, default: constants.VOTE_MODEL.MAJORITY },
  securityMinPassword: { type: Number, default: 8 },
  //security2FA: { type: Boolean, default: false },
  securityDaysPasswordValid: { type: Number, default: 90 },
  securityTokenExpirationDays: { type: Number, default: 30 },
  securityLoginAttempts: { type: Number, default: 9 },
  privacyDisappearingTimer: { type: Number, default: 0 },
  privacyDisappearingTimerSeconds: { type: Number, default: 0 },
  //invitationTimeout: { type: Number, default: 48 },
  owner: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  expiration: { type: Date, default: null },

}, { timestamps: { createdAt: 'created', updatedAt: 'lastUpdate' } }, { collection: 'circles' });

CircleSchema.methods.chatType = function () {
  if (this.dm)
    return 'dm';
  else
    return 'circle';
}


mongoose.model('Circle', CircleSchema);

module.exports = mongoose.model('Circle');