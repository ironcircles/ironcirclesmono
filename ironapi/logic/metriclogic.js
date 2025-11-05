/***************************************************************************
 * 
 * Author: JC
 * 
 * Purpose: Encapsulates logic for dealing with Metrics.   
 * 
 * 
 *  
 ***************************************************************************/
const Metric = require('../models/metric');


module.exports.setLastAccessed = async function (user) {

  try {

    let metric = await Metric.findOne({ user: user._id });

    if (!(metric instanceof Metric)) {
      metric = new Metric({ user: user, recentMessageCount:0 });

    }
    metric.lastAccessed = Date.now();

    await metric.save();
  } catch (err) {
    console.log(err)
  }

}

module.exports.incrementPosts = async function (user) {

  try {
    let metric = await Metric.findOne({ user: user._id });

    if (!(metric instanceof Metric)) {
      metric = new Metric({ user: user });

    }
    metric.recentMessageCount = metric.recentMessageCount + 1;

    await metric.save();

  } catch (err) {

  }

}
