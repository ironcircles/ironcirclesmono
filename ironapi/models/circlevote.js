const mongoose = require('mongoose');
const constants = require('../util/constants')

/*var CircleVoteOptionSchema = new mongoose.Schema({
  option: String,
  voteTally: { type: Number, default: 0 },
  usersVotedFor: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }]
});*/

var CircleVoteSchema = new mongoose.Schema({
  circle: { type: mongoose.Schema.Types.ObjectId, ref: 'Circle', required: true },
  question: { type: String },
  description: { type: String },
  closeMessage: { type: String },
  setting: { type: String },  //if the vote is for a circle setting, store the setting type here
  object: { type: String },  //question metadata, for example, a userid
  open: { type: Boolean, default: true },
  type: { type: String, default: constants.VOTE_TYPE.STANDARD }, //standard, invitation, remove
  model: { type: String, default: constants.VOTE_MODEL.UNANIMOUS },  //versus majority controlled
  //winner: CircleVoteOptionSchema,
  //options: [CircleVoteOptionSchema]
  winner: { type: mongoose.Schema.Types.ObjectId, ref: 'CircleVoteOption' },
  options: [{ type: mongoose.Schema.Types.ObjectId, ref: 'CircleVoteOption' }]

}, { timestamps: { createdAt: 'created', updatedAt: 'lastUpdate' } }, { collection: 'circlevotes' });

//mongoose.model('CircleVoteOption', CircleVoteOptionSchema);
mongoose.model('CircleVote', CircleVoteSchema);

module.exports = mongoose.model('CircleVote');
//module.exports = mongoose.model('CircleVoteOption');