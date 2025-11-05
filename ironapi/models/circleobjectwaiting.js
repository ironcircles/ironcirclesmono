const mongoose = require('mongoose');
const device = require('./device');

///used for 
var CircleObjectWaitingSchema = new mongoose.Schema({
    circleObject: { type: mongoose.Schema.Types.ObjectId, ref: "CircleObject" },
    taggedUsers: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],
    pushToken: { type: String },
    notification: { type: String },
    notificationType: { type: String },
    skipDevice: { type: String },


}, { timestamps: { createdAt: 'created', updatedAt: 'lastUpdate'}}, { collection: 'circleobjectwaiting' });

mongoose.model('CircleObjectWaiting', CircleObjectWaitingSchema);

module.exports = mongoose.model('CircleObjectWaiting');