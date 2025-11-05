const express = require('express');
const router = express.Router();
const CircleList = require('../models/circlelist');
const CircleListTask = require('../models/circlelisttask');
const CircleListTemplate = require('../models/circlelisttemplate');
const CircleListTemplateTask = require('../models/circlelisttemplatetask');
const CircleObject = require('../models/circleobject');
const User = require('../models/user');
const logUtil = require('../util/logutil');
const passport = require('passport');
const securityLogic = require('../logic/securitylogicasync');
const circleObjectLogic = require('../logic/circleobjectlogic');
var circleListLogic = require('../logic/circlelistlogic');
const deviceLogic = require('../logic/devicelogic');
const deviceLogicSingle = require('../logic/devicelogicsingle');
const bodyParser = require('body-parser');
const ObjectID = require('mongodb').ObjectId;
const constants = require('../util/constants');
const metricLogic = require('../logic/metriclogic');
const CircleObjectCircle = require('../models/circleobjectcircle');
const kyberLogic = require('../logic/kyberlogic');
if (process.env.NODE_ENV !== 'production') {
  require('dotenv').load();
}

//router.use(bodyParser.urlencoded({ extended: true }));
//router.use(bodyParser.json());

router.use(bodyParser.json({ limit: '10mb' }));
router.use(bodyParser.urlencoded({ limit: '10mb', extended: true, parameterLimit: 50000 }));
var userFieldsToPopulate = '_id username';

async function upsertTemplate(json, userID, fromTemplate, templateID) {
  try {
    var template;

    var jsonTemplate;

    if (fromTemplate) {
      jsonTemplate = json;

    } else {
      jsonTemplate = json['userTemplateRatchet'];
      jsonTemplate['tasks'] = json['tasks'];
      jsonTemplate['seed'] = json['seed'];
      jsonTemplate['owner'] = userID;
    }

    if (templateID) {
      template = await CircleListTemplate.findById(templateID);

      if (template) {
        if (!template.owner.equals(userID))
          throw new Error('access denied');
        await template.update(jsonTemplate);

      } else throw ('template not found');

    } else {
      template = await CircleListTemplate.new(jsonTemplate);
    }

    if (json['seed']) {
      let duplicate = await CircleListTemplate.findOne({ 'seed': json['seed'] });
      if (duplicate)
        return null;

    }

    await template.save();
    await template.populate('tasks');

    return template;
  } catch (err) {

    logUtil.logError(err, true);
    throw (err);
  }

}

router.put('/template', passport.authenticate('jwt', { session: false }), async (req, res) => {
  try {
    //AUTHORIZATION CHECK OCCURS IN FUNCTION
    let template = await upsertTemplate(req.body, req.user._id, true, req.body.template);

    return res.status(200).json({ template: template });

  } catch (err) {
    logUtil.logError(err, true);
    return res.status(500).json({ msg: err });
  }
});


router.post('/', passport.authenticate('jwt', { session: false }), async (req, res) => {
  try {

    let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);

    //AUTHORIZATION CHECK
    var usercircle = await securityLogic.canUserAccessCircle(req.user.id, body.circle);

    if (!usercircle)
      return res.status(400).json({ msg: 'Access denied' });

    //make sure the parameters were passed in
    try {
      var circleID = new ObjectID(body.circle);

    } catch (err) {
      console.error(err);
      return res.status(400).json({ msg: 'Need to send parameters' });
    }

    let payload = {};

    //does the seed from this user already exist?
    var existing = await CircleObject.findOne({ seed: body.seed, creator: req.user.id, circle: circleID }).populate('creator').populate('circle').populate({ path: 'list', populate: [{ path: 'tasks', populate: { path: 'assignee' } },] }).populate({ path: 'reactions', populate: { path: 'users', select: '_id username' } }).populate({ path: 'reactionsPlus', populate: { path: 'users', select: '_id username' } }).exec();;

    if (existing instanceof CircleObject) {
      console.log('Seed already exists');

      //The user can see this object because we already validated they are in the Circle above
      payload = { msg: 'Seed already exists', circleobject: existing };

    } else {
      let circleObject = await CircleObject.new(body);
      circleObject.creator = req.user.id;
      circleObject = circleObjectLogic.setTimer(circleObject, usercircle.circle);

      //create the circlelist object
      var circlelist = new CircleList({ circle: circleID, checkable: body.checkable, /*template: body.template*/ });

      for (i = 0; i < body.tasks.length; i++) {

        var task = body.tasks[i];

        var circlelisttask = new CircleListTask({ /*name: task.name,*/ seed: task.seed, due: task.due, assignee: task.assignee, order: i + 1 })
        await circlelisttask.save();
        //await circlelisttask.populate('assignee').execPopulate();
        circlelist.tasks.push(circlelisttask);
      }

      var template;

      if (body.saveList == true) {
        template = await upsertTemplate(body, req.user._id, false, body.template);
        //circleObject.m
      }

      await circlelist.save();

      metricLogic.incrementPosts(circleObject.creator);

      circleObject.list = circlelist;
      circleObject.lastUpdate = Date.now();
      circleObject.lastUpdateNotReaction = circleObject.lastUpdate;
      if (body.scheduledFor) {
        circleObject.scheduledFor = new Date(body.scheduledFor);
        if (circleObject.scheduledFor < Date.now()) {
          logUtil.logAlert(req.user.id + ' tried to schedule sending a list for a time before now.');
          return res.status(500);
        }
      }
      await circleObject.save();
      //await circleObject.populate(['creator', 'circle', { path: 'list', populate: [{ path: 'tasks', populate: { path: 'assignee' } }, /*{ path: 'lastEdited}' }*/] }]);
      await circleObject.populate([{path: 'creator',select: userFieldsToPopulate}, 'circle', { path: 'list', populate: [{ path: 'tasks', populate: [{ path: 'assignee', select: userFieldsToPopulate }] }] }]);

      if (circleObject.scheduledFor != null && circleObject.scheduledFor != undefined) {
        let connection = new CircleObjectCircle({
          circle: body.circle,
          circleObject: circleObject._id,
          taggedUsers: body.taggedUsers
        });
        await connection.save();
        circleObject.circle = undefined;
        await circleObject.save();
  
        //return res.status(200).json({ circleobject: circleObject, circlelist: circlelist, template: template });
        payload = { circleobject: circleObject, circlelist: circlelist, template: template };
      } else { 

        //Add the circleobject to the user's newItems list
      circleObjectLogic.saveNewItem(usercircle.circle._id, circleObject, body.device);

      var notification = circleObject.creator.username + " created an ironclad list";
      var notificationType = constants.NOTIFICATION_TYPE.MESSAGE;
      let oldNotification = "New ironclad message";

      //send a notification to the circle and return
      deviceLogicSingle.sendMessageNotificationToCircle(circleObject, circleID, req.user.id, body.pushtoken, circleObject.lastUpdate, notification, notificationType, oldNotification);  //async ok

      //return res.status(200).json({ circleobject: circleObject, circlelist: circlelist, template: template });

      payload = { circleobject: circleObject, circlelist: circlelist, template: template };

      }
    }
    payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);
    return res.status(200).json(payload);

  } catch (err) {
    logUtil.logError(err, true);
    return res.status(500).json({ msg: "Failed to post list" });
  }

});


router.put('/:id', passport.authenticate('jwt', { session: false }), async (req, res) => {

  try {


    console.log('UPDATELIST: started ' + new Date(Date.now()));

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
    var circleobject = await CircleObject.findOne({ "_id": circleObjectID }).populate({ path: 'list', populate: [{ path: 'tasks' }, { path: 'lastEdited', select: userFieldsToPopulate }] });

    //console.log('UPDATELIST: object loaded');

    ///log start and end
    let start = new Date(Date.now());
    circleobject.list.tasks = await circleListLogic.updateList(req.user.id, circleobject.list.tasks, body.tasks);
    //console.log('UPDATELIST: list update started at ' + start + ' and ended at ' + new Date(Date.now()));

    //circleobject.list.name = body.name;
    start = new Date(Date.now());
    circleobject.list.complete = await circleListLogic.isListComplete(circleobject.list.tasks);
    //console.log('UPDATELIST: list check complete started at ' + start + ' and ended at ' + new Date(Date.now()));

    circleobject.list.lastUpdate = Date.now();

    circleobject.list.lastEdited = req.user;

    
    await circleobject.list.save();
    //console.log('UPDATELIST: list.save() complete');

    await circleobject.update(body);
    await circleobject.save();
    //console.log('UPDATELIST: circleobject.save() complete');

    await circleobject.populate([{ path: 'reactions', populate: { path: 'users', select: userFieldsToPopulate } }, { path: 'reactionsPlus', populate: { path: 'users', select: userFieldsToPopulate } }, {path: 'creator',select: User.reducedFields }, 'circle', { path: 'list', populate: [ { path: 'lastEdited', select: userFieldsToPopulate }, { path: 'tasks', populate: [{ path: 'completedBy', select: userFieldsToPopulate }, { path: 'assignee',select: userFieldsToPopulate }] },] }]);
    //console.log('UPDATELIST: populate complete');

    //var notification = circleobject.creator.username + " edited an ironclad list";
    var notification = userCircle.user.username + " edited an ironclad list";
    var notificationType = constants.NOTIFICATION_TYPE.MESSAGE;
    let oldNotification = "New ironclad message";

    //send a notification to the circle and return
    deviceLogicSingle.sendMessageNotificationToCircle(circleobject, userCircle.circle._id, req.user.id, body.pushtoken, circleobject.lastUpdate, notification, notificationType, oldNotification);  //async ok

    //return res.status(200).json({ circleobject: circleobject, circlelist: circleobject.list });

    let payload = { circleobject: circleobject, /*circlelist: circleobject.list*/ };
    payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);

    console.log('UPDATELIST: completed ' + new Date(Date.now()));

    return res.status(200).json(payload);
  } catch (err) {
    let msg = await logUtil.logError(err, true);
    return res.status(500).json({ msg: "Failed to update list" });
  }

});

router.delete('/template/:id', passport.authenticate('jwt', { session: false }), async (req, res) => {

  try {

    //AUTHORIZATION CHECK - throw error if invalid
    var userCircle = await securityLogic.canUserAccessCircleListTemplate(req.user.id, req.params.id);
    if (!userCircle) {
      console.log('access denied');
      return res.status(400).json({ msg: 'access denied' });
    }

    var templateID;
    //make sure the parameters are valid
    try {
      templateID = new ObjectID(req.params.id);
    } catch (err) {
      return res.status(400).json({ msg: "Need to send parameters" });
    }

    var removed = await CircleListTemplate.deleteOne({ "_id": templateID });

    return res.json({ success: true, msg: 'Successfully deleted template' });

  } catch (err) {
    logUtil.logError(err, true);
    return res.status(500).json({ msg: err });
  }
});

// Returns all templates for the supplied user
router.get('/template/:id', passport.authenticate('jwt', { session: false }), async (req, res) => {

  try {
    //AUTHORIZATION CHECK
    if (req.user.id != req.params.id)  //this is sort of useless outside of chaos engineering
      return res.status(400).json({ err: 'Access denied' });

    var templates = await CircleListTemplate.find({ "owner": req.user.id }).populate("tasks");
    res.status(200).send({ templates: templates });

  } catch (err) {
    logUtil.logError(err, true);
    return res.status(500).json({ err: err });
  }
});

module.exports = router;