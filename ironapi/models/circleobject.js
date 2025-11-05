const mongoose = require('mongoose');
const constants = require('../util/constants');
const RatchetIndex = require('../models/ratchetindex');
const CircleImage = require('../models/circleimage');
const DeviceUser = require('./circleobjectdelivered');
const Metric = require('./metric');

//Needs to be a generic object
//meta data and tags will be stored outside of body
//everything else needs to be pulled and decrypted clientside
//so the contects are not visible
/***************************************************************************
 * 
 * Author: JC
 * 
 * Purpose: Model for posts within a circle.
 * 
 * After great debate (no joins in MongoDB), instead of a single type
 * property or a "linker" table, the types are stored as 1:1 documents
 * within this model.
 * 
 * Mongoose is smart enough not to store the types that are not used so
 * there is no real ineffiency.  A saved model will never have more than
 * one of the type properties below.  
 *
 * NOTE: URLs are not a type of their own, instead the URL property is
 * set when a url is entered.
 * 
 * The body and url fields are shared across all object types.
 * 
 * The type property is the name of the child model in lowercase.  
 *    For example, circleevent
 * 
 * removeFromCache property:  This is set when a users deletes a circleobject.
 * The rest of the users need to be notified that the item needs to be removed
 * from their cache.  We don't trust push notifications by themselves to ensure
 * something gets deleted.  This property is set, the rest of the properties are 
 * blanked out, and the client app handles the delete upon next refresh.
 *  
 ***************************************************************************/

var CircleObjectSchema = new mongoose.Schema({
  circle: { type: mongoose.Schema.Types.ObjectId, ref: 'Circle' },
  creator: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },

  ///this only stores one of the original 6 emojis
  reactions: [{ type: mongoose.Schema.Types.ObjectId, ref: 'CircleObjectReaction' }],
  ///this stores all emojis, always
  reactionsPlus: [{ type: mongoose.Schema.Types.ObjectId, ref: 'CircleObjectReaction' }],

  waitingOn:{ type: String },
  vote: { type: mongoose.Schema.Types.ObjectId, ref: 'CircleVote' },
  review: { type: mongoose.Schema.Types.ObjectId, ref: 'CircleReview' },
  image: { type: mongoose.Schema.Types.ObjectId, ref: 'CircleImage' },
  file: { type: mongoose.Schema.Types.ObjectId, ref: 'CircleFile' },
  lastEdited: { type: mongoose.Schema.Types.ObjectId, ref: 'User' }, 
  album: { type: mongoose.Schema.Types.ObjectId, ref: 'CircleAlbum' },
  link: { type: mongoose.Schema.Types.ObjectId, ref: 'CircleLink' },
  event: { type: mongoose.Schema.Types.ObjectId, ref: 'CircleEvent' },
  blob: { type: mongoose.Schema.Types.ObjectId, ref: 'CircleBlob' },
  video: { type: mongoose.Schema.Types.ObjectId, ref: 'CircleVideo' },
  list: { type: mongoose.Schema.Types.ObjectId, ref: 'CircleList' },
  recipe: { type: mongoose.Schema.Types.ObjectId, ref: 'CircleRecipe' },
  emojiOnly: { type: Boolean }, //deprecated
  albumChild: { type: Boolean },
  pinnedUsers: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],
  ratchetIndexes: [mongoose.model('RatchetIndex').schema],
  senderRatchetPublic: { type: String },
  replyObjectID: { type: String },
  crank: { type: String },
  signature: { type: String },
  verification: { type: String },
  device: { type: String },
  removeFromCache: { type: String },
  timer: { type: Number },
  timerExpires: { type: Date, },
  scheduledFor: { type: Date },
  body: { type: String },
  oneTimeView: { type: Boolean, default: false },
  url: { type: String },
  type: { type: String },
  seed: { type: String, unique: true, },
  storageID: { type: String, },
  lastUpdate: { type: Date },
  lastUpdateNotReaction: { type: Date },
  lastReactedDate: { type: Date },
  created: { type: Date },

}, { timestamps: { createdAt: false, updatedAt: false } }, { collection: 'circleobject' });

CircleObjectSchema.methods.update = async function (json) {

  this.body = json["body"];
  this.senderRatchetPublic = json["senderRatchetPublic"];
  this.crank = json["crank"];
  this.signature = json["signature"];
  this.verification = json["verification"];
  this.device = json["uuid"];

  await RatchetIndex.deleteMany({
    _id: {
      $in: this.ratchetIndexes
    }
  });

  this.ratchetIndexes = [];

  if (json["ratchetIndexes"]) {

    for (let i = 0; i < json["ratchetIndexes"].length; i++) {

      let ratchetIndex = RatchetIndex.fromJson(json["ratchetIndexes"][i]);
      //await ratchetIndex.save();
      this.ratchetIndexes.push(ratchetIndex);

    }

  }

  this.markModified('ratchetIndexes');

  let now = Date.now();
  this.lastUpdate = now;
  this.lastUpdateNotReaction = now;
}

CircleObjectSchema.statics.new = async function (json) {

  let circleObject = this(json);

  this.device = json["uuid"];
  //circleObject.created = Date.now();

  circleObject.ratchetIndexes = [];

  if (json["ratchetIndexes"]) {

    for (let i = 0; i < json["ratchetIndexes"].length; i++) {

      let ratchetIndex = RatchetIndex.new(json["ratchetIndexes"][i]);

      if (circleObject.timer == 1) {  //don't save posters ratchet keys if a disappearing message

        if (circleObject.creator.equals(ratchetIndex.user) == true)
          continue;
      }


      //await ratchetIndex.save();
      circleObject.ratchetIndexes.push(ratchetIndex);

    }

  }

  circleObject.markModified('ratchetIndexes');
  circleObject.lastUpdate = Date.now();
  circleObject.created = Date.now();
  return circleObject;
}




mongoose.model('CircleObject', CircleObjectSchema);
module.exports = mongoose.model('CircleObject');