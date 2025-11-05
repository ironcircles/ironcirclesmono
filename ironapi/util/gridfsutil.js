/*const mongoose = require('mongoose');
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


module.exports.saveBlob = function (req, res, fileName, bucketName, metadatatag,) {

    // return new Promise(function (resolve, reject) {

    const storage = new GridFSStorage({
        db: conn, cache: 'connections',
        file: (req, file) => {
            return {
                bucketName: bucketName,
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


module.exports.saveDual = function (thumbnailBucket, fullBucket, req, res, metadatatag,) {

    // return new Promise(function (resolve, reject) {

    const storage = new GridFSStorage({
        db: conn, cache: 'connections',
        file: (req, file) => {

            var bucketName = thumbnailBucket;
            if (file.fieldname == 'full')
                bucketName = fullBucket;

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

            if (file.bucketName == thumbnailBucket) {
                blobSaved.thumbnail = file.id;
                blobSaved.thumbnailSize = file.size;
            }

            else if (file.bucketName == fullBucket) {
                blobSaved.full = file.id;
                blobSaved.fullSize = file.size;
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

module.exports.saveBlobReturnBlob = function (req, res, fileName, bucketName, metadatatag,) {

    // return new Promise(function (resolve, reject) {



    const storage = new GridFSStorage({
        db: conn, cache: 'connections',
        file: (req, file) => {

            return {
                bucketName: bucketName,
                metadata: metadatatag
            }
        }

    });

    var blob = new this.Blob();

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

            blob.id = file.id;
            blob.size = file.size;
            //results.push(file.id);

            return resolve(blob);

        });

        storage.on('streamError', (error) => {
            console.error(error);
            return reject(error);
        });

    });


}

//This function is deprecated.  Stop using it. 

module.exports.saveBlobReturnArray = function (req, res, fileName, bucketName, metadatatag,) {

    // return new Promise(function (resolve, reject) {

    const storage = new GridFSStorage({
        db: conn, cache: 'connections',
        file: (req, file) => {

            return {
                bucketName: bucketName,
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
            var results = [];
            results.push(file.id);

            if (req.body["body"] != undefined) {
                results.push(req.body["body"]);
            }
            return resolve(results);

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
*/

/*
module.exports.loadBlobStreaming = function (res, bucketName, id) {

    try {

        return new Promise(function (resolve, reject) {
            var ID = new ObjectID(id);

            //res.set('content-type', 'application/json');
            //res.set('content-type', 'image/jpeg');
            //res.set('accept-ranges', 'bytes');

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
*/

/*
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
}*/




/*
module.exports.saveBlob = function (req, res, bucketName){

    return new Promise(function(resolve, reject){



        const storage = multer.memoryStorage();


       const upload = multer({ storage: storage, limits:
        { fields: 1, fileSize: 6000000000, files: 1}});

        upload.single('image')(req, res, (err) => {
        if (err){
            console.error(err);
            return reject(err);

        }

        let imageName = req.file.originalname + "_" + Date.now();

        // Covert buffer to Readable Stream
        const readableStream = new Readable();
        readableStream.push(req.file.buffer);
        readableStream.push(null);

        let bucket = new mongodb.GridFSBucket(mongoose.connection.db, {
            bucketName: bucketName
        });

        let uploadStream = bucket.openUploadStream(imageName);
        let id = uploadStream.id;
        readableStream.pipe(uploadStream);

        uploadStream.on('error', () => {
            if (err) return reject(err);
        });

        uploadStream.on('finish', () => {
            //console.log("upload finished");
            return resolve(id);
        });

        });
    });

}

*/





