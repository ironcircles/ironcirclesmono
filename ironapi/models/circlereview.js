/***************************************************************************
 * 
 * Author: JC
 * 
 * Purpose: Model for reviews.  Where it all started.  
 * 
 * 
 *  
 ***************************************************************************/
const mongoose = require('mongoose');  


var CircleReviewSchema = new mongoose.Schema({  
  master: { type: mongoose.Schema.Types.ObjectId, ref: 'CircleReviewMaster' },

//denormalized to avoid Mongo search hell; master field is in circlereviewmaster
  name: String, 
  user: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  circle: { type: mongoose.Schema.Types.ObjectId, ref: 'Circle' },

  details: String,
  rating: {type: Number, default: 0}
}, { timestamps: { createdAt: 'created', updatedAt: 'lastUpdate'}}, { collection: 'circlereviews' });

mongoose.model('CircleReview', CircleReviewSchema);

module.exports = mongoose.model('CircleReview');
