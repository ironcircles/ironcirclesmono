//This object is the master object of a specific reviwed item per circle
//Normal way to load this object is CircleObject->CirceVote->-CircleReviewMasterSchema
//That said, I also store the circleID to easy fetch reviews for autocomplete in the client

const mongoose = require('mongoose');  

var CircleReviewMasterSchema = new mongoose.Schema({  
    circle: { type: mongoose.Schema.Types.ObjectId, ref: 'Circle' },  //denormalized to avoid Mongo search hell
    type: String, 
    name: String,
    url: String,
    sumofRatings: {type: Number, default: 0},
    numberofRatings: {type: Number, default: 0},
    averageRating: {type: Number, default: 0}

}, { timestamps: { createdAt: 'created', updatedAt: 'lastUpdate'}}, { collection: 'circlereviewmasters' });

mongoose.model('CircleReviewMaster', CircleReviewMasterSchema);

module.exports = mongoose.model('CircleReviewMaster');
