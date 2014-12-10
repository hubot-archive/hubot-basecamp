# Basecamp in Hubot

Provides text previews of Basecamp urls. Something like this:


![hubot-basecamp-demo](https://raw.githubusercontent.com/hubot-scripts/hubot-basecamp/master/images/hubot-basecamp-preview.png)

This script monitors chat for basecamp.com urls and:
* shows todos and includes the latest comment for urls of the form https://basecamp.com/1234567/projects/1234567/todos/123456789
* shows todo list names and lists outstanding and completed count for urls of the form https://basecamp.com/1234567/projects/1234567/todolists/12345678
* shows a discussion's subject, first message and latest comment for urls of the form https://basecamp.com/1234567/projects/1234567/messages/123456789


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
If you're having an issue, please [describe it](https://github.com/hubot-scripts/hubot-basecamp/issues/new) to me, and I'll do my best to address is.

If you've got a good idea for something hubot should do, [create the issue](https://github.com/hubot-scripts/hubot-basecamp/issues/new) and tag it as an enhancement.
