const express = require('express');
const router = express.Router();
const CircleRecipe = require('../models/circlerecipe');
const CircleRecipeTemplate = require('../models/circlerecipetemplate');
const CircleRecipeIngredient = require('../models/circlerecipeingredient');
const CircleRecipeInstruction = require('../models/circlerecipeinstruction');
const CircleImage = require('../models/circleimage');
const CircleObject = require('../models/circleobject');
const passport = require('passport');
const securityLogic = require('../logic/securitylogicasync');
var circleRecipeLogic = require('../logic/circlerecipelogic');
const circleObjectLogic = require('../logic/circleobjectlogic');
const deviceLogic = require('../logic/devicelogic');
const deviceLogicSingle = require('../logic/devicelogicsingle');
const bodyParser = require('body-parser');
const ObjectID = require('mongodb').ObjectId;
const logUtil = require('../util/logutil');
const constants = require('../util/constants');
const metricLogic = require('../logic/metriclogic');
const CircleObjectCircle = require('../models/circleobjectcircle');
const kyberLogic = require('../logic/kyberlogic');

if (process.env.NODE_ENV !== 'production') {
  require('dotenv').load();
}

router.use(bodyParser.json({ limit: '10mb' }));
router.use(bodyParser.urlencoded({ limit: '10mb', extended: true, parameterLimit: 50000 }));


async function upsertTemplate(userID, json, fromTemplate, templateID) {
  try {
    var template;

    var jsonTemplate;

    if (fromTemplate) {
      jsonTemplate = json;

    } else {
      jsonTemplate = json['userTemplateRatchet'];
      jsonTemplate['ingredients'] = json['ingredients'];
      jsonTemplate['instructions'] = json['instructions'];
      jsonTemplate['seed'] = json['seed'];
      jsonTemplate['owner'] = userID;
    }


    if (templateID) {
      template = await CircleRecipeTemplate.findById(templateID);

      if (template) {
        if (!template.owner.equals(userID))
          throw new Error('access denied');
        await template.update(jsonTemplate);

      } else throw ('template not found');

    } else {

      template = await CircleRecipeTemplate.new(jsonTemplate);
    }

    if (json['seed']) {
      let duplicate = await CircleRecipeTemplate.findOne({ 'seed': json['seed'] });
      if (duplicate)
        return null;

    }

    await template.save();
    await template.populate(['ingredients', 'instructions']);

    return template;
  } catch (err) {

    logUtil.logError(err, true);
    throw (err);
  }

}

router.put('/template', passport.authenticate('jwt', { session: false }), async (req, res) => {
  try {
    //AUTHORIZATION CHECK OCCURS IN FUNCTION
    let template = await upsertTemplate(req.user._id, req.body, true, req.body.templateid);

    return res.status(200).json({ template: template });

  } catch (err) {
    logUtil.logError(err, true);
    return res.status(500).json({ msg: err });
  }
});

router.post('/', passport.authenticate('jwt', { session: false }), async (req, res) => {

  try {

    let body =  await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);

    //AUTHORIZATION CHECK
    var usercircle = await securityLogic.canUserAccessCircle(req.user.id, body.circleid);

    if (!usercircle)
      return res.status(400).json({ msg: 'Access denied' });

    //make sure the parameters were passed in
    try {
      var circleID = new ObjectID(body.circleid);

    } catch (err) {
      console.error(err);
      return res.status(400).json({ msg: 'Need to send parameters' });
    }

    //does the seed from this user already exist?
    var existing = await CircleObject.findOne({ seed: body.seed, creator: req.user.id }).populate('recipe').populate('creator').populate('circle').populate({ path: 'reactions', populate: { path: 'users', select: '_id username' } }).populate({ path: 'reactionsPlus', populate: { path: 'users', select: '_id username' } }).exec();;

    if (existing instanceof CircleObject) {
      logUtil.logAlert(req.user.id + ' tried to post an object that already exists. seed: ' + body.seed);
      return res.status(200).json({ circleobject: existing, msg: 'circleobject already exists.' });

    }

    else {
      let circleObject = await CircleObject.new(body);
      circleObject.creator = req.user.id;
      circleObject = circleObjectLogic.setTimer(circleObject, usercircle.circle);

      //create the circlerecipe object
      var circleRecipe = new CircleRecipe({
        circle: circleID, /*name: body.name, prepTime: body.preptime, servings: body.servings,
      cookTime: body.cooktime, totalTime: body.totaltime, notes: body.notes,*/ template: body.template
      });

      //add ingredients
      for (i = 0; i < body.ingredients.length; i++) {

        var ingredient = body.ingredients[i];

        var circleRecipeIngredient = new CircleRecipeIngredient({ seed: ingredient.seed, order: ingredient.order });
        circleRecipe.ingredients.push(circleRecipeIngredient);
      }

      //add instructions
      for (i = 0; i < body.instructions.length; i++) {

        var instruction = body.instructions[i];

        var circleRecipeInstruction = new CircleRecipeInstruction({ seed: instruction.seed, order: instruction.order });
        circleRecipe.instructions.push(circleRecipeInstruction);
      }

      var template;
      if (body.saveTemplate == true) {
        template = await upsertTemplate(req.user._id, body, false, body.template);
      }

      if (body.recipeimage != null && body.recipeimage != undefined) {
        var circleImage = await CircleImage.new(body.recipeimage);
        circleRecipe.image = circleImage;
      }

      await circleRecipe.save();
      circleObject.recipe = circleRecipe;
      if (body.scheduledFor) {
        circleObject.scheduledFor = new Date(body.scheduledFor);
        if (circleObject.scheduledFor < Date.now()) {
          logUtil.logAlert(req.user.id + ' tried to schedule sending a recipe for a time before now.');
          return res.status(500);
        }
      }

      circleObject.lastUpdateNotReaction = circleObject.lastUpdate;
      await circleObject.save();

      await circleObject.populate([{ path: 'reactions', populate: { path: 'users', select: '_id username' } }, { path: 'reactionsPlus', populate: { path: 'users', select: '_id username' } }, 'creator', 'circle', 'recipe']);

      if (circleObject.scheduledFor != null && circleObject.scheduledFor != undefined) {
        let connection = new CircleObjectCircle({
          circle: body.circle,
          circleObject: circleObject._id,
          taggedUsers: body.taggedUsers
        });
        await connection.save();
        circleObject.circle = undefined;
        await circleObject.save();
  
        return res.status(200).json({ circleobject: circleObject, circlerecipe: circleRecipe, template: template });
  
      } else { 
        
        metricLogic.incrementPosts(circleObject.creator);

      //Add the circleobject to the user's newItems list
      circleObjectLogic.saveNewItem(usercircle.circle._id, circleObject, body.device);

      var notification = circleObject.creator.username + " created an ironclad recipe";
      var notificationType = constants.NOTIFICATION_TYPE.MESSAGE;
      let oldNotification = "New ironclad message";

      //send a notification to the circle and return
      deviceLogicSingle.sendMessageNotificationToCircle(circleObject, circleID, req.user.id, body.pushtoken, circleObject.lastUpdate, notification, notificationType, oldNotification);  //async ok
      //deviceLogicSingle.sendMessageNotificationToCircle(circleObject, body.circleid, req.user.id, body.pushtoken, circleObject.lastUpdate);  //async ok

      //return res.status(200).json({ circleobject: circleObject, circlerecipe: circleRecipe, template: template });

      let payload = { circleobject: circleObject, circlerecipe: circleRecipe, template: template };
      payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);
      return res.status(200).json(payload);
      }
    }
  } catch (err) {
    console.error(err);
    return res.status(500).json({ msg: "Failed to save recipe" });
  }

});


router.put('/:id', passport.authenticate('jwt', { session: false }), async (req, res) => {


  try {

    let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);

    let circleObjectID = req.params.id;

    if (circleObjectID == 'undefined'){
      circleObjectID = body.circleObjectID;
    }

    //AUTHORIZATION CHECK
    var userCircle = await securityLogic.canUserAccessCircle(req.user.id, body.circleid); //error is thrown if invalid
    if (!userCircle) return res.status(400).json({ msg: 'Access denied' });

    var circleID;

    //make sure the parameters were passed in
    try {
      circleID = new ObjectID(body.circleid);
      circleObjectID = new ObjectID(circleObjectID);
    } catch (err) {
      console.error(err);
      return res.status(400).json({ msg: 'Need to send parameters' });
    }

    //fetch the circleobject
    var circleobject = await CircleObject.findOne({ "_id": circleObjectID }).populate('recipe');

    circleobject.recipe.ingredients = await circleRecipeLogic.updateIngredients(circleobject.recipe, body.ingredients);
    circleobject.recipe.instructions = await circleRecipeLogic.updateInstructions(circleobject.recipe, body.instructions);

    if (body.recipeimage != null && body.recipeimage != undefined) {
      var circleImage = await CircleImage.new(body.recipeimage);
      circleobject.recipe.image = circleImage;
    }

    await circleobject.recipe.save();

    await circleobject.update(body);
    await circleobject.save();

    await circleobject.populate([{ path: 'reactions', populate: { path: 'users', select: '_id username' } }, { path: 'reactionsPlus', populate: { path: 'users', select: '_id username' } }, 'creator', 'circle', 'recipe']);

    //send a notification to the circle and return
    //await deviceLogic.sendNotificationToCircle(circleID, req.user.id, body.pushtoken);
    //deviceLogicSingle.sendMessageNotificationToCircle(circleobject, body.circleid, req.user.id, body.pushtoken, circleobject.lastUpdate, 'Member updated ironclad message');  //async ok
    //deviceLogic.sendNotificationToCircle(body.circleid, req.user.id, body.pushtoken, circleobject.lastUpdate, req.user.username + ' updated ironclad recipe');
    //deviceLogic.sendDataOnlyMessage(circleID, userCircle, body.pushtoken, 'IronCircles', circleobject.lastUpdate);

    var notification = userCircle.user.username + " edited an ironclad recipe";
    var notificationType = constants.NOTIFICATION_TYPE.MESSAGE;
    let oldNotification = "New ironclad message";
    deviceLogicSingle.sendMessageNotificationToCircle(circleobject, userCircle.circle._id, req.user.id, body.pushtoken, circleobject.lastUpdate, notification, notificationType, oldNotification);

    //return res.status(200).json({ circleobject: circleobject, circlerecipe: circleobject.recipe });

    let payload = { circleobject: circleobject, circlerecipe: circleobject.recipe };
    payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);
    return res.status(200).json(payload);

  } catch (err) {
    console.error(err);
    //next(err);
    return res.status(500).json({ msg: "Failed to upload list" });
  }

});

router.delete('/template/:id', passport.authenticate('jwt', { session: false }), async (req, res) => {

  try {

    var templateID;
    //make sure the parameters are valid
    try {
      templateID = new ObjectID(req.params.id);
    } catch (err) {
      return res.status(400).json({ msg: "Need to send parameters" });
    }

    //AUTHORIZATION CHECK - throw error if invalid
    var template = await securityLogic.canUserAccessCircleRecipeTemplate(req.user.id, templateID);
    if (!template) return res.status(400).json({ msg: 'Access denied' });

    var removed = await CircleRecipeTemplate.deleteOne({ "_id": templateID });

    return res.json({ success: true, msg: 'Successfully deleted template' });

  } catch (err) {
    logUtil.logError(err, true);
    return res.status(500).json({ msg: err });
  }
});

// Returns all MasterLists for the supplied user
router.get('/template/:id', passport.authenticate('jwt', { session: false }), async (req, res) => {

  try {
    //AUTHORIZATION CHECK
    if (req.user.id != req.params.id)  //this is sort of useless outside of chaos engineering
      return res.status(400).json({ err: 'Access denied' });

    var templates = await CircleRecipeTemplate.find({ "owner": req.user.id });
    res.status(200).send({ templates: templates });

  } catch (err) {
    logUtil.logError(err, true);
    return res.status(500).json({ err: err });
  }
});

module.exports = router;