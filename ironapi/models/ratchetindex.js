const mongoose = require('mongoose');

const RatchetIndexSchema = new mongoose.Schema({
  user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  ratchetIndex: { type: String },  //index of remote user's public key
  ratchetValue: { type: String },  //encrypted message key
  crank: { type: String },  //nounce
  signature: { type: String },  ///XChaCha signature
  device: { type: String, },
  active: { type: Boolean, default: true },
  kdfNonce: { type: String},  //this nonce is used for encrypted backup secrets
  //these are not used for baseCircleObjects
  cipher: { type: String },  //user for all but CircleObjects
  cipherCrank: { type: String },  //nonce
  cipherSignature: { type: String },  //mac signature
  senderRatchetPublic: { type: String },  //sender's ratcheted public key

}, { timestamps: false }, { collection: 'ratchetindex' });

//deprecated
RatchetIndexSchema.statics.fromJson = function (json) {
  let local = this(json);

  if (local.kdfNonce == null) local.kdfNonce = undefined;
  if (local.cipher == null) local.cipher = undefined;
  if (local.cipherCrank == null) local.cipherCrank = undefined;
  if (local.cipherSignature == null) local.cipherSignature = undefined;
  if (local.senderRatchetPublic == null) local.senderRatchetPublic = undefined;

  return local;
}

RatchetIndexSchema.statics.new = function (json) {
  let local = this(json);

  if (local.kdfNonce == null) local.kdfNonce = undefined;
  if (local.cipher == null) local.cipher = undefined;
  if (local.cipherCrank == null) local.cipherCrank = undefined;
  if (local.cipherSignature == null) local.cipherSignature = undefined;
  if (local.senderRatchetPublic == null) local.senderRatchetPublic = undefined;

  return local;

}


mongoose.model('RatchetIndex', RatchetIndexSchema);
module.exports = mongoose.model('RatchetIndex');
