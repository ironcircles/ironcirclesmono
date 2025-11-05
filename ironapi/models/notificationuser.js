const mongoose = require('mongoose');

var NotificationUserSchema = new mongoose.Schema({  
    user: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
    officialNotification: { type: mongoose.Schema.Types.ObjectId, ref: 'OfficialNotification' },

}, { timestamps: { createdAt: 'created', updatedAt: 'lastUpdate'}}, { collection: 'notificationuser' });

mongoose.model('NotificationUser', NotificationUserSchema);

module.exports = mongoose.model('NotificationUser');