/***************************************************************************
 * 
 * Author: JC
 * 
 * Purpose: Model for user avatar information
 * 
 * 
 *  
 ***************************************************************************/
const mongoose = require('mongoose');

var HostedFurnaceImageSchema = new mongoose.Schema({
  name: { type: String },
  size: { type: Number },
  location: { type: String },

}, { timestamps: { createdAt: 'created', updatedAt: 'lastUpdate' } }, { collection: 'hostedfurnaceimage' });



mongoose.model('HostedFurnaceImage', HostedFurnaceImageSchema);

module.exports = mongoose.model('HostedFurnaceImage');