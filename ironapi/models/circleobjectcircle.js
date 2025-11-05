const mongoose = require('mongoose');

///for use for scheduled messages
var CircleObjectCircleSchema = new mongoose.Schema({
    circle: { type: mongoose.Schema.Types.ObjectId, ref: 'Circle' },
    circleObject: { type: mongoose.Schema.Types.ObjectId, ref: "CircleObject" },
    taggedUsers: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],
}, { timestamps: { createdAt: 'created', updatedAt: 'lastUpdate'}}, { collection: 'circleobjectcircle' });

mongoose.model('CircleObjectCircle', CircleObjectCircleSchema);

module.exports = mongoose.model('CircleObjectCircle');