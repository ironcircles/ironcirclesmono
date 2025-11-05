const mongoose = require('mongoose');
const constants = require('../util/constants');
const { Decimal128 } = require('mongodb');

var IronCurrencySchema = new mongoose.Schema({
    newUserCoins: { type: Number, default: 1000 },
    subscriberCoins: { type: Number, default: 2500 }, //monthly
    baseLora: { type: Number, default: 0.0012 },
    //baseStep: { type: Decimal128, default: 0.0000670 }, ///deprecated
    stepsSmall: { type: Number, default: 0.0000335 },
    stepsMedium: { type: Number, default: 0.0000335 },
    stepsLarge: { type: Number, default: 0.0001455 },
    stepsXLarge: { type: Number, default: 0.0003025 },
    sizeSmall: { type: Number, default: 0.000950 },
    sizeMedium: { type: Number, default: 0.000950 },
    sizeLarge: { type: Number, default: 0.004350 },
    sizeXLarge: { type: Number, default: 0.009050 },
    upscaleSmall: { type: Number, default: 0.00025 },
    upscaleMedium: { type: Number, default: 0.0006 },
    upscaleLarge: { type: Number, default: 0.00145 },
    upscaleXLarge: { type: Number, default: 0.00255 },
    markup: { type: Number, default: 1.3 },
    coinMultiplier: { type: Number, default: 10000 },
}, { timestamps: { createdAt: 'created', updatedAt: 'lastUpdate' } });


IronCurrencySchema.methods.getValuesList = function () {
    let list = [];

    list.push(this.newUserCoins);
    list.push(this.subscriberCoins);

    list = this.getImageSizeCosts(list);

    list = this.getCoinCalculations(list);

    return list;
}

IronCurrencySchema.methods.getImageSizeCosts = function (list) {

    ///for 320
    let smallest = (0.0019 / 2) * this.markup * this.coinMultiplier;
    list.push(smallest); //13.3
    let smallestUpscale = 0.0017 * this.coinMultiplier;
    list.push(smallestUpscale); //17

    //for 512
    let medium = (0.0019 / 2) * this.markup * this.coinMultiplier;
    list.push(medium); //13.3
    let mediumUpscale = 0.0022 * this.coinMultiplier;
    list.push(mediumUpscale); //22

    //for 768
    let large = (0.0087 / 2) * this.markup * this.coinMultiplier;
    list.push(large); //60.89
    let largeUpscale = 0.0081 * this.coinMultiplier;
    list.push(largeUpscale); //81

    //for 1024
    let XLarge = (0.0181 / 2) * this.markup * this.coinMultiplier;
    list.push(XLarge); //126.7
    let XLargeUpscale = 0.0162 * this.coinMultiplier;
    list.push(XLargeUpscale); //162

    return list;
}

IronCurrencySchema.methods.getCoinCalculations = function (list) {

    let loraPrice = this.baseLora * this.coinMultiplier;
    list.push(Math.round(loraPrice)); //12
    let stepPrice = this.baseStep * this.markup * this.coinMultiplier;
    list.push(stepPrice); //0.938

    return list;
}

mongoose.model('IronCurrency', IronCurrencySchema);

module.exports = mongoose.model('IronCurrency');