# Description
#   Provides text previews of Basecamp URLs.
#
# Configuration:
#   HUBOT_BCX_ACCOUNT_ID
#   HUBOT_BCX_USERNAME
#   HUBOT_BCX_PASSWORD
#
# Commands:
#   hubot basecamp - provides an explanation of what previews are available.
#
# Notes:
#   1. Your Basecamp account ID is the number directly after
#   "https://basecamp.com/" when logged in.
#	  2. Don't use your own Basecamp username and password. Rather, create one
#   that has access to all projects, and is added to the templates you use.
#
# Author:
#   Ivan Stegic [@ivanstegic]


# Dependencies.
totxt = require "html-to-text"

# Variables.
id = process.env.HUBOT_BCX_ACCOUNT_ID
user = process.env.HUBOT_BCX_USERNAME
pass = process.env.HUBOT_BCX_PASSWORD

# Perform a GET request to Basecamp API.
getRequest = (msg, path, callback) ->
  msg.http("https://basecamp.com/#{id}/api/v1/#{path}")
    .headers("User-Agent": "Hubot (https://github.com/github/hubot)")
    .auth(user, pass)
    .get() (err, res, body) ->
      callback(err, res, body)

# Modified typeof function that is actually reliable.
type = (obj) ->
    if obj == undefined or obj == null
      return String obj
    classToType = {
      '[object Boolean]': 'boolean',
      '[object Number]': 'number',
      '[object String]': 'string',
      '[object Function]': 'function',
      '[object Array]': 'array',
      '[object Date]': 'date',
      '[object RegExp]': 'regexp',
      '[object Object]': 'object'
    }
    return classToType[Object.prototype.toString.call(obj)]

# No ID is set.
unless id?
    console.log "Missing HUBOT_BCX_ACCOUNT_ID environment variable, please set it with your Basecamp account ID. This is the number directly following \"https://basecamp.com/\" in the URL when you are logged into your Basecamp account."
    process.exit(1)

# No Basecamp user is set.
unless user?
    console.log "Missing HUBOT_BCX_USERNAME environment variable, please set it with your Basecamp username or email address. Protip: create a generic user with access to all Basecamp projects, don't use your personal details."
    process.exit(1)

# No Basecamp password is set.
unless pass?
    console.log "Missing HUBOT_BCX_PASSWORD environment variable, please set it with your Basecamp password."
    process.exit(1)

# Export the robot, as hubot expects.
module.exports = (robot) ->

  # Responsd to 'basecamp' with what this guy does.
  robot.respond /basecamp/, (msg) ->
    msg.reply "Sit back and let me do the work. I'll expand todos and messages for you when you paste basecamp.com URLs."

  # Display a single todo item.
  robot.hear /https:\/\/basecamp\.com\/(\d+)\/projects\/(\d+)\/todos\/(\d+)/, (msg) ->
    heard_project = msg.match[2]
    heard_todo = msg.match[3]
    getRequest msg, "projects/#{heard_project}/todos/#{heard_todo}.json", (err, res, body) ->
      response = JSON.parse body
      m = "*#{response.content}*"
      if (response.assignee)
        m = m + "\n_ Assigned to #{response.assignee.name} _"
      if (response.comments)
        last = response.comments.pop()
        t = type last
        if (t == 'object')
          m = m + "\n_ The last comment was made by #{last.creator.name}: _"
          comment = totxt.fromString(last.content, { wordwrap: 70 });
          m = m + "\n```#{comment}```"
      msg.send m

  # Display the todo list name and item counts.
  robot.hear /https:\/\/basecamp\.com\/(\d+)\/projects\/(\d+)\/todolists\/(\d+)/, (msg) ->
    heard_project = msg.match[2]
    heard_list = msg.match[3]
    getRequest msg, "projects/#{heard_project}/todolists/#{heard_list}.json", (err, res, body) ->
      response = JSON.parse body
      m = "*#{response.name}* todo list"
      m = m + "\n#{response.completed_count} completed, #{response.remaining_count} remaining"
      msg.send m

  # Display the original message of a thread, and the last comment if there is one.
  robot.hear /https:\/\/basecamp\.com\/(\d+)\/projects\/(\d+)\/messages\/(\d+)/, (msg) ->
    heard_project = msg.match[2]
    heard_message = msg.match[3]
    getRequest msg, "projects/#{heard_project}/messages/#{heard_message}.json", (err, res, body) ->
      response = JSON.parse body
      m = "*#{response.subject}*"
      if (response.creator)
        m = m + "\n_ #{response.creator.name} first wrote: _"
      if (response.content)
        body = totxt.fromString(response.content, { wordwrap: 70 });
        m = m + "\n```#{body}```"
      if (response.comments)
        last = response.comments.pop()
        t = type last
        if (t == 'object')
          m = m + "\n_ The last comment was made by #{last.creator.name}: _"
          comment = totxt.fromString(last.content, { wordwrap: 70 });
          m = m + "\n```#{comment}```"
      msg.send m
