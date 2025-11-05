const mongoose = require('mongoose');

var OfficialNotificationSchema = new mongoose.Schema({  
    title: {type: String},
    message: {type: String},
    enabled: {type: Boolean, default: true},
}, { timestamps: { createdAt: 'created', updatedAt: 'lastUpdate'}}, { collection: 'officialnotification' });

mongoose.model('OfficialNotification', OfficialNotificationSchema);

module.exports = mongoose.model('OfficialNotification');