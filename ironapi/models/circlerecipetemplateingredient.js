const mongoose = require('mongoose');

const CircleRecipeTemplateIngredientSchema = new mongoose.Schema({
  seed: { type: String }, //need to be able to match to the client side decrypted name
  order: { type: Number}, 
}, { timestamps: { createdAt: 'created', updatedAt: 'lastUpdate' } }, { collection: 'circlerecipetemplateingredient' });

mongoose.model('CircleRecipeTemplateIngredient', CircleRecipeTemplateIngredientSchema);
module.exports = mongoose.model('CircleRecipeTemplateIngredient');
