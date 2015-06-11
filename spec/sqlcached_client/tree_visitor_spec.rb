require 'sqlcached_client/tree_visitor'

describe SqlcachedClient::TreeVisitor do

  let(:fake_class) do
    Class.new(Object) do
      include SqlcachedClient::TreeVisitor

      attr_reader :subtrees, :depth

      def initialize(depth, subtrees)
        @depth = depth; @subtrees = subtrees
      end
    end
  end

  let(:fake_tree) do
    fake_class.new(0, [
      fake_class.new(1, [
        fake_class.new(2, [
            fake_class.new(3, []), fake_class.new(3, [])
          ])
        ]),
      fake_class.new(1, [])
    ])
  end

  let(:result_builder) do
    -> (root, subtrees) { [root, subtrees] }
  end


  describe :visit_in_preorder do

    context "with an empty tree" do
      it "is expected to visit the root element only" do
        tree = double(element: 'root', subtrees: [])
        tree.extend(SqlcachedClient::TreeVisitor)
        values = []
        tree.visit_in_preorder(:subtrees.to_proc,
          -> (el, parent, index) { values << el.element },
          result_builder)
        expect(values).to eq(['root'])
      end
    end

    it "is expected to be 0, 1, 2, 3, 3, 1" do
      values = []
      fake_tree.visit_in_preorder(:subtrees.to_proc,
        -> (item, parent, index) { values << item.depth },
        result_builder)
      expect(values).to eq([0, 1, 2, 3, 3, 1])
    end
  end
end
