const mongoose = require('mongoose');


var DeviceSchema = new mongoose.Schema({  
    uuid : {type: String},
    platform : {type: String},
    manufacturer: {type: String},
    name: {type: String},
    model: {type: String},
    build: {type: Number},
    lastLogin: {type: Date},
    identity: { type: String },
    // pk: { type: Buffer },
    // sk: { type: Buffer },
    // ss: { type: Buffer },
    pushToken: {type: String}, 
    expiredToken: {type: String}, 
    activated: {type: Boolean, default: true},
    keysRemoved: {type: Boolean},
    wiped: {type: Boolean, default: false},
    loggedIn: {type: Boolean, default:true},
}, { timestamps: { createdAt: 'created', updatedAt: 'lastUpdate'}}, { collection: 'devices' });


module.exports = mongoose.model('Device', DeviceSchema);
