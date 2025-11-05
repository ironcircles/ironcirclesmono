const kyberLogic = require('../logic/kyberlogic');

module.exports.safeParse = async function (req) {
    try {
        // Check if file was uploaded
        if (!req.file) {
            throw new Error('No file uploaded');
        }

        // Get file content from buffer and convert to JSON
        const fileContent = req.file.buffer.toString('utf-8');

        let body = JSON.parse(fileContent);

        body = await kyberLogic.decryptBody(body, body.uuid, body.iv, body.mac, body.enc, req.user);

        return body;

    } catch (err) {
        //var msg = await logUtil.logError(err, true);
        throw (err);
    }
}