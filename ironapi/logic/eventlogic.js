/***************************************************************************
 * 
 * Author: JC
 * 
 * Purpose: Encapsulates event logic.  
 * 
 *  
 ***************************************************************************/
var CircleEvent = require('../models/circleevent');
var CircleEventMaster = require('../models/circleeventmaster');
const CircleObject = require('../models/circleobject');
const logUtil = require('../util/logutil');
const constants = require('../util/constants');


module.exports.saveAttendingCircleEvent = function (circleID, userID, response, numberOfGuests, circleeventid) {

    //?

    return new Promise(function (resolve, reject) {

        //load the movie to find the chunk and file reference
        CircleEvent.findOne({ _id: circleeventid })
            .then(function (circleEvent) {

                //populate the atteendees
                return CircleEvent.populate(circleEvent, { path: "respondees" });
            })
            .then(function (circleEvent) {

                if (circleEvent.respondees.length == 1) {

                    //has the response changed?
                    if (response != circleEvent.respondees[0].response) {



                    }


                    //update the number of guests
                    circleEvent.numberOfGuests -= circleEvent.respondees[0].numberOfGuests;
                    circleEvent.respondees[0].numberOfGuests = numberOfGuests;
                    circleEvent.numberOfGuests += numberOfGuests;

                    //update the response
                    circleEvent.respondees[0].response = response;

                } else {
                    //push new response    


                }

                //did this user respond?
                circleEvent.respondees.forEach(function (respondee) {
                    if (respdonee.user._id == userID) {
                        userVoted = true;
                    }
                });

            });


        //update


        //push a new response


        //update the totals
    })
        .catch(function (err) {
            console.error(err);
            return reject();
        });

}


/*module.exports.createCircleEvent = async function (circleID, userID, body, circleEvent) {

    try {


        await circleEvent.save();

        //create the circleobject
        let circleObject = new CircleObject({
            seed, 
            body: body,
            circle: circleID,
            creator: userID,
            event: circleEvent,
            type: constants.CIRCLEOBJECT_TYPE.CIRCLEEVENT,
            lastUpdate: Date.now()
        });

        await circleObject.save();

        await circleObject.populate(['creator', 'circle', 'event']);

        return circleObject;


    } catch (err) {
        var msg = await logUtil.logError(err, false);

    }
}*/

