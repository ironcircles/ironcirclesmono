/***************************************************************************
 * 
 * Author: JC
 * 
 * Purpose: Model for storing call sessions
 * 
 * 
 *  
 ***************************************************************************/
const { duration } = require('moment');
const mongoose = require('mongoose');

var CircleAgoraCallSchema = new mongoose.Schema({
  circle: { type: mongoose.Schema.Types.ObjectId, ref: 'Circle', required: true },
  circleobject: { type: mongoose.Schema.Types.ObjectId, ref: 'CircleObject', required: true },
  channel: { type: String },
  active: { type: Boolean, default: true },
  duration: { type: Number, default: 0 },
  startTime: { type: Date, default: Date.now },
  endTime: { type: Date, default: null },
  participants: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],
  activeParticipants: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],
  callType: { type: String, enum: ['audio', 'video'], default: 'video' }

}, { timestamps: { createdAt: 'created', updatedAt: 'lastUpdate' } }, { collection: 'circleagoracall' });


mongoose.model('CircleAgoraCall', CircleAgoraCallSchema);

module.exports = mongoose.model('CircleAgoraCall');