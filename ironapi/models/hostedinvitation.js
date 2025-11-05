const mongoose = require('mongoose');

var HostedInvitationSchema = new mongoose.Schema({
  token: { type: String, required: true },
  active: { type: Boolean, default: true },
  inviter: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  circle: { type: mongoose.Schema.Types.ObjectId, ref: 'Circle' },
  hostedFurnace: { type: mongoose.Schema.Types.ObjectId, ref: 'HostedFurnace' },
}, { timestamps: { createdAt: 'created', updatedAt: 'lastUpdate' } }, { collection: 'hostedinvitation' });

HostedInvitationSchema.statics.new = async function (json) {

  let object = this(json);
  return object;
}


mongoose.model('HostedInvitation', HostedInvitationSchema);

module.exports = mongoose.model('HostedInvitation');