require 'drb'
class Chat
  attr_accessor :messages
  def show_message
    puts @message
  end
  
end

@server = "druby://localhost:9000"
@p = Chat.new
DRb.start_service(@server, @p)
DRb.thread.join
