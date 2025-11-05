// Generates a random unsigned 32-bit integer (0 to 4294967295)
module.exports.randomUInt32 =  function () {
  return Math.floor(Math.random() * 0x100000000);
}

