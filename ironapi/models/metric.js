const mongoose = require('mongoose');
var Schema = mongoose.Schema;

var MetricSchema = new Schema({
    user: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
    lastAccessed: { type: Date, },
    accountDeleted: { type: Boolean },
    recentMessageCount: { type: Number, },

}, { timestamps: { createdAt: 'created', updatedAt: 'lastUpdate' } });


module.exports = mongoose.model('metric', MetricSchema);


