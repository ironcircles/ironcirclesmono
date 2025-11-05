const mongoose = require('mongoose');

var KeychainBackupSchema = new mongoose.Schema({
  keychain: { type: String, },
  device: { type: String, },
  location: { type: String, },
  keychainSize: { type: String },
  user: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
}, { timestamps: { createdAt: 'created', updatedAt: 'lastUpdate' } }, { collection: 'keychainbackup' });

mongoose.model('KeychainBackup', KeychainBackupSchema);

module.exports = mongoose.model('KeychainBackup');