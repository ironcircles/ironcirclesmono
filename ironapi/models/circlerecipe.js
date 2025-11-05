const mongoose = require('mongoose');
const CircleRecipeIngredient = require('./circlerecipeingredient');
const CircleRecipeInstruction = require('./circlerecipeinstruction');

const CircleRecipeSchema = new mongoose.Schema({
  circle: { type: mongoose.Schema.Types.ObjectId, ref: 'Circle', required: true },
  template: { type: mongoose.Schema.Types.ObjectId, ref: 'CircleRecipeTemplate' },
  //name: { type: String, default: 'New Recipe' },
  //prepTime: { type: String, },
  //cookTime: { type: String, },
  //totalTime: { type: String, },
  //servings: { type: String, },
  //notes: { type: String },
  libraryRatchetIndex: { type: String },
  image: mongoose.model('CircleImage').schema,
  ingredients: [mongoose.model('CircleRecipeIngredient').schema],
  instructions: [mongoose.model('CircleRecipeInstruction').schema],


}, { timestamps: { createdAt: 'created', updatedAt: 'lastUpdate' } }, { collection: 'circlerecipe' });


mongoose.model('CircleRecipe', CircleRecipeSchema);
module.exports = mongoose.model('CircleRecipe');
