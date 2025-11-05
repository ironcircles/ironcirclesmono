const express = require('express');
const router = express.Router();
const mongoose = require('mongoose');
const CircleImage = require('../models/circleimage');
const CircleGif = require('../models/circlegif');
const CircleVideo = require('../models/circlevideo');
const CircleObject = require('../models/circleobject');
const CircleAlbum = require('../models/circlealbum');
const AlbumItem = require('../models/albumitem');
const passport = require('passport');
const securityLogic = require('../logic/securitylogic');
const securityLogicAsync = require('../logic/securitylogicasync');
const deviceLogic = require('../logic/devicelogic');
const deviceLogicSingle = require('../logic/devicelogicsingle');
const imageLogic = require('../logic/imagelogic');
const videoLogic = require('../logic/videologic');
const logUtil = require('../util/logutil');
const s3Util = require('../util/s3util');
const metricLogic = require('../logic/metriclogic');
const circleObjectLogic = require('../logic/circleobjectlogic');
const constants = require('../util/constants');
const CircleObjectCircle = require('../models/circleobjectcircle');
const gridFS = require('../util/gridfsutil');
let Grid = require('gridfs-stream');
Grid.mongo = mongoose.mongo;
const CircleObjectLineItem = require('../models/circleobjectlineitem');
const kyberLogic = require('../logic/kyberlogic');
const bodyParser = require('body-parser');
const { CIRCLEOBJECT_TYPE } = require('../util/constants');
router.use(bodyParser.urlencoded({ extended: true }));
router.use(bodyParser.json());

const ObjectID = require('mongodb').ObjectID;

if (process.env.NODE_ENV !== 'production') {
  require('dotenv').load();
}

router.post('/objectonly', passport.authenticate('jwt', { session: false}), async (req, res) => {
  try {

    let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);

    //AUTHORIZATION CHECK
    var usercircle = await securityLogic.canUserAccessCircleAsync(req.user.id, body.circleid);
    if (!usercircle) {
      return res.status(400).json({ msg: 'Access denied' });
    }

    if (usercircle.beingVotedOut == true) {
      throw new Error(constants.ERROR_MESSAGE.USER_BEING_VOTED_OUT);
    }

    //create the circleobject
    var existingObject = await CircleObject.findOne({'creator': req.user.id, 'seed': body.seed, circle: body.circleid }).populate('creator').populate('circle').populate({path: 'album', populate: [{ path: 'media', populate: { path: 'encryptedLineItem' } } ]}).populate({ path: 'reactions', populate: { path: 'users', select: '_id username' } }).populate({ path: 'reactionsPlus', populate: { path: 'users', select: '_id username' } }).exec();

    if (existingObject instanceof CircleObject) {
      console.log('Seed already exists');

      //The user can see this object because we already validated they are in the Circle above
      return res.status(200).json({ msg: 'Seed already exists', circleObject: existingObject });
    }

    let circleAlbum = new CircleAlbum({
      circle: body.circle,
    });

    for (let i = 0; i < body.items.length; i++) {
      let item = body.items[i];
      let encryptedLineItem = await CircleObjectLineItem.new(item.encryptedLineItem, req.user.id);
      await encryptedLineItem.save();
      let albumItem = new AlbumItem({
        type: item.type,
        encryptedLineItem: encryptedLineItem,
        removeFromCache: item.removeFromCache,
        index: item.index,
      });
      await albumItem.save();
      circleAlbum.media.push(albumItem);
    }

    await circleAlbum.save();

    let circleObject = await CircleObject.new(body);
    circleObject.creator = req.user.id;
    circleObject.circle = body.circleid;
    circleObject.album = circleAlbum;
    circleObject = circleObjectLogic.setTimer(circleObject, usercircle.circle);
    if (body.scheduledFor) {
      circleObject.scheduledFor = new Date(body.scheduledFor);
      if (circleObject.scheduledFor < Date.now()) {
        logUtil.logAlert(req.user.id + ' tried to schedule sending an album for a time before now.');
        return res.status(500);
      }
    }

    await circleObject.save();

    await circleObject.populate(
      [
        'creator',
        'circle',
        { path: 'album', populate: { path: 'media', populate: { path: 'encryptedLineItem'}} },
      ]
    );

    if (circleObject.scheduledFor != null && circleObject.scheduledFor != undefined) {
      let connection = new CircleObjectCircle({
        circle: circleObject.circle._id, //body.circle,
        circleObject: circleObject._id,
        taggedUsers: body.taggedUsers
      });
      await connection.save();
      circleObject.circle = undefined;
      await circleObject.save();

      return res.status(200).json({ circleObject: circleObject });

    } else {
      metricLogic.incrementPosts(circleObject.creator);

      //Add the circleobject to the user's newItems list
      circleObjectLogic.saveNewItem(usercircle.circle._id, circleObject, body.device);

      var notification = circleObject.creator.username + " sent a new ironclad album";
      var notificationType = constants.NOTIFICATION_TYPE.MESSAGE;
      let oldNotification = "New ironclad message";

      deviceLogicSingle.sendMessageNotificationToCircle(circleObject, body.circleid, req.user.id, body.pushtoken, circleObject.lastUpdate, notification, notificationType, oldNotification);  //async ok

      //return res.status(200).json({ circleObject: circleObject });

      let payload = { circleObject: circleObject };
      payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);
      return res.status(200).json(payload);
    }

  } catch (error) {
     console.error(error);
     return res.status(500).json({ msg: error });
  }
});

router.put('/objectonly/:id', passport.authenticate('jwt', { session: false }), async (req, res) => {

  try {

    let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);

    let circleObjectID = req.params.id;
    if (circleObjectID == 'undefined') {
      circleObjectID = body.circleObjectID;
    }

    //AUTHORIZATION CHECK
    var usercircle = await securityLogic.canUserAccessCircleAsync(req.user.id, body.circleid);
    if (!usercircle) {
      return res.status(400).json({ msg: 'Access denied' });
    }

    if (usercircle.beingVotedOut == true) {
      throw new Error(constants.ERROR_MESSAGE.USER_BEING_VOTED_OUT);
    }

    //find object
    let circleObject = await CircleObject.findOne({ "_id": circleObjectID, creator: req.user.id }).populate('creator').populate('circle').populate({ path: 'album', populate: [{ path: 'lastUpdate' }, { path: 'created' }, { path: 'media', populate: [{ path: 'index'}, { path: 'removeFromCache'}, { path: 'type'}, { path: 'encryptedLineItem', populate: { path: 'ratchetIndex' }} ] } ]},).populate({ path: 'reactions', populate: { path: 'users', select: '_id username' } }).populate({ path: 'reactionsPlus', populate: { path: 'users', select: '_id username' } }).exec();
    if (!(circleObject instanceof CircleObject)) {
      return res.status(400).json({ success: false, msg: 'CircleObject doesn\'t exist' });
    }

    let circleAlbum = await CircleAlbum.findOne({ "_id": circleObject.album._id }).populate({path: 'media', populate: [{path: 'index'}, { path: 'removeFromCache'}, { path: 'encryptedLineItem', populate: { path: 'ratchetIndex'}}] }).exec();
    if (!(circleAlbum instanceof CircleAlbum)) {
      return res.status(400).json({ success: false, msg: 'CircleAlbum doesn\'t exist' });
    }

    await circleObject.update(body);
    
    if (body.newItems != null) {

      ///add new items, no need to check if they exist

      for (let i = 0; i < body.newItems.length; i++) {
        var item = body.newItems[i];
        let encryptedLineItem = await CircleObjectLineItem.new(item.encryptedLineItem, req.user.id);
        await encryptedLineItem.save();
        let albumItem = new AlbumItem({
          type: item.type,
          encryptedLineItem: encryptedLineItem,
          removeFromCache: item.removeFromCache,
          index: item.index,
        });
        await albumItem.save();
        circleAlbum.media.push(albumItem);
      }

    } else if (body.deletedItems != null) {

      ///find and update cache status of old items

      for (let i = 0; i < body.deletedItems.length; i++) {
        for (let j = 0; j < circleAlbum.media.length; j++) {
          if (circleAlbum.media[j]._id.equals(body.deletedItems[i]._id)) {
            var item = circleAlbum.media[j];
            item.removeFromCache = true;
            await item.save();
            // circleAlbum.media[j].removeFromCache = true;
            // await circleAlbum.media[j].save();
          }
        }
      }

    }

    await circleAlbum.save();
    circleObject.album = circleAlbum;
    await circleObject.save();

    var notification = circleObject.creator.username + " edited an ironclad album";
    var notificationType = constants.NOTIFICATION_TYPE.MESSAGE;
    let oldNotification = "New ironclad message";

    deviceLogicSingle.sendMessageNotificationToCircle(circleObject, body.circleid, req.user.id, body.pushtoken, circleObject.lastUpdate, notification, notificationType, oldNotification);  //async ok
    //return res.status(200).json({ circleObject: circleObject, msg: 'Successfully updated circlealbum' });

    let payload = { circleObject: circleObject, msg: 'Successfully updated circlealbum' };
    payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);
    return res.status(200).json(payload);


  } catch (error) {
    console.log(error);
    return res.status(500).json({ msg: error });
  }

});

router.put('/sort/:id', passport.authenticate('jwt', { session: false }), async (req, res) => {
  try {

    let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);

    let circleObjectID = req.params.id;
    if (circleObjectID == 'undefined') {
      circleObjectID = body.circleObjectID;
    }

    ///AUTHORIZATION CHECK
    var usercircle = await securityLogic.canUserAccessCircleAsync(req.user.id, body.circleid);
    if (!usercircle) {
      return res.status(400).json({ msg: 'Access denied' });
    }

    if (usercircle.beingVotedOut == true) {
      throw new Error(constants.ERROR_MESSAGE.USER_BEING_VOTED_OUT);
    }

    ///find object
    let circleObject = await CircleObject.findOne({ "_id": circleObjectID, creator: req.user.id }).populate('creator').populate('circle').populate({ path: 'album', populate: { path: 'media', populate: { path: 'encryptedLineItem', populate: { path: 'ratchetIndex' }} } }).populate({ path: 'reactions', populate: { path: 'users', select: '_id username' } }).populate({ path: 'reactionsPlus', populate: { path: 'users', select: '_id username' } }).exec();
    if (!(circleObject instanceof CircleObject)) {
      return res.status(400).json({ success: false, msg: 'CircleObject doesn\'t exist' });
    }

    let circleAlbum = await CircleAlbum.findOne({ "_id": circleObject.album._id }).populate({ path: 'media', populate: { path: 'encryptedLineItem'} }).exec();
    if (!(circleAlbum instanceof CircleAlbum)) {
      return res.status(400).json({ success: false, msg: 'CircleAlbum doesn\'t exist' });
    } 

    await circleObject.update(body);

    for (let i = 0; i < body.items.length; i++) {
      for (let j = 0; j < circleAlbum.media.length; j++) {
        if (circleAlbum.media[j]._id.equals(body.items[i]._id)) {
          circleAlbum.media[j].index = body.items[i].index;
          circleAlbum.media[j].save();
          // var itemBase = body.items[i];
          // circleAlbum.media[j].index = itemBase.index;
          // var item = await AlbumItem.findOne({ "_id": itemBase._id });
          // item.index = itemBase.index;
          // await item.save();
        }
      }
      
    }

    await circleAlbum.save();
    circleObject.album = circleAlbum;
    await circleObject.save();

    var notification = circleObject.creator.username + " reordered an ironclad album";
    var notificationType = constants.NOTIFICATION_TYPE.MESSAGE;
    let oldNotification = "New ironclad message";

    deviceLogicSingle.sendMessageNotificationToCircle(circleObject, body.circleid, req.user.id, body.pushtoken, circleObject.lastUpdate, notification, notificationType, oldNotification); //async ok
    //return res.status(200).json({ circleObject: circleObject, msg: 'Successfully reordered circlealbum' });

    let payload = { circleObject: circleObject, msg: 'Successfully reordered circlealbum' };
    payload = await kyberLogic.encryptPayload(body.enc, body.uuid, payload);
    return res.status(200).json(payload);

  } catch (error) {
    console.log(error);
    return res.status(500).json({ msg: error });
  }
});

// module.exports.deleteAlbumItem = async function (creatorID, itemID) {
//   try {

//     var albumItem = await AlbumItem.findOne({ "_id": itemID }).populate('image').populate('gif').populate('video').populate('type');

//     if (!albumItem) throw new Error(('Could not find album item'));

//     if (albumItem.type == constants.ALBUM_ITEM_TYPE.IMAGE) {
//       imageLogic.deleteCircleImage(creatorID, albumItem.image);
//     } else if (albumItem.type == constants.ALBUM_ITEM_TYPE.VIDEO) {
//       videoLogic.deleteCircleVideo(creatorID, albumItem.video);
//     }

//     // let hostedFurnaceStorage = await getHostedFurnaceStorage(userID);

//     //await _delete(albumItem, hostedFurnaceStorage);

//     await AlbumItem.deleteOne({ _id: albumItem._id });


//   } catch (err) {
//     console.error(err);
//     return false;

//   }
//}


// module.exports.removeAlbumItem = async function (creatorID, itemID) {
//   try {

//     var albumItem = await AlbumItem.findOne({ "_id": itemID }).populate('image').populate('gif').populate('video').populate('type');

//     if (!albumItem) throw new Error(('Could not find album item'));

//     if (albumItem.type == constants.ALBUM_ITEM_TYPE.IMAGE) {
//       //imageLogic.deleteCircleImage(creatorID, albumItem.image);
//       imageLogic.removeAlbumImage(creatorID, albumItem.image);

//     } else if (albumItem.type == constants.ALBUM_ITEM_TYPE.VIDEO) {
//       videoLogic.removeAlbumVideo(creatorID, albumItem.video);
//     }

//     // let hostedFurnaceStorage = await getHostedFurnaceStorage(userID);

//     //await _delete(albumItem, hostedFurnaceStorage);

//     //await AlbumItem.deleteOne({ _id: albumItem._id });


//   } catch (err) {
//     console.error(err);
//     return false;

//   }
// }

module.exports.deleteCircleAlbum = async function (albumID) {
  try {

    var circleAlbum = await CircleAlbum.findById(albumID);

    if (!circleAlbum) throw new Error(('Could not find album object'));

    await CircleAlbum.deleteOne({ '_id': albumID });

  } catch (error) {
    let msg = await logUtil.logError(error, true);
    return false;
  }
}

module.exports = router;