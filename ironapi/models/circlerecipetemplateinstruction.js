const mongoose = require('mongoose');

const CircleRecipeTemplateInstructionSchema = new mongoose.Schema({
  seed: { type: String }, //need to be able to match to the client side decrypted name
  order: { type: Number}, 
}, { timestamps: { createdAt: 'created', updatedAt: 'lastUpdate' } }, { collection: 'circlerecipetemplateinstruction' });

mongoose.model('CircleRecipeTemplateInstruction', CircleRecipeTemplateInstructionSchema);
module.exports = mongoose.model('CircleRecipeTemplateInstruction');
