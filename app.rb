# encoding: utf-8
require "rubygems"
require "bundler/setup"
Bundler.require(:default)

configure do
  # Load .env vars
  Dotenv.load
  # Disable output buffering
  $stdout.sync = true
end

get "/" do
  ""
end

post "/lookup" do
  response['content-type'] = 'application/json'
  response = ""
begin
  puts "[LOG] incoming lookup params: #{params}"
  params[:text] = params[:text]
  unless params[:token] != ENV["OUTGOING_WEBHOOK_TOKEN_LOOKUP"]
    cardData = lookupCardByName
    response = { text: generate_text(cardData) }
    response[:response_type] = "in_channel"
    response[:attachments] = [ generate_attachment(cardData) ]
    response = response.to_json
  end
end
  status 200
  body response
end

post "/search" do
  response['content-type'] = 'application/json'
  response = ""
begin
  puts "[LOG] incoming search params: #{params}"
  params[:text] = params[:text]
  unless params[:token] != ENV["OUTGOING_WEBHOOK_TOKEN_SEARCH"]
    cardData = searchCardName
    response = { text: generate_search_text(cardData) }
    response[:response_type] = "in_channel"
    #response[:attachments] = [ generate_attachment(cardData) ]
    response = response.to_json
  end
end
  status 200
  body response
end

def lookupCardByName
  @user_query = params[:text].sub(/^!/,'').sub(/^\s/,'').sub(/\|[A-Z1-9]{3}$/i,'').gsub(/\s/,'-').gsub(/\'/,'').downcase

  if @user_query.length == 0
    uri = "https://api.deckbrew.com/mtg/colors"
  else
    #uri = "https://api.deckbrew.com/mtg/cards?name=#{@user_query}"
    uri = "https://api.deckbrew.com/mtg/cards/#{@user_query}"
  end

  puts "[LOG] api uri: #{uri}"

  request = HTTParty.get(uri)
  puts "[LOG] request.body: #{request.body}"
  if request.code == 200
    return [ JSON.parse(request.body) ]
  end
  return searchCardName
end

def searchCardName
  @user_query = params[:text].sub(/^[!\?]/,'').sub(/^\s/,'').gsub(/\s/,'+').gsub(/\'/,'').downcase

  uri = "https://api.deckbrew.com/mtg/cards?name=#{@user_query}"

  puts "[LOG] api uri: #{uri}"

  request = HTTParty.get(uri)
  puts "[LOG] request.body: #{request.body}"
  return JSON.parse(request.body)
end

def generate_text(cardData)
  if cardData[0].nil?
    response = "No matching card found."
  else
    @cardname = cardData[0]["name"]
    response = "#{@cardname}"
  end
  response
end

def generate_search_text(cardData)
  response = ""
  if cardData[0].nil?
    response = "No matching card found."
  else
    cardData.each{ |x, i|
      @cardName = x['name']
      x["editions"].each{ |e, i|
        @editionSymbol = e['set_id']
        @search = "- !#{@cardName}|#{@editionSymbol}"
        puts "[Log] Search result added: #{@search}"
        response = response + @search + "\n"
      }
    }
  end
  response = "The following search items were found:\n" + response
  response
end

def generate_attachment(cardData)
  replacements = [
    ["{W/P}", ":whitephyrexian:"],
    ["{U/P}", ":bluephyrexian:"],
    ["{B/P}", ":blackphyrexian:"],
    ["{R/P}", ":redphyrexian:"],
    ["{G/P}", ":greenphyrexian:"],
    ["{W}", ":whitemana:"],
    ["{U}", ":bluemana:"],
    ["{B}", ":blackmana:"],
    ["{R}", ":redmana:"],
    ["{G}", ":greenmana:"],
    ["{X}", ":xsymbol:"],
    ["{0}", ":0:"],
    ["{1}", ":1:"],
    ["{2}", ":2:"],
    ["{3}", ":3:"],
    ["{4}", ":4:"],
    ["{5}", ":5:"],
    ["{6}", ":6:"],
    ["{7}", ":7:"],
    ["{8}", ":8:"],
    ["{9}", ":9:"],
    ["{10}", ":10:"],
    ["{11}", ":11:"],
    ["{12}", ":12:"],
    ["{15}", ":15:"],
    ["{", ""],
    ["}", ""]
  ]
  if cardData[0].nil?
    response = ""
  else
  @cardtext = cardData[0]["text"]
  @imageurl = generate_image_url cardData[0]["editions"]
  @types = cardData[0]["types"][0]
  @cost = cardData[0]["cost"]

  replacements.each {|replacement| @cost.gsub!(replacement[0], replacement[1])}
  replacements.each {|replacement| @cardtext.gsub!(replacement[0], replacement[1])}

  response = {
            text: "#{@cardtext}",
            fields: [
                {
                    "title": "Types",
                    "value": "#{@types}",
                    "short": true
                },
                {
                    "title": "Cost",
                    "value": "#{@cost}",
                    "short": true
                },
            ],
            image_url: "#{@imageurl}"
          }
  end
response
end

def generate_image_url(editions)
  @user_query = params[:text].sub(/^[!\?]/,'').sub(/^\s/,'').gsub(/\s/,'+').gsub(/\'/,'').downcase

  if /\|[A-Z1-9]{3}$/i.match(@user_query)
    @edition = @user_query[-3,3].upcase
    puts "[LOG] @edition #{@edition}"

    editions.each{ |e|
      puts "[LOG] Checking edition: " + e['set_id']
      if e['set_id'] == @edition
        return e['image_url']
      end
    }
    return "https://image.deckbrew.com/mtg/multiverseid/0.jpg"
  end

  editions.each{ |x, i|
    if !x["image_url"].end_with?("/0.jpg")
      return x["image_url"]
    else
      puts "[LOG] skipping image for edition: " + x["set"]
    end
  }
  return "https://image.deckbrew.com/mtg/multiverseid/0.jpg"
end