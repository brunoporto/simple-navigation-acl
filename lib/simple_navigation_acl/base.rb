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
        context=:default if context.nil?
        rules_keys = id==:all ? :all : SimpleNavigationAcl::AclRule.where(context: context).where(id: id).pluck(:key)
        container = navigation.is_a?(SimpleNavigation::Configuration) ? navigation.instance_variable_get(:@primary_navigation) : navigation
        filter_simple_navigation_with_rules!(container, rules_keys)
        true
      end

      def filter_simple_navigation_with_rules!(simple_navigation_item_container, keys)
        unless keys==:all
          simple_navigation_item_container.items.delete_if do |simple_navigation_item|
            if keys.include?(simple_navigation_item.key.to_s)
              sub_navigation = simple_navigation_item.sub_navigation
              filter_simple_navigation_with_rules!(sub_navigation, keys) if sub_navigation
              false
            else
              true
            end
          end
        end
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