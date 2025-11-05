const mongoose = require('mongoose');

/***************************************************************************
 * 
 * Author: JC
 * 
 * Purpose: 
 *  
 ***************************************************************************/

var DeviceBlockSchema = new mongoose.Schema({
  deviceID: String,
  pushToken: String,
}, { timestamps: false }, { collection: 'deviceblock' });


module.exports = mongoose.model('DeviceBlock', DeviceBlockSchema);