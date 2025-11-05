
/***************************************************************************
 * 
 * Author: JC
 * 
 * Purpose: Encapsulates review logic
 * 
 * TODO: Replace functions that use callbacks with promises.  
 * Validate parameters
 * 
 *  
 ***************************************************************************/
var CircleReview = require('../models/circlereview');
var CircleReviewMaster = require('../models/circlereviewmaster');
const CircleObject = require('../models/circleobject');
const logUtil = require('../util/logutil');


function deleteCircleReview(circleobject, callback) {

   // CircleObject.findOne({"_id": circleObjectID}, function (err, circleobject){

     //   if (err) return callback (false);
        
        circleobject.populate("review", function(err, review){


            if (err)
                return callback (false);

            circleobject.review.populate("master", function(err, master){
                if (err)
                    return callback (false);

                    //var master = circleobject.review.master;

                    //is the last review on this topic?
                    if (circleobject.review.master.numberofRatings == 1){
                        
                        CircleReviewMaster.deleteOne({"_id": circleobject.review.master}, function(err){
                            if (err) 
                                return callback (false);
                        });
                        
                    } else {
                        //update the totals and save the object
                        circleobject.review.master.numberofRatings += -1;
                        circleobject.review.master.sumofRatings += -circleobject.review.rating;
                        circleobject.review.master.averageRating = circleobject.review.master.sumofRatings / circleobject.review.master.numberofRatings;
                        circleobject.review.master.save();

                        //TODO need to broadcast to people who have the app running that the numbers change
                    }
                    
                    
                    CircleReview.deleteOne({"_id": circleobject.review}, function(err){
                        if (err) {
                            return callback(false);
                        } else {
            
                            //delete the actual object
                            CircleObject.deleteOne({"_id":circleobject._id}, function (err) {
                                if (err) return callback(false);
            
                                return callback(true);
                    
                            });
                            
                        }
                    });
                
            });


        });

       

}



function updateCircleReview(circlereviewID, rating, details, callback) {

    try{

        //did this user already review this item?

        CircleReview.findOne({"_id": circlereviewID}, function (err, circlereview){
                
            if (err || !circlereview) return callback (false);

            //update the master review record
            circlereview.master.sumofRatings -= circlereview.rating;  //subtract the old rating
            circlereview.master.sumofRatings += rating;  //add the new rating           
            circlereview.master.averageRating =  circlereview.master.sumofRatings /  circlereview.master.numberofRatings;


            circlereview.master.save(function(err){
                if (err) return callback (false);


                //update the circlereview
                circlereview.details = details;
                circlereview.rating = rating;
                

                circlereview.save(function(err) {
                    if (err) {
                        callback(false);
                    } else {     
                        
                        //update the date on the circleobject for push notification
                        CircleObject.findOne({"review": circlereviewID}, function (err, circleobject){
                            if (err || !circleobject) 
                                callback(false);
                            else {    
                                circleobject.lastUpdate = Date.now();

                                circleobject.save(function(err){
                                    if (err) 
                                        callback(false);
                                    else 
                                        callback(true, circlereview.master.averageRating);

                                });

                            }

                        });

                    
                    }
            
                });

            });
                
            
        }).populate("master");

    }catch(err){
        console.error(err);
        return callback(false);
    }

}



function createCircleReview(circleID, userID, name, type, details, url, rating, callback) {

    try{
        //did this user already review this item?

        CircleReview.findOne({"user": userID, "name": name}, function (err, reviewexists){
                
            if (err) return callback (false);

            if (reviewexists != null) {
                return callback (false, "You have already reviewed this.");
            } 


            //Is there a master record?
            CircleReviewMaster.findOne({circle: circleID, "name": name}, function (err, reviewMaster){
                
                if (err) return callback (false);

                if (reviewMaster == null){   //no one has reviewed this item

                    reviewMaster = new CircleReviewMaster ({                
                        name: name,
                        type: type,
                        url: url,
                        sumofRatings: rating,
                        numberofRatings: 1,
                        averageRating: rating, //first rating so no need for math
                        circle: circleID
                    });

                } else {

                    //update the master review record
                    reviewMaster.sumofRatings += rating;
                    reviewMaster.numberofRatings += 1;
                    reviewMaster.averageRating = reviewMaster.sumofRatings / reviewMaster.numberofRatings;

                }
                
                reviewMaster.save(function(err){
                    if (err) return callback (false);


                    //create the circlereview
                    var circlereview = new CircleReview({
                        master: reviewMaster._id,
                        rating: rating,
                        details: details,

                        //denormalize for sanity
                        name: name,
                        user: userID,
                        circle: circleID
                    });


                    circlereview.save(function(err) {
                        if (err) {
                            callback(false);
                        } else {
                
                            //create the circleobject
                            var circleobject = new CircleObject({
                                circle: circleID,
                                creator: userID,
                                review: circlereview._id,
                                body: "",  
                                type: "circlereview",
                                lastUpdate: Date.now(),
                                created: Date.now(),
                            });
                            
                
                            // save the circleobject
                            circleobject.save(function(err) {
                                if (err) 
                                    callback(false);
                                else 
                                    callback(true, "created review", circlereview._id, reviewMaster.averageRating);
                            });
                
                        }
                
                    });

                });
                
                
            });

            
        }).populate({path: "master", match: {circle:circleID}});
        
    }catch(err){
        console.error(err);
        return callback(false);
    }
}



module.exports.deleteAllCircleReviews =function deleteAllCircleReviews(circle){
    return new Promise(function(resolve, reject){

        CircleReview.Remove({"circle":circle._id})
        .then(function(circlereview){
            return resolve();
        })
         .catch(function (err) {
             console.error(err);
             return reject(err);
         });
 
     });
}

module.exports.createCircleReview = createCircleReview;
module.exports.updateCircleReview = updateCircleReview;
module.exports.deleteCircleReview = deleteCircleReview;

