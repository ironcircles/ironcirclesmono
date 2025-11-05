const mongoose = require('mongoose');

const CircleRecipeIngredientSchema = new mongoose.Schema({
  seed: { type: String},
  order: { type: Number}, 
}, { timestamps: { createdAt: 'created', updatedAt: 'lastUpdate' } }, { collection: 'circlerecipeingredient' });

mongoose.model('CircleRecipeIngredient', CircleRecipeIngredientSchema);
module.exports = mongoose.model('CircleRecipeIngredient');
