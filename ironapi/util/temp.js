const mongoose = require('mongoose');
const { Readable } = require('stream');
const multer = require('multer');
const mongodb = require('mongodb');
const ObjectID = require('mongodb').ObjectID;

let conn = mongoose.connection;
//let multer = require('multer');
let GridFSStorage = require('multer-gridfs-storage');
//let Grid = require('gridfs-stream');
//Grid.mongo = mongoose.mongo;
//let gfs = Grid(conn, mongodb);


const { dbReady } = require('../db');


function getBuckets(type) {

    var buckets = new this.Buckets();

    buckets.thumbnail = 'thumbnails';
    buckets.full = 'fullimages';

    if (type) {
        if (type = "video") {
            buckets.thumbnail = "videoPreviewBlob";
            buckets.full = "videoFullBlob"
        }

    }
}


module.exports.saveBlob = function (req, res, fileName, type, metadatatag,) {

    var buckets = new this.Buckets(type);
    
    const storage = new GridFSStorage({
        db: conn, cache: 'connections',
        file: (req, file) => {
            return {
                bucketName: buckets.full,
                metadata: metadatatag
            }
        }

    });

    const upload = multer({
        storage: storage
    }).single(fileName);

    return new Promise(function (resolve, reject) {
        storage.on('connection', (db) => {

            upload(req, res, (err) => {

                if (err) {
                    console.error(err);
                    return reject(err.message);
                }

            });
        });

        storage.on('file', (file) => {
            var body;
            var results;

            if (req.body["body"] != undefined) {

                results = [];
                results.push(req.body["body"]);
                results.push(body);

            } else results = file.id;

            return resolve(results);

        });

        storage.on('streamError', (error) => {
            console.error(error);
            return reject(error);
        });

    });


}


module.exports.saveDual = function (req, res, type, metadatatag,) {

    // return new Promise(function (resolve, reject) {

    var buckets = getBuckets(type);

    const storage = new GridFSStorage({
        db: conn, cache: 'connections',
        file: (req, file) => {

            var bucketName = buckets.thumbnail;
            if (file.fieldname == 'full')
                bucketName = buckets.full;

            return {
                bucketName: bucketName,
                metadata: metadatatag
            }
        }

    });

    const upload = multer({
        storage: storage
    }).fields([{ name: 'thumbnail', maxCount: 1 }, { name: 'full', maxCount: 8 }]);

    var blobSaved = new this.BlobSaved();

    return new Promise(function (resolve, reject) {
        storage.on('connection', (db) => {

            upload(req, res, (err) => {

                if (err) {
                    console.error(err);
                    return reject(err.message);
                }

            });
        });

        storage.on('file', (file) => {

            if (file.bucketName == buckets.thumbnail) {
                blobSaved.thumbnail = file.id;
                blobSaved.thumbnailSize = file.size;
            }

            else if (file.bucketName == buckets.full) {
                blobSaved.fullimage = file.id;
                blobSaved.fullimageSize = file.size;
            }

            if (blobSaved.full != null && blobSaved.thumbnail != null)
                return resolve(blobSaved);

        });

        storage.on('streamError', (error) => {
            console.error(error);
            return reject(error);
        });

    });


}

module.exports.deleteBlob = function (bucketName, id) {



    return new Promise(function (resolve, reject) {

        var blobID = new ObjectID(id);

        //delete the chunks and files
        let bucket = new mongodb.GridFSBucket(mongoose.connection.db, {
            bucketName: bucketName
        });

        bucket.delete(blobID)
            .then(function () {
                return resolve();
            })
            .catch(function (err) {
                console.error(err);
                //next(err);
                return reject(err);
            });

    });


}

module.exports.loadBlob = function (res, bucketName, id) {

    try {

        return new Promise(function (resolve, reject) {
            var ID = new ObjectID(id);

            //res.set('content-type', 'application/json');
            res.set('content-type', 'image/jpeg');
            res.set('accept-ranges', 'bytes');

            let bucket = new mongodb.GridFSBucket(mongoose.connection.db, {
                //chunkSizeBytes: 1024,
                bucketName: bucketName
            });

            let downloadStream = bucket.openDownloadStream(ID);
            bucket.find();

            //console.log(downloadStream.readableLength);
            //res.set('content-length', '1024');

            downloadStream.on('data', (chunk) => {
                res.write(chunk);
            });

            downloadStream.on('error', (err) => {
                console.error(err);
                res.set('content-type', 'application/json');
                return reject(err.message);
            });

            downloadStream.on('end', () => {
                res.end();
                console.log('blob loaded: ' + id + '  bucketname: ' + bucketName);
                return resolve(res);
            });
        });

    } catch (err) {
        console.error(err);
        //return res.status(500).json({ message: "Invalid gridfs id" });
        res.set('content-type', 'application/json');
        return reject(err.message);
    }
}

module.exports.Buckets = class Buckets {
    constructor() {
    }

    set thumbnail(thumbnail) {
        this._thumbnail = thumbnail;
    }
    get thumbnail() {
        return this._thumbnail;
    }

    set full(full) {
        this._full = full;
    }
    get full() {
        return this._full;
    }
}

module.exports.Blob = class Blob {
    constructor() {
    }

    set id(id) {
        this._id = id;
    }
    get id() {
        return this._id;
    }

    set size(size) {
        this._size = size;
    }
    get size() {
        return this._size;
    }
}

module.exports.BlobSaved = class BlobSaved {
    constructor() {

    }
    set thumbnail(thumbnail) {
        this._thumbnail = thumbnail;
    }
    get thumbnail() {
        return this._thumbnail;
    }

    set full(full) {
        this._full = full;
    }
    get full() {
        return this._full;
    }

    set fullSize(fullSize) {
        this._fullSize = fullSize;
    }
    get fullSize() {
        return this._fullSize;
    }

    set thumbnailSize(thumbnailSize) {
        this._thumbnailSize = thumbnailSize;
    }
    get thumbnailSize() {
        return this._thumbnailSize;
    }
}


