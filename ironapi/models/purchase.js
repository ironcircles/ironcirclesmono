/*********************
* Purchase Object
* For buying IronCoin
**********************/

const User = require('./user');
const mongoose = require('mongoose');

var PurchaseSchema = new mongoose.Schema({
    user: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
    seed: { type: String },
    type: { type: String },
    purchaseDetailsJson: { type: String },
    purchaseID: { type: String },
    transactionDate: { type: Date },
    verificationLocal: { type: String },
    verificationServer: { type: String },
    verificationSource: { type: String },
    status: { type: Number },
    quantity: { type: Number },
}, { timestamps: { createdAt: 'created', updatedAt: 'lastUpdate' } }, { collection: 'purchase'});

mongoose.model('Purchase', PurchaseSchema);

module.exports = mongoose.model('Purchase');
