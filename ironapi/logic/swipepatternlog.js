const mongoose = require('mongoose');

var SwipePatternAttemptSchema = new mongoose.Schema({  
    circle: { type: mongoose.Schema.Types.ObjectId, ref: 'Circle' },
    user: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
    device: { type: mongoose.Schema.Types.ObjectId, ref: 'Device' },
    attemptDate: {type: Date},
}, { collection: 'swipePatternAttempts' });


mongoose.model('SwipePatternAttempt', SwipePatternAttemptSchema);

module.exports = mongoose.model('SwipePatternAttempt');
