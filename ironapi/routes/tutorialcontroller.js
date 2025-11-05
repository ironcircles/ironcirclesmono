const express = require('express');
const router = express.Router();
const bodyParser = require('body-parser');
const mongoose = require('mongoose');
mongoose.Promise = require('bluebird');
const logUtil = require('../util/logutil');
const Topic = require('../models/topic');
const Tutorial = require('../models/tutorial');
const TutorialLineItem = require('../models/tutoriallineitem');
const CircleObject = require('../models/circleobject');
const User = require('../models/user');
const passport = require('passport');
const securityLogic = require('../logic/securitylogic');
const securityLogicAsync = require('../logic/securitylogicasync');
const deviceLogic = require('../logic/devicelogic');
const gridFS = require('../util/gridfsutil');
const ObjectID = require('mongodb').ObjectID;
const constants = require('../util/constants');

const mongodb = require('mongodb');
let conn = mongoose.connection;
let Grid = require('gridfs-stream');
const tutoriallineitem = require('../models/tutoriallineitem');
Grid.mongo = mongoose.mongo;


if (process.env.NODE_ENV !== 'production') {
  require('dotenv').load();
}

router.use(bodyParser.urlencoded({ extended: true }));
router.use(bodyParser.json());

router.get('/', passport.authenticate('jwt', { session: false }), async (req, res) => {

  try {


    let tutorial = new Tutorial({ title: 'Update Required', description: 'An app update is required before accessing the tutorials' });

    return res.status(200).send({
      tutorials: [tutorial],
    });

  } catch (err) {
    var msg = await logUtil.logError(err, true);
    return res.status(500).json({ msg: msg });
  }


});

router.get('/topics/:id', async (req, res) => {

  try {

      //   var topics = await Topic.find({requireHidden: false}).sort({ 'order': 1 });

      // return res.status(200).send({
      //   topics: topics,
      // });

    if (req.headers.textbased != undefined && req.headers.textbased != null) {
      let user = await User.findById(req.params.id);

      //don't include hidden circle/browser tutorials for minors
      var topics = await Topic.find({ $or: [{ requireHidden: false }, { requireHidden: user.allowClosed }] }).sort({ 'order': 1 });

      return res.status(200).send({
        topics: topics,
      });
    } 

  } catch (err) {
    var msg = await logUtil.logError(err, true);
    return res.status(500).json({ msg: msg });
  }


});


// router.get('/topics', async (req, res) => {

//   try {


//     var topics = await Topic.find().sort({ 'order': 1 });

//     return res.status(200).send({
//       topics: topics,
//     });


//     // if (req.headers.textbased != undefined && req.headers.textbased != null) {
//     //   let user = await User.findById(req.params.id);

//     //   //don't include hidden circle/browser tutorials for minors
//     //   var topics = await Topic.find({ $or: [{ requireHidden: false }, { requireHidden: user.allowClosed }] }).sort({ 'order': 1 });

//     //   return res.status(200).send({
//     //     topics: topics,
//     //   });
//     // } else {

//     //   let tutorials = [];
//     //   tutorials.push(new Tutorial({ id: '', title: 'Your app needs an updated before Tutorials can be accessed' }));

//     //   let topic = new Topic({ id: '', topic: 'Update Required', order: 0, tutorials: tutorials });

//     //   return res.status(200).send({
//     //     topics: [topic],
//     //   });
//     //}

//   } catch (err) {
//     var msg = await logUtil.logError(err, true);
//     return res.status(500).json({ msg: msg });
//   }


// });

router.post('/generate/', passport.authenticate('jwt', { session: false }), async (req, res) => {
  //router.post('/generate/', async (req, res) => {
  try {

    let validUser = req.user;

    if (validUser.role != constants.ROLE.IC_ADMIN && process.env.NODE_ENV == 'production') 
      return res.status(400).json({ message: "Unauthorized" });


    await Topic.deleteMany({});

    var topic;
    var tutorial;
    var order = 0;

    topic = new Topic({ topic: 'Getting Started', order: order++ });

    tutorial = new Tutorial({ title: 'Terminology ' });
    tutorial.lineItems.push(new TutorialLineItem({ item: 'Networks', subTitle: true }));
    tutorial.lineItems.push(new TutorialLineItem({ item: 'Networks are your own private place to connect with friends and family and stash personnel stuff.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: 'No one can join your network or access any of it\'s contents without your permission.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: 'Networks contain a central Feed and unlimited Circles, DMs, and Vaults.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: 'Feed', subTitle: true }));
    tutorial.lineItems.push(new TutorialLineItem({ item: 'The feed is a central place to post across an entire Network. Think Instgram, but secure.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: 'Circles', subTitle: true }));
    tutorial.lineItems.push(new TutorialLineItem({ item: 'Circles are encrypted places to have group conversations.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: 'DMs', subTitle: true }));
    tutorial.lineItems.push(new TutorialLineItem({ item: 'Direct Messages (DMs) are encrypted conversations between two people.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: 'Vaults', subTitle: true }));
    tutorial.lineItems.push(new TutorialLineItem({ item: 'Vaults are personal encrypted places to store information. No one else can be added to a Vault.' }));
    topic.tutorials.push(tutorial);

    tutorial = new Tutorial({ title: 'Walkthroughs' });
    tutorial.lineItems.push(new TutorialLineItem({ item: 'Screens with ? icon in the top menu bar include walkthroughs for that screen.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: 'The walkthroughs will guide you through the most commonly used features.' }));
    topic.tutorials.push(tutorial);

    tutorial = new Tutorial({ title: 'Intro videos' });
    tutorial.lineItems.push(new TutorialLineItem({ item: 'Feature Overview', video: 'https://ic-tutorials.s3.us-west-2.amazonaws.com/ironcircles_intro.mp4' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: 'Tutorial on Secure Messaging', video: 'https://ic-tutorials.s3.us-west-2.amazonaws.com/forward_secrecy.mp4' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: 'Promo Video', video: 'https://ic-tutorials.s3.us-west-2.amazonaws.com/IronCircles_promo.mp4' }));
    topic.tutorials.push(tutorial);

    await topic.save();

    topic = new Topic({ topic: 'Manage your network', order: order++ });
    
    tutorial = new Tutorial({ title: 'Lockout a user from your network' });
    tutorial.lineItems.push(new TutorialLineItem({ item: 'An owner or admin of a network can lockout a user' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: 'This will will remove the user\s access. They will be unable to view message history or post new items.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: 'To lock out a user', subTitle: true }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '1) Tap on the left upper menu icon from the Home screen.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '2) Tap on Network Manager.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '3) Select the network from the list.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '4) Tap lockout next to the user\'s name.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: 'You can unlock their account at anytime.' }));
    topic.tutorials.push(tutorial);

    tutorial = new Tutorial({ title: 'Change network access code' });
    tutorial.lineItems.push(new TutorialLineItem({ item: 'To change the access code', subTitle: true }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '1) Tap on the left upper menu icon from the Home screen.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '2) Tap on Network Manager.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '3) Select the network from the list.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '4) Enter a new access code.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: 'The change is effective immediately. Also, it does not impact any users already connected to your network' }));
    topic.tutorials.push(tutorial);

    tutorial = new Tutorial({ title: 'Make your network discoverable' });
    tutorial.lineItems.push(new TutorialLineItem({ item: 'Setting your network to discoverable allows people you don\'t know to request to join. You receive a notification and can approve / deny in the Network Manager.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: 'To set your network to discoverable:', subTitle: true }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '1) Tap on the left upper menu icon from the Home screen.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '2) Tap on Network Manager.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '3) Select the network from the list.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '4) Flip the \'Make network discoverable\' toggle.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: 'The change is effective immediately.' }));
    topic.tutorials.push(tutorial);

    tutorial = new Tutorial({ title: 'Turn the Network wide Feed on / off' });
    tutorial.lineItems.push(new TutorialLineItem({ item: 'The Feed is a central place to post across an entire Network. Think Instgram, but secure.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: 'To turn the central Feed on or off:', subTitle: true }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '1) Tap on the left upper menu icon from the Home screen.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '2) Tap on Network Manager.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '3) Select the network from the list.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '4) Flip the \'Enable network wide social feed\' toggle.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: 'The change is effective immediately.' }));
    topic.tutorials.push(tutorial);

    tutorial = new Tutorial({ title: 'Allow others to create Circles and send invites' });
    tutorial.lineItems.push(new TutorialLineItem({ item: 'Other users can create Circles, DMs, and Vaults and send invitations on your network by default. You can control this permission.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: 'To turn on / off:', subTitle: true }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '1) Tap on the left upper menu icon from the Home screen.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '2) Tap on Network Manager.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '3) Select the network from the list.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '4 ) Flip the \'Allow anyone to created circles and send invites\' button.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: 'The change is effective immediately.' }));
    topic.tutorials.push(tutorial);

    tutorial = new Tutorial({ title: 'Change your Network image' });
    tutorial.lineItems.push(new TutorialLineItem({ item: 'An owner or admin of a network can change the image' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: 'To change the image:', subTitle: true }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '1) Tap on the left upper menu icon from the Home screen.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '2) Tap on Network Manager.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '3) Select the network from the list.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '4) Tap either the \'generate image\' or \'select from device\' buttons .' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '5) Generate or pick an image.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: 'The change is effective immediately.' }));
    topic.tutorials.push(tutorial);

    tutorial = new Tutorial({ title: 'Change your network description' });
    tutorial.lineItems.push(new TutorialLineItem({ item: 'To change the description:', subTitle: true }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '1) Tap on the left upper menu icon from the Home screen.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '2) Tap on Network Manager.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '3) Select the network from the list.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '4) Enter a new access code.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: 'The change is effective immediately.' }));
    topic.tutorials.push(tutorial);

    await topic.save();


    topic = new Topic({ topic: 'Create Circles, Vaults and DMs', order: order++ });

    tutorial = new Tutorial({ title: 'Create a new Circle' });
    tutorial.lineItems.push(new TutorialLineItem({ item: '1) Tap the + icon on the Circle tab on the Home screen.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '2) Enter a name for the Circle.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '3) Select a Network from the network dropdown.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '4) Optional - select a background image.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '5) Optional - configure privacy settings.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '6) Tap the Next button.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '7) Optional - Select users from the list to include in the Circle.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '8) Optional - Add a user to the list by typing their username and tapping the Add button.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '9) Tap the Create New Circle button.' }));
    topic.tutorials.push(tutorial);

    tutorial = new Tutorial({ title: 'Create a new Vault' });
    tutorial.lineItems.push(new TutorialLineItem({ item: '1) Tap the + icon on the Circle tab on the Home screen.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '2) Enter a name for the Vault.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '3) Select a Network from the network dropdown.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '4) Change the dropdown from standard to vault.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '5) Optional - select a background image.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '6) Optional - configure privacy settings.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '7) Tap the Create button.' }));
    topic.tutorials.push(tutorial);

    tutorial = new Tutorial({ title: 'Create a new DM' });
    tutorial.lineItems.push(new TutorialLineItem({ item: 'There are two ways to invite someone to a new DM.', }));
    tutorial.lineItems.push(new TutorialLineItem({ item: 'From the Home screen.', subTitle: true }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '1) Swipe left on the Home screen to enter DMs.', }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '2) Tap the + icon on the bottom right.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '3) Select the name from the list if you are already connected. If not, enter the name.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '4) Tap the Slide button.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: 'From the Friends screen.', subTitle: true }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '1) Tap on the Friends icon from the Home screen.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '2) Tap on your friend\'s name or avatar.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '3) Tap on the DM button.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: 'You will enter the DM if it exists or an invitation will be sent if not.' }));
    topic.tutorials.push(tutorial);

    await topic.save();


    topic = new Topic({ topic: 'Invitations', order: order++ });

    tutorial = new Tutorial({ title: 'Invite a new person to your network' });
    tutorial.lineItems.push(new TutorialLineItem({ item: 'IronCircles makes it easy to invite new friends to the platform.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: 'You can generate a Magic Link and share it to them directly from the app.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: 'The Magic Link will allow them to join your network and be placed in a Direct Message (DM) with you.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: 'To send from the Friends screen:', subTitle: true }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '1) Tap on the Friends icon from the Home screen.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '2) Tap on the Invite Friends To A Network button.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '3) Select a network from the dropdown.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '4) Tap Share Magic Link.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '5) You can share to an existing Circle or outside IronCircles, which includes a copy option.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: 'To send from the Network Manager screen:', subTitle: true }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '1) Tap on the Network filter icon near top right of the Home screen.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '2) Tap open Network Manager.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '3) Select a Network from the list.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '4) Tap Share Magic Link.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '5) You can share to an existing Circle or outside IronCircles, which includes a copy option.' }));
    topic.tutorials.push(tutorial);

    tutorial = new Tutorial({ title: 'Create a new Circle and send invitations' });
    tutorial.lineItems.push(new TutorialLineItem({ item: '1) Tap the + icon on the Circle tab on the Home screen.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '2) Enter a name for the Circle.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '3) Select a Network from the network dropdown.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '4) Optional - select a background image.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '5) Optional - configure privacy settings.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '6) Tap the Next button.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '7) Optional - Select users from the list to include in the Circle.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '8) Optional - Add a user to the list by typing their username and tapping the Add button.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '9) Tap the Create New Circle button.' }));

    topic.tutorials.push(tutorial);

    tutorial = new Tutorial({ title: 'Send an invite to an existing Circle' });
    tutorial.lineItems.push(new TutorialLineItem({ item: 'From the Friends screen:', subTitle: true }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '1) Tap on the Friends icon from the Home screen.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '2) Tap on your friend\'s name or avatar.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '3) Tap on the Add to Circle button.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '4) Select the Circle or Circles to add your friend to.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '5) Tap the Send Invitations button.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: 'From inside of a Circle:', subTitle: true }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '1) Open the Circle.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '2) Select Users from the upper right gear icon.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '3) Type the username (or alias) for the person (they must be in a shared network).' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '4) Tap the Send Invite button.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: 'If you are the only user of the Circle, the invitation will be sent immediately. If there are other users, a vote will be created instead.' }));
    topic.tutorials.push(tutorial);

    tutorial = new Tutorial({ title: 'Invite someone to a Direct Message (DM)' });
    tutorial.lineItems.push(new TutorialLineItem({ item: 'There are two ways to invite someone to a new DM.', }));
    tutorial.lineItems.push(new TutorialLineItem({ item: 'From the Home screen.', subTitle: true }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '1) Swipe left on the Home screen to enter DMs.', }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '2) Tap the + icon on the bottom right.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '3) Select the name from the list if you are already connected. If not, enter the name.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '5) Tap the Slide button.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: 'From the Friends screen.', subTitle: true }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '1) Tap on the Friends icon from the Home screen.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '2) Tap on your friend\'s name or avatar.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '3) Tap on the DM button.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: 'You will enter the DM if it exists or an invitation will be sent if not.' }));
    topic.tutorials.push(tutorial);

    await topic.save();


    topic = new Topic({ topic: 'Hide and Guard Chats (18+)', order: order++, requireHidden: true });

    tutorial = new Tutorial({ title: 'Hide a chat or vault' });
    tutorial.lineItems.push(new TutorialLineItem({ item: '1) Enter the chat or vault.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '2) Tap on gear icon on the upper right.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '3) Tap on Settings.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '4) Select the Hide toggle.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '5) Enter a passphrase that can be used to reopen the chat/vault later.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '6) Reenter the passphrase.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '7) Tap the hide button.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: 'Chat/vault will be hidden and you will return to the home screen' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: 'Push notifications for hidden chats will stop until you reopen them.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: 'Hint: You can reuse a passphrase for multiple chats/vaults to open them all at once' }));
    topic.tutorials.push(tutorial);

    tutorial = new Tutorial({ title: 'Open hidden chats/vaults' });
    tutorial.lineItems.push(new TutorialLineItem({ item: '1) Go to the Home screen.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '2) Tap on the wrench icon to open the Manage screen.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '3) Tap the golden key in the upper right corner.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '4) Enter the passphrase to open the hidden chat(s).' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: 'All chats that match the passphrase will be opened and ' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: 'Rehide an open hidden chat', subTitle: true }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '1) Tap the shield icon on top of any screen.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: 'All open hidden chats will close, the screen will refresh, and you will be taken to the home screen.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: 'Push notifications for hidden chats will stop until you reopen them.' }));
    topic.tutorials.push(tutorial);

    tutorial = new Tutorial({ title: 'Rehide an open hidden chats/vaults' });
    tutorial.lineItems.push(new TutorialLineItem({ item: '1) Tap the shield icon on the top of any screen.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: 'All open hidden chats will close, the screen will refresh, and you will be taken to the home screen.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: 'Push notifications for hidden chats will stop until you reopen them.' }));
    topic.tutorials.push(tutorial);

    tutorial = new Tutorial({ title: 'Guard a chat with a swipe pattern' });
    tutorial.lineItems.push(new TutorialLineItem({ item: 'Guard from within the chat/vault', subTitle: true }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '1) Enter the chat/vault.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '2) Tap on gear icon on the upper right.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '3) Tap on Settings.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '4) Select the Guard toggle.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '4) Enter a swipe pattern.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '5) Confirm the swipe pattern.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: 'Chat is now guarded with a pattern.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: 'Guard from within the Manager', subTitle: true }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '1) Go to the Home screen.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '2) Tap on the wrench icon to open the Manage screen.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '3) Tap the Guard text button.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '4) Enter a swipe pattern.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '5) Confirm the swipe pattern.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: 'Chat is now guarded with a pattern.' }));
    topic.tutorials.push(tutorial);

    tutorial = new Tutorial({ title: 'Remove swipe pattern from chats/vaults' });
    tutorial.lineItems.push(new TutorialLineItem({ item: 'Remove from within the chat/vault', subTitle: true }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '1) Enter the chat/vault.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '2) Tap on gear icon on the upper right.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '3) Tap on Settings.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '4) Tap the Guard toggle.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: 'Swipe pattern has been removed.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: 'Remove from the Manager', subTitle: true }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '1) Go to the Home screen.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '2) Tap on the wrench icon to open the Manage screen.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '3) Tap the unguard text button.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: 'Swipe pattern has been removed.' }));
    topic.tutorials.push(tutorial);

    await topic.save();

    topic = new Topic({ topic: 'User Administration', order: order++ });

    tutorial = new Tutorial({ title: 'Report a post'});
    tutorial.lineItems.push(new TutorialLineItem({ item: 'A post that violates the IronCircles Terms of Service or the Network\s rules can be reported by any user.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: 'Reporting a post immedietely removes the post from the platform. The users of the Circle can decide if further action is necessary, including removing the user from the Circle or Network.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: 'Being reported repeatedly can result in an account ban.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: 'Reporting a post is powerful tool that can be misused by Circle users. Network owners should take appropriate action if the feature is being misused.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: 'To report post:', subTitle: true }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '1) Long press the post.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '2) Tap on the report post icon (stop sign with !)' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '3) Select the violation type.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '4) Optionally enter comments.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '5) Tap the report button.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: 'The post will be replaced by a system message letting the Circle know a violation was reported.' }));
    topic.tutorials.push(tutorial);

    tutorial = new Tutorial({ title: 'Hide another user\'s post'});
    tutorial.lineItems.push(new TutorialLineItem({ item: 'Hiding a post will remove the post from your device and it will no longer be visible in the Circle/DM or the library.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: 'Hiding a post only affects the user who hides it. Noone else will know the post has been removed.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: 'To report post:', subTitle: true }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '1) Long press the post.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '2) Tap on the eye with a slay icon.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '3) Tap the yes button if you wish to hide the post.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: 'The post is now hidden. This cannot be undone.' }));
    topic.tutorials.push(tutorial);


    tutorial = new Tutorial({ title: 'Lockout a user from your network' });
    tutorial.lineItems.push(new TutorialLineItem({ item: 'An owner of a network can lockout a user' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: 'This will will remove the user\s access. They will be unable to view message history or post new items until their account is unlocked.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: 'To lock out a user', subTitle: true }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '1) Tap on the left upper menu icon from the Home screen.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '2) Tap on Network Manager.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '3) Select the network from the list.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '4) Tap lockout next to the user\'s name.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: 'You can unlock their account at anytime. Any activity that occured while their account was locked will not be visible to them.' }));
    topic.tutorials.push(tutorial);

    tutorial = new Tutorial({ title: 'Remove a user from a Circle' });
    tutorial.lineItems.push(new TutorialLineItem({ item: '1) Enter a Circle.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '2) Tap on the gear icon in the upper right.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '3) Select Users.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '4) Tap the Users tab.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '5) Tap vote out next to the users name.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: 'A vote will be kicked off to remove the user.' }));
    topic.tutorials.push(tutorial);

    tutorial = new Tutorial({ title: 'Block a user' });
    tutorial.lineItems.push(new TutorialLineItem({ item: 'To block all posts from a user', subTitle: true }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '1) Tap on the user\'s avatar.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '2) Tap on Block User. You will no longer see any posts from this person in any Circle, Feed, or DM. They will not be notified that they are blocked and can still see your messages in group chats you are both in.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: 'To unblock a user', subTitle: true }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '1) Tap on the user\'s avatar.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '2) Tap on Unblock User. You will not see any messages the user posted while you had them blocked.' }));
    topic.tutorials.push(tutorial);

    // tutorial = new Tutorial({ title: 'Coming soon - Network owner(s) can remove a user from a Circle without a vote.'});
    // topic.tutorials.push(tutorial);

    await topic.save();



    topic = new Topic({ topic: 'Manage Your Profile', order: order++ });

    tutorial = new Tutorial({ title: 'Change your username' });
    tutorial.lineItems.push(new TutorialLineItem({ item: '1) Enter the upper left menu from the Home screen.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '2) Tap on your avatar (upper left).' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '3) Enter a new username', }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '4) Tap the Set button.' }));
    topic.tutorials.push(tutorial);

    tutorial = new Tutorial({ title: 'Change your avatar' });
    tutorial.lineItems.push(new TutorialLineItem({ item: '1) Enter the upper left menu from the Home screen.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '2) Tap on your avatar (upper left).' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '3) Select a a new avatar by tapping on the current one under Profile.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '4) Optionally crop and/or rotate with the crop icon.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '5) Tap the Set button.' }));

    topic.tutorials.push(tutorial);

    tutorial = new Tutorial({ title: 'Change color theme' });
    tutorial.lineItems.push(new TutorialLineItem({ item: '1) Enter the upper left menu from the Home screen.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '2) Tap on your avatar (upper left).' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '3) Tap dark or light to set the theme to Dark or Light mode.' }));

    topic.tutorials.push(tutorial);

    tutorial = new Tutorial({ title: 'Reset message text colors' });
    tutorial.lineItems.push(new TutorialLineItem({ item: '1) Enter the upper left menu from the Home screen.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '2) Tap on your avatar (upper left).' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '3) Tap on Reset Message Text Colors under Color Theme (you may have to scroll).' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '4) Tap dark or light to set the theme to Dark or Light mode.' }));

    topic.tutorials.push(tutorial);

    await topic.save();


    topic = new Topic({ topic: 'Password Management', order: order++ });

    tutorial = new Tutorial({ title: 'Reset password on your primary Network' });
    tutorial.lineItems.push(new TutorialLineItem({ item: '1) Enter the upper left menu from the Home screen.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '2) Tap on bottom right Gear icon to enter Settings.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '3) Tap on the Security tab.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '4) Tap the Change Password/Pin button.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '5) Enter a new password (minimum of 8).' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '6) Enter a new pin (minimum of 4).' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '7) Tap the Set New Password/Pin button.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: 'Note: your primary network password also controls access to your linked networks' }));
    topic.tutorials.push(tutorial);


    tutorial = new Tutorial({ title: 'Reset a password on a secondary Network' });
    tutorial.lineItems.push(new TutorialLineItem({ item: '1) Enter the upper left menu from the Home screen.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '2) Tap on Network Manager.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '3) Open the Network.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '2) Tap on the Security tab.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '3) Tap the Change Password/Pin button.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '4) Enter a new password (minimum of 8).' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '5) Enter a new pin (minimum of 4).' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '6) Tap the Set New Password/Pin button.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: 'Hint: if you do not see a Security tab, your secondary network account is probably linked to your primary and does not have it\'s own password.' }));
    topic.tutorials.push(tutorial);

    tutorial = new Tutorial({ title: 'Account Recovery' });
    tutorial.lineItems.push(new TutorialLineItem({ item: 'To protect your privacy, the IronCircles company cannot reset your password.' }));
    //tutorial.lineItems.push(new TutorialLineItem({ item: 'Please do one (or both) of the following:' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: 'Setup Passsord Helpers', subTitle: true }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '1) Enter the upper left menu from the Home screen.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '2) Tap on bottom right Gear icon to enter Settings.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '3) Select 1-4 friends from the dropdown.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: '4) Tap the Update Helpers button.' }));
    tutorial.lineItems.push(new TutorialLineItem({ item: 'In the future when you initiate a Forgot Password reset, each of these users will receive a fragment of a Recovery Key that you can use to reset your password/pin.' }));
    //tutorial.lineItems.push(new TutorialLineItem({ item: 'Store a Recovery Key somewhere safe, such as a Password Manager', subTitle: true }));
    //tutorial.lineItems.push(new TutorialLineItem({ item: '1) Enter the upper left menu from the Home screen.' }));
    //tutorial.lineItems.push(new TutorialLineItem({ item: '2) Tap on bottom right Gear icon to enter Settings.' }));
    //tutorial.lineItems.push(new TutorialLineItem({ item: '3) Tap on the Security tab.' }));
    //tutorial.lineItems.push(new TutorialLineItem({ item: '4) Tap on Create a Recovery Key.' }));
    //tutorial.lineItems.push(new TutorialLineItem({ item: '5) Copy the key somewhere safe, like a Password Manager.' }));
    topic.tutorials.push(tutorial);
    /*
        tutorial = new Tutorial({ title: 'Request a password reset from a friend' });
        tutorial.lineItems.push(new TutorialLineItem({ item: '1) Enter the upper left menu from the Home screen.' }));
        tutorial.lineItems.push(new TutorialLineItem({ item: '2) Tap on bottom right Gear icon to enter Settings.' }));
        tutorial.lineItems.push(new TutorialLineItem({ item: '3) Tap on the Security tab.' }));
        topic.tutorials.push(tutorial);
        */

    await topic.save();


    /*
        addTutorialDetail('Walkthroughs', )
        TutorialCategory.tutorials.push(new Tutorial({ title: 'Walkthrough', description: 'One minute feature overview', order: 2, video: 'https://ic-tutorials.s3.us-west-2.amazonaws.com/ironcircles_intro.mp4' }));
        TutorialCategory.tutorials.push(new Tutorial({ title: 'Promo video', description: 'Check our our first promo video!', order: 3, video: 'https://ic-tutorials.s3.us-west-2.amazonaws.com/IronCircles_promo.mp4' }));
        TutorialCategory.tutorials.push(new Tutorial({ title: 'Tutorial on Secure Messaging', description: 'Explanation of how IronCircles protects your data', order: 4, video: 'https://ic-tutorials.s3.us-west-2.amazonaws.com/forward_secrecy.mp4' }));
        await tutorialCategory.save();
    
        topic = new TutorialByTopic({ topic: 'User Profile and Password', order: 1 });
        topic.tutorials.push(new Tutorial({ title: 'Important! Setup password reset assistance', description: 'If you don\'t set this, your password cannot be reset', order: 1 }));
        topic.tutorials.push(new Tutorial({ title: 'Change username', description: 'Change username on a network', order: 1 }));
        topic.tutorials.push(new Tutorial({ title: 'Change password', description: 'Change password on a network', order: 2 }));
        topic.tutorials.push(new Tutorial({ title: 'Avatar', description: 'Set or change avatar', order: 3 }));
        topic.tutorials.push(new Tutorial({ title: 'Change theme to light mode', description: 'Flip between dark and light mode', order: 4 }));
        await topic.save();
    
        topic = new TutorialByTopic({ topic: 'Circles and Direct Messages', order: 2 });
        topic.tutorials.push(new Tutorial({ title: 'Create a circle', description: 'Walk through creating a new circle', order: 1, video: 'https://ic-tutorials.s3.us-west-2.amazonaws.com/t+_create_circle.mp4' }));
        topic.tutorials.push(new Tutorial({ title: 'Send invitations', description: 'Invite others to a circle', order: 2 }));
        topic.tutorials.push(new Tutorial({ title: 'Create a direct message', description: 'Invite a user to a direct message', order: 3 }));
        topic.tutorials.push(new Tutorial({ title: 'Leave a circle or dm', description: 'If you are the only person in the Circe it is deleted', order: 5 }));
        topic.tutorials.push(new Tutorial({ title: 'Delete a circle', description: 'Delete a circle. Kicks off a vote if other users are in the circle', order: 5 }));
        await topic.save();
    
        topic = new TutorialByTopic({ topic: 'Hidden and guarded circles', order: 3, requireHidden: true });
        topic.tutorials.push(new Tutorial({ title: 'Hide a circle', description: 'Hide a circle from the main screen', order: 1 }));
        topic.tutorials.push(new Tutorial({ title: 'Guard a circle', description: 'Require a swipe pattern before a circle can be entered', order: 2 }));
        await topic.save();
    
        topic = new TutorialByTopic({ topic: 'Add and remove people', order: 4 });
        topic.tutorials.push(new Tutorial({ title: 'Invite people', description: 'Add users to a circle', order: 1 }));
        topic.tutorials.push(new Tutorial({ title: 'Cancel an invitation', description: 'Cancel a pending invitation', order: 2 }));
        topic.tutorials.push(new Tutorial({ title: 'Vote someone out', description: 'Kickoff a vote to remove a circle user', order: 3 }));
        await topic.save();
    
        topic = new TutorialByTopic({ topic: 'Create, edit, and delete messages', order: 5 });
        topic.tutorials.push(new Tutorial({ title: 'Create a message', description: 'Create new messages', order: 1 }));
        topic.tutorials.push(new Tutorial({ title: 'Edit a message', description: 'Edit the text or swap out an image', order: 2 }));
        topic.tutorials.push(new Tutorial({ title: 'Delete a message', description: 'Delete a message you posted from all devices', order: 3 }));
        topic.tutorials.push(new Tutorial({ title: 'Hide another user\'s message', description: 'Permanently remove another person\'s message from your devices', order: 4 }));
        topic.tutorials.push(new Tutorial({ title: 'Report a violation', description: 'Report a post in breach of the IronCircles terms of service', order: 5 }));
        await topic.save();
    
        topic = new TutorialByTopic({ topic: 'Disappearing messages', order: 6 });
        topic.tutorials.push(new Tutorial({ title: 'Post a disappearing message', description: 'Post a message that disappears based on a timer', order: 1 }));
        topic.tutorials.push(new Tutorial({ title: 'Set for entire circle', description: 'Turn disappearing messages permanently on for a circle', order: 2 }));
        topic.tutorials.push(new Tutorial({ title: 'Post a one time view message', description: 'Post a message that each user of a Circle can see only once', order: 3 }));
        await topic.save();
    
        topic = new TutorialByTopic({ topic: 'Reacting, quoting, and pinning messages', order: 7 });
        topic.tutorials.push(new Tutorial({ title: 'React to a message', description: 'React to a message', order: 1 }));
        topic.tutorials.push(new Tutorial({ title: 'Remove a reaction', description: 'Remove one or more reactions', order: 2 }));
        topic.tutorials.push(new Tutorial({ title: 'See who has reacted', description: 'See who has reacted to a message', order: 3 }));
        topic.tutorials.push(new Tutorial({ title: 'Quote a message in a reply', description: 'Quote another user\'s message when replying', order: 4 }));
        topic.tutorials.push(new Tutorial({ title: 'Pin a message', description: 'Pin for yourself or the entire circle', order: 5 }));
        topic.tutorials.push(new Tutorial({ title: 'View pinned messages', description: 'See all messages pinned in a circle', order: 6 }));
        await topic.save();
    
        topic = new TutorialByTopic({ topic: 'Sharing', order: 9 });
        topic.tutorials.push(new Tutorial({ title: 'Share from IronCircles', description: 'Walk through creating a new circle', order: 1 }));
        topic.tutorials.push(new Tutorial({ title: 'Share to IronCircles', description: 'Invite others to a circle', order: 2 }));
        topic.tutorials.push(new Tutorial({ title: 'Enabling sharing', description: 'Change sharing options in a circle or dm', order: 3 }));
        topic.tutorials.push(new Tutorial({ title: 'Sharing multiple items at a time', description: 'Share multiple images/videos at the same time', order: 4 }));
        await topic.save();
    
        topic = new TutorialByTopic({ topic: 'Videos', order: 10 });
        topic.tutorials.push(new Tutorial({ title: 'Post and select thumbnail', description: 'Select a specific frame for the video thumbnail', order: 1 }));
        topic.tutorials.push(new Tutorial({ title: 'E2E Encrypted vs Streaming', description: 'Short tutorial on the differences', order: 2 }));
        await topic.save();
    
        topic = new TutorialByTopic({ topic: 'Lists', order: 11 });
        topic.tutorials.push(new Tutorial({ title: 'Create a list', description: 'Create a list for a circle or yourself', order: 1 }));
        topic.tutorials.push(new Tutorial({ title: 'Edit a list', description: 'Add or check items on list', order: 2 }));
        topic.tutorials.push(new Tutorial({ title: 'Reorder items on a list', description: 'Drag items on a list to reorder', order: 3 }));
        await topic.save();
    
        topic = new TutorialByTopic({ topic: 'The Library', order: 12 });
        topic.tutorials.push(new Tutorial({ title: 'View, sort, filter images', description: 'Create a list for a circle or yourself', order: 1 }));
        topic.tutorials.push(new Tutorial({ title: 'Share from the library', description: 'Share multiple images/videos at the same time', order: 2 }));
        topic.tutorials.push(new Tutorial({ title: 'Central calendar', description: 'Add or check items on list', order: 3 }));
        await topic.save();
        */

    //return res.status(200).json({ msg: "updated" });

    var topics = await Topic.find({ $or: [{ requireHidden: false }, { requireHidden: req.user.allowClosed }] }).sort({ 'order': 1 });

    return res.status(200).send({
      topics: topics,
    });

  } catch (err) {
    console.error(err);
    return res.status(500).json({ msg: err });
  }
});


module.exports = router;
