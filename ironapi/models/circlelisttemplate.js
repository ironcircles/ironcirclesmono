const mongoose = require('mongoose');
const CircleListTemplateTask = require('./circlelisttemplatetask');
const RatchetIndex = require('./ratchetindex');

const CircleListTemplateSchema = new mongoose.Schema({
  owner: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  seed: { type: String, },
  body: { type: String, },
  signature: {type: String},
  ratchetIndexes: [mongoose.model('RatchetIndex').schema],
  crank: { type: String },
  checkable: { type: Boolean, default: true },
  tasks: [{ type: mongoose.Schema.Types.ObjectId, ref: 'CircleListTemplateTask' }],

}, { timestamps: { createdAt: 'created', updatedAt: 'lastUpdate' } }, { collection: 'circletemplatelist' });


async function addChildren(object, json) {

  object.ratchetIndexes = [];
  object.tasks = [];

  for (let i = 0; i < json["ratchetIndexes"].length; i++) {

    let ratchetIndex = RatchetIndex.fromJson(json["ratchetIndexes"][i]);
    //await ratchetIndex.save();
    object.ratchetIndexes.push(ratchetIndex);

  }

  for (i = 0; i < json["tasks"].length; i++) {
    let task = json["tasks"][i];
    let templateListTask = new CircleListTemplateTask({ order: task.order, seed: task.seed });

    await templateListTask.save();
    object.tasks.push(templateListTask);
  }

  object.markModified('ratchetIndexes');
  object.markModified('tasks');

}

CircleListTemplateSchema.methods.update = async function (json) {

  this.body = json["body"];
  this.crank = json["crank"];
  this.signature = json["signature"];

  await RatchetIndex.deleteMany({
    _id: {
      $in: this.ratchetIndexes
    }
  });

  await CircleListTemplateTask.deleteMany({
    _id: {
      $in: this.tasks
    }
  });

  await addChildren(this, json);

  lastUpdate = Date.now();

}

CircleListTemplateSchema.statics.new = async function (json) {

  let template = this(json);

  await addChildren(template, json);


  return template;
}

mongoose.model('CircleListTemplate', CircleListTemplateSchema);
module.exports = mongoose.model('CircleListTemplate');
