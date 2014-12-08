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

  # Respond to 'basecamp' or 'bcx' with what this guy does.
  robot.respond /basecamp|bcx/i, (msg) ->
    msg.send "Sit back and let me do the work. I'll preview todos and messages for you when you paste basecamp.com urls. I currently support expanding single todos with most recent comment, summarizing todolists and expanding messages."

  # Display a single todo item.
  robot.hear /https:\/\/basecamp\.com\/(\d+)\/projects\/(\d+)\/todos\/(\d+)/, (msg) ->
    heard_project = msg.match[2]
    heard_todo = msg.match[3]
    getBasecampRequest msg, "projects/#{heard_project}/todos/#{heard_todo}.json", (err, res, body) ->
      msg.send parseBasecampResponse('todo', JSON.parse body)

  # Display the todo list name and item counts.
  robot.hear /https:\/\/basecamp\.com\/(\d+)\/projects\/(\d+)\/todolists\/(\d+)/, (msg) ->
    heard_project = msg.match[2]
    heard_list = msg.match[3]
    getBasecampRequest msg, "projects/#{heard_project}/todolists/#{heard_list}.json", (err, res, body) ->
      msg.send parseBasecampResponse('todolist', JSON.parse body)

  # Display the original message of a thread, and the last comment if there is one.
  robot.hear /https:\/\/basecamp\.com\/(\d+)\/projects\/(\d+)\/messages\/(\d+)/, (msg) ->
    heard_project = msg.match[2]
    heard_message = msg.match[3]
    getBasecampRequest msg, "projects/#{heard_project}/messages/#{heard_message}.json", (err, res, body) ->
      msg.send parseBasecampResponse('message', JSON.parse body)

############################################################################
# Helper functions.

# Parse a response and format nicely.
parseBasecampResponse = (msgtype, body) ->

  switch msgtype

    when "todolist"
      m = "*#{body.name}* todo list"
      m = m + "\n#{body.completed_count} completed, #{body.remaining_count} remaining"

    when "todo"
      m = "*#{body.content}*"
      if (body.completed)
        m = m + " _ (COMPLETED) _"
      attcnt = body.attachments.length
      if (attcnt > 0)
        if (attcnt == 1)
          m = m + "\n_ 1 file: _"
        else
          m = m + "\n_ #{attcnt} files: _"
        for att in body.attachments
          m = m + "\n> #{att.name} (#{att.app_url}|download)"
      if (body.assignee)
        m = m + "\n_ Assigned to #{body.assignee.name} _"
      if (body.comments)
        last = body.comments.pop()
        t = type last
        if (t == 'object')
          m = m + "\n_ The last comment was made by #{last.creator.name}: _"
          comment = totxt.fromString(last.content, { wordwrap: 70 });
          m = m + "\n```#{comment}```"
          lstattcnt = last.attachments.length
          if (lstattcnt > 0)
            if (lstattcnt == 1)
              m = m + "\n_ 1 file: _"
            else
              m = m + "\n_ #{lstattcnt} files: _"
            for att in last.attachments
              m = m + "\n> #{att.name} (#{att.app_url}|download)"

    when "message"
      m = "*#{body.subject}*"
      if (body.creator)
        m = m + "\n_ #{body.creator.name} first wrote: _"
      if (body.content)
        bd = totxt.fromString(body.content, { wordwrap: 70 });
        m = m + "\n```#{bd}```"
      if (body.attachments)
        attcnt = body.attachments.length
        if (attcnt > 0)
          if (attcnt == 1)
            m = m + "\n_ 1 file: _"
          else
            m = m + "\n_ #{attcnt} files: _"
          for att in body.attachments
            m = m + "\n> #{att.name} (#{att.app_url}|download)"
      if (body.comments)
        last = body.comments.pop()
        t = type last
        if (t == 'object')
          m = m + "\n_ The last comment was made by #{last.creator.name}: _"
          comment = totxt.fromString(last.content, { wordwrap: 70 });
          m = m + "\n```#{comment}```"
          lstattcnt = last.attachments.length
          if (lstattcnt > 0)
            if (lstattcnt == 1)
              m = m + "\n_ 1 file: _"
            else
              m = m + "\n_ #{lstattcnt} files: _"
            for att in last.attachments
              m = m + "\n> #{att.name} (#{att.app_url}|download)"

  m


# Perform a GET request to Basecamp API.
getBasecampRequest = (msg, path, callback) ->
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
