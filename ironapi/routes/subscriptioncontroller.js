const express = require('express');
const router = express.Router();
const bodyParser = require('body-parser');
const passport = require('passport');
const Log = require('../models/log');
const logUtil = require('../util/logutil');
const User = require('../models/user');
const Subscription = require('../models/subscription');
const constants = require('../util/constants');
//const GoogleReceiptVerify = require('google-play-billing-validator');
const AppleReceiptVerify = require('node-apple-receipt-verify');
const IronCurrency = require('../models/ironcurrency');
const IronCoinTransaction = require('../models/ironcointransaction');
const IronCoinWallet = require('../models/ironcoinwallet');
const request = require('google-oauth-jwt').requestWithJWT();
//const ServiceAccount = require('../pc-api-9178273158800928928-58-7ba9376382d8')
const kyberLogic = require('../logic/kyberlogic');

if (process.env.NODE_ENV !== 'production') {
  require('dotenv').load();
}

router.use(bodyParser.json({ limit: '100mb' }));
router.use(bodyParser.urlencoded({ limit: '100mb', extended: true, parameterLimit: 50000 }));

//Per apple, hit [production] first, then fall back to [sandbox] if it doesn't work
AppleReceiptVerify.config({
  secret: process.env.apple_shared_secret,
  environment: ['production', 'sandbox']
});

router.post('/reverify/', passport.authenticate('jwt', { session: false }), async (req, res) => {
  try {

    //validate params
    if (req.body.subscriptionType == undefined || req.body.verificationServer == undefined)
      throw new Error("Unauthorized");


    let success = false;

    if (req.body.platform == undefined) {

      // var googleReceiptVerify = new GoogleReceiptVerify({
      //   email: process.env.gcp_email,
      //   key: process.env.gcp_key.replace(/\\n/g, '\n'),
      // });

      // let googleResponse = await googleReceiptVerify.verifySub({
      //   packageName: "com.ironcircles.ironcirclesapp",
      //   productId: req.body.subscriptionType,
      //   purchaseToken: req.body.verificationServer,
      // });

      let googleResponse = await startGooglePlaySubscription(
        req.body.subscriptionType,
        req.body.verificationServer
      );

      success = googleResponse.isSuccessful;
    } else if (req.body.platform == constants.DEVICE_PLATFORM.iOS) {

      //validate later

      success = true;
    }

    if (success == true) {

      res.status(200).json({ success: true });

    } else {

      res.status(200).json({ success: false });
    }

  } catch (err) {

    var msg = await logUtil.logError(err, true);
    return res.status(500).json({ err: msg });

  }

});

async function startGooglePlaySubscription(type, token) {
  try {

    let urlBase = 'https://androidpublisher.googleapis.com/androidpublisher/v3/applications/com.ironcircles.ironcirclesapp/purchases/subscriptions/';
    let urlSubscription = type;
    let urlToken = token;
    let fullUrl = urlBase + urlSubscription + '/tokens/' + urlToken;

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
          // Google Auth Errors returned here
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

          if (res.statusCode == 200 || res.statusCode === 204) {
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

router.post('/subscribe/', passport.authenticate('jwt', { session: false }), async (req, res) => {
  try {


    let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);

    let bodySubscription = body.subscription;

    //console.log(bodySubscription.verificationServer);

    //validate params
    if (bodySubscription.type == undefined ||
      bodySubscription.purchaseID == undefined || bodySubscription.transactionDate == undefined ||
      bodySubscription.verificationLocal == undefined || bodySubscription.verificationServer == undefined
      || bodySubscription.verificationSource == undefined)
      throw new Error("Unauthorized");


    let success = false;

    ///checking for undefined can go away after everyone is on 87
    if (body.platform == undefined || body.platform == 'android') {

      let googleResponse = await startGooglePlaySubscription(
        bodySubscription.type,
        bodySubscription.verificationServer,
      );

      success = googleResponse.isSuccessful;
    } else if (body.platform == constants.DEVICE_PLATFORM.iOS) {

      console.log('Made it to iOS');

      try {

        const products = await AppleReceiptVerify.validate({
          receipt: bodySubscription.verificationServer,
        });

        console.log('Got products');

        if (products != null && products != undefined)
          success = true;
        console.log('Success');
      }
      catch (e) {
        console.log('Error:' + e);
        if (e instanceof AppleReceiptVerify.EmptyError) {
          console.log('ReceiptVerifyError');
        }
        else if (e instanceof AppleReceiptVerify.ServiceUnavailableError) {
          console.log('ServiceUnavailableError');
        }
      }


    }

    if (success == true) {

      console.log('Success continues');

      let user = await User.findById(req.user._id).populate({
        path: "ironCoinWallet", populate:
          [
            { path: "ironCoinTransactions" }]
      });;


      let subscription = new Subscription({
        purchaseDetailsJson: bodySubscription.purchaseDetailsJson,
        user: user._id, type: bodySubscription.type, purchaseID: bodySubscription.purchaseID, seed: bodySubscription.seed,
        transactionDate: bodySubscription.transactionDate, verificationLocal: bodySubscription.verificationLocal, verificationServer:
          bodySubscription.verificationServer, verificationSource: bodySubscription.verificationSource, status: constants.SUBSCRIPTION_STATUS.ACTIVE,
      });

      await subscription.save();


      user.accountType = constants.ACCOUNT_TYPE.PREMIUM;
      let now = new Date(Date.now());
      let day = now.getDate();
      if (day > 28) {
        user.subscribedOn = 28;
      } else {
        user.subscribedOn = day;
      }
      let currency = new IronCurrency();


      let wallet = await IronCoinWallet.findOne({ user: user._id }); //.populate("transactions");

      if (wallet == null || wallet == undefined) {
        wallet = new IronCoinWallet({ user: user._id });
      }

      wallet.balance += currency.subscriberCoins;
      let payment = new IronCoinTransaction({
        amount: currency.subscriberCoins,
        paymentType: constants.COIN_PAYMENT_TYPE.SUBSCRIBER_COINS,
        user: user,
        wallet: wallet,
        created: Date.now(),
        lastUpdated: Date.now(),
      });
      await payment.save();
      //wallet.transactions.push(payment);
      await wallet.save();
      await user.save();

      //res.status(200).json({ success: true, subscription: subscription });

      let payload = { success: true, subscription: subscription };
      payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);
      return res.status(200).json(payload);

    } else {

      throw new Error("Unauthorized");
    }

  } catch (err) {

    var msg = await logUtil.logError(err, true);
    return res.status(500).json({ err: msg });

  }

});


router.get('/', passport.authenticate('jwt', { session: false }), async (req, res) => {
  try {

    //authorization check
    let user = await User.findById(req.user._id);

    if (user.role != constants.ROLE.IC_ADMIN) {
      await logUtil.logError('unauthorized access to subscription listing', true);
      return res.status(400).json({ message: "Unauthorized" });
    }

    let subscriptions = await Subscription.find({ status: { $ne: 3 } }).populate({ path: 'user', populate: { path: 'hostedFurnace' } });

    res.status(200).json({ subscriptions: subscriptions });

  } catch (err) {

    var msg = await logUtil.logError(err, true);
    return res.status(500).json({ err: msg });

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

async function cancelGooglePlaySubscription(type, token) {
  try {

    let urlBase = 'https://androidpublisher.googleapis.com/androidpublisher/v3/applications/com.ironcircles.ironcirclesapp/purchases/subscriptions/';
    let urlSubscription = type;
    let urlToken = token;
    let fullUrl = urlBase + urlSubscription + '/tokens/' + urlToken + ':cancel';

    let options = {
      uri: fullUrl,
      method: 'post',
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
          // Google Auth Errors returned here
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

          if (res.statusCode == 200 || res.statusCode === 204) {
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
    }
    )

  } catch (err) {
    var msg = await logUtil.logError(err, true);
    return res.status(500).json({ err: msg });
  }
};

router.post('/cancel/', passport.authenticate('jwt', { session: false }), async (req, res) => {
  try {

    let body = await kyberLogic.decryptBody(req.body, req.body.uuid, req.body.iv, req.body.mac, req.body.enc, req.user);

    //validate params
    if (body.subscription == undefined) throw new Error("Unauthorized");

    if (body.platform == undefined || body.platform == 'android') {

      let response = await cancelGooglePlaySubscription(
        body.subscription.type,
        body.subscription.verificationServer,
      );

      if (response.isSuccessful == true) {

        let user = await User.findById(req.user._id);

        var subscription;

        if (body.subscription.purchaseID.length != 0) {
          subscription = await Subscription.findOne({ purchaseID: body.subscription.purchaseID });

        } else {
          //this will only happend for super early Privacy+ adopters
          subscription = await Subscription.findOne({ userID: user._id, status: constants.SUBSCRIPTION_STATUS.ACTIVE });
        }

        if (subscription instanceof Subscription) {
          subscription.cancelDate = Date.now();
          subscription.status = constants.SUBSCRIPTION_STATUS.CANCELED;
          await subscription.save();
        }

        user.accountType = constants.ACCOUNT_TYPE.FREE;
        await user.save();

        //res.status(200).json({ user: user, subscription: subscription });

        let payload = { user: user, subscription: subscription };
        payload = await kyberLogic.encryptPayload(req.body.enc, req.body.uuid, payload);
        return res.status(200).json(payload);


      } else {
        return res.status(500).json({ err: response.errorMessage });
      }

    } else if (req.body.platform == constants.DEVICE_PLATFORM.iOS) {
      ///TODO

      ///Right now, this shouldn't be called by the client on iOS
      return res.status(500);
    }

  } catch (err) {

    var msg = await logUtil.logError(err, true);
    return res.status(500).json({ err: msg });

  }

});
/*
router.post('/subscribe/', passport.authenticate('jwt', { session: false }), async (req, res) => {
  try {

    //validate params
    if (req.body.subscriptionType == undefined || req.body.subscriptionType == undefined ||
      req.body.subscriptionType == undefined || req.body.subscriptionType == undefined ||
      req.body.subscriptionType == undefined || req.body.subscriptionType == undefined)
      throw new Error("unauthorized");

    let user = await User.findById(req.user._id);


    let subscription = new Subscription({
      user: user._id, subscriptionType: req.body.subscriptionType, purchaseID: req.body.purchaseID,
      transactionDate: req.body.transactionDate, verificationLocal: req.body.verificationLocal, verificationServer:
        req.body.verificationServer, verificationSource: req.body.verificationSource, active: true,
    });

    await subscription.save();


    user.accountType = constants.ACCOUNT_TYPE.PREMIUM;
    await user.save();

    res.status(200).json({ success: true, user: user });


  } catch (err) {

    var msg = await logUtil.logError(err, true);
    return res.status(500).json({ err: msg });

  }

});
*/




module.exports = router;