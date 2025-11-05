const express = require('express');
var app = express();
var db = require('./db');
const passport = require('passport');
let worker = require('./util/worker');
const NSFW = require('./models/nsfw');

const cors = require("cors");
app.use(cors());

//bind the controllers
var UserController = require('./routes/usercontroller');
app.use('/user', UserController);

var CircleController = require('./routes/circlecontroller');
app.use('/circle', CircleController);

const CircleListController = require('./routes/circlelistcontroller');
app.use('/circlelist', CircleListController);

const CircleRecipeController = require('./routes/circlerecipecontroller');
app.use('/circlerecipe', CircleRecipeController);

var UserCircleController = require('./routes/usercirclecontroller');
app.use('/usercircle', UserCircleController);

var InvitationController = require('./routes/invitationcontroller');
app.use('/invitation', InvitationController);

var CircleObjectController = require('./routes/circleobjectcontroller');
app.use('/circleobject', CircleObjectController);

var AvatarController = require('./routes/avatarcontroller');
app.use('/avatar', AvatarController);

var CircleImageController = require('./routes/circleimagecontroller');
app.use('/circleimage', CircleImageController);

var CircleAlbumController = require('./routes/circlealbumcontroller');
app.use('/circlealbum', CircleAlbumController);

var BlobController = require('./routes/blobcontroller');
app.use('/blob', BlobController);

var CircleLinkController = require('./routes/circlelinkcontroller');
app.use('/circlelink', CircleLinkController);

var LogController = require('./routes/logcontroller');
app.use('/log', LogController);

var CircleVoteController = require('./routes/circlevotecontroller');
app.use('/circlevote', CircleVoteController);

var CircleReviewController = require('./routes/circlereviewcontroller');
app.use('/circlereview', CircleReviewController);

var CircleBackgroundController = require('./routes/circlebackgroundcontroller');
app.use('/circlebackground', CircleBackgroundController);

var UserCircleBackgroundController = require('./routes/usercirclebackgroundcontroller');
app.use('/usercirclebackground', UserCircleBackgroundController);

var CircleEventController = require('./routes/circleeventcontroller');
app.use('/circleevent', CircleEventController);

var GCMController = require('./routes/gcmcontroller');
app.use('/gcmcontroller', GCMController);

var BlockedListController = require('./routes/userblockedlistcontroller');
app.use('/blockedlist', BlockedListController);

var CircleVideoControllerS3 = require('./routes/circlevideocontroller_s3');
app.use('/circlevideos3', CircleVideoControllerS3);

var CircleVideoController = require('./routes/circlevideocontroller');
app.use('/circlevideo', CircleVideoController);

var UpgradeController = require('./routes/upgradecontroller');
app.use('/icupgrade', UpgradeController);

//var AWSController = require('./routes/awscontroller');
//app.use('/aws', AWSController);

var RatchetPublicKeyController = require('./routes/ratchetpublickeycontroller');
app.use('/ratchetpublickey', RatchetPublicKeyController);

//var GridFSController = require('./routes/gridfscontroller');
//app.use('/gridfs', GridFSController);

var KeychainBackupController = require('./routes/keychainbackupcontroller');
app.use('/keychainbackup', KeychainBackupController);

var TutorialController = require('./routes/tutorialcontroller');
app.use('/tutorial', TutorialController);

var ReleaseController = require('./routes/releasecontroller');
app.use('/release', ReleaseController);

var BacklogController = require('./routes/backlogcontroller');
app.use('/backlog', BacklogController);

var HostedFurnaceController = require('./routes/hostedfurnacecontroller');
app.use('/hostedfurnace', HostedFurnaceController);

var IronCoinController = require('./routes/ironcoincontroller');
app.use('/ironcoin', IronCoinController);

var MetricsController = require('./routes/metricscontroller');
app.use('/metrics', MetricsController);


var DeviceController = require('./routes/devicecontroller');
app.use('/device', DeviceController);

var SubscriptionController = require('./routes/subscriptioncontroller');
app.use('/subscriptions', SubscriptionController);

var MagicLinkController = require('./routes/magiclinkcontroller');
app.use('/magiclink', MagicLinkController);

var ActionRequiredController = require('./routes/actionrequiredcontroller');
app.use('/actionrequired', ActionRequiredController);

var CircleFileController = require('./routes/circlefilecontroller');
app.use('/circlefile', CircleFileController);

var NetworkRequestController = require('./routes/networkrequestcontroller');
app.use('/networkrequest', NetworkRequestController);

var UserConnectionController = require('./routes/userconnectioncontroller');
app.use('/userconnection', UserConnectionController);

var SettingsController = require('./routes/settingscontroller');
app.use('/settings', SettingsController);

var ReplyObjectController = require('./routes/replyobjectcontroller');
app.use('/replyobject', ReplyObjectController);

var AgoraController = require('./routes/agoracontroller');
app.use('/agora', AgoraController);

//init passport
app.use(passport.initialize());

//prep for maintenance
app.get('/', function (req, res) {
  res.send('Network is up and running');
});

require('events').EventEmitter.defaultMaxListeners = 50;

//app.emitter.setMax(0);


const second = 1000;
const minute = second * 60;
const hour = minute * 60;

process.on('warning', e => console.warn(e.stack));

setInterval(() => worker.timeoutMagicLinks(), hour * 4);
setInterval(() => worker.timeoutInvitations(), minute * 10);
setInterval(() => worker.timeoutVotes(), hour * 8);
setInterval(() => worker.sendReminders(), minute * 10);
//setInterval(() => worker.deleteExpiredPublicKeys(), hour * 7);
setInterval(() => worker.disappear(), second * 2);
setInterval(() => worker.cleanLogs(), hour * 8);
setInterval(() => worker.scheduledMessage(), second * 30);
//setInterval(() => worker.deliverMonthlySubscriberCoin(), hour * 12);
setInterval(() => worker.deleteExpiredCircles(), minute * 15);
setInterval(() => worker.publicNetworkActivityChecker(), hour * 12);
setInterval(() => worker.processWaitingObjects(), minute * 4);

///RBR
//worker.processWaitingObjects();
//worker.deleteExpiredPublicKeys();

module.exports = app;

