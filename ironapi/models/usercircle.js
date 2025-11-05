const RatchetIndex = require('../models/ratchetindex');

const mongoose = require('mongoose');
var bcrypt = require('bcrypt');

var UserCircleSchema = new mongoose.Schema({
    circle: { type: mongoose.Schema.Types.ObjectId, ref: 'Circle' },
    user: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
    ratchetIndex: mongoose.model('RatchetIndex').schema,
    prefName: { type: String },
    dm: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
    dmConnected: { type: Boolean, default: false },
    background: { type: String },
    backgroundColor: { type: Number },
    backgroundLocation: { type: String },
    backgroundSize: { type: Number },
    hidden: { type: Boolean, default: false },
    hiddenOpen: [{ type: String }],
    closed: { type: Boolean, default: false },
    wall: { type: Boolean, default: false },
    removeFromCache: { type: String },
    hiddenPassphrase: String,
    guarded: { type: Boolean, default: false },
    guardedPin: [{ type: Number }],
    newItems: { type: Number, default: 0 },
    showBadge: { type: Boolean, default: false },
    beingVotedOut: { type: Boolean },
    muted: { type: Boolean, default: false },
    lastAccessed: { type: Date, default: Date.now },
    pinnedOrder: { type: Number, default: 999 },
    lastItemUpdate: { type: Date, default: Date('2018-01-01T00:00:00.000Z"') },
    ratchetPublicKeys: [mongoose.model('RatchetPublicKey').schema],
}, { timestamps: { createdAt: 'created', updatedAt: 'lastUpdate' } }, { collection: 'usercircles' });


UserCircleSchema.pre('save', async function (next) {
    var usercircle = this;

    if (this.isModified('hiddenPassphrase') || this.isNew) {
        if (this.hiddenPassphrase != undefined) {
            try {
                const salt = await bcrypt.genSalt(10);
                const hash = await bcrypt.hash(usercircle.hiddenPassphrase, salt);
                usercircle.hiddenPassphrase = hash;
            } catch (err) {
                return next(err);
            }
        }
    }

    if (this.isModified('guardedPin') || this.isNew) {
        if (this.guardedPin != undefined && this.guardedPin.length > 0) {
            try {
                const salt = await bcrypt.genSalt(10);
                // Convert array of numbers to string for hashing
                const pinString = Array.isArray(this.guardedPin) ? this.guardedPin.join('') : String(this.guardedPin);
                const hash = await bcrypt.hash(pinString, salt);
                usercircle.guardedPin = hash;
            } catch (err) {
                return next(err);
            }
        }
    }

    return next();
});


UserCircleSchema.methods.comparePassphrase = async function (passw) {
    try {
        const isMatch = await bcrypt.compare(passw, this.hiddenPassphrase);
        return isMatch;
    } catch (err) {
        console.error(err);
        return false;
    }
};

UserCircleSchema.methods.comparePin = async function (pin) {
    try {
        // Convert array of numbers to string for comparison
        const pinString = Array.isArray(pin) ? pin.join('') : String(pin);
        const isMatch = await bcrypt.compare(pinString, this.guardedPin);
        return isMatch;
    } catch (err) {
        console.error(err);
        return false;
    }
};

mongoose.model('UserCircle', UserCircleSchema);

module.exports = mongoose.model('UserCircle');