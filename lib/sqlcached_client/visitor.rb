module SqlcachedClient
  module Visitor

    # @param get_subtrees [Proc]
    # @param visit [Proc]
    def visit_in_preorder(get_subtrees, visit, parent = nil, index = nil)
      [
        visit.(self, parent, index),
        get_subtrees.(self).map.with_index do |item, i|
          item.visit_in_preorder(get_subtrees, visit, self, i)
        end
      ]
    end
  end
end
