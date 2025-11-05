/***************************************************************************
 * 
 * Author: JC
 * 
 * Purpose: Encapsulates logic to deal with Circle models.  
 *  
 * TODO: update logic to use promises instead of callbacks.
 * 
 *  
 ***************************************************************************/
const constants = require('../util/constants');
const Circle = require('../models/circle');
const User = require('../models/user');
const CircleObject = require('../models/circleobject');
const UserCircle = require('../models/usercircle');
const CircleVote = require('../models/circlevote');
const CircleVoteOption = require('../models/circlevoteoption');
const usercircleLogic = require('../logic/usercirclelogic');
const awsLogic = require('../logic/awslogic');
const voteLogic = require('./votelogicasync');
const circleobjectLogic = require('../logic/circleobjectlogic');
var circleRecipeLogic = require('../logic/circlerecipelogic');
const imageLogic = require('../logic/imagelogic');
const videoLogic = require('../logic/videologic');
const invitationLogic = require('../logic/invitationlogic');
const gridFS = require('../util/gridfsutil');
const systemMessageLogic = require('../logic/systemmessagelogic');
const user = require('../models/user');
const logUtil = require('../util/logutil');
const { ChainableTemporaryCredentials } = require('aws-sdk');

if (process.env.NODE_ENV !== 'production') {
    require('dotenv').load();
}

module.exports.requestToRemoveMember = async function (userID, circleID, memberID) {

    try {

        if (userID == memberID)
            throw new Error(("Choose the leave option instead"));

        let member = await User.findById(memberID);
        if (member.minor == true) throw new Error(("Minors cannot be voted out"));

        //load circle in question
        var circle = await Circle.findById({ "_id": circleID });

        if (circle.ownershipModel == constants.CIRCLE_OWNERSHIP.OWNER) {

            if (circle.owner == userID) {
                var userCircle = await UserCircle.findOne({ "circle": circleID, "user": memberID }).populate("circle").populate("user").exec();
                await usercircleLogic.deactivateUserCircle(userCircle, ' was removed');
                return ("");
            }
            else {
                throw new Error(("Only the owner of this circle can remove members"));
            }

        } else {
            //how many users are there in this circle?
            var count = await usercircleLogic.getNumberofUsersP(circleID);

            if (count > 2) {
                return createVoteToRemoveMember(circleID, userID, memberID);

            } else if (count == 2) {

                return ("Cannot remove 1 of 2 members.  Consider leaving instead.");

            } else if (count == 1) {

            } else {
                return ("Could not find any members");
            }
        }

    } catch (err) {
        logUtil.logError(err, true);
        throw (err);
    }

}

async function createVoteToRemoveMember(circleID, userID, memberID) {
    try {

        var userCircle = await UserCircle.findOne({ 'user': memberID, 'circle': circleID }).populate("user").populate("circle").exec();

        if (!(userCircle instanceof UserCircle)) throw new Error(("Could not find UserCircle"));

        var circleVote = new CircleVote({});
        circleVote.options.push(CircleVoteOption({ option: "Yes" }));
        circleVote.options.push(CircleVoteOption({ option: "No" }));

        //create a vote
        var circleObject = await voteLogic.createCircleVote(userCircle.circle.id, userID,
            "Remove " + userCircle.user.username + " from this circle?",
            constants.VOTE_TYPE.REMOVE_MEMBER, userCircle.circle.votingModel, memberID, circleVote.options);

        if (!(circleObject instanceof CircleObject)) {

            if (circleObject != null)
                throw new Error((circleObject));
            else
                throw new Error("Could not create vote");
        }

        //set a flag so the user can't see anything until the vote is over, deleted, or canceled.
        userCircle.beingVotedOut = true;
        await userCircle.save();

        return "Vote to remove user created";

    } catch (err) {

        logUtil.logError(err, true);
        return err;
    }
}

module.exports.requestToDeleteCircle = async function (userID, circleID) {

    try {
        //can this circle be deleted?
        var circle = await Circle.findById({ "_id": circleID });

        if (!(circle instanceof Circle)) throw new Error(("Could not load circle"));

        if (circle.ownershipModel == constants.CIRCLE_OWNERSHIP.OWNER) {

            if (circle.owner == userID) {
                await deleteCircle(userID, circle);

                return "Circle deleted";
            }

            else
                throw new Error("Only the owner can delete this circle");

        } else {

            //find out if there is more than one user in the circle
            var userCircles = await UserCircle.find({ "circle": circle._id });

            if (userCircles.length == 1) {

                //sanity check
                if (userCircles[0].user == userID) {
                    await deleteCircle(userID, circle);
                    return circle.chatType() + " deleted";

                }
            }
            var circlevote = new CircleVote({});
            //var circleVoteYes = await CircleVoteOption.create({option: "Yes"});
            //var circleVoteNo = await CircleVoteOption.create({option: "Yes"});

            circlevote.options.push(CircleVoteOption({ option: "Yes" }));
            circlevote.options.push(CircleVoteOption({ option: "No" }));

            //create a vote
            var circleObject = await voteLogic.createCircleVote(circle._id, userID,
                "Permanently delete this " + circle.chatType(),
                constants.VOTE_TYPE.DELETE_CIRCLE, constants.VOTE_MODEL.UNANIMOUS, null, circlevote.options);

            if (!(circleObject instanceof CircleObject)) {
                if (circleObject) throw new Error((circleObject)); else throw new Error(("Failed to create vote"));
            }

            return circleObject;
        }


    } catch (err) {
        logUtil.logError(err, true);
        throw new Error(err);
    }

}


async function deleteCircle(userID, circle) {

    try {
        await Circle.deleteOne({ "_id": circle._id });

        await videoLogic.deleteAllCircleVideos(userID, circle);
        await imageLogic.deleteAllCircleImages(userID, circle);
        await usercircleLogic.deleteAllCircleUserCircles(circle);
        await circleobjectLogic.deleteAllCircleCircleObjects(circle);
        await voteLogic.deleteAllCircleVotes(circle);
        await circleRecipeLogic.deleteAllCircleRecipes(circle);
        //await imageLogic.deleteAllCircleImages(circle);
        await invitationLogic.deleteAllCircleInvitations(circle);

        if (circle.background) {
            if (circle.backgroundLocation == constants.BLOB_LOCATION.GRIDFS) {
                gridFS.deleteBlob("circlebackgrounds", circle.background);
            } else {
                awsLogic.deleteObject(process.env.s3_backgrounds_bucket, circle.background);
            }
        }

        return circle.chatType() + " deleted";

    } catch (err) {
        logUtil.logError(err, true);
        throw (err);
    }


}


module.exports.memberCount = async function (circle) {

    try {
        let memberCount = await UserCircle.countDocuments({ "circle": circle._id });
        return memberCount;
    } catch (err) {
        await logUtil.logError(err, true);
        throw (err);
    }
}


module.exports.deleteCircle = deleteCircle;