const mongoose = require('mongoose');


const CircleListTemplateTaskSchema = new mongoose.Schema({
  //name: { type: String},
  //due: { type: Date},
  seed: { type: String }, //need to be able to match the task id to the client side decrypted name
  assignee: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  order: { type: Number },
  //created: { type: Date, default: Date.now()},
}, { timestamps: { createdAt: 'created', updatedAt: 'lastUpdate' } }, { collection: 'circlelisttemplatetask' });


mongoose.model('CircleListTemplateTask', CircleListTemplateTaskSchema);
module.exports = mongoose.model('CircleListTemplateTask');
