const mongoose = require('mongoose');

/***************************************************************************
 * 
 * Author: JC
 * 
 * Purpose: 
 *  
 ***************************************************************************/

var ReceiptSchema = new mongoose.Schema({
  creator: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  devices: [{ type: String }],
  read: [{ type: Number }],
}, { timestamps: false }, { collection: 'receipt' });


module.exports = mongoose.model('Receipt', ReceiptSchema);