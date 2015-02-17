# Basecamp URL Expander for Hubot

A simple bot that listens for [basecamp.com](http://basecamp.com/) discussions and todos expanding them with more useful information via the [Basecamp API](https://github.com/basecamp/bcx-api/).

Recognizes
* discussions
* individual todos
* todo lists

Renders
* discussion title, first post and latest comment
* todo title, due date, assignee, first post, latest comment
* specific comments on discussions and todos if `#comment_12345678` URL fragments are detected
* direct links to associated files
* todo list summary

## Examples
### Individual todo
In [Slack](http://slack.com/) individual todo URLs of the form `https://basecamp.com/1234567/projects/1234567/todos/123456789` with an assignee, due date and attachments look something like this
![hubot-basecamp-demo-1](https://www.evernote.com/shard/s248/sh/ef176564-c382-47ab-9f4f-86211d2dde68/3178dd932a8fd6870f254a2d5c274cb4/deep/0/Slack.png)

### Discussion with specific comment
You can also just extract a particular comment from a discussion (or a todo) by including the fragment in the URL. So, something like `https://basecamp.com/1234567/projects/1234567/messages/12345678#comment_123456789` looks something like this
![hubot-basecamp-demo-2](https://www.evernote.com/shard/s248/sh/a01ee471-c158-4d2d-9804-6181634c3df3/46ff5569183ec0708133de930b9b4039/deep/0/test---TEN7-Slack.png)


### Todo list
Summary information for a todolist is also provided:
![hubot-basecamp-demo-3](https://www.evernote.com/shard/s248/sh/f07bf604-e5e5-42e3-9cf9-ce0eab605014/702a138455f6377de34ad27fb5e84bad/deep/0/test---TEN7-Slack.png)

## Installation

In hubot project repo, run:

`npm install hubot-basecamp --save`

Then add **hubot-basecamp** to your `external-scripts.json`:

```json
["hubot-basecamp"]
```

## Configuration

You'll need to configure the following environment variables so that hubot knows about your Basecamp account:
```
HUBOT_BCX_ACCOUNT_ID
HUBOT_BCX_USERNAME
HUBOT_BCX_PASSWORD
```

The `HUBOT_BCX_ACCOUNT_ID` is the number that comes directly after `basecamp.com` in the URL after you are logged into your account. For example, in `https://basecamp.com/1234567/projects/7654321/todolists` it would be `1234567`.

You can use your own username (or email address) and password in the configuration of `HUBOT_BCX_USERNAME` and `HUBOT_BCX_PASSWORD` -- hubot will only have access to those projects that this user has access to. It's a good idea to:
* create a user for hubot in your Basecamp project
* add this user to all projects
* add this user to any templates you have so hubot gets added to new template based projects

## Issues and Feature Requests
If you're having an issue, please [describe it](https://github.com/hubot-scripts/hubot-basecamp/issues/) to me, and I'll do my best to address is.

If you've got a good idea for something hubot should do, [create the issue](https://github.com/hubot-scripts/hubot-basecamp/issues/) and tag it as an `enhancement`.
