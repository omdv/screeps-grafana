###
hopsoft\screeps-statsd

Licensed under the MIT license
For full copyright and license information, please see the LICENSE file

@author     Bryan Conrad <bkconrad@gmail.com>
@copyright  2016 Bryan Conrad
@link       https://github.com/hopsoft/docker-graphite-statsd
@license    http://choosealicense.com/licenses/MIT  MIT License
###

###
SimpleClass documentation

@since  0.1.0
###
rp = require 'request-promise'
zlib = require 'zlib'
# require('request-debug')(rp)
StatsD = require 'node-statsd'
token = process.env.SCREEPS_TOKEN
update_rate = process.env.UPDATE_FREQUENCY_SECONDS * 1000
class ScreepsStatsd

  ###
  Do absolutely nothing and still return something

  @param    {string}    string      The string to be returned - untouched, of course
  @return   string
  @since    0.1.0
  ###
  run: ( string ) ->
    rp.defaults jar: true
    @loop()

    setInterval @loop, update_rate

  loop: () =>
    @getMemory()

  getMemory: () =>
    @statsclient = new StatsD host: process.env.GRAPHITE_PORT_8125_UDP_ADDR
    options =
      uri: 'https://screeps.com/api/user/memory'
      method: 'GET' 
      json: true
      resolveWithFullResponse: true
      headers:
        "X-Token": process.env.SCREEPS_TOKEN
      qs:
        path: 'stats'
        shard: process.env.SCREEPS_SHARD
    rp(options).then (x) =>
      return unless x.body.data
      data = x.body.data.split('gz:')[1]
      finalData = JSON.parse zlib.gunzipSync(new Buffer(data, 'base64')).toString()
      @report(finalData)

  report: (data, prefix="") =>
    if prefix is ''
      console.log "Pushing to gauges - " + new Date()
    for k,v of data
      if typeof v is 'object'
        @report(v, prefix+k+'.')
      else
        @statsclient.gauge prefix+k, v

module.exports = ScreepsStatsd
