const express = require('express');
const router = express.Router();
const bodyParser = require('body-parser');
const passport = require('passport');
const User = require('../models/user');
const logUtil = require('../util/logutil');
const IronCurrency = require('../models/ironcurrency');
const NSFW = require('../models/nsfw');
const IronCoinTransaction = require('../models/ironcointransaction');
const IronCoinWallet = require('../models/ironcoinwallet');
const Prompt = require('../models/prompt');
const constants = require('../util/constants');
const DeviceLogic = require('../logic/devicelogic');
const request = require('google-oauth-jwt').requestWithJWT();
const Purchase = require('../models/purchase');
const kyberLogic = require('../logic/kyberlogic');

router.use(bodyParser.urlencoded({ extended: true }));
router.use(bodyParser.json());

///return currency values POSTKYBER
router.get('/getcurrency', async (req, res) => {

  try {

    await validateAPIKey(req.headers.apikey);

    let matrix = new IronCurrency();

    return res.status(200).send({
      matrix: matrix,
    });


    // let currencyList = await currency.getValuesList();

    // return res.status(200).send({
    //   currency: currencyList,
    // });

  } catch (err) {
    var msg = await logUtil.logError(err, true);
    return res.status(500).json({ msg: msg });
  }

});

router.post('/getcurrencyp/', async (req, res) => {

  try {

    let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);

    await validateAPIKey(req.headers.apikey);

    let matrix = new IronCurrency();

    // return res.status(200).send({
    //   matrix: matrix,
    // });

    let payload = { matrix: matrix, };
    payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);
    return res.status(200).json(payload);


  } catch (err) {
    var msg = await logUtil.logError(err, true);
    return res.status(500).json({ msg: msg });
  }

});

async function getPrimaryUser(user) {
  try {

    if (user.linkedUser != null) {
      user = await User.findById(user.linkedUser);
    }

    return user;

  } catch (err) {
    var msg = await logUtil.logError(err, true);
    return res.status(500).json({ msg: msg });
  }
}

///make coin payment
router.post('/coinpayment', passport.authenticate('jwt', { session: false }), async (req, res) => {

  try {
    let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);

    var user = await getPrimaryUser(req.user); //await User.findById(req.user.id);

    //restrict minors and Google and Apple prompts 
    if (user.minor == true || user.username == 'apple27895' || user.username == 'google32395') {

      let nsfw = await NSFW.findOne({});

      if (nsfw != null && nsfw != undefined) {

        for (let i = 0; i < nsfw.filter.length; i++) {
          if (body.prompt.prompt.includes(nsfw.filter[i]) || (body.prompt.maskPrompt == undefined && body.maskPrompt.includes(nsfw.filter[i]))) {
            return res.status(500).json({ msg: "Prompt contains inappropriate language" });
          }
        }
      }
    }


    let wallet = await IronCoinWallet.findOne({ user: user.id });

    if (wallet.balance >= body.cost) {

      let payment = new IronCoinTransaction({
        amount: body.cost,
        paymentType: body.paymentType,
        user: user,
        wallet: wallet,
        created: Date.now(),
        lastUpdated: Date.now(),
      });

      if (body.prompt != null && body.prompt != undefined) {

        let prompt = await Prompt.new(body.prompt);
        prompt.userID = user._id;
        payment.prompt = prompt;
      }
      console.debug("prompt: " + payment.prompt);

      await payment.save();

      //await IronCoinWallet.updateOne({ '_id': wallet._id }, { $push: { 'transactions': payment } });
      wallet.balance -= body.cost;
      await wallet.save();


      // return res.status(200).send({
      //   wallet: wallet,
      //   payment: payment,
      //   prompt: payment.prompt,
      // });

      let payload = {
        wallet: wallet,
        payment: payment,
        prompt: payment.prompt,
      };
      payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);
      return res.status(200).json(payload);


    } else {
      return res.status(500).json({ msg: "Not enough IronCoin" });
    }

  } catch (err) {
    var msg = await logUtil.logError(err, true);
    return res.status(500).json({ msg: msg });
  }

});

///refund coin payment
router.post('/refundcoinpayment', passport.authenticate('jwt', { session: false }), async (req, res) => {

  try {

    let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);

    var user = await getPrimaryUser(req.user);

    let wallet = await IronCoinWallet.findOne({ user: user.id });

    let refund = new IronCoinTransaction({
      amount: body.cost,
      paymentType: body.paymentType,
      user: user,
      wallet: wallet,
      created: Date.now(),
      lastUpdated: Date.now(),
    });

    await refund.save();

    //await IronCoinWallet.updateOne({ '_id': wallet._id }, { $push: { 'transactions': refund } });
    wallet.balance += body.cost;
    await wallet.save();

    // return res.status(200).send({
    //   wallet: wallet,
    //   payment: refund,
    // })

    let payload = {
      wallet: wallet,
      payment: refund,
    };
    payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);
    return res.status(200).json(payload);


  } catch (err) {
    var msg = await logUtil.logError(err, true);
    return res.status(500).json({ msg: msg });
  }

});

///get coin ledger POSTKYBER
router.get('/fetchledger', passport.authenticate('jwt', { session: false }), async (req, res) => {

  try {

    var user = await getPrimaryUser(req.user);

    // TODO this needs to return 60 at a time and support paging
    //let wallet = await IronCoinWallet.findOne({ user: req.user.id }).populate({ path: 'transactions', options: { limit: 1000, sort: { created: -1 } } });
    let transactions = await IronCoinTransaction.find({ user: user._id }).sort({ created: -1 }).limit(1000);

    return res.status(200).send({
      transactions: transactions,
    });

  } catch (err) {
    var msg = await logUtil.logError(err, true);
    return res.status(500).json({ msg: msg });
  }

});

router.post('/fetchledgerp/', passport.authenticate('jwt', { session: false }), async (req, res) => {

  try {

    var user = await getPrimaryUser(req.user);

    // TODO this needs to return 60 at a time and support paging
    //let wallet = await IronCoinWallet.findOne({ user: req.user.id }).populate({ path: 'transactions', options: { limit: 1000, sort: { created: -1 } } });
    let transactions = await IronCoinTransaction.find({ user: user._id }).sort({ created: -1 }).limit(1000);

    // return res.status(200).send({
    //   transactions: transactions,
    // });

    let payload = { transactions: transactions };
    payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);
    return res.status(200).json(payload);


  } catch (err) {
    var msg = await logUtil.logError(err, true);
    return res.status(500).json({ msg: msg });
  }

});

///get coins
router.get('/getcoins', passport.authenticate('jwt', { session: false }), async (req, res) => {

  try {

    var user = await getPrimaryUser(req.user);

    let wallet = await IronCoinWallet.findOne({ user: user._id });

    return res.status(200).send({
      coins: wallet.balance,
    });

  } catch (err) {
    var msg = await logUtil.logError(err, true);
    return res.status(500).json({ msg: msg });
  }

});

router.post('/getcoinsp', passport.authenticate('jwt', { session: false }), async (req, res) => {

  try {

    var user = await getPrimaryUser(req.user);

    let wallet = await IronCoinWallet.findOne({ user: user._id });

    // return res.status(200).send({
    //   coins: wallet.balance,
    // });

    let payload = { coins: wallet.balance, };
    payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);
    return res.status(200).json(payload);


  } catch (err) {
    var msg = await logUtil.logError(err, true);
    return res.status(500).json({ msg: msg });
  }

});


///give coins to another user
router.post('/givecoins', passport.authenticate('jwt', { session: false }), async (req, res) => {

  try {

    let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);

    if (body.coins < 1) {
      return res.status(500).json({ msg: "Transfer must be 1 coin or more" });
    }

    var user = await getPrimaryUser(req.user);
    let senderWallet = await IronCoinWallet.findOne({ user: user._id });


    var recipient = await User.findById(body.recipient).populate("linkedUser");

    if (recipient.linkedUser != null) {
      recipient = recipient.linkedUser;
    }

    let recipientWallet = await IronCoinWallet.findOne({ user: recipient });


    if (senderWallet.balance >= body.coins) {

      let payment = new IronCoinTransaction({
        amount: body.coins,
        paymentType: constants.COIN_PAYMENT_TYPE.GAVE_COINS,
        user: user,
        reciever: recipient,
        sender: user,
        wallet: senderWallet,
        created: Date.now(),
        lastUpdated: Date.now(),
      });

      await payment.save();

      //senderWallet.transactions.push(payment);
      senderWallet.balance -= body.coins;
      await senderWallet.save();

      let gift = new IronCoinTransaction({
        amount: body.coins,
        paymentType: constants.COIN_PAYMENT_TYPE.GIFTED_COINS,
        user: recipient,
        reciever: recipient,
        sender: user,
        wallet: recipientWallet,
        created: Date.now(),
        lastUpdated: Date.now(),
      });

      await gift.save();

      //recipientWallet.transactions.push(gift);
      recipientWallet.balance += body.coins;
      await recipientWallet.save();

      DeviceLogic.sendNotification(recipient, "Gifted IronCoin by " + user.username, constants.NOTIFICATION_TYPE.GIFTED_IRONCOIN);

      // return res.status(200).send({
      //   payment: payment,
      // });

      let payload = { payment: payment, };
      payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);
      return res.status(200).json(payload);


    } else {
      return res.status(500).json({ msg: "Not enough IronCoin" });
    }

  } catch (err) {
    var msg = await logUtil.logError(err, true);
    return res.status(500).json({ msg: msg });
  }

});

function isValidJson(string) {
  try {
    JSON.parse(string);
  } catch (e) {
    return false;
  }
  return true;
}

async function purchaseCoinsGooglePlay(type, token) {
  try {

    let urlBase = 'https://androidpublisher.googleapis.com/androidpublisher/v3/applications/com.ironcircles.ironcirclesapp/purchases/products/';
    let urlPurchase = type;
    let urlToken = token;
    let fullUrl = urlBase + urlPurchase + '/tokens/' + urlToken;

    let options = {
      uri: fullUrl,
      method: 'get',
      body: "",
      json: false,
      jwt: {
        email: process.env.gcp_email,
        key: process.env.gcp_key.replace(/\\n/g, '\n'),
        scopes: ['https://www.googleapis.com/auth/androidpublisher']
      }
    };

    return new Promise(function (resolve, reject) {
      request(options, function (err, res, body) {
        let resultInfo = {};
        if (err) {
          // Google Auth errors returned here
          let errBody = err.body;
          let errorMessage;
          if (errBody) {
            errorMessage = err.body.error_description;
          } else {
            errorMessage = err;
          }
          resultInfo.isSuccessful = false;
          resultInfo.errorMessage = errorMessage;
          reject(resultInfo);
        } else {
          let obj = {
            "error": {
              "code": res.statusCode,
              "message": "Invalid response, please check configuration or the statusCode above"
            }
          };
          if (res.statusCode === 204) {
            obj = {
              "code": res.statusCode,
              "message": "Acknowledged Cancelation Successfully"
            };
          }
          if (isValidJson(body)) {
            obj = JSON.parse(body);
          }

          if (res.statusCode === 200 || res.statusCode === 204) {
            resultInfo.isSuccessful = true;
            resultInfo.errorMessage = null;
            resultInfo.payload = obj;
            resolve(resultInfo);
          } else {
            let errorMessage = obj.error.message;
            let errorCode = obj.error.code;
            resultInfo.isSuccessful = false;
            resultInfo.errorCode = errorCode;
            resultInfo.errorMessage = errorMessage;
            reject(resultInfo);
          }
        }
      });
    })
  } catch (err) {
    var msg = await logUtil.logError(err, true);
    return res.status(500).json({ err: msg });
  }
}

///Purchase coins
router.post('/purchasecoins/', passport.authenticate('jwt', { session: false }), async (req, res) => {
  try {

    let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);

    var user = await getPrimaryUser(req.user);

    let bodyPurchase = body.purchase;

    if (bodyPurchase.type == undefined ||
      bodyPurchase.purchaseID == undefined || bodyPurchase.transactionDate == undefined ||
      bodyPurchase.verificationLocal == undefined || bodyPurchase.verificationServer == undefined
      || bodyPurchase.verificationSource == undefined) {
      throw new Error("Unauthorized");
    }

    let success = false;

    ///checking for undefined can go away after everyone is on 87
    if (body.platform == undefined || body.platform == 'android') {

      let googleResponse = await purchaseCoinsGooglePlay(
        bodyPurchase.type,
        bodyPurchase.verificationServer,
      );

      success = googleResponse.isSuccessful;

    } else if (body.platform == constants.DEVICE_PLATFORM.iOS) {
      throw new Error("Unauthorized");
    }

    if (success == true) {

      //console.log('Success continues');

      let coins = bodyPurchase.quantity * 20000;

      let wallet = await IronCoinWallet.findOne({ user: user._id });
      let transaction = new IronCoinTransaction({
        amount: coins,
        user: user,
        wallet: wallet,
        paymentType: constants.COIN_PAYMENT_TYPE.PURCHASED_COINS,
        created: Date.now(),
        lastUpdated: Date.now(),
      });

      await transaction.save();
      wallet.balance += coins;
      await wallet.save();

      let purchase = new Purchase({
        purchaseDetailsJson: bodyPurchase.purchaseDetailsJson,
        user: req.user.id,
        type: bodyPurchase.type,
        purchaseID: bodyPurchase.purchaseID,
        seed: bodyPurchase.seed,
        transactionDate: bodyPurchase.transactionDate,
        verificationLocal: bodyPurchase.verificationLocal,
        verificationServer: bodyPurchase.verificationServer,
        verificationSource: bodyPurchase.verificationSource,
        status: constants.PURCHASE_OBJECT_STATUS.PURCHASED,
        quantity: bodyPurchase.quantity,
      });

      await purchase.save();

      // return res.status(200).send({
      //   purchase: purchase,
      // });

      let payload = {  purchase: purchase, };
      payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);
      return res.status(200).json(payload);
  

    } else {
      throw new Error("Unauthorized");
    }

  } catch (err) {
    var msg = await logUtil.logError(err, true);
    return res.status(500).json({ msg: msg });
  }
});

function validateAPIKey(apikey) {

  try {
    return new Promise(function (resolve, reject) {
      if (!apikey) {
        return reject('Unauthorized');
      } else {

        if (process.env.NODE_ENV !== 'production')
          require('dotenv').load();

        if (apikey != process.env.apikey)
          return reject('Unauthorized');
        else
          return resolve('valid');
      }
    });

  } catch (err) {
    console.error(err);
    return reject(err);
  }

}

///delete prompt
router.delete('/prompt', passport.authenticate('jwt', { session: false }), async (req, res) => {

  try {

    let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);

    let transaction = await IronCoinTransaction.findOne({ user: req.user, _id: body.promptID });

    if (transaction != null && transaction != undefined) {

      transaction.prompt = null;
      await transaction.save();
    }

    // return res.status(200).send({
    //   msg: "success",
    // });

    let payload = {   msg: "success",};
    payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);
    return res.status(200).json(payload);


  } catch (err) {
    var msg = await logUtil.logError(err, true);
    return res.status(500).json({ msg: msg });
  }

});


router.put('/prompt', passport.authenticate('jwt', { session: false }), async (req, res) => {

  try {

    let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);

    var user = await getPrimaryUser(req.user); //await User.findById(req.user.id);
    let ironCoinTransaction = await IronCoinTransaction.findOne({ user: user, 'prompt._id': body.promptID });

    if (ironCoinTransaction != null && ironCoinTransaction != undefined) {
      ironCoinTransaction.prompt.jobID = body.jobID;
      ironCoinTransaction.prompt.seed = body.seed;
    }

    await ironCoinTransaction.save();

    // return res.status(200).send({
    //   msg: "success"
    // });

    let payload = { msg: "success" };
    payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);
    return res.status(200).json(payload);



  } catch (err) {
    var msg = await logUtil.logError(err, true);
    return res.status(500).json({ msg: msg });
  }

});


module.exports = router;