{ CommentStream } = rawjs = require 'raw.js'
reddit = new rawjs('phish bot')
request = require('request')
moment = require 'moment-timezone'

extractDate = require './extract_date'

# optionally log in
auth =
  username: ''
  password: ''
  app:
    id: ''
    secret: ''

reddit.setupOAuth2 auth.app.id, auth.app.secret
reddit.auth { username: auth.username, password: auth.password }, (error, response) ->
  if error?
    console.error 'error on', (new Date())
    console.error 'could not log in (bot):', error
    console.error ''
  else
    stream = new CommentStream subreddit: 'phish', run: false, interval: 5000
    stream.start()

    # do stuff with new items here
    stream.on 'comment', (comment) ->
      return if comment.author == "helping_friendly_bot"

      time = moment.unix(comment.created).subtract(8, 'hour')
      now = moment()
      diff = now.diff(time) / 1000

      # 30 seconds
      return if diff > 120

      date = extractDate comment.body
      return unless date
      {year, month, day} = date
      return unless year && month && date
      showDate = "#{year}-#{month}-#{day}"

      request "http://api.phish.net/api.js?method=pnet.shows.setlists.md.get&showdate=#{showDate}&apikey=&api=2.0&format=json", (err, res, body) ->
        json = JSON.parse(body)?[0]

        return unless json and json.setlistdata

        output = ""

        output += "**Stream this show: [Relisten.net](http://relisten.net/phish/#{year}/#{month}/#{day}) · [PhishTracks](http://www.phishtracks.com/shows/#{showDate}) · [Phish.in](http://phish.in/#{showDate})**"

        output += "\n\n\n\n"

        output += "###[#{json.nicedate}](#{json.url})\n"
        output += "####[#{json.venue}](http://phish.net/venue/#{json.venueid}), #{json.city} #{json.state}\n"

        output += "\n\n"
        output += json.setlistdata
        output += "\n\n"
        output += "_" + cleanNotes(json.setlistnotes) + "_"

        output += "\n\n\n\n"

        output += "This data is provided by [Phish.net](http://phish.net) and [The Mockingbird Foundation](http://mbird.org). Please thank them for all of their hard work."


        reddit.comment comment.name, output, (err) -> console.log "comment failed:", err if err
        console.log "Added a comment for #{showDate}"


    cleanNotes = (notes) ->
      notes.replace /<[^>]*>/g, ''