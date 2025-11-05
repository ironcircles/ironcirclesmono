const mongoose = require('mongoose');
const constants = require('../util/constants');
//var Prompt = require('./prompt');
const Double = require("@mongoosejs/double");

var IronCoinWalletSchema = new mongoose.Schema({
    balance: { type: Double, default: 0 },
    user: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
    //transactions: [{ type: mongoose.Schema.Types.ObjectId, ref: 'IronCoinTransaction' }],
}, { timestamps: { createdAt: 'created', updatedAt: 'lastUpdate' } }, { collection: 'ironcoinwallet' });

mongoose.model('IronCoinWallet', IronCoinWalletSchema);

module.exports = mongoose.model("IronCoinWallet");