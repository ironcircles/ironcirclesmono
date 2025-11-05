const mongoose = require('mongoose');


const CircleListTaskSchema = new mongoose.Schema({
  seed: { type: String}, //need to be able to match the task id to the client side decrypted name
  due: { type: Date},
  assignee: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  complete: { type: Boolean, default: false },
  completed: { type: Date},
  completedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' }, 
  order: { type: Number}, 
  //created: { type: Date, default: Date.now()},
}, { timestamps: { createdAt: 'created', updatedAt: 'lastUpdate' } }, { collection: 'circlelisttask' });


mongoose.model('CircleListTask', CircleListTaskSchema);
//mongoose.model('MasterList', MasterListSchema);

module.exports = mongoose.model('CircleListTask');
//module.exports = mongoose.model('MasterList');