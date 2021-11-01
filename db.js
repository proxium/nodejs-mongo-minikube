const mongoose = require('mongoose');

const {
  MONGO_USERNAME,
  MONGO_PASSWORD,
  MONGO_HOSTNAME,
  MONGO_PORT,
  MONGO_DB
} = process.env;

const url = `mongodb://${MONGO_USERNAME}:`+encodeURIComponent(`${MONGO_PASSWORD}`)+`@${MONGO_HOSTNAME}:${MONGO_PORT}/${MONGO_DB}`;

const options = {
  useNewUrlParser: true,
  useUnifiedTopology: true,
  connectTimeoutMS: 10000,
};

mongoose.connect(url, options).then( function() {
  console.log('MongoDB is connected');
})
  .catch( function(err) {
  console.log(err);
});

const Schema = mongoose.Schema;
const thingSchema = new Schema({}, { strict: false });
module.exports.helloCollection = mongoose.model('helloCollection', thingSchema);

