const RatchetIndex = require('./ratchetindex');

const mongoose = require('mongoose');

var UserKeyBackupSchema = new mongoose.Schema({
    user: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
    userIndex: mongoose.model('RatchetIndex').schema,
    backupIndex: mongoose.model('RatchetIndex').schema,
    assistants: [mongoose.model('RatchetIndex').schema],
    recoveryIndexes: [mongoose.model('RatchetIndex').schema],

}, { timestamps: { createdAt: 'created', updatedAt: 'lastUpdate' } }, { collection: 'userkeybackup' });

UserKeyBackupSchema.statics.new = async function (json) {

    let backupObject = this(json);

    backupObject.assistants = [];

    if (json["userIndex"]) {
        backupObject.userIndex = RatchetIndex.new(json["userIndex"]);
    }

    if (json["backupIndex"]) {
        backupObject.backupIndex = RatchetIndex.new(json["backupIndex"]);
    }

    if (json["assistants"]) {

        for (let i = 0; i < json["assistants"].length; i++) {

            let ratchetIndex = RatchetIndex.new(json["assistants"][i]);
            backupObject.assistants.push(ratchetIndex);

        }

    }

    backupObject.markModified('ratchetIndexes');
    return backupObject;
}

mongoose.model('UserKeyBackup', UserKeyBackupSchema);

module.exports = mongoose.model('UserKeyBackup');