const mongoose = require('mongoose');

var DeviceRemoteWipe = new mongoose.Schema({  
    users: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],
    deviceOwner: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
    uuid : {type: String},
    code : {type: String},
}, { timestamps: { createdAt: 'created', updatedAt: 'lastUpdate'}}, { collection: 'deviceremotewipe' });


module.exports = mongoose.model('DeviceRemoteWipe', DeviceRemoteWipe);