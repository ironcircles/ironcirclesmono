const mongoose = require('mongoose');

var UserConnectionSchema = new mongoose.Schema({
  user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', unique: true, },
  connections: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],
}, { timestamps: { createdAt: 'created', updatedAt: 'lastUpdate' } }, { collection: 'userconnection' });

mongoose.model('UserConnection', UserConnectionSchema);

module.exports = mongoose.model('UserConnection');