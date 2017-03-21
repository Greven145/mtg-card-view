# mtg-slack
### Slack slash command that retrieves Magic: The Gathering card information
![example image](https://raw.githubusercontent.com/jeffcampbell/mtg-slack/master/readme/screenshot.png)

### What you will need
* A [Heroku](http://www.heroku.com) account
* An [Outgoing Webhook token](https://api.slack.com/slash-commands) for your Slack team

### Setup
* Clone this repo locally
* Create a new Heroku app and initialize the repo
* Push the repo to Heroku
* Load your [Outgoing Webhook page](https://my.slack.com/services/new/outgoing-webhook) and add an outgoing Webhook for lookup, specifying the URL of our Heroku app and adding the /lookup route
* Load your [Outgoing Webhook page](https://my.slack.com/services/new/outgoing-webhook) and add an outgoing Webhook for search, specifying the URL of our Heroku app and adding the /search route
* Navigate to the settings page of the Heroku app and add the following config variables:
  * ```OUTGOING_WEBHOOK_TOKEN_LOOKUP``` The token from your lookup webhook
  * ```OUTGOING_WEBHOOK_TOKEN_SEARCH``` The token from your search webhook

Thanks to https://deckbrew.com/api/ for their awesome API
