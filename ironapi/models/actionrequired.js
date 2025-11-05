const mongoose = require('mongoose');

/***************************************************************************
 * 
 * Author: JC
 * 
 * Purpose: 
 *  
 ***************************************************************************/

var ActionRequiredSchema = new mongoose.Schema({
  user: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  resetFragment: { type: String},
  resetUser: { type: mongoose.Schema.Types.ObjectId, ref: 'User' }, //for backwards compatibilty, use the one below for new AR types
  member: { type: mongoose.Schema.Types.ObjectId, ref: 'User' }, //Use this going forward
  alert: { type: String},
  ratchetPublicKey: mongoose.model('RatchetPublicKey').schema,
  alertType: { type: Number},
  networkRequest: { type: mongoose.Schema.Types.ObjectId, ref: 'NetworkRequest'},
  requestHostedFurnace: { type: mongoose.Schema.Types.ObjectId, ref: 'HostedFurnace'}

}, { timestamps: { createdAt: 'created', updatedAt: 'lastUpdate' } }, { collection: 'actionrequired' });



mongoose.model('ActionRequired', ActionRequiredSchema);

module.exports = mongoose.model('ActionRequired');