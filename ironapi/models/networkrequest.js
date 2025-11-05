const mongoose = require('mongoose');


var NetworkRequestSchema = new mongoose.Schema({  
    description : {type: String},
    user: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
    hostedFurnace: { type: mongoose.Schema.Types.ObjectId, ref: 'HostedFurnace' },
    status: { type: Number },
}, { timestamps: { createdAt: 'created', updatedAt: 'lastUpdate'}}, { collection: 'networkrequest' });

NetworkRequestSchema.statics.new = async function (json) {

    let object = this(json);
  
    return object;
  }


mongoose.model('NetworkRequest', NetworkRequestSchema);

module.exports = mongoose.model('NetworkRequest', NetworkRequestSchema);