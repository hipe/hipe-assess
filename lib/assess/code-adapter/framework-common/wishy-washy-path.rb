require 'assess/util/strict-attr-accessors'
require 'assess/util/sexpesque'
module Hipe
  module Assess
    module FrameworkCommon
      class WishyWashyPath
        extend UberAllesArray, StrictAttrAccessors
        attr_reader :path_id
        attr_accessor :might_have_extension
        boolean_attr_accessor :might_be_folder, :might_be_plural
        def initialize
          @relative_to_id = nil
          @path_id = self.class.register(self)
          @might_be_plural = false
          @might_be_folder = true
          @might_have_extension = nil
        end
        def clear
          @relative_to_id = nil
          @absolute_path = nil
          @relative_path = nil
        end
        def ancestors
          if relative?
            relative_to.ancestors + [path_id]
          else
            [path_id]
          end
        end
        def relative_to= path
          if @relative_to_id
            fail("already relative to something else. clear first.")
          end
          anc = path.ancestors
          if anc.include? path_id
            fail("won't make circular reference!")
          end
          @relative_to_id = path.path_id
        end
        def relative_to
          if @relative_to_id.nil?
            fail("check relative? first")
          end
          WishyWashyPath.all[@relative_to_id]
        end
        def relative?
          (! @relative_to_id.nil?) # don't care about @relative_path for now
        end
        def absolute?
          @relative_to_id.nil? && @absolute_path
        end
        def relative_path?
          ! @relative_path.nil?
        end
        def relative_path
          fail("no relative path. check relative_path? first") unless
            relative_path?
          @relative_path
        end
        SansRe = %r{^\./}
        def relative_path_sans
          relative_path.gsub(SansRe,'')
        end
        def relative_path= str
          if @abolute_path
            fail("won't relative path when absolute is set. clear first.")
          end
          unless @relative_to_id
            fail("won't set relative path unless relative_to is set first.")
          end
          @relative_path = str
        end
        def absolute_path= str
          if @relative_to_id || @relative_path
            fail("won't set abs path when relative properties exist."<<
              " clear first.")
          end
          @absolute_path = str
        end
        def absolute_path
          if absolute?
            @absolute_path
          elsif relative?
            File.expand_path(
              File.join(relative_to.absolute_path, relative_path)
            )
          else
            nil
          end
        end
        def pretty_path
          if absolute?
            if FileUtils.pwd == absolute_path
              resp = '.'
            else
              resp = absolute_path
            end
          elsif relative?
            pretty_base = relative_to.pretty_path
            resp = File.join(pretty_base, relative_path_sans)
          else
            resp = nil
          end
          resp
        end
        def absolute_path_resolved
          other = resolve absolute_path
          other ? other : absolute_path
        end
        def pretty_path_resolved
          other = resolve pretty_path
          other ? other : pretty_path
        end
        def summary
          s = Sexpesque
          arr = s.new
          arr.push s[:path, pretty_path_resolved]
          arr.push s[:exists, exists? ? :yes : :no  ]
          arr
        end
        def exists?
          File.exist?(absolute_path_resolved)
        end
        def path
          unless exists?
            fail("Path does not exist.  Check exists? first")
          end
          pretty_path_resolved
        end
      private

        #
        # Try the different permuations of the path
        # @return false if not found
        # thanks rue
        #
        def resolve path
          return nil if path.nil?
          lefts = [path]
          rights = ['']
          lefts.push("#{path}s") if might_be_plural?
          rights.push(might_have_extension) if might_have_extension
          try_these = lefts.map{|x| rights.map{|y| "#{x}#{y}"}}.flatten
          try_these.each do |try|
            if File.exist?(try)
              return try
            end
          end
          return false
        end # resolve
      end # WishyWashyPath
    end # FrameworkCommon
  end # Assess
end # Hipe