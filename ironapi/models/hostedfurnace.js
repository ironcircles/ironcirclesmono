const mongoose = require('mongoose');

var HostedFurnaceStorage = require('../models/hostedfurnacestorage');
var HostedFurnaceImage = require('../models/hostedfurnaceimage');

var HostedFurnaceSchema = new mongoose.Schema({
  name: { type: String, required: true },
  lowercase: { type: String, required: true },
  key: { type: String, required: true },
  discoverable: { type: Boolean, default: false },
  approved: { type: Boolean, default: false }, ///networks are not discoverable until approved by admin
  storeApproved: { type: Boolean }, ///networks are not discoverable until approved by admin, no default, so it is not set until approved
  override: { type: Boolean, default: false }, ///ability to change a network to discoverable is blocked, used to disable discovery for a network, for example if hate speech is found
  enableWall: { type: Boolean, default: false },
  wallCircleID: { type: String, }, //not an object ref on purpose, would cause a circular reference
  adultOnly: { type: Boolean, default: false },
  memberAutonomy: { type: Boolean, default: true }, ///can members create circles/vaults & send invites
  type: { type: Number, default: 1 },
  description: { type: String },
  link: { type: String },
  hostedFurnaceImage: mongoose.model('HostedFurnaceImage').schema,
  storage: [mongoose.model('HostedFurnaceStorage').schema],
}, { timestamps: { createdAt: 'created', updatedAt: 'lastUpdate' } }, { collection: 'hostedfurnace' });

HostedFurnaceSchema.statics.new = async function (json) {

  let object = this(json);
  return object;
}


mongoose.model('HostedFurnace', HostedFurnaceSchema);

module.exports = mongoose.model('HostedFurnace');