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

var CircleAgoraCallMinutesSchema = new mongoose.Schema({
  agoraCall: { type: mongoose.Schema.Types.ObjectId, ref: 'CircleAgoraCall' },
  duration: { type: Number, default: 0 },
  startTime: { type: Date, default: Date.now },
  endTime: { type: Date, default: null },
  user: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },

}, { timestamps: { createdAt: 'created', updatedAt: 'lastUpdate' } }, { collection: 'circleagoracallminutes' });


mongoose.model('CircleAgoraCallMinutes', CircleAgoraCallMinutesSchema);
module.exports = mongoose.model('CircleAgoraCallMinutes');