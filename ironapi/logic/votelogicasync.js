/***************************************************************************
 * 
 * Author: JC
 * 
 * Purpose: Encapsulates logic around circlevotes.  
 * 
 * Tread lightly.  This logic is part of the backbone of the application.
 * 
 * 
 *  
 ***************************************************************************/
var CircleVote = require('../models/circlevote');
var CircleVoteOption = require('../models/circlevoteoption');
var CircleSettingsObject = require('../models/circlesettingsobject');
const CircleObject = require('../models/circleobject');
const Circle = require('../models/circle');
const usercircleLogic = require('./usercirclelogic');
var invitationLogic = require('./invitationlogic');
const circleLogic = require('./circlelogic');
const systemMessageLogic = require('./systemmessagelogic');
const UserCircle = require('../models/usercircle');
const constants = require('../util/constants');
const logUtil = require('../util/logutil');
const circle = require('../models/circle');
var randomstring = require("randomstring");


module.exports.deleteByVoteID = async function (voteID) {
    try {

        var circleVote = await CircleVote.findById(voteID);

        return this.deleteByVote(circleVote);
    } catch (err) {
        console.error(err);
        return false;
    }

}

module.exports.deleteByVote = async function (circleVote) {
    try {

        if (circleVote.type == constants.VOTE_TYPE.SECURITY_SETTING ||
            circleVote.type == constants.VOTE_TYPE.PRIVACY_SETTING
            // || circleVote.type == constants.VOTE_TYPE.SECURITY_SETTING_MODEL
            //|| circleVote.type == constants.VOTE_TYPE.PRIVACY_SETTING_MODEL
        ) {

            if (circleVote.object)
                await CircleSettingsObject.deleteOne({ "_id": circleVote.object });
        }

        for (var i = 0; i < circleVote.options.length; i++) {
            var id = circleVote.options[i];

            //console.log(id.toString());
            await CircleVoteOption.deleteOne({ "_id": id })
        }

        await CircleVote.deleteOne({ '_id': circleVote._id });
        return true;
    } catch (err) {
        console.error(err);
        return false;
    }

}

module.exports.deleteAllCircleVotes = async function deleteAllCircleVotes(circle) {

    try {
        await CircleVote.deleteMany({ "circle": circle._id });
        return true;

    } catch (err) {
        console.error(err);
        return false;
    }

}


async function createVote(circleID, creatorID, question, type, model, object, options, seed, description) {

    try {

        //create the circlevote object
        var circlevote = new CircleVote({
            circle: circleID,
            question: question
        });

        if (model)
            circlevote.model = model;

        if (type)
            circlevote.type = type;

        if (object)
            circlevote.object = object;

        if (description)
            circlevote.description = description;

        if (!seed || seed == null)
            seed = randomstring.generate({
                length: 40,
                charset: 'alphabetic'
            });


        for (var i = 0; i < options.length; i++) {
            var circleVoteOption = new CircleVoteOption({
                option: options[i].option
            })

            await circleVoteOption.save();

            circlevote.options.push(circleVoteOption);

        }

        await circlevote.save();

        //create the circleobject
        var circleobject = new CircleObject({
            circle: circleID,
            creator: creatorID,
            vote: circlevote._id,
            seed: seed,
            body: "",
            type: "circlevote",
            lastUpdate: Date.now(),
            created: Date.now(),
        });

        circleobject.lastUpdateNotReaction = circleobject.lastUpdate;

        // save the circleobject
        await circleobject.save();
        //await circleobject.populate('circle').populate('creator').populate({ path: 'vote', populate: [{ path: 'winner', populate: { path: 'usersVotedFor' } }, { path: 'options', populate: { path: 'usersVotedFor' } }] }).execPopulate();
        await circleobject.populate(['circle', 'creator', { path: 'vote', populate: [{ path: 'winner', populate: { path: 'usersVotedFor' } }, { path: 'options', populate: { path: 'usersVotedFor' } }] }]);
        return circleobject;

    } catch (err) {
        console.error(err);
        throw err;
    }
}

module.exports.voteExists = async function (circleID, type, model,) {

    try {
        let circleVote = await CircleVote.findOne({ 'circle': circleID, type: type, open: true });

        if (circleVote instanceof CircleVote)
            return true;

    } catch (err) {
        console.error(err);

    }
    return false;
}

module.exports.createCircleVote = async function (circleID, creatorID, question, type, model, object, options, seed, description) {

    try {

        if (type != constants.VOTE_TYPE.STANDARD) {

            if (type == constants.VOTE_TYPE.ADD_MEMBER) {
                var circleVote = await CircleVote.findOne({ 'circle': circleID, object: object, type: type, open: true });

                if (circleVote instanceof CircleVote)
                    throw new Error("Vote already exists");

            } else {
                var circleVote = await CircleVote.findOne({ 'circle': circleID, type: type, open: true });

                if (circleVote instanceof CircleVote)
                    throw new Error("Vote already exists");
            }
        }


        var circleObject = await createVote(circleID, creatorID, question, type, model, object, options, seed, description);

        if (type != constants.VOTE_TYPE.STANDARD) {
            //set this members vote to yes
            circleObject = await this.setUserVote(circleObject, creatorID, "Yes", null,);
        }

        return circleObject;

    } catch (err) {
        var msg = await logUtil.logError(err, true, null, creatorID);
        throw (err);
    }

}

module.exports.forceCloseVote = async function (vote, isInvitation) {

    try {

        let circleObject = await CircleObject.findOne({ vote: vote._id }).populate({ path: 'vote', populate: [{ path: 'winner', populate: { path: 'usersVotedFor' } }, { path: 'options', populate: { path: 'usersVotedFor' } }] }).populate('circle').populate("creator").exec();

        //find the option and push the user
        var voteTally = 0;

        if (circleObject == null || circleObject.vote == null) {
            //console.log(vote);
            return;
        }

        for (var i = 0; i < circleObject.vote.options.length; i++) {
            var optionToCompare = circleObject.vote.options[i];
            voteTally += optionToCompare.voteTally;
        }

        var numberOfUsers = await usercircleLogic.getNumberofUsers(circleObject.circle);

        if (isInvitation) {
            //set to majority
            circleObject.vote.model = constants.VOTE_MODEL.MAJORITY;
        }

        //force close
        circleObject = determineIfWinner(circleObject, numberOfUsers, voteTally, true);

        if (isInvitation == true) {

            await systemMessageLogic.sendMessage(circleObject.circle, 'invitation vote timed out and was closed with majority wins');
        } else if (circleObject.vote.model == constants.VOTE_MODEL.POLL) {

            await systemMessageLogic.sendMessage(circleObject.circle, 'poll timed out and was closed');
        } else if (circleObject.vote.model == constants.VOTE_MODEL.MAJORITY) {
            await systemMessageLogic.sendMessage(circleObject.circle, 'vote timed out and was closed with majority wins');
        } else if (circleObject.vote.model == constants.VOTE_MODEL.UNANIMOUS) {
            await systemMessageLogic.sendMessage(circleObject.circle, 'vote timed out and failed to get unanimous support');
        }


        await circleObject.vote.save();

        circleObject.lastUpdate = Date.now();
        await circleObject.save();
        // await circleObject.populate('circle').populate('creator').populate({ path: 'vote', populate: [{ path: 'winner', populate: { path: 'usersVotedFor' } }, { path: 'options', populate: { path: 'usersVotedFor' } }] }).execPopulate();
        await circleObject.populate(['circle', 'creator', { path: 'vote', populate: [{ path: 'winner', populate: { path: 'usersVotedFor' } }, { path: 'options', populate: { path: 'usersVotedFor' } }] }]);

        circleObject = await handleVoteClose(circleObject);




        return circleObject;

    } catch (err) {
        console.error(err);
        throw (err);
    }

}

module.exports.setUserVote = async function (circleObject, userID, option) {

    try {

        //was ID or object sent?
        if (!(circleObject instanceof CircleObject)) {
            circleObject = await CircleObject.findById({ '_id': circleObject }).populate({ path: 'vote', populate: [{ path: 'winner', populate: { path: 'usersVotedFor' } }, { path: 'options', populate: { path: 'usersVotedFor' } }] }).populate('circle').populate("creator").exec();

            if (!(circleObject instanceof CircleObject)) throw ("Could not find circleobject.");
        } else {
            //await circleObject.populate({ path: 'vote', populate: [{ path: 'winner', populate: { path: 'usersVotedFor' } }, { path: 'options', populate: { path: 'usersVotedFor' } }] }).populate('circle').populate("creator").execPopulate();
            await circleObject.populate(['circle', 'creator', { path: 'vote', populate: [{ path: 'winner', populate: { path: 'usersVotedFor' } }, { path: 'options', populate: { path: 'usersVotedFor' } }] }]);
        }

        //find the circlevote object and only retrive the option we are updating
        // var circleObject = await CircleObject.findById({ '_id': circleObjectID });
        //await circleObject.populate('circle').populate('creator').populate({ path: 'vote', populate: { path: 'options', populate: { path: 'usersVotedFor' } } }).execPopulate();

        //if (!circleObject) throw ("Could not find circleobject.");

        //can this user vote for this item?
        if (circleObject.vote.type == 'remove_member') {

            if (circleObject.vote.object == userID) {
                throw ("User cannot vote on their own exit");
            }
        }

        //Make sure this user did not already vote
        for (var i = 0; i < circleObject.vote.options.length; i++) {
            for (var j = 0; j < circleObject.vote.options[i].usersVotedFor.length; j++) {
                if (circleObject.vote.options[i].usersVotedFor[j]._id == userID) {

                    //remove the option
                    await circleObject.vote.options[i].usersVotedFor.pull({ "_id": userID });
                    circleObject.vote.options[i].voteTally = circleObject.vote.options[i].voteTally - 1;
                    await circleObject.vote.options[i].save();

                    //throw ("User already voted");
                }
            }
        }

        //find the option and push the user
        var voteTally = 0;

        for (var i = 0; i < circleObject.vote.options.length; i++) {
            var optionToCompare = circleObject.vote.options[i];

            if (option == optionToCompare.option) {
                optionToCompare.usersVotedFor.push(userID);
                optionToCompare.voteTally += 1;
                await optionToCompare.save();
            }

            //count the votes as we go to see if we should close the vote
            voteTally += optionToCompare.voteTally;
        }

        var numberOfUsers = await usercircleLogic.getNumberofUsers(circleObject.circle);

        circleObject = determineIfWinner(circleObject, numberOfUsers, voteTally);

        await circleObject.vote.save();

        circleObject.lastUpdate = Date.now();
        circleObject.lastUpdateNotReaction = circleObject.lastUpdate;
        await circleObject.save();
        // await circleObject.populate('circle').populate('creator').populate({ path: 'vote', populate: [{ path: 'winner', populate: { path: 'usersVotedFor' } }, { path: 'options', populate: { path: 'usersVotedFor' } }] }).execPopulate();
        await circleObject.populate(['circle', 'creator', { path: 'vote', populate: [{ path: 'winner', populate: { path: 'usersVotedFor' } }, { path: 'options', populate: { path: 'usersVotedFor' } }] }]);

        //if we closed the vote, check to see if there is anything we are supposed to do if there was a winner
        if (!circleObject.vote.open) {
            circleObject = await handleVoteClose(circleObject);

        }

        return circleObject;

    } catch (err) {
        console.error(err);
        throw (err);
    }

}

//Remove the user's vote on any open votes
module.exports.userLeftAdjustVotes = async function (circle, user) {

    try {

        //Close any votes to remove this user
        await CircleVote.updateMany({ "circle": circle._id, object: user._id }, { "open": false });

        //TODO remove user from vote choices on open votes (leave closed)

        //TODO remove user from assigned tasks

    } catch (err) {
        console.error(err);
    }

}


function determineIfWinner(circleObject, numberOfUsers, voteTally, forceClose) {

    var winner;

    ///the below is now account for when numberOfUsers is calculated
    ///if (circleObject.vote.type == constants.VOTE_TYPE.REMOVE_MEMBER) numberOfUsers = numberOfUsers - 1;  //user being removed doesn't get a vote

    //which option won?
    if (circleObject.vote.model == constants.VOTE_MODEL.MAJORITY) {

        var highestTally = 0;
        var secondHighestTally = 0;
        var drawCheck = 0;
        var winningOption;


        for (var i = 0; i < circleObject.vote.options.length; i++) {
            var optionToCompare = circleObject.vote.options[i];

            if (optionToCompare.voteTally > highestTally) {

                secondHighestTally = highestTally;
                highestTally = optionToCompare.voteTally;
                winningOption = optionToCompare;
            } else if (optionToCompare.voteTally == highestTally) {
                drawCheck = highestTally;
            } else {
                //adjust secondHighestTally
                if (secondHighestTally < optionToCompare.voteTally)
                    secondHighestTally = optionToCompare.voteTally;
            }

        }

        //console.log(highestTally - secondHighestTally);
        //console.log(numberOfUsers - voteTally);

        let close = (highestTally - secondHighestTally) > (numberOfUsers - voteTally);  //enough remaining voters to swing the balance
        //console.log(close);


        if (forceClose) {

            close = true;

        }

        //first, determine if vote is still open
        if (close == false) {

            return circleObject;

        } else {  //there is a majority, or at least everyone voted, or the vote was force closed
            circleObject.vote.open = false;

            if (highestTally > drawCheck)
                winner = winningOption;
        }

    } else if (circleObject.vote.model == constants.VOTE_MODEL.POLL) {

        if (forceClose) {
            circleObject.vote.open = false;
            return circleObject;
        }

        if (numberOfUsers > voteTally) return circleObject;  //vote is not finished

        circleObject.vote.open = false;

        var highestTally = 0;
        var drawCheck = 0;
        var winningOption;

        for (var i = 0; i < circleObject.vote.options.length; i++) {
            var optionToCompare = circleObject.vote.options[i];

            if (optionToCompare.voteTally > highestTally) {

                highestTally = optionToCompare.voteTally;
                winningOption = optionToCompare;
            } else if (optionToCompare.voteTally == highestTally) {
                drawCheck = highestTally;
            }

        }

        if (highestTally > drawCheck == true)
            winner = winningOption;
        else
            return circleObject;

    } else if (circleObject.vote.model == constants.VOTE_MODEL.UNANIMOUS) {

        if (forceClose) {
            circleObject.vote.open = false;
            return circleObject;
        }


        var match = false;
        var possibleWinner;

        for (var i = 0; i < circleObject.vote.options.length; i++) {
            var optionToCompare = circleObject.vote.options[i];

            if (optionToCompare.voteTally > 0) {
                if (match) {
                    //vote failed because at least one other person voted against the idea
                    circleObject.vote.open = false;
                    return circleObject;
                }
                possibleWinner = optionToCompare;
                match = true;
            }

        }

        ///check to see if someone voted no and it's a yes/no vote
        if (circleObject.vote.options.length == 2 && match == true && possibleWinner.option == 'No') {
            //winner = possibleWinner;
            ///there is no winner
            winner = undefined;
        } else if (numberOfUsers > voteTally) {
            //vote is not finished (waited to see if there was a dissenter first
            return circleObject;
        } else {
            //we made it out of the for loop.  posssibleWinner is the winner
            winner = possibleWinner;
        }

    }

    circleObject.vote.open = false;
    circleObject.vote.winner = winner;
    return circleObject;

}

async function flipUserBeingVotedOut(circleObject, beingVotedOut) {

    var userCircle = await UserCircle.findOne({ "circle": circleObject.circle._id, "user": circleObject.vote.object }).populate("circle").populate("user").exec();

    userCircle.beingVotedOut = beingVotedOut;
    await userCircle.save();
}

async function handleVoteClose(circleObject) {

    //add more than yes later.
    /*if (circleObject.vote.winner == null || circleObject.vote.winner.option != 'Yes') {

        if (circleObject.vote.type == constants.VOTE_TYPE.REMOVE_MEMBER) {
            await flipUserBeingVotedOut(circleObject, false);
        }
        return circleObject;
    }
    */

    try {
        if (circleObject.vote.type == constants.VOTE_TYPE.ADD_MEMBER) {
            await invitationLogic.handleVoteClosure(circleObject.vote);

        } else if (circleObject.vote.type == constants.VOTE_TYPE.DELETE_CIRCLE) {

            if (circleObject.vote.winner != undefined && circleObject.vote.winner != null) {
                if (circleObject.vote.winner.option == 'Yes') {
                    await circleLogic.deleteCircle(circleObject.creator._id, circleObject.circle);
                }
            }

        } else if (circleObject.vote.type == constants.VOTE_TYPE.REMOVE_MEMBER) {

            if (circleObject.vote.winner != undefined && circleObject.vote.winner != null) {

                if (circleObject.vote.winner.option == 'Yes') {
                    var userCircle = await UserCircle.findOne({ "circle": circleObject.circle._id, "user": circleObject.vote.object }).populate("circle").populate("user").exec();
                    await usercircleLogic.deactivateUserCircle(userCircle, ' was voted out');
                } else {
                    ///there is a winner and it is a no
                    await flipUserBeingVotedOut(circleObject, false);
                }
            } else {
                ///there is no winner
                await flipUserBeingVotedOut(circleObject, false);
            }

        } else if (circleObject.vote.type == constants.VOTE_TYPE.SECURITY_SETTING
            || circleObject.vote.type == constants.VOTE_TYPE.PRIVACY_SETTING) {

            if (circleObject.vote.winner != undefined && circleObject.vote.winner != null) {

                if (circleObject.vote.winner.option == 'Yes') {

                    let circleSettingObject = await CircleSettingsObject.findById(circleObject.vote.object);
                    //var circle = await Circle.findById(circleSettingObject.circle);
                    let circle = circleObject.circle;

                    circle.privacyInvitationTimeout = circleSettingObject.proposedCircle.privacyInvitationTimeout;
                    circle.privacyIncludeCircleName = circleSettingObject.proposedCircle.privacyIncludeCircleName;
                    circle.privacyShareImage = circleSettingObject.proposedCircle.privacyShareImage;
                    circle.privacyShareURL = circleSettingObject.proposedCircle.privacyShareURL;
                    circle.privacyShareGif = circleSettingObject.proposedCircle.privacyShareGif;
                    circle.privacyCopyText = circleSettingObject.proposedCircle.privacyCopyText;
                    circle.securityMinPassword = circleSettingObject.proposedCircle.securityMinPassword;
                    //circle.security2FA = circleSettingObject.proposedCircle.security2FA
                    circle.securityDaysPasswordValid = circleSettingObject.proposedCircle.securityDaysPasswordValid;
                    circle.securityTokenExpirationDays = circleSettingObject.proposedCircle.securityTokenExpirationDays;
                    circle.securityLoginAttempts = circleSettingObject.proposedCircle.securityLoginAttempts;
                    circle.toggleEntryVote = circleSettingObject.proposedCircle.toggleEntryVote;

                    if (circle.privacyDisappearingTimer != circleSettingObject.proposedCircle.privacyDisappearingTimer) {

                        if (circleSettingObject.proposedCircle.privacyDisappearingTimer == 0) {
                            circle.privacyDisappearingTimer = 0;
                            circle.privacyDisappearingTimerSeconds = 0;
                        } else {

                            //circle = setTimerForCircle(circle, circleSettingObject.proposedCircle);
                            circle.privacyDisappearingTimer = circleSettingObject.proposedCircle.privacyDisappearingTimer;
                            circle.privacyDisappearingTimerSeconds = circle.privacyDisappearingTimer * 60 * 60;
                        }
                    }

                    circle.lastUpdate = Date.now();
                    await circle.save();
                    await CircleSettingsObject.deleteOne({ "_id": circleObject.vote.object });
                }
            }


        } else if (circleObject.vote.type == constants.VOTE_TYPE.SECURITY_SETTING_MODEL
            || circleObject.vote.type == constants.VOTE_TYPE.PRIVACY_SETTING_MODEL) {

            if (circleObject.vote.winner != undefined && circleObject.vote.winner != null) {

                if (circleObject.vote.winner.option == 'Yes') {

                    let circle = circleObject.circle;

                    if (circleObject.vote.type == constants.VOTE_TYPE.SECURITY_SETTING_MODEL)
                        circle.securityVotingModel = circleObject.vote.object;
                    else
                        circle.privacyVotingModel = circleObject.vote.object;

                    circle.lastUpdate = Date.now();
                    await circle.save();
                }
            }

        }

        return circleObject;
    } catch (err) {
        var msg = await logUtil.logError(err, true);
    }

}


async function setTimerForCircle(circle, proposedCircle) {

    try {

        let timer = proposedCircle.privacyDisappearingTimer * 1000 * 60 * 60;
        let timerExpires = new Date(Date.now() - timer);

        circle.timerExpires = timerExpires;


        return circle;
        // await CircleObject.updateMany({ "circle": circle._id, 'type': {$ne: 'deleted'} }, { $set: { timerExpires: timerExpires, timer: timer } });

        //let the worker delete them on next sweep
    } catch (err) {
        logUtil.logError(err, true);
    }

}



//SECURITY_SETTING_MODEL: 'security_setting_model',
//PRIVACY_SETTING_MODEL: 'privacy_setting_model',