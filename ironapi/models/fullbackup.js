const mongoose = require('mongoose');

var FullBackupSchema = new mongoose.Schema({
  fullBackup: { type: String, },
  device: { type: String, },
  location: { type: String, },
  keychainSize: { type: String },
  user: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
}, { timestamps: { createdAt: 'created', updatedAt: 'lastUpdate' } }, { collection: 'fullbackup' });

mongoose.model('FullBackup', FullBackupSchema);

module.exports = mongoose.model('FullBackup');