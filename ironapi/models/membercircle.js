module.exports = class MemberCircle {
    constructor({ userID, memberID, circleID, dm, removeFromCache }) {
        this.memberID = memberID;
        this.userID = userID;
        this.circleID = circleID;
        this.dm = dm;
        this.removeFromCache = removeFromCache;
    }

}