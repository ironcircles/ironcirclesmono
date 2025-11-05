const logUtil = require('../util/logutil');
const AWS = require("aws-sdk");


if (process.env.NODE_ENV !== 'production') {
    require('dotenv').load();
}


AWS.config.update({ region: process.env.s3region });

const s3 = new AWS.S3({
    accessKeyId: process.env.s3one,
    secretAccessKey: process.env.s3key,
    region: AWS.config.region,
    signatureVersion: "v4",
});


module.exports.deleteObject = async function (bucket, object) {

    const params = {
        Bucket: bucket,
        Key: object
    };

    return new Promise((resolve, reject) => {

        s3.deleteObject(params, function (err, data) {
            if (err) console.log(err);
            else
                console.log(
                    "Successfully deleted file from bucket"
                );
        });

    });

}