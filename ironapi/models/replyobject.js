const mongoose = require('mongoose');
const RatchetIndex = require('../models/ratchetindex');


var ReplyObjectSchema = new mongoose.Schema({
    circleObject: { type: mongoose.Schema.Types.ObjectId, ref: 'CircleObject' },
    creator: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
    reactions: [{ type: mongoose.Schema.Types.ObjectId, ref: 'CircleObjectReaction' }],
    replyToID: { type: String },

    ratchetIndexes: [mongoose.model('RatchetIndex').schema],
    senderRatchetPublic: { type: String },
    //circleObjectID: { type: String },
    crank: { type: String },
    signature: { type: String },
    verification: { type: String },
    device: { type: String },
    removeFromCache: { type: String },
    body: { type: String },
    type: { type: String },
    seed: { type: String, unique: true },
    lastUpdate: { type: Date },
    lastUpdateNotReaction: { type: Date },
    lastReactedDate: { type: Date },
    created: { type: Date },

    //replyObjectID: { type: String },

    //encryptedLineItem: { type: mongoose.Schema.Types.ObjectId, ref: "CircleObjectLineItem" },

}, { timestamps: { createdAt: 'created', updatedAt: 'lastUpdate' } }, { collection: 'replyobject' });

ReplyObjectSchema.methods.update = async function (json) {

    this.body = json["body"];
    this.senderRatchetPublic = json["senderRatchetPublic"];
    this.crank = json["crank"];
    this.signature = json["signature"];
    this.verification = json["verification"];
    this.device = json["uuid"];
    this.replyToID = json["replyToID"];

    await RatchetIndex.deleteMany({
        _id: {
            $in: this.ratchetIndexes
        }
    });

    this.ratchetIndexes = [];

    if (json["ratchetIndexes"]) {

        for (let i = 0; i < json["ratchetIndexes"].length; i++) {

            let ratchetIndex = RatchetIndex.fromJson(json["ratchetIndexes"][i]);
            this.ratchetIndexes.push(ratchetIndex);
        }
    }

    this.markModified('ratchetIndexes');

    let now = Date.now();
    this.lastUpdate = now;
    this.lastUpdateNotReaction = now;
}


ReplyObjectSchema.statics.new = async function (json) {
    let replyObject = this(json);

    this.device = json["uuid"];

    replyObject.ratchetIndexes = [];

    if (json["ratchetIndexes"]) {
        
        for (let i = 0; i < json["ratchetIndexes"].length; i++) {

            let ratchetIndex = RatchetIndex.new(json["ratchetIndexes"][i]);

            replyObject.ratchetIndexes.push(ratchetIndex);
        }
    }

    replyObject.markModified('ratchetIndexes');
    replyObject.lastUpdate = Date.now();
    replyObject.created = Date.now();
    return replyObject;
}

ReplyObjectSchema.statics.baseNew = async function (reply) {
    let replyObject = this(reply);

    replyObject.circleObject = undefined;
    replyObject.creator = undefined;
    replyObject.reactions = undefined;
    replyObject.ratchetIndexes = undefined;
    replyObject.senderRatchetPublic = undefined;
    replyObject.crank = undefined;
    replyObject.signature = undefined;
    replyObject.verification = undefined;
    replyObject.device = undefined;
    replyObject.removeFromCache = undefined;
    replyObject.body = undefined;
    replyObject.type = undefined;
    replyObject.seed = undefined;
    replyObject.lastUpdate = undefined;
    replyObject.lastUpdateNotReaction = undefined;
    replyObject.lastReactedDate = undefined;
    replyObject.created = undefined;

    return replyObject;

}


mongoose.model('ReplyObject', ReplyObjectSchema);

module.exports = mongoose.model('ReplyObject');