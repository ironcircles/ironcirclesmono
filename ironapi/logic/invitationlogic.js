/***************************************************************************
 * 
 * Author: JC
 * 
 * Purpose: Encapsulates invitation logic
 * 
 * TODO: Rewrite functions that use callbacks with promises
 * 
 *  
 ***************************************************************************/
var Invitation = require('../models/invitation');
const CircleObject = require('../models/circleobject');
var CircleVote = require('../models/circlevote');
const deviceLogic = require('../logic/devicelogic');
var voteLogic = require('./votelogicasync');
const systemmessageLogic = require('../logic/systemmessagelogic');
const constants = require('../util/constants');
const logUtil = require('../util/logutil');


module.exports.handleVoteClosure = async function (circlevote) {

    try {

        var invitation = await Invitation.findOne({ vote: circlevote._id });
        await invitation.populate("invitee");

        if (!invitation)
            throw new Error(("Could not load invitation"));

        var success = false;

        //Was the vote successful?
        if (circlevote.winner) {
            if (circlevote.winner.option == "Yes") {
                success = true;
            }
        }

        if (success)
            await this.inviteUser(invitation);
        else {

            //vote failed
            await deleteInvitationVoteFailed(invitation);
        }

        return;

    } catch (err) {
        console.error(err);
        throw (err);
    }


}


module.exports.deleteAllCircleInvitations = function (circle) {
    try {

        return new Promise(function (resolve, reject) {

            Invitation.deleteMany({ "circle": circle._id })
                .then(function () {
                    return resolve();
                })
                .catch(function (err) {
                    console.error(err);
                    return reject(err);
                });

        });

    } catch (err) {
        console.error(err);
        return callback(false);
    }

}


module.exports.deleteByVoteID = async function (voteID) {
    try {
        var invitation = await Invitation.deleteOne({ 'vote': voteID });

        if (invitation instanceof Invitation) {
            await systemmessageLogic.sendMessage(invitation.circle, "Invitation deleted");
            return true;

        }

    } catch (err) {
        console.error(err);
    }

    return false;

}

module.exports.delete = async function (invitation) {
    try {


        await Invitation.deleteOne({ '_id': invitation._id });
        await CircleVote.deleteOne({ '_id': invitation.vote });

        return true;

    } catch (err) {
        console.error(err);
    }

    return false;

}


module.exports.deleteAllForUser = async function (user) {
    try {

        ///TODO change this to a mongo or
        let myInvites = await Invitation.find({ 'inviter': user._id });
        let memberInvites = await Invitation.find({ 'invitee': user._id });

        for (let i = 0; i < myInvites.length; i++) {
            let invitation = myInvites[i];
            await CircleVote.deleteOne({ '_id': invitation.vote });

        }

        for (let i = 0; i < memberInvites.length; i++) {
            let invitation = memberInvites[i];
            await CircleVote.deleteOne({ '_id': invitation.vote });

        }

        await Invitation.deleteMany({ 'invitee': user._id });
        await Invitation.deleteMany({ 'inviter': user._id });

        return true;

    } catch (err) {
        console.error(err);
    }

    return false;

}

async function deleteInvitationVoteFailed(invitation, callback) {

    try {
        await Invitation.deleteOne({ _id: invitation._id });

        var message = "Vote to invite " + invitation.invitee.username + " did not pass.";

        systemmessageLogic.sendMessage(invitation.circle, message);
        //deviceLogic.sendDataOnlyMessage(invitation.circle, null, null);

    } catch (err) {
        console.error(err);
        return callback(false);
    }
}

module.exports.getUserInvitationCount = async function (userid) {

    let count = 0;

    try {
        //fetch the number of invitations for this user and pass it back.  
        count = await Invitation.countDocuments({ "invitee": userid, status: "pending", circle: { $ne: null } });

        return count;
    } catch (err) {
        console.error(err);
        return null;
    }
}

module.exports.getUserInvitations = async function (userid) {

    try {
        //fetch invitations for this user and pass it back.  
        let results = await Invitation.find({ "invitee": userid, status: "pending", circle: { $ne: null } }).sort({ created: 1 }).populate('circle').populate("invitee").populate("inviter");

        return results;
    } catch (err) {
        console.error(err);
        return null;
    }
}

module.exports.kickOffMemberVote = async function (invitation, circle, invitee, inviterID, seed) {

    try {

        //create the vote
        var circleObject = await voteLogic.createCircleVote(circle._id, inviterID,
            "Ok to invite " + invitee.username + " to this circle?",
            constants.VOTE_TYPE.ADD_MEMBER, circle.privacyVotingModel, invitee._id, [{ option: "Yes" }, { option: "No" }], seed);


        await circleObject.populate(['creator', 'circle', 'vote']);

        //var circleObject = await CircleObject.findOne({"vote":circleVote._id});

        //set this members vote to yes
        await voteLogic.setUserVote(circleObject, inviterID, "Yes", null,);

        if (!(circleObject instanceof CircleObject)) throw new Error(("Failed to save vote"));

        // save the invitation
        invitation.status = "voting";
        invitation.vote = circleObject.vote._id;

        await invitation.save();
        await invitation.populate(["vote", "invitee", "inviter", "circle"]);

        return [circleObject, invitation];

    } catch (err) {
        console.error(err);
    }
}

module.exports.inviteUser = async function (invitation) {

    try {
        invitation.status = constants.INVITATION_STATUS.PENDING;

        for (let i = 0; i < invitation.invitee.blockedList.length; i++) {
            if (invitation.invitee.blockedList[i]._id == invitation.inviter.toString()) {
                invitation.status = constants.INVITATION_STATUS.BLOCKED;
                break;
            }
        }

        await invitation.save();
        await invitation.populate(["vote", "invitee", "inviter", "circle"]);


        if (invitation.dm == false) {
            let systemMessageTrailer = 'Circle';
            //if (invitation.dm)
            //   systemMessageTrailer = 'DM';
            await systemmessageLogic.sendMessage(invitation.circle,
                invitation.invitee.username + " has been invited to this " + systemMessageTrailer);
        }


        let trailer = ' a Circle';
        if (invitation.dm)
            trailer = ' a DM';

        if (invitation.status == constants.INVITATION_STATUS.PENDING)
            await deviceLogic.sendInvitation(invitation.invitee._id, invitation.inviter.username + ' has invited you to' + trailer, invitation);

        return invitation;

    } catch (err) {
        console.error(err);
    }

}

