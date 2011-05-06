module Enumerable
  def sort_any(sort_candidates)
    self.sort do |e1, e2|
      e1.instance_variable_get("@#{sort_candidates[e1.class.to_s.to_sym]}") <=> e2.instance_variable_get("@#{sort_candidates[e2.class.to_s.to_sym]}")
    end
  end
end

class FieldsToSort
  def initialize(options = {})
    options.each do |key, value|
      instance_variable_set("@#{key}", value)
    end
  end
end




class A
  
  attr_accessor :first_name
end

class B
  attr_accessor :title
end

class C
  attr_accessor :last_name
end

a,b,c = A.new, B.new, C.new
a.first_name = "abc"
b.title = "def"
c.last_name = "xyz"
arr = [b, a, c]
@sort = FieldsToSort.new(:A => :first_name, :B => :title, :C => :last_name)
p arr.sort_any(@sort)

