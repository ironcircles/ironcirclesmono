const mongoose = require('mongoose');
const CircleRecipeTemplateIngredient = require('./circlerecipetemplateingredient');
const CircleRecipeTemplateInstruction = require('./circlerecipetemplateinstruction');
const RatchetIndex = require('./ratchetindex');

const CircleRecipeTemplateSchema = new mongoose.Schema({
  owner: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  seed: { type: String, },
  body: { type: String, },
  signature: {type: String},
  image: mongoose.model('CircleImage').schema,
  ratchetIndexes: [mongoose.model('RatchetIndex').schema],
  crank: { type: String },
  ingredients: [mongoose.model('CircleRecipeTemplateIngredient').schema],
  instructions: [mongoose.model('CircleRecipeTemplateInstruction').schema],
}, { timestamps: { createdAt: 'created', updatedAt: 'lastUpdate' } }, { collection: 'circlerecipetemplate' });

async function addChildren(object, json) {

  object.ratchetIndexes = [];
  object.ingredients = [];
  object.instructions = [];

  for (let i = 0; i < json["ratchetIndexes"].length; i++) {

    let ratchetIndex = RatchetIndex.fromJson(json["ratchetIndexes"][i]);
    object.ratchetIndexes.push(ratchetIndex);

  }

  if (json["ingredients"]) {
    for (i = 0; i < json["ingredients"].length; i++) {
      let ingredient = json["ingredients"][i];
      let templateItem = new CircleRecipeTemplateIngredient({ order: ingredient.order, seed: ingredient.seed });
      object.ingredients.push(templateItem);
    }
  }

  if (json["instructions"]) {
    for (i = 0; i < json["instructions"].length; i++) {
      let instruction = json["instructions"][i];
      let templateItem = new CircleRecipeTemplateInstruction({ order: instruction.order, seed: instruction.seed });
      object.instructions.push(templateItem);
    }
  }

  object.markModified('ratchetIndexes');
  object.markModified('ingredients');
  object.markModified('instructions');

}


CircleRecipeTemplateSchema.methods.update = async function (json) {

  this.body = json["body"];
  this.crank = json["crank"];
  this.signature = json["signature"];

  await RatchetIndex.deleteMany({
    _id: {
      $in: this.ratchetIndexes
    }
  });

  await CircleRecipeTemplateIngredient.deleteMany({
    _id: {
      $in: this.ingredients
    }
  });

  await CircleRecipeTemplateInstruction.deleteMany({
    _id: {
      $in: this.instructions
    }
  });

  await addChildren(this, json);

  lastUpdate = Date.now();

}

CircleRecipeTemplateSchema.statics.new = async function (json) {

  let template = this(json);

  await addChildren(template, json);


  return template;
}

mongoose.model('CircleRecipeTemplate', CircleRecipeTemplateSchema);
module.exports = mongoose.model('CircleRecipeTemplate');
