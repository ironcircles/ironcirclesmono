const mongoose = require('mongoose');

var CircleObjectDeliveredSchema = new mongoose.Schema({
  circleObjectID: { type: mongoose.Schema.Types.ObjectId, ref: 'CircleObject', required: true },
  device: { type: String, required: true },
  userID: { type: String, required: true },
}, { timestamps: { createdAt: 'created', updatedAt: 'lastUpdate' } }, { collection: 'circleobjectdelivered' });

CircleObjectDeliveredSchema.statics.new = function (json) {
  return this(json);
}

module.exports = mongoose.model('CircleObjectDelivered', CircleObjectDeliveredSchema);