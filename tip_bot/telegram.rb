require "telegram/bot"

class TipBot::Telegram < TipBot::Base
  def start!
    client.run do |client|
      client.listen { |message| message(message) }
    end
  end

  private

  def message(message)
    return if message.text.empty?
    text = message.text.split(" ")
    dispatch(text, message)
  end

  def dispatch(text, message)
    logger.info "#{text}"
    # command = text.shift
    # # case message.text
    # # when '/start'
    # #   bot.api.send_message(chat_id: message.chat.id, text: "Hello, #{message.from.first_name}")
    # # when '/stop'
    # #   bot.api.send_message(chat_id: message.chat.id, text: "Bye, #{message.from.first_name}")
    # # end
    #
    # case command
    # when "awaiting" then awaiting(data)
    # when "tip" then tip(text, data)
    # when "withdraw" then withdraw(text, data)
    # else
    #   unknown(command, data)
    # end
  end

  def unknown(command, data)
    say(data, "Unknown command: #{command}")
  end

  # rubocop:disable Metrics/AbcSize
  def tip(text, data)
    nickname = text.shift.to_s[2..-2]
    user = client.users[nickname]

    return say(data, "Unknown user: <@#{nickname}>") if user.nil?

    TipBot::User.new(nickname, dapp).tip(tip_value)

    say(data, "<@#{nickname}>, you've been tipped!")
  rescue Mobius::Client::Error::InsufficientFunds
    say(data, "<@#{nickname}>, TipBot have not sufficient balance to send tips!")
  rescue Mobius::Client::Error
    say(data, "<@#{nickname}>, Error sending tip!")
  end
  # rubocop:enable Metrics/AbcSize

  def awaiting(data)
    user = TipBot::User.new(data.user, dapp)
    say(data, "Your balance awaiting for withdraw is #{user.balance}, use @tipbot withdraw <address> to get your tips!")
  end

  def withdraw(text, data)
    address = text.shift
    TipBot::User.new(data.user, dapp).withdraw(address)
    return say(data, "Provide target address to withdraw!") if address.nil?
    say(data, "Your tips has been successfully withdrawn to #{address}!")
  rescue Mobius::Client::Error::UnknownKeyPairType
    say(data, "Invalid target address: #{address}")
  end

  def client
    @client ||= Telegram::Bot::Client.new(token, logger: logger)
  end

  def say(data, text)
    client.message(channel: data.channel, text: text)
  end

  def app
    @app ||= TipBot::App.new(dapp)
  end

  def tip_value
    (rate || 1).to_f
  end
end