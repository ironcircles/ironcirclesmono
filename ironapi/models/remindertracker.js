const mongoose = require('mongoose');

/***************************************************************************
 * 
 * Author: JC
 * 
 * Purpose: 
 *  
 ***************************************************************************/

var ReminderTrackerSchema = new mongoose.Schema({
  user: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  objectID: {type: String},
  reminderType: { type: Number },
}, { timestamps: { createdAt: 'created', updatedAt: 'lastUpdate' } }, { collection: 'remindertracker' });



mongoose.model('ReminderTracker', ReminderTrackerSchema);

module.exports = mongoose.model('ReminderTracker');