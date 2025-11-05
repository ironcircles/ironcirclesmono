const express = require('express');
const router = express.Router();
const bodyParser =  require('body-parser');
const passport = require('passport');
var reviewLogic = require('../logic/reviewlogic');
var CircleReviewMaster = require('../models/circlereviewmaster');
var CircleReview = require('../models/circlereview');
const securityLogic = require('../logic/securitylogic');
const deviceLogic = require('../logic/devicelogic');
const logUtil = require('../util/logutil');
const kyberLogic = require('../logic/kyberlogic');

const ObjectID = require('mongodb').ObjectID;

if (process.env.NODE_ENV !== 'production') {
    require('dotenv').load();
  }
 

router.use(bodyParser.urlencoded({ extended: true }));
router.use(bodyParser.json());


router.post('/', passport.authenticate('jwt', { session: false}), function(req, res) {

    //AUTHORIZATION CHECK
    securityLogic.canUserAccessCircle(req.user.id, req.body.circleid, function(valid){
      if (!valid)
        return res.json({success: false, msg: 'Access denied'});

      //make sure the parameters were passed in
      try {
         //var circleID = new ObjectID(req.body.circleid);

          reviewLogic.createCircleReview(req.body.circleid, req.user.id, req.body.name, req.body.type, req.body.details,
              req.body.url, req.body.rating, function(success, msg, circlereviewid, updatedrating){

            if (success){

              deviceLogic.sendNotificationToCircle(req.body.circleID, req.user.id, req.headers.devicetoken)
              .then(function(){
                return res.json({success: true, msg: 'Successfully saved new review', circlereviewid: circlereviewid, averagerating:updatedrating});
              })
              .catch(function(err){
                  console.error(err);
                  return res.json({success: false, circleobject: circleobject, msg: 'Could not send review notification'});
              });

            }
          });


      } catch(err) {
          return res.status(400).json({ success: false, msg: "Need to send parameters" }); 
      }
    });

});


router.put('/:id', passport.authenticate('jwt', { session: false}), function(req, res) {

    //AUTHORIZATION CHECK
    securityLogic.canUserAccessCircleReturnUserCircle(req.user.id, req.body.circleid, function(valid, usercircle){
      if (!valid)
        return res.json({success: false, msg: 'Access denied'});

        try {

            reviewLogic.updateCircleReview(req.params.id, req.body.rating, req.body.details, function(success, updatedrating){

              if (!success)
                return res.json({success: false, msg: msg});                

              deviceLogic.sendNotificationToCircle(req.body.circleID, req.user.id, req.headers.devicetoken)
              .then(function(){
                return res.json({success: true, msg: 'Successfully updated review', averagerating: updatedrating});
              })
              .catch(function(err){
                  console.error(err);
                  return res.json({success: false, circleobject: circleobject, msg: 'Could not send review notification'});
              });
              
            });

        } catch(err) {
            return res.status(400).json({ success: false, msg: "Update review failed" }); 
        }
    });

});


router.delete('/:id', passport.authenticate('jwt', { session: false}), function(req, res) {

  //AUTHORIZATION CHECK
  securityLogic.canUserAccessCircleObject(req.user.id, req.params.id, function(valid){
    if (!valid)
      return res.json({success: false, msg: 'Access denied'});

        //make sure the parameters were passed in
      try {
          var circleObjectID = new ObjectID(req.body.circleid);
          //var userID = new ObjectID(req.body.userid);

          reviewLogic.deleteCircleReview(circleObjectID, function(success, msg){

            if (success){
              return res.json({success: true, msg: 'Successfully deleted review'});
            } else  {
              return res.json({success: false, msg: msg});
            }
            
          });


      } catch(err) {
          return res.status(400).json({ success: false, msg: "Need to send parameters" }); 
      }
    });
});


//Return master review objects along with individual responses for the user looking at the review
router.get('/distinctreview/:id', passport.authenticate('jwt', { session: false}), function(req, res) {

  
    CircleReviewMaster.findOne({"_id":req.params.id}, function (err, reviewMaster) {
      if (err) return res.status(500).send("There was a problem finding the master review."); 

      //AUTHORIZATION CHECK
      securityLogic.canUserAccessCircle(req.user.id, reviewMaster.circle, function(valid){
        if (!valid)
          return res.json({success: false, msg: 'Access denied'});

      
          CircleReview.find({"master":reviewMaster._id}, function (err, reviews) {
            if (err) return res.status(500).send("There was a problem finding the reviews."); 
            
            
            res.status(200).send({success: true, reviewmaster: reviewMaster, reviews: reviews});
          
          }).populate("user");

      });
  
    });
});



router.get('/uniquenamesforcircle/:id', passport.authenticate('jwt', { session: false}), function(req, res) {

  //AUTHORIZATION CHECK
  securityLogic.canUserAccessCircle(req.user.id, req.params.id, function(valid){
    if (!valid)
      return res.json({success: false, msg: 'Access denied'});

      CircleReviewMaster.find({"circle":req.params.id}, function (err, reviewMasters) {
        if (err) return res.status(500).send("There was a problem finding the reviews.");      

        res.status(200).send({success: true, reviewmasters: reviewMasters});
      
      });
  });
});


module.exports = router;
