/*const mongoose = require('mongoose');
var Schema = mongoose.Schema;
const constants = require('../util/constants');


var AccountSchema = new Schema({
    userID: { type: String, required: true },
    authServer: { type: Boolean, default: true },
    guaranteedUnique: { type: Boolean, default: false },
    accountType: { type: Number, default: constants.ACCOUNT_TYPE.FREE },
    tos: { type: Date },
    over18: { type: Boolean, default: true },
    autoKeychainBackup: { type: Boolean, default: false },
    submitLogs: { type: Boolean, default: false },
    lastKeyBackup: { type: Date },
    hostedFurnace: { type: mongoose.Schema.Types.ObjectId, ref: 'HostedFurnace' },

}, { timestamps: { createdAt: 'created', updatedAt: 'lastUpdate' } });



module.exports = mongoose.model('Account', AccountSchema);*/
