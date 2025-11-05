const mongoose = require('mongoose');

const CircleRecipeInstructionSchema = new mongoose.Schema({
  seed: { type: String},
  order: { type: Number}, 
}, { timestamps: { createdAt: 'created', updatedAt: 'lastUpdate' } }, { collection: 'circlerecipeinstruction' });

mongoose.model('CircleRecipeInstruction', CircleRecipeInstructionSchema);
module.exports = mongoose.model('CircleRecipeInstruction');
