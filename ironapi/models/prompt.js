/***************************************************************************
 * 
 * Author: JC
 * 
 * 
 * 
 *  
 ***************************************************************************/
const mongoose = require('mongoose');

var PromptSchema = new mongoose.Schema({
  //user: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  userID:  { type: String }, //don't want this to be an object
  jobID:  { type: String },
  prompt: { type: String },
  maskPrompt: { type: String },
  negativePrompt: { type: String },
  model: { type: String },
  guidance: { type: Number },
  promptType: { type: Number },
  seed: { type: Number },
  steps: { type: Number },
  sampler: { type: String },
  loraOne: { type: String },
  loraTwo: { type: String },
  loraOneStrength: { type: Number },
  loraTwoStrength: { type: Number },
  width: { type: Number },
  height: { type: Number },
  upscale: { type: Number },
}, { timestamps: { createdAt: 'created', updatedAt: 'lastUpdate' } }, { collection: 'prompt' });

PromptSchema.statics.new = async function (json) {

  let object = this(json);
  delete object.id;
  return object;
}


mongoose.model('Prompt', PromptSchema);

module.exports = mongoose.model('Prompt');
