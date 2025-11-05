const mongoose = require('mongoose');
var Schema = mongoose.Schema;
const constants = require('../util/constants');


var NSFWSchema = new Schema({
    filter: [{ type: String, required: true, default: "NONE" }],

}, { timestamps: { createdAt: 'created', updatedAt: 'lastUpdate' } });



module.exports = mongoose.model('NSFW', NSFWSchema);
