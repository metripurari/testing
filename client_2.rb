require 'drb'
@server = "druby://localhost:9000"
DRb.start_service
obj = DRbObject.new(nil, "druby://localhost:9000")

obj.messages ="Tripurari : Hi How are you"
obj.show_message