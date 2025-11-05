const mongoose = require('mongoose');
//const CircleListTask = require('../models/circlelisttask');

const CircleListSchema = new mongoose.Schema({
  circle: { type: mongoose.Schema.Types.ObjectId, ref: 'Circle', required: true },
  lastEdited: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  template: { type: mongoose.Schema.Types.ObjectId, ref: 'CircleListTemplate' },
  complete: { type: Boolean, default: false },
  checkable: { type: Boolean, default: true },
  /*tasks: [mongoose.model('CircleListTask').schema]*/
  tasks: [{ type: mongoose.Schema.Types.ObjectId, ref: 'CircleListTask' }],

}, { timestamps: false /*{ createdAt: 'created', updatedAt: 'lastUpdate' }*/ }, { collection: 'circlelist' });

mongoose.model('CircleList', CircleListSchema);
module.exports = mongoose.model('CircleList');
