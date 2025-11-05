/***************************************************************************
 * 
 * Author: JC
 * 
 * 
 *  
 ***************************************************************************/
const mongoose = require('mongoose');  

var CircleAlbumSchema = new mongoose.Schema({  
  media: [{ type: mongoose.Schema.Types.ObjectId, ref: 'AlbumItem' }],
  circle: { type: mongoose.Schema.Types.ObjectId, ref: 'Circle' },
}, { timestamps: { createdAt: 'created', updatedAt: 'lastUpdate'}}, { collection: 'circlealbums' });

mongoose.model('CircleAlbum', CircleAlbumSchema);

module.exports = mongoose.model('CircleAlbum');