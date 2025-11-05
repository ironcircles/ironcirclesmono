const mongoose = require('mongoose');

const RatchetPublicKeySchema = new mongoose.Schema({
  //circle: { type: mongoose.Schema.Types.ObjectId, ref: 'Circle', required: true },
  user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', },
  //mongoose.model('RatchetIndex').schema
  device: {type: String, required: true},
  public: {type: String, required: true},
  keyIndex: {type: String, required: true},

}, { timestamps: { createdAt: 'created', updatedAt: 'lastUpdate' } }, { collection: 'ratchetpublickey' });



RatchetPublicKeySchema.statics.new = function (json) {
  return this(json);
}



module.exports = mongoose.model('RatchetPublicKey', RatchetPublicKeySchema);
