require 'drb'
@server = "druby://localhost:9000"
DRb.start_service
obj = DRbObject.new(nil, "druby://localhost:9000")

obj.messages ="Debashis : I am Fine"
obj.show_message