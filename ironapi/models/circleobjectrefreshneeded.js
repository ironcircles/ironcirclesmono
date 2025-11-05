/***************************************************************************
 * 
 * Author: JC
 * 
 * Purpose: Queue of items that need a client side refresh. 
 * Items are deleted upon read receipt from the client.
 *  
 ***************************************************************************/
const mongoose = require('mongoose');

var CircleObjectRefreshNeededSchema = new mongoose.Schema({
  user: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  circleObject: { type: mongoose.Schema.Types.ObjectId, ref: 'CircleObject' },
  device: { type: String }

}, { timestamps: { createdAt: 'created', updatedAt: false } }, { collection: 'circleobjectrefreshneeded' });


mongoose.model('CircleObjectRefreshNeeded', CircleObjectRefreshNeededSchema);

module.exports = mongoose.model('CircleObjectRefreshNeeded');