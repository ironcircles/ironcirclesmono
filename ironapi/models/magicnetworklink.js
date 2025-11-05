const mongoose = require('mongoose');
var PublicKey = require('./ratchetpublickey');

var MagicNetworkLinkSchema = new mongoose.Schema({
  link: { type: String, required: true },
  firebaseLink: { type: String },
  active: { type: Boolean, default: true },
  dm: { type: Boolean, default: false },
  inviter: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  circle: { type: mongoose.Schema.Types.ObjectId, ref: 'Circle' },
  hostedFurnace: { type: mongoose.Schema.Types.ObjectId, ref: 'HostedFurnace' },
  ratchetPublicKey: mongoose.model('RatchetPublicKey').schema,
}, { timestamps: { createdAt: 'created', updatedAt: 'lastUpdate' } }, { collection: 'magicnetworklink' });

MagicNetworkLinkSchema.statics.new = async function (json) {

  let object = this(json);
  return object;
}


mongoose.model('MagicNetworkLink', MagicNetworkLinkSchema);

module.exports = mongoose.model('MagicNetworkLink');