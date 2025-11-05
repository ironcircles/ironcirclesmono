/***************************************************************************
 * 
 * Author: JC
 * 
 * Purpose: Master class for all events in a circle.  
 * 
 * TODO:  Feature not finished
 * 
 *  
 ***************************************************************************/const mongoose = require('mongoose');  


var CircleEventMasterSchema = new mongoose.Schema({  
    circle: { type: mongoose.Schema.Types.ObjectId, ref: 'Circle' },  //denormalized to avoid Mongo search hell
    host: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
    event: { type: mongoose.Schema.Types.ObjectId, ref: 'Event' }
   
}, { timestamps: { createdAt: 'created', updatedAt: 'lastUpdate'}}, { collection: 'circleeventmasterss' });

mongoose.model('CircleEventMaster', CircleEventMasterSchema);

module.exports = mongoose.model('CircleEventMaster');