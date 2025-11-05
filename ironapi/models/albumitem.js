const mongoose = require('mongoose');
const CircleObjectLineItem = require('../models/circleobjectlineitem');

var AlbumItemSchema = new mongoose.Schema({
    type: { type: String },
    encryptedLineItem: { type: mongoose.Schema.Types.ObjectId, ref: 'CircleObjectLineItem' },
    removeFromCache: { type: Boolean, default: false },
    index: { type: Number },
}, { timestamps: { createdAt: 'created', updatedAt: 'lastUpdate'}}, { collection: 'albumitems' });

mongoose.model('AlbumItem', AlbumItemSchema);

module.exports = mongoose.model('AlbumItem');