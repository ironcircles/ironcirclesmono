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
const Circle = require('./circle');


var CircleSettingsObjectSchema = new mongoose.Schema({
  circle: { type: mongoose.Schema.Types.ObjectId, ref: 'Circle' },
  proposedCircle:  mongoose.model('Circle').schema, 

}, { timestamps: { createdAt: 'created', updatedAt: 'lastUpdate' } }, { collection: 'circlesettingsobjectschema' });

mongoose.model('CircleSettingsObject', CircleSettingsObjectSchema);

module.exports = mongoose.model('CircleSettingsObject');