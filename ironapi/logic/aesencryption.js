var crypto = require('crypto');
const algorithm = 'aes-256-gcm';
//const Aes = require('aes-256-gcm');

iv = '60iP0h6vJoEa';

module.exports.encrypt = (secret, text) => {

    const ssBuffer = Buffer.from(secret, 'base64');

    const iv = new Buffer(crypto.randomBytes(12), 'utf8');
    const cipher = crypto.createCipheriv(algorithm, ssBuffer, iv, {
        authTagLength: 16
      });
    let encrypted = cipher.update(text, 'utf8', 'hex');
    encrypted += cipher.final('hex');

    const tag = cipher.getAuthTag();

    // var testOuput = this.decrypt(ssBuffer, encrypted, iv, tag);
    // console.log('Test Output: ' + testOuput);

    // console.log('tag: ' + Array.apply([], tag).join(","));
    // console.log('iv: ' + Array.apply([], iv).join(","));
    // console.log('encrypted: ' + encrypted);
    // console.log('encrypted: ' +  Array.apply([],  Buffer.from(encrypted, 'utf8')).join(","));
    // console.log('secret: ' +  secret    );
    // console.log('secret array: ' +  Array.apply([], ssBuffer).join(","));


    return {
        enc: encrypted,
        tag: tag,
        iv: iv
    };
}

module.exports.decrypt = (ss, encrypted, iv, tag) => {

    var decipher = crypto.createDecipheriv(algorithm, Buffer.from(ss, 'utf8'), iv);
    decipher.setAuthTag(tag);
    var dec = decipher.update(encrypted, 'hex', 'utf8');
    dec += decipher.final('utf8');
    return dec;
}
//};


// const KEY = new Buffer(crypto.randomBytes(32), 'utf8');

// const aesCipher = aes256gcm(KEY);

// const [encrypted, iv, authTag] = aesCipher.encrypt('hello, world');
// const decrypted = aesCipher.decrypt(encrypted, iv, authTag);

