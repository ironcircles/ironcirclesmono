/***************************************************************************
 * 
 * Author: JC
 * 
 * Purpose: Model for subscriptions
 * 
 * 
 *  
 ***************************************************************************/

const User = require('./user');

const mongoose = require('mongoose');

var UserHelperSchema = new mongoose.Schema({
  user: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  helpers: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' },],
  helperType: {type: Number},

}, { timestamps: { createdAt: 'created', updatedAt: 'lastUpdate' } }, { collection: 'userhelper' });



mongoose.model('UserHelper', UserHelperSchema);

module.exports = mongoose.model('UserHelper');