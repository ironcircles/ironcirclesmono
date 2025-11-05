const mongoose = require('mongoose');

var KeychainFullSchema = new mongoose.Schema({
  keychain: { type: String, },
  device: { type: String, },
  location: { type: String, },
  keychainSize: { type: String },
  user: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
}, { timestamps: { createdAt: 'created', updatedAt: 'lastUpdate' } }, { collection: 'keychainfull' });

mongoose.model('KeychainFull', KeychainFullSchema);

module.exports = mongoose.model('KeychainFull');