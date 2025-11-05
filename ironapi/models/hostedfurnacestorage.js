const mongoose = require('mongoose');

var HostedFurnaceStorageSchema = new mongoose.Schema({
  accessKey: { type: String },
  secretKey: { type: String },
  region: { type: String },
  mediaBucket: { type: String },
  location: { type: String },
}, { timestamps: { createdAt: 'created', updatedAt: 'lastUpdate' } }, { collection: 'hostedfurnacestorage' });

HostedFurnaceStorageSchema.statics.new = async function (json) {

  let object = this(json);
  return object;
}

mongoose.model('HostedFurnaceStorage', HostedFurnaceStorageSchema);
module.exports = mongoose.model('HostedFurnaceStorage');