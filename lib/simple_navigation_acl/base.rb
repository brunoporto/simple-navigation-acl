module SimpleNavigationAcl
  class Base

    @contexts = [:default]
    @current_user_method = :current_user
    @entity = 'Role'
    @verify_method = 'role'

    class << self

      attr_accessor :current_user_method, :entity, :verify_method

      attr_reader :contexts

      def contexts=(contexts)
        contexts = [contexts] unless contexts.is_a?(Array)
        @contexts = contexts.map(&:to_sym)
        @contexts.uniq!
      end

      def navigations(obj_caller=nil, navigation_context=nil)
        navigations = {}
        contexts = if navigation_context.nil?
                     SimpleNavigationAcl::Base.contexts
                   else
                     navigation_context.is_a?(Array) ? navigation_context : [navigation_context]
                   end
        contexts.each do |context|
          SimpleNavigation::Helpers.load_config({context: context}, obj_caller)
          primary_navigation = SimpleNavigation.config.primary_navigation
          navigations[context] = get_nav_items(primary_navigation, context)
        end
        navigations
      end

      def apply_acl(navigation, id, context)

        container = navigation.is_a?(SimpleNavigation::Configuration) ? navigation.instance_variable_get(:@primary_navigation) : navigation
        rules_keys = SimpleNavigationAcl::AclRule.where(id: id, context: context).pluck(:key)
        filter_simple_navigation_with_rules!(container, rules_keys)

        #SimpleNavigation::ItemContainer . @items [SimpleNavigation::Item . @key, @sub_navigation [SimpleNavigation::ItemContainer] ]
        #SimpleNavigation::Configuration . @primary_navigation (SimpleNavigation::ItemContainer)


        # navs = get_nav_items(navigation.primary_navigation, context)
        # rules = SimpleNavigationAcl::AclRule.where(id: id, context: context)
        # raise navs.inspect
      end

      def filter_simple_navigation_with_rules!(simple_navigation_item_container, keys)
        items = simple_navigation_item_container.instance_variable_get(:@items)
        items.each_with_index do |simple_vavigation_item, index|
          key = simple_vavigation_item.instance_variable_get(:@key)
          if keys.include?(key.to_s)
            sub_navigation = simple_vavigation_item.instance_variable_get(:@sub_navigation)
            filter_simple_navigation_with_rules!(sub_navigation, keys) if sub_navigation.present?
          else
            items.delete_at(index)
          end
        end
        # simple_navigation_item_container.instance_variable_set(:@items, 5)
      end

      private
      def get_nav_items(nav, context=:default)
        nav.items.map do |item|
          items = {key: item.key, name: item.name, url: item.url, level: nav.level, context: context}
          items[:items] = get_nav_items(item.sub_navigation, context) if item.sub_navigation.present?
          items
        end
      end

      # def get_nav_items_inline(nav, parent_key=nil)
      #   items = []
      #   nav.items.each do |item|
      #     h_item = {key: item.key, name: item.name, url: item.url, level: nav.level}
      #     h_item[:parent_key] = parent_key unless parent_key.nil?
      #     items << h_item
      #     items = items + get_nav_items_inline(item.sub_navigation, item.key) if item.sub_navigation.present?
      #   end
      #   items
      # end

    end

  end
end