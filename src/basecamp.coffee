# Description
#   Expands Basecamp URLs with more useful information.
#
# Configuration:
#   HUBOT_BCX_ACCOUNT_ID
#   HUBOT_BCX_USERNAME
#   HUBOT_BCX_PASSWORD
#
# Commands:
#   hubot bcx - provides an explanation of what previews are available.
#   hubot bcx stats - provides statistics on how many URLs have been expanded.
#
# Notes:
#   1. Your Basecamp account ID is the number directly after
#   "https://basecamp.com/" when logged in.
#   2. Don't use your own Basecamp username and password. Rather, create one
#   that has access to all projects, and is added to the templates you use.
#
# Author:
#   Ivan Stegic [@ivanstegic]


# Dependencies.
totxt = require "html-to-text"
dateformat = require "dateformat"

# Variables.
id = process.env.HUBOT_BCX_ACCOUNT_ID
user = process.env.HUBOT_BCX_USERNAME
pass = process.env.HUBOT_BCX_PASSWORD

# Constants.
VERSION = "v0.6.1"

# No ID is set.
unless id?
    console.log "Missing HUBOT_BCX_ACCOUNT_ID environment variable, please set it with your Basecamp account ID. This is the number directly following \"https://basecamp.com/\" in the URL when you are logged into your Basecamp account. More help is available at https://github.com/hubot-scripts/hubot-basecamp"
    process.exit(1)

# No Basecamp user is set.
unless user?
    console.log "Missing HUBOT_BCX_USERNAME environment variable, please set it with your Basecamp username or email address. Protip: create a generic user with access to all Basecamp projects, don't use your personal details. More help is available at https://github.com/hubot-scripts/hubot-basecamp"
    process.exit(1)

# No Basecamp password is set.
unless pass?
    console.log "Missing HUBOT_BCX_PASSWORD environment variable, please set it with your Basecamp password. More help is available at https://github.com/hubot-scripts/hubot-basecamp"
    process.exit(1)

# Export the robot, as hubot expects.
module.exports = (robot) ->

  # Respond to 'basecamp' or 'bcx' with what this guy does.
  robot.respond /(basecamp|bcx)$/i, (msg) ->
    msg.send "Greetings, human. I'll expand discussions and todos for you when you paste basecamp.com URLs into chat. I currently support expanding discussions, single todos and I can summarize todolists. https://github.com/hubot-scripts/hubot-basecamp|More..."

  # Respond to 'basecamp stats' or 'bcx stats' with distribution of URLs expanded.
  robot.respond /(basecamp|bcx) stats$/i, (msg) ->
    # Get stored numbers in the robot brain.
    todos = robot.brain.get('bcx_todos') * 1 or 0
    messages = robot.brain.get('bcx_messages') * 1 or 0
    todolists = robot.brain.get('bcx_todolists') * 1 or 0
    # Figure out grand total.
    grand_total = todos + messages + todolists
    m = "Here, I give you amazing Basecamp stats! URLs expanded:"
    m = m + "\n> Todos: " + todos
    m = m + "\n> Discussions: " + messages
    m = m + "\n> To-do lists: " + todolists
    m = m + "\nTotal expanded: " + grand_total
    msg.send m

  # Display a single todo item. Include latest or a specific comment.
  robot.hear /https:\/\/basecamp\.com\/(\d+)\/projects\/(\d+)\/todos\/(\d+)/, (msg) ->
    # Parse out the URL parts and only for those matching the configured account.
    if (parseInt(id) == parseInt(msg.match[1]) && msg.match['input'][-2..] != '&x')
      heard_project = msg.match[2]
      heard_todo = msg.match[3]
      heard_comment_id = getCommentID msg.match['input']
      # Get the todo item detail from the API.
      getBasecampRequest msg, "projects/#{heard_project}/todos/#{heard_todo}.json", (err, res, body) ->
        todo_json = JSON.parse body || null
        t = type todo_json
        if (t == 'object')
          todolist_id = todo_json.todolist_id
          # Get the todo list detail from the API.
          getBasecampRequest msg, "projects/#{heard_project}/todolists/#{todolist_id}.json", (err, res, body) ->
            todolist_json = JSON.parse body || null
            t = type todolist_json
            if (t == 'object')
              # Todo list name is really what we wanted here, the reason for the extra API call.
              todolist_name = todolist_json.name
              track robot, "bcx_todos"
              msg.send parseBasecampResponse('todo', todo_json, heard_comment_id, todolist_name)

  # Display the todo list name and item counts.
  robot.hear /https:\/\/basecamp\.com\/(\d+)\/projects\/(\d+)\/todolists\/(\d+)/, (msg) ->
    # Parse out the URL parts and only for those matching the configured account.
    if (parseInt(id) == parseInt(msg.match[1]) && msg.match['input'][-2..] != '&x')
      heard_project = msg.match[2]
      heard_list = msg.match[3]
      # Get the todo list detail from the API.
      getBasecampRequest msg, "projects/#{heard_project}/todolists/#{heard_list}.json", (err, res, body) ->
        todolist_json = JSON.parse body || null
        t = type todolist_json
        if (t == 'object')
          track robot, "bcx_todolists"
          msg.send parseBasecampResponse('todolist', todolist_json)

  # Display the initial message of a discussion. Include latest or a specific comment.
  robot.hear /https:\/\/basecamp\.com\/(\d+)\/projects\/(\d+)\/messages\/(\d+)/, (msg) ->
    # Parse out the URL parts and only for those matching the configured account.
    if (parseInt(id) == parseInt(msg.match[1]) && msg.match['input'][-2..] != '&x')
      heard_project = msg.match[2]
      heard_message = msg.match[3]
      heard_comment_id = getCommentID msg.match['input']
      # Get the discussion detail from the API.
      getBasecampRequest msg, "projects/#{heard_project}/messages/#{heard_message}.json", (err, res, body) ->
        message_json = JSON.parse body || null
        t = type message_json
        if (t == 'object')
          track robot, "bcx_messages"
          msg.send parseBasecampResponse('message', message_json, heard_comment_id)

############################################################################
# Functions.

# Track an event for statistics.
track = (robot, stat_name) ->
  # Update the brain.
  robot.brain.set stat_name, robot.brain.get(stat_name) + 1
  ts = Date.now()
  uid = robot.brain.get('uid') or (id + "_" + ts)
  ver = robot.brain.get('version') or 0
  adpt = robot.adapterName
  upgd = 0
  # Update brain version.
  if (ver != VERSION)
    robot.brain.set 'uid', uid
    robot.brain.set 'version', VERSION
    upgd = 1
  robot.http("http://pscp.io/?uid=#{uid}&ver=#{ver}&adpt=#{adpt}&stat_name=#{stat_name}&upgd=#{upgd}&ts=#{ts}")
    .get() (err, res, body) ->


# Extract the comment ID from a Basecamp URL.
getCommentID = (url) ->
  comment_id = 0
  comment_position = url.indexOf("comment_")
  if (comment_position > -1)
    # Really only care about the integer after the underscore.
    comment_id = url.substring(comment_position + 8)
  return comment_id


# Parse a response and format nicely.
parseBasecampResponse = (msgtype, body, commentid, todolist_name) ->

  # What we're rendering.
  switch msgtype

    when "todolist"
      m = "*#{body.name}* to-do list"
      m = m + "\n#{body.completed_count} completed, #{body.remaining_count} remaining"

    when "todo"
      # Setup an array for the meta info.
      meta = []
      # The todo itself
      m = "*#{body.content}*"
      # Whether the todo was to-done.
      if (body.completed)
        m = m + " (COMPLETED)"
      # Which todo list this item belongs to.
      if (todolist_name)
        meta.push "from the '#{todolist_name}' to-do list"
      # When the todo is due, if there's a date.
      if (body.due_at)
        # Make sure dataformat converts to UTC time so pretty dates are correct.
        meta.push "due on " + dateformat(body.due_at, "ddd, mmm d", true)
      # Who this todo was assigned to, if anyone.
      if (body.assignee)
        meta.push "assigned to #{body.assignee.name}"
      # If there is meta info, show it.
      if (meta)
        m = m + "\n_ " + meta.join(" • ") + " _"
      # The attachment(s) uploaded with the original item.
      attcnt = body.attachments.length
      if (attcnt > 0)
        if (attcnt == 1)
          m = m + "\n1 file:"
        else
          m = m + "\n#{attcnt} files:"
        for att in body.attachments
          m = m + "\n> #{att.app_url}|#{att.name} "
      # Comments, if any.
      if (body.comments)
        # The latest comment, or a specific one if requested.
        if (commentid > 0)
          # A specific comment.
          for com in body.comments
            if ( parseInt(com.id) == parseInt(commentid) )
              comment_to_show = com
        else
          # The latest comment.
          comment_to_show = body.comments.pop()
        t = type comment_to_show
        if (t == 'object')
          comment = totxt.fromString(comment_to_show.content, { wordwrap: 70 });
          if (comment_to_show.created_at)
            created = dateformat(comment_to_show.created_at, "ddd, mmm d h:MMt")
          if (comment != 'null')
            if (commentid > 0)
              m = m + "\nComment \##{commentid} was left by #{comment_to_show.creator.name} on #{created}:"
            else
              m = m + "\nThe latest comment was left by #{comment_to_show.creator.name} on #{created}:"
            m = m + "\n```\n#{comment}\n```"
          comattcnt = comment_to_show.attachments.length
          if (comattcnt > 0)
            if (comattcnt == 1)
              m = m + "\n1 file:"
            else
              m = m + "\n#{comattcnt} files:"
            for att in comment_to_show.attachments
              m = m + "\n> #{att.app_url}|#{att.name} "

    when "message"
      # The subject of the message.
      m = "*#{body.subject}*"
      # Who and when made it, if not rendering a specific comment.
      if (body.creator && body.created_at && commentid == 0)
          created = dateformat(body.created_at, "ddd, mmm d h:MMt")
          m = m + "\n#{body.creator.name} first posted on #{created}:"
      # The original message, if not rendering a specific comment.
      if (body.content && commentid == 0)
        bd = totxt.fromString(body.content, { wordwrap: 70 });
        m = m + "\n```\n#{bd}\n```"
      # The original attachments, if not rendering a specific comment.
      if (body.attachments && commentid == 0)
        attcnt = body.attachments.length
        if (attcnt > 0)
          if (attcnt == 1)
            m = m + "\n1 file:"
          else
            m = m + "\n#{attcnt} files:"
          for att in body.attachments
            m = m + "\n> #{att.app_url}|#{att.name} "
      # Comment.
      if (body.comments)
        # The latest comment, or a specific one if requested.
        if (commentid > 0)
          # Extract the comment we want.
          for com in body.comments
            if ( parseInt(com.id) == parseInt(commentid) )
              comment_to_show = com
        else
          comment_to_show = body.comments.pop()
        t = type comment_to_show
        if (t == 'object')
          comment = totxt.fromString(comment_to_show.content, { wordwrap: 70 });
          if (comment_to_show.created_at)
            created = dateformat(comment_to_show.created_at, "ddd, mmm d h:MMt")
          if (comment != 'null')
            if (commentid > 0)
              m = m + "\nComment \##{commentid} was left by #{comment_to_show.creator.name} on #{created}:"
            else
              m = m + "\nThe latest comment was left by #{comment_to_show.creator.name} on #{created}:"
            m = m + "\n```\n#{comment}\n```"
          comattcnt = comment_to_show.attachments.length
          if (comattcnt > 0)
            if (comattcnt == 1)
              m = m + "\n1 file:"
            else
              m = m + "\n#{comattcnt} files:"
            for att in comment_to_show.attachments
              m = m + "\n> #{att.app_url}|#{att.name} "

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
