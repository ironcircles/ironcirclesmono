/***************************************************************************
 * 
 * Author: JC
 * 
 * Purpose: Model for subscriptions
 * 
 * 
 *  
 ***************************************************************************/

const User = require('../models/user');

const mongoose = require('mongoose');

var SubscriptionSchema = new mongoose.Schema({
  user: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  seed: { type: String },
  type: { type: String },
  purchaseDetailsJson: { type: String },
  purchaseID: { type: String },
  transactionDate: { type: Date },
  cancelDate: { type: Date },
  pauseDate: { type: Date },
  resumeDate: { type: Date },
  verificationLocal: { type: String },
  verificationServer: { type: String },
  verificationSource: { type: String },
  status: { type: Number },

}, { timestamps: { createdAt: 'created', updatedAt: 'lastUpdate' } }, { collection: 'subscription' });



mongoose.model('Subscription', SubscriptionSchema);

module.exports = mongoose.model('Subscription');