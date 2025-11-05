const mongoose = require('mongoose');
var Schema = mongoose.Schema;
var bcrypt = require('bcrypt');
const constants = require('../util/constants');

//These are actually needed, ignore the compiler
var Device = require('../models/device');
var Avatar = require('../models/avatar');
var PublicKey = require('./ratchetpublickey');


var UserSchema = new Schema({
    username: { type: String, required: true },
    lowercase: { type: String, }, //lowercase username or lowercase username + HostedFurnace._id
    reservedUsername: { type: Boolean, default: false },
    //deprecated
    password: { type: String, select: false },
    //deprecated
    pin: { type: String, required: false, select: false },
    passwordHash: { type: String, select: false },
    passwordNonce: { type: String, select: false },
    passwordResetRequired: { type: Boolean, default: false },
    joinBeta: { type: Boolean, default: false },
    passwordChangedOn: { type: Date },
    accountType: { type: Number, default: constants.ACCOUNT_TYPE.FREE },
    role: { type: Number, default: constants.ROLE.MEMBER },
    tos: { type: Date },
    ratchetPublicKey: mongoose.model('RatchetPublicKey').schema,  //used for Circle names and templates
    //over18: { type: Boolean, default: true },
    minor: { type: Boolean, default: false },
    passwordExpired: { type: Boolean, default: false },
    passwordResetRequired: { type: Boolean, default: false },
    accountRecovery: { type: Boolean, default: false },
    loginAttempts: { type: Number, default: 0 },
    loginAttemptsExceeded: { type: Boolean, default: false },
    loginAttemptsLastFailed: { type: Date },
    resetCode: { type: String, select: false },
    resetCodeCreatedOn: { type: Date, },
    resetCodeAttempts: { type: Number, },
    resetCodeAttemptsExceeded: { type: Boolean, default: false },
    autoKeychainBackup: { type: Boolean, default: true },
    passwordBeforeChange: { type: Boolean, default: false },
    submitLogs: { type: Boolean, default: false },
    lastKeyBackup: { type: Date },
    resetCodeAttemptsLastFailed: { type: Date },
    tokenExpired: { type: Boolean, default: false },
    lockedOut: { type: Boolean, default: false },
    securityMinPassword: { type: Number, default: 8 },
    securityDaysPasswordValid: { type: Number, default: 365 },
    securityTokenExpirationDays: { type: Number, default: 365 },
    securityLoginAttempts: { type: Number, default: 9 },
    passwordHelpers: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' },],
    avatar: mongoose.model('Avatar').schema,
    devices: [mongoose.model('Device').schema],
    blockedEnabled: { type: Boolean, default: true },  //allowed list versus blocked list for invitations, can go away with ironfriends connections
    allowClosed: { type: Boolean, default: true },
    keyGen: { type: Boolean, default: false },
    clearPattern: { type: Boolean },
    removeFromCache: { type: Boolean },
    ironCoinWallet: { type: mongoose.Schema.Types.ObjectId, ref: 'IronCoinWallet' },
    // ironCoin: { type: Number, default: 0 },
    // coinLedger: [mongoose.model('CoinPayment').schema],
    subscribedOn: { type: Number, default: 28 }, //day of month
    linkedUser: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
    blockedList: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],
    allowedList: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],
    hostedFurnace: { type: mongoose.Schema.Types.ObjectId, ref: 'HostedFurnace' },

}, { timestamps: { createdAt: 'created', updatedAt: 'lastUpdate' } });

UserSchema.pre('save', async function (next) {
    var user = this;
    
    try {
        if (this.isModified('password') || this.isNew) {
            if (user.password) {
                const salt = await bcrypt.genSalt(10);
                const hash = await bcrypt.hash(user.password, salt);
                user.password = hash;
            }
        }

        if (this.isModified('passwordHash') || this.isNew) {
            if (user.passwordHash) {
                const salt = await bcrypt.genSalt(10);
                const hash = await bcrypt.hash(user.passwordHash, salt);
                user.passwordHash = hash;
            }
        }

        if (this.isModified('pin') || this.isNew) {
            if (user.pin) {
                const salt = await bcrypt.genSalt(10);
                const hash = await bcrypt.hash(user.pin, salt);
                user.pin = hash;
            }
        }

        if (this.isModified('resetCode')) {
            if (this.resetCode != undefined) {
                const salt = await bcrypt.genSalt(10);
                const hash = await bcrypt.hash(user.resetCode, salt);
                user.resetCode = hash;
            }
        }
        
        next();
    } catch (err) {
        next(err);
    }
});

UserSchema.methods.comparePassword = function (passw) {
    let password = this.password;

    return new Promise(function (resolve, reject) {
        bcrypt.compare(passw, password, function (err, isMatch) {
            if (err || !isMatch)
                return reject("invalid network name or credentials");
            else
                return resolve();
        });
    });
};

UserSchema.methods.comparePasswordHash = function (passw) {
    let passwordHash = this.passwordHash;

    return new Promise(function (resolve, reject) {
        bcrypt.compare(passw, passwordHash, function (err, isMatch) {
            if (err || !isMatch)
                return reject("invalid network name or credentials");
            else
                return resolve();
        });
    });
};

UserSchema.methods.comparePin = function (passw) {
    let pin = this.pin;

    return new Promise(function (resolve, reject) {
        bcrypt.compare(passw, pin, function (err, isMatch) {
            if (err || !isMatch)
                return reject("invalid network name or credentials");
            else
                return resolve();
        });
    });
};

UserSchema.methods.compareResetCode = function (passcode) {
    let resetCode = this.resetCode;

    return new Promise(function (resolve, reject) {
        bcrypt.compare(passcode, resetCode, function (err, isMatch) {
            if (err || !isMatch)
                return reject("invalid reset code");
            else
                return resolve();
        });
    });
};

UserSchema.post('save', function (err, doc, next) {
    if (err.name === 'MongoError' && err.code === 11000) {
        next(new Error('username is already taken'));
    } else {
        next(err);
    }
})


UserSchema.statics.blankOutFields = function (user) {


    let tempObject = JSON.parse(JSON.stringify(user));


    delete tempObject.lowercase;
    delete tempObject.password;
    delete tempObject.pin;
    delete tempObject.devices;
    //delete tempObject.ratchetPublicKey;
    //delete tempObject.over18;
    /*
    delete user.guaranteedUnique;
    delete user.password;
    delete user.pin;
    delete user.passwordChangedOn;
    delete user.accountType;
    delete user.tos;
    delete user.ratchetPublicKey;
    delete user.over18;
    delete user.passwordExpired;
    delete user.loginAttempts;
    delete user.loginAttemptsExceeded;
    delete user.loginAttemptsLastFailed;
    delete user.resetCode;
    delete user.resetCodeCreatedOn;
    delete user.resetCodeAttempts;
    delete user.resetCodeAttemptsExceeded;
    delete user.autoKeychainBackup;
    delete user.submitLogs;
    delete user.lastKeyBackup;
    delete user.resetCodeAttemptsLastFailed;
    delete user.tokenExpired;
    delete user.lockedOut;
    delete user.securityMinPassword;
    delete user.securityDaysPasswordValid;
    delete user.securityTokenExpirationDays;
    delete user.securityLoginAttempts;
    delete user.passwordHelpers;
    delete user.avatar;
    delete user.devices;
    delete user.blockedEnabled;
    delete user.allowClosed;
    delete user.keyGen;
    delete user.blockedList;
    delete user.allowedList;
    delete user.hostedFurnace;
    */

    return this(tempObject);

}

/*UserSchema.index({
    'Key': 1,
    'Value': 1,
    'NamespaceId': 1
},{unique: true ,background: true})
*/

module.exports = mongoose.model('User', UserSchema);

module.exports.reducedFields = '_id username'
//module.exports.baseFields = '_id username lowercase reservedUsername passwordResetRequired joinBeta accountType role tos ratchetPublicKey minor passwordExpired passwordResetRequired accountRecovery loginAttempts loginAttemptsExceeded loginAttemptsLastFailed resetCode resetCodeCreatedOn resetCodeAttempts resetCodeAttemptsExceeded autoKeychainBackup passwordBeforeChange submitLogs lastKeyBackup resetCodeAttemptsLastFailed tokenExpired lockedOut securityMinPassword securityDaysPasswordValid securityTokenExpirationDays securityLoginAttempts passwordHelpers avatar devices blockedEnabled allowClosed keyGen clearPattern removeFromCache ironCoinWallet subscribedOn linkedUser blockedList allowedList hostedFurnace created lastUpdate';
module.exports.all = '_id ratchetPublicKey username lowercase accountRecovery linkedUser devices minor allowClosed role accountType avatar keyGen autoKeychainBackup lockedOut lastUpdate created securityDaysPasswordValid securityMinPassword loginAttempts loginAttemptsExceeded loginAttemptsLastFailed securityLoginAttempts securityTokenExpirationDays tokenExpired passwordChangedOn passwordExpired autoKeyBackup lastKeyBackup passwordHelpers hostedFurnace joinBeta +password +pin +resetCode +passwordHash +passwordNonce';
