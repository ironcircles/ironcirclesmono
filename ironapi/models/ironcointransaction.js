const mongoose = require('mongoose');
const constants = require('../util/constants');
var Prompt = require('./prompt');

var IronCoinTransactionSchema = new mongoose.Schema({
    amount: { type: Number },
    paymentType: { type: String },
    transactionID: { type: String },
    receiver: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
    sender: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
    user: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
    wallet: { type: mongoose.Schema.Types.ObjectId, ref: 'IronCoinWallet' },
    prompt: mongoose.model('Prompt').schema, //inbedded record
}, { timestamps: { createdAt: 'created', updatedAt: 'lastUpdate' } }, { collection: 'ironcointransaction' });

mongoose.model('IronCoinTransaction', IronCoinTransactionSchema);

module.exports = mongoose.model("IronCoinTransaction");