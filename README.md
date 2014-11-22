# Basecamp in Hubot - hubot-basecamp

Provides text previews of Basecamp URLs.

![hubot-basecamp-demo](https://cloud.githubusercontent.com/assets/509217/5155887/0a6248a8-7263-11e4-9cb6-ae8d4c4b1742.png)

## Installation

In hubot project repo, run:

`npm install hubot-basecamp --save`

Then add **hubot-basecamp** to your `external-scripts.json`:

```json
["hubot-basecamp"]
```

## Configuration

You'll need to configure environment variables so that hubot knows about your Basecamp account:
```HUBOT_BCX_ACCOUNT_ID
HUBOT_BCX_USERNAME
HUBOT_BCX_PASSWORD
```

The `HUBOT_BCX_ACCOUNT_ID` is the number that comes directly after `basecamp.com` in the URL after you are logged into your account. For example, in `https://basecamp.com/12345678/projects/7654321/todolists` it would be `12345678`.

You can use your own username (or email address) and password in the configuration of `HUBOT_BCX_USERNAME` and `HUBOT_BCX_PASSWORD` -- hubot will only have access to those projects that this user has access to. It's a good idea to:
* create a user for hubot in your Basecamp project
* add this user to all projects
* add this user to any templates you have so hubot gets added to new template based projects

## Issues
Issues are tracked in Github.
