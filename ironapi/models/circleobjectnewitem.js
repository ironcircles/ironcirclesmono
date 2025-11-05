const mongoose = require('mongoose');

var CircleObjectNewItemSchema = new mongoose.Schema({
  circleObject: { type: mongoose.Schema.Types.ObjectId, ref: 'CircleObject', required: true },
  device: { type: String, required: true },
  user: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
}, { timestamps: { createdAt: 'created', updatedAt: 'lastUpdate' } }, { collection: 'circleobjectnewitem' });

CircleObjectNewItemSchema.statics.new = function (json) {
  return this(json);
}

module.exports = mongoose.model('CircleObjectNewItem', CircleObjectNewItemSchema);