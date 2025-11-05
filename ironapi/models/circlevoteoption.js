const mongoose = require('mongoose');


var CircleVoteOptionSchema = new mongoose.Schema({
  option: String,
  voteTally: { type: Number, default: 0 },
  usersVotedFor: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],


}, { timestamps: { createdAt: 'created', updatedAt: 'lastUpdate' } }, { collection: 'circlevoteoption' });

//mongoose.model('CircleVoteOption', CircleVoteOptionSchema);
mongoose.model('CircleVoteOption', CircleVoteOptionSchema);

module.exports = mongoose.model('CircleVoteOption');
//module.exports = mongoose.model('CircleVoteOption');