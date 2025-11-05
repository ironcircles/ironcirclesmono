/***************************************************************************
 * 
 * Author: JC
 * 
 * Purpose: Model for reviews.  Where it all started.  
 * 
 * 
 *  
 ***************************************************************************/
const mongoose = require('mongoose');


var ProductSchema = new mongoose.Schema({
  versionCurrent: { type: String },
  versionMinimum: { type: String },
}, { timestamps: { createdAt: 'created', updatedAt: 'lastUpdate' } }, { collection: 'product' });

mongoose.model('Product', ProductSchema);

module.exports = mongoose.model('Product');
